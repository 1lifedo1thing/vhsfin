import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/living_room/widgets/crt_glass_overlay.dart';
import 'package:vhsfin/features/living_room/widgets/crt_rewind_overlay.dart';
import 'package:vhsfin/features/living_room/widgets/letterboxed_video.dart';
import 'package:vhsfin/features/living_room/widgets/static_screen.dart';
import 'package:vhsfin/features/playback/state/deck_player.dart';

/// The CRT screen inside the VCR bezel — static, insert anim, or playback.
class VcrCrtScreen extends StatefulWidget {
  const VcrCrtScreen({
    super.key,
    required this.power,
    required this.style,
    required this.player,
    required this.surfaceEpoch,
    this.tape,
    this.resumeAt,
    this.rewinding = false,
  });

  final VcrPower power;
  final PlaybackStyle style;
  final Tape? tape;
  final DeckPlayerController player;
  final int surfaceEpoch;
  final Duration? resumeAt;
  final bool rewinding;

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
    _insertSlide = Tween<Offset>(
      begin: const Offset(0, 1.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _insertController, curve: Curves.easeInOutCubic),
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
    // Coming back from fullscreen — CRT just remounted; nudge play after paint.
    if (oldWidget.style == PlaybackStyle.cleanFullscreen &&
        widget.style == PlaybackStyle.vhsCrt &&
        widget.power == VcrPower.playing) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
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
      case VcrPower.ejecting:
        await deck.stop();
        if (!mounted || gen != _syncGen) return;
        _insertController.value = 0;
      case VcrPower.inserting:
        if (tape != null && tape.streamUrl.isNotEmpty) {
          await deck.load(
            tape.streamUrl,
            play: false,
            seekTo: widget.resumeAt,
          );
        }
        if (!mounted || gen != _syncGen) return;
        await _insertController.forward(from: 0);
      case VcrPower.playing:
        _insertController.value = 1;
        if (tape == null || tape.streamUrl.isEmpty) return;
        await deck.load(
          tape.streamUrl,
          play: true,
          seekTo: widget.resumeAt,
        );
    }
  }

  @override
  void dispose() {
    _insertController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deck = widget.player;
    final surfaceEpoch = widget.surfaceEpoch;
    // Don't bind a second Video while fullscreen owns the surface.
    final showVideo = widget.style != PlaybackStyle.cleanFullscreen &&
        (widget.power == VcrPower.playing ||
            (widget.power == VcrPower.inserting && widget.tape != null));
    final controller = deck.controllerOrNull;

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            if (showVideo && controller != null)
              LetterboxedVideo(
                key: ValueKey('crt-$surfaceEpoch-${widget.tape?.id}'),
                player: deck.player,
                controller: controller,
                opacity: widget.power == VcrPower.playing ? 1 : 0.15,
              ),
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
