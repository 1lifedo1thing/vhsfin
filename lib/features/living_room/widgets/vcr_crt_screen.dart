import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/living_room/widgets/crt_glass_overlay.dart';
import 'package:vhsfin/features/living_room/widgets/crt_rewind_overlay.dart';
import 'package:vhsfin/features/living_room/widgets/static_screen.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_playback_status_overlay.dart';
import 'package:vhsfin/features/playback/state/deck_player.dart';

/// The CRT screen inside the VCR bezel — static, insert anim, or playback.
class VcrCrtScreen extends StatefulWidget {
  const VcrCrtScreen({
    super.key,
    required this.power,
    required this.style,
    required this.player,
    required this.surfaceEpoch,
    required this.surfaceOwner,
    this.tape,
    this.resumeAt,
    this.rewinding = false,
    this.screenRadius = 3,
    this.videoSurface,
  });

  final VcrPower power;
  final PlaybackStyle style;
  final Tape? tape;
  final DeckPlayerController player;
  final int surfaceEpoch;
  final DeckSurfaceOwner surfaceOwner;
  final Duration? resumeAt;
  final bool rewinding;

  /// Squircle-ish CRT aperture — higher for bubble / WEGA looks.
  final double screenRadius;
  final Widget? videoSurface;

  @override
  State<VcrCrtScreen> createState() => _VcrCrtScreenState();
}

class _VcrCrtScreenState extends State<VcrCrtScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _insertController;
  late final Animation<Offset> _insertSlide;
  var _syncGen = 0;

  @override
  void initState() {
    super.initState();
    _insertController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _insertSlide = Tween<Offset>(begin: const Offset(0, 1.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _insertController,
            curve: Curves.easeInOutCubic,
          ),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPlayback());
  }

  @override
  void didUpdateWidget(covariant VcrCrtScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.power != widget.power ||
        oldWidget.tape?.id != widget.tape?.id) {
      _syncPlayback();
    }
    // Coming back from fullscreen — living room reattaches; nudge play after
    // the new Video surface paints (web HtmlElementView needs a frame).
    final regainedSurface =
        oldWidget.surfaceOwner != DeckSurfaceOwner.crt &&
        widget.surfaceOwner == DeckSurfaceOwner.crt;
    if (regainedSurface &&
        widget.power == VcrPower.playing &&
        widget.surfaceOwner == DeckSurfaceOwner.crt) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (widget.surfaceOwner != DeckSurfaceOwner.crt) return;
        await widget.player.play();
      });
    }
  }

  Future<void> _syncPlayback() async {
    final gen = ++_syncGen;
    final deck = widget.player;
    final tape = widget.tape;

    switch (widget.power) {
      case VcrPower.off:
        _insertController.value = 0;
      case VcrPower.ejecting:
        await deck.stop();
        if (!mounted || gen != _syncGen) return;
        _insertController.value = 0;
      case VcrPower.inserting:
        if (tape != null && tape.streamUrl.isNotEmpty) {
          try {
            await deck.load(tape.streamUrl, play: false);
          } catch (_) {
            // The playback status overlay presents the retained player error.
          }
        }
        if (!mounted || gen != _syncGen) return;
        await _insertController.forward(from: 0);
      case VcrPower.playing:
        _insertController.value = 1;
        if (tape == null || tape.streamUrl.isEmpty) return;
        try {
          await deck.load(tape.streamUrl, play: true, seekTo: widget.resumeAt);
        } catch (_) {
          // The playback status overlay presents the retained player error.
        }
    }
  }

  Future<void> _retryPlayback() async {
    final tape = widget.tape;
    if (tape == null || tape.streamUrl.isEmpty) return;
    await widget.player.stop();
    if (!mounted) return;
    await widget.player.load(tape.streamUrl, play: true);
  }

  @override
  void dispose() {
    _insertController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showVideo =
        widget.style == PlaybackStyle.vhsCrt &&
        (widget.power == VcrPower.playing ||
            (widget.power == VcrPower.inserting && widget.tape != null));

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.screenRadius),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            if (showVideo && widget.videoSurface != null) widget.videoSurface!,
            // Ejecting = black while the clunk plays; off = snow.
            if (widget.power == VcrPower.off) const StaticScreen(),
            if (widget.power == VcrPower.inserting)
              SlideTransition(
                position: _insertSlide,
                child: _InsertingTapeLabel(title: widget.tape?.title ?? ''),
              ),
            if (widget.power == VcrPower.playing &&
                widget.style == PlaybackStyle.vhsCrt)
              const CrtGlassOverlay(),
            if (widget.rewinding && widget.power == VcrPower.playing)
              const CrtRewindOverlay(),
            if (widget.power == VcrPower.playing &&
                widget.style == PlaybackStyle.vhsCrt &&
                widget.player.isReady)
              VhsPlaybackStatusOverlay(
                key: ValueKey(widget.tape?.id),
                playing: widget.player.player.stream.playing,
                buffering: widget.player.player.stream.buffering,
                position: widget.player.player.stream.position,
                errors: widget.player.errors,
                initialPlaying: widget.player.player.state.playing,
                initialBuffering: widget.player.player.state.buffering,
                initialPosition: widget.player.player.state.position,
                initialError: widget.player.lastError,
                onRetry: _retryPlayback,
                onRecovered: widget.player.clearLastError,
              ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.65),
                    width: 3,
                  ),
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.15,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsertingTapeLabel extends StatelessWidget {
  const _InsertingTapeLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VhsColors.tapeShell.withValues(alpha: 0.92),
      child: Center(
        child: Text(
          'LOADING\n${title.toUpperCase()}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF2A1810),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
