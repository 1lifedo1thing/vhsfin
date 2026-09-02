import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/model/vcr_state.dart';
import 'package:vhsfin/features/living_room/presentation/crt_glass_overlay.dart';
import 'package:vhsfin/features/living_room/presentation/letterboxed_video.dart';
import 'package:vhsfin/features/living_room/presentation/static_screen.dart';
import 'package:vhsfin/features/playback/data/deck_player.dart';

/// The CRT screen inside the VCR bezel — static, insert anim, or playback.
class VcrCrtScreen extends ConsumerStatefulWidget {
  const VcrCrtScreen({
    super.key,
    required this.power,
    required this.style,
    this.tape,
  });

  final VcrPower power;
  final PlaybackStyle style;
  final Tape? tape;

  @override
  ConsumerState<VcrCrtScreen> createState() => _VcrCrtScreenState();
}

class _VcrCrtScreenState extends ConsumerState<VcrCrtScreen>
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
    // Coming back from fullscreen — keep playing on the CRT surface.
    if (oldWidget.style == PlaybackStyle.cleanFullscreen &&
        widget.style == PlaybackStyle.vhsCrt &&
        widget.power == VcrPower.playing) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(deckPlayerProvider).play();
      });
    }
  }

  Future<void> _syncPlayback() async {
    final gen = ++_syncGen;
    final deck = ref.read(deckPlayerProvider);
    final tape = widget.tape;

    switch (widget.power) {
      case VcrPower.off:
        await deck.stop();
        if (!mounted || gen != _syncGen) return;
        _insertController.value = 0;
      case VcrPower.inserting:
        if (tape != null && tape.streamUrl.isNotEmpty) {
          await deck.load(tape.streamUrl, play: false);
        }
        if (!mounted || gen != _syncGen) return;
        await _insertController.forward(from: 0);
      case VcrPower.playing:
        _insertController.value = 1;
        if (tape == null || tape.streamUrl.isEmpty) return;
        await deck.load(tape.streamUrl, play: true);
    }
  }

  @override
  void dispose() {
    _insertController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(deckPlayerProvider);
    final surfaceEpoch = ref.watch(deckSurfaceEpochProvider);
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
            if (widget.power == VcrPower.off) const StaticScreen(),
            if (widget.power == VcrPower.inserting)
              SlideTransition(
                position: _insertSlide,
                child: _InsertingTapeLabel(title: widget.tape?.title ?? ''),
              ),
            if (widget.power == VcrPower.playing &&
                widget.style == PlaybackStyle.vhsCrt)
              const CrtGlassOverlay(),
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
