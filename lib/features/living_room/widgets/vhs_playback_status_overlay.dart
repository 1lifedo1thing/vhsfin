import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// What a VCR shows when the tape isn't giving a clean picture: a PLAY
/// readout as playback starts, rolling tracking noise while the signal
/// stalls, a TRACKING readout if it stays lost, and the blue screen when the
/// stream fails outright.
class VhsPlaybackStatusOverlay extends StatefulWidget {
  const VhsPlaybackStatusOverlay({
    super.key,
    required this.playing,
    required this.buffering,
    required this.position,
    required this.errors,
    required this.initialPlaying,
    required this.initialBuffering,
    required this.initialPosition,
    required this.initialError,
    required this.onRetry,
    required this.onRecovered,
    this.shuttling = false,
    this.startDelay = const Duration(seconds: 20),
    this.trackingDelay = const Duration(seconds: 10),
    this.noiseDelay = const Duration(milliseconds: 1500),
  });

  final Stream<bool> playing;
  final Stream<bool> buffering;
  final Stream<Duration> position;
  final Stream<String> errors;
  final bool initialPlaying;
  final bool initialBuffering;
  final Duration initialPosition;
  final String? initialError;
  final Future<void> Function() onRetry;
  final VoidCallback onRecovered;

  /// REW/FF held: the picture jumps around on purpose, so don't call it lost.
  final bool shuttling;

  /// Patience before the first frame (Jellyfin may still be transcoding).
  final Duration startDelay;

  /// Patience for a stall once the tape has been playing, and for errors.
  final Duration trackingDelay;

  /// How soon a stall starts showing tracking noise.
  final Duration noiseDelay;

  @override
  State<VhsPlaybackStatusOverlay> createState() =>
      _VhsPlaybackStatusOverlayState();
}

enum _Signal { clean, noisy, tracking, failed }

