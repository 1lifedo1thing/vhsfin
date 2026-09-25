import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/living_room/widgets/crt_glass_overlay.dart';
import 'package:vhsfin/features/living_room/widgets/crt_rewind_overlay.dart';
import 'package:vhsfin/features/living_room/widgets/static_screen.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_playback_status_overlay.dart';
import 'package:vhsfin/features/playback/state/deck_player.dart';

/// The CRT screen inside the VCR bezel — static, loading, or playback.
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

class _VcrCrtScreenState extends State<VcrCrtScreen> {
  var _syncGen = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPlayback();
    });
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
        break;
      case VcrPower.ejecting:
        await deck.stop();
        if (!mounted || gen != _syncGen) return;
        break;
      case VcrPower.inserting:
        if (tape != null && tape.streamUrl.isNotEmpty) {
          try {
            await deck.load(tape.streamUrl, play: false);
          } catch (_) {
            // The playback status overlay presents the retained player error.
          }
        }
        if (!mounted || gen != _syncGen) return;
        break;
      case VcrPower.playing:
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
            if (widget.power == VcrPower.off)
              const StaticScreen(intensity: 0.38),
            if (widget.power == VcrPower.off)
              const Positioned(
                left: 22,
                top: 24,
                child: Text(
                  'AV 1',
                  style: TextStyle(
                    color: Color(0xFFBCE6E8),
                    fontFamily: 'monospace',
                    fontSize: 12,
                    letterSpacing: 2,
                    shadows: [Shadow(color: Color(0xFF5FA9AD), blurRadius: 5)],
                  ),
                ),
              ),
            if (widget.power == VcrPower.inserting)
              _InsertingTapeLabel(title: widget.tape?.title ?? ''),
            if (widget.style == PlaybackStyle.vhsCrt) const CrtGlassOverlay(),
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
                shuttling: widget.rewinding,
              ),
            // Curved glass highlight, drawn without filters over the video.
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.screenRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0, 0.12, 0.42, 0.7, 1],
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.04),
                      Colors.transparent,
                      Colors.transparent,
                      VhsColors.accent.withValues(alpha: 0.035),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
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
                      Colors.black.withValues(alpha: 0.65),
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
      color: const Color(0xE6080C0E),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.play_arrow_rounded,
                color: VhsColors.accent,
                size: 24,
              ),
              const SizedBox(height: 8),
              const Text(
                'READING TAPE',
                style: TextStyle(
                  color: VhsColors.accent,
                  fontFamily: 'monospace',
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: VhsColors.accent.withValues(alpha: 0.6),
                  fontSize: 9,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
