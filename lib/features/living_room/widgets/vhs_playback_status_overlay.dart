import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/living_room/widgets/static_screen.dart';

/// VHS-themed feedback for a stream that errors or never begins advancing.
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
    this.trackingDelay = const Duration(seconds: 6),
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
  final Duration trackingDelay;

  @override
  State<VhsPlaybackStatusOverlay> createState() =>
      _VhsPlaybackStatusOverlayState();
}

class _VhsPlaybackStatusOverlayState extends State<VhsPlaybackStatusOverlay> {
  final _subscriptions = <StreamSubscription<Object?>>[];
  Timer? _trackingTimer;
  late Duration _lastPosition;
  late bool _playing;
  late bool _buffering;
  var _hasPlaybackProgress = false;
  var _showTracking = false;
  String? _pendingError;
  String? _error;

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
    }
  }

  void _bind() {
    _playing = widget.initialPlaying;
    _buffering = widget.initialBuffering;
    _lastPosition = widget.initialPosition;
    _hasPlaybackProgress = false;
    _showTracking = false;
    _pendingError = widget.initialError;
    _error = null;
    _armTrackingTimer();

    _subscriptions
      ..add(widget.playing.listen(_onPlaying))
      ..add(widget.buffering.listen(_onBuffering))
      ..add(widget.position.listen(_onPosition))
      ..add(widget.errors.listen(_onError));
  }

  void _unbind() {
    _trackingTimer?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }

  void _armTrackingTimer() {
    _trackingTimer?.cancel();
    _trackingTimer = Timer(widget.trackingDelay, () {
      if (!mounted || _error != null) return;
      if (_hasPlaybackProgress) return;
      setState(() {
        _error = _pendingError;
        _showTracking = _pendingError == null;
      });
    });
  }

  void _onPlaying(bool value) {
    _playing = value;
    if (!value && !_hasPlaybackProgress) {
      _armTrackingTimer();
    }
  }

  void _onBuffering(bool value) {
    _buffering = value;
    if (value) {
      _hasPlaybackProgress = false;
      _armTrackingTimer();
    } else if (_playing && _hasPlaybackProgress) {
      _clearStatus();
    }
  }

  void _onPosition(Duration value) {
    if (value == _lastPosition) return;
    final advanced = value > _lastPosition;
    _lastPosition = value;
    if (_playing && advanced) {
      _hasPlaybackProgress = true;
      if (!_buffering) _clearStatus();
    }
  }

  void _onError(String message) {
    if (message.trim().isEmpty || !mounted) return;
    _pendingError = message;
    _hasPlaybackProgress = false;
    _armTrackingTimer();
  }

  void _clearStatus() {
    _trackingTimer?.cancel();
    if (!mounted) return;
    final recovered = _pendingError != null || _error != null;
    if (!_showTracking && !recovered) return;
    setState(() {
      _showTracking = false;
      _pendingError = null;
      _error = null;
    });
    if (recovered) widget.onRecovered();
  }

  Future<void> _retry() async {
    setState(() {
      _pendingError = null;
      _error = null;
      _showTracking = true;
    });
    _lastPosition = widget.initialPosition;
    _hasPlaybackProgress = false;
    _armTrackingTimer();
    try {
      await widget.onRetry();
    } catch (_) {
      if (!mounted) return;
      _trackingTimer?.cancel();
      setState(() {
        _error = 'retry failed';
        _showTracking = false;
      });
    }
  }

  @override
  void dispose() {
    _unbind();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error == null && !_showTracking) return const SizedBox.shrink();

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.88),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Opacity(opacity: 0.22, child: StaticScreen(intensity: 0.35)),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: _PlaybackStatusCard(
                failed: _error != null,
                onRetry: _retry,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaybackStatusCard extends StatelessWidget {
  const _PlaybackStatusCard({required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101412).withValues(alpha: 0.92),
        border: Border.all(color: VhsColors.phosphorDim),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              failed ? Icons.warning_amber_rounded : Icons.track_changes,
              color: VhsColors.phosphor,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              failed ? 'TAPE READ ERROR' : 'ADJUSTING TRACKING',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: VhsColors.phosphor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              failed
                  ? 'CHECK SERVER OR TRY THE TAPE AGAIN'
                  : 'THE SIGNAL IS TAKING A WHILE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: VhsColors.brand.withValues(alpha: 0.72),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.replay_rounded, size: 15),
              label: const Text('RE-TRACK'),
            ),
          ],
        ),
      ),
    );
  }
}