class _VhsPlaybackStatusOverlayState extends State<VhsPlaybackStatusOverlay> {
  final _subscriptions = <StreamSubscription<Object?>>[];
  Timer? _noiseTimer;
  Timer? _trackingTimer;
  Timer? _playOsdTimer;
  late Duration _lastPosition;
  late bool _playing;
  late bool _buffering;
  var _started = false;
  var _progressing = false;
  var _signal = _Signal.clean;
  var _showPlayOsd = false;
  String? _pendingError;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(covariant VhsPlaybackStatusOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playing != widget.playing ||
        oldWidget.buffering != widget.buffering ||
        oldWidget.position != widget.position ||
        oldWidget.errors != widget.errors) {
      _unbind();
      _bind();
      return;
    }
    if (oldWidget.shuttling != widget.shuttling) {
      if (widget.shuttling) {
        _cancelStallTimers();
        _setSignal(_Signal.clean);
      } else {
        // Judge the picture afresh once the shuttle lets go.
        _progressing = false;
        _armStallTimers();
      }
    }
  }

  void _bind() {
    _playing = widget.initialPlaying;
    _buffering = widget.initialBuffering;
    _lastPosition = widget.initialPosition;
    _started = false;
    _progressing = false;
    _signal = _Signal.clean;
    _pendingError = widget.initialError;
    _armStallTimers();

    _subscriptions
      ..add(widget.playing.listen(_onPlaying))
      ..add(widget.buffering.listen(_onBuffering))
      ..add(widget.position.listen(_onPosition))
      ..add(widget.errors.listen(_onError));
  }

  void _unbind() {
    _cancelStallTimers();
    _playOsdTimer?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }

  void _cancelStallTimers() {
    _noiseTimer?.cancel();
    _trackingTimer?.cancel();
  }

  /// Escalate clean → noisy → tracking/failed while nothing advances.
  void _armStallTimers() {
    _cancelStallTimers();
    if (widget.shuttling) return;
    if (!_playing && _pendingError == null) return;
    _noiseTimer = Timer(widget.noiseDelay, () {
      if (!mounted || _progressing) return;
      if (_signal == _Signal.clean) _setSignal(_Signal.noisy);
    });
    final patience = _pendingError != null || _started
        ? widget.trackingDelay
        : widget.startDelay;
    _trackingTimer = Timer(patience, () {
      if (!mounted || _progressing) return;
      _setSignal(_pendingError != null ? _Signal.failed : _Signal.tracking);
    });
  }

  void _setSignal(_Signal next) {
    if (_signal == next || !mounted) return;
    setState(() => _signal = next);
  }

  void _onPlaying(bool value) {
    _playing = value;
    if (!value && _pendingError == null) {
      // Paused is a still picture, not a lost one.
      _cancelStallTimers();
      if (_signal != _Signal.failed) _setSignal(_Signal.clean);
      return;
    }
    _progressing = false;
    _armStallTimers();
  }

  void _onBuffering(bool value) {
    _buffering = value;
    if (value && _playing) {
      _progressing = false;
      _armStallTimers();
    } else if (_playing && _progressing) {
      _clearStatus();
    }
  }

  void _onPosition(Duration value) {
    if (value == _lastPosition) return;
    final advanced = value > _lastPosition;
    _lastPosition = value;
    if (_playing && advanced) {
      _progressing = true;
      if (!_buffering) _clearStatus();
    }
  }

  void _onError(String message) {
    if (message.trim().isEmpty || !mounted) return;
    _pendingError = message;
    _progressing = false;
    _armStallTimers();
  }

  void _clearStatus() {
    _cancelStallTimers();
    if (!mounted) return;
    if (!_started) {
      _started = true;
      // A deck flashes PLAY when the picture locks.
      setState(() => _showPlayOsd = true);
      _playOsdTimer = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _showPlayOsd = false);
      });
    }
    final recovered = _pendingError != null || _signal == _Signal.failed;
    _pendingError = null;
    _setSignal(_Signal.clean);
    if (recovered) widget.onRecovered();
  }

  Future<void> _retry() async {
    _pendingError = null;
    _started = false;
    _progressing = false;
    _lastPosition = widget.initialPosition;
    _setSignal(_Signal.noisy);
    _armStallTimers();
    try {
      await widget.onRetry();
    } catch (_) {
      if (!mounted) return;
      _cancelStallTimers();
      _pendingError = 'retry failed';
      _setSignal(_Signal.failed);
    }
  }

  @override
  void dispose() {
    _unbind();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final unit = (constraints.maxHeight / 12).clamp(9.0, 30.0);
        return switch (_signal) {
          _Signal.failed => _BlueScreen(unit: unit, onRetry: _retry),
          _Signal.tracking => Stack(
            fit: StackFit.expand,
            children: [
              const _TrackingNoise(strength: 1),
              _TrackingReadout(unit: unit, onRetry: _retry),
            ],
          ),
          _Signal.noisy => const _TrackingNoise(strength: 0.6),
          _Signal.clean when _showPlayOsd => _Osd(
            unit: unit,
            alignment: Alignment.topLeft,
            child: _OsdText('PLAY ▶', unit: unit),
          ),
          _Signal.clean => const SizedBox.shrink(),
        };
      },
    );
  }
}

/// On-screen display text: chunky, white, hard black edge — like a VCR's
/// character generator laid over the picture.
class _OsdText extends StatelessWidget {
  const _OsdText(this.text, {required this.unit, this.dim = false});

  final String text;
  final double unit;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.vt323(
        fontSize: unit * 1.25,
        height: 1,
        letterSpacing: unit * 0.12,
        color: dim ? const Color(0xCCE9F1F2) : const Color(0xFFF4FAFA),
        shadows: const [
          Shadow(color: Colors.black, offset: Offset(1.5, 1.5)),
          Shadow(color: Color(0x6629C7CF), blurRadius: 6),
        ],
      ),
    );
  }
}

class _Osd extends StatelessWidget {
  const _Osd({
    required this.unit,
    required this.child,
    this.alignment = Alignment.center,
  });

  final double unit;
  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: alignment == Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.fromLTRB(unit * 1.4, unit * 1.1, unit, unit),
        child: Align(alignment: alignment, child: child),
      ),
    );
  }
}

/// A tappable OSD line — the deck's own "menu" affordance.
class _OsdButton extends StatelessWidget {
  const _OsdButton({
    required this.label,
    required this.unit,
    required this.onTap,
  });

  final String label;
  final double unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: unit * 0.6,
            vertical: unit * 0.35,
          ),
          child: _OsdText('▶ $label', unit: unit),
        ),
      ),
    );
  }
}

class _TrackingReadout extends StatelessWidget {
  const _TrackingReadout({required this.unit, required this.onRetry});

  final double unit;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _Osd(
      unit: unit,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OsdText('TRACKING', unit: unit),
            SizedBox(height: unit * 0.5),
            _TrackingMeter(unit: unit),
            SizedBox(height: unit * 0.8),
            _OsdButton(label: 'RE-TRACK', unit: unit, onTap: onRetry),
          ],
        ),
      ),
    );
  }
}

/// The deck's tracking bar: a marker hunting back and forth for the signal.
class _TrackingMeter extends StatefulWidget {
  const _TrackingMeter({required this.unit});
  final double unit;

  @override
  State<_TrackingMeter> createState() => _TrackingMeterState();
}

class _TrackingMeterState extends State<_TrackingMeter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hunt = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    _hunt.repeat(reverse: true);
  }

  @override
  void dispose() {
    _hunt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cells = 13;
    return AnimatedBuilder(
      animation: _hunt,
      builder: (context, _) {
        // Stepped like a character display, never smooth.
        final at = (Curves.easeInOut.transform(_hunt.value) * (cells - 1))
            .round();
        return _OsdText(
          [for (var i = 0; i < cells; i++) i == at ? '█' : '-'].join(),
          unit: widget.unit * 0.8,
          dim: true,
        );
      },
    );
  }
}

/// Classic "blue back": the deck gives up on the picture and says so.
class _BlueScreen extends StatelessWidget {
  const _BlueScreen({required this.unit, required this.onRetry});

  final double unit;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1631C4),
      child: _Osd(
        unit: unit,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OsdText('TAPE ERROR', unit: unit),
              SizedBox(height: unit * 0.45),
              _OsdText('CHECK THE SERVER', unit: unit * 0.72, dim: true),
              SizedBox(height: unit * 0.9),
              _OsdButton(label: 'RETRY', unit: unit, onTap: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rolling tracking noise: a band of torn scanlines drifting down the screen
/// with a few stray dropouts, over the (frozen) picture.
class _TrackingNoise extends StatefulWidget {
  const _TrackingNoise({required this.strength});

  final double strength;

  @override
  State<_TrackingNoise> createState() => _TrackingNoiseState();
}

class _TrackingNoiseState extends State<_TrackingNoise>
    with SingleTickerProviderStateMixin {
  late final AnimationController _roll = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void initState() {
    super.initState();
    if (!WidgetsBinding.instance.disableAnimations) _roll.repeat();
  }

  @override
  void dispose() {
    _roll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _TrackingNoisePainter(_roll, widget.strength),
        ),
      ),
    );
  }
}

class _TrackingNoisePainter extends CustomPainter {
  _TrackingNoisePainter(this.roll, this.strength) : super(repaint: roll);

  final Animation<double> roll;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final t = roll.value;
    // New grain every ~40ms, like fields of a video frame.
    final rng = math.Random((t * 80).floor());
    final w = size.width;
    final h = size.height;

    // Slight darkening: the picture has lost sync.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.18 * strength),
    );

    final bandH = h * 0.16;
    final bandY = -bandH + (h + bandH * 2) * t;
    final line = Paint()..strokeWidth = 1;
    for (var y = bandY; y < bandY + bandH; y += 1.5) {
      if (y < 0 || y > h) continue;
      final edge = 1 - ((y - bandY) / bandH * 2 - 1).abs(); // 0 → 1 → 0
      var x = -rng.nextDouble() * 30;
      while (x < w) {
        final len = 4 + rng.nextDouble() * 40 * edge;
        final a = (0.15 + rng.nextDouble() * 0.6) * edge * strength;
        line.color = Color.fromRGBO(235, 245, 245, a);
        canvas.drawLine(Offset(x, y), Offset(x + len, y), line);
        x += len + rng.nextDouble() * 24;
      }
    }

    // Stray dropouts elsewhere on the frame.
    for (var i = 0; i < (10 * strength).round(); i++) {
      final y = rng.nextDouble() * h;
      final x = rng.nextDouble() * w;
      line.color = Color.fromRGBO(255, 255, 255, 0.25 + rng.nextDouble() * 0.4);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + 6 + rng.nextDouble() * 30, y),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_TrackingNoisePainter oldDelegate) =>
      oldDelegate.strength != strength;
}
