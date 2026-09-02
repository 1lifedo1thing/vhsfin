import 'package:fancy_overlay/fancy_overlay.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/model/vcr_state.dart';
import 'package:vhsfin/features/living_room/presentation/static_screen.dart';

/// The CRT screen inside the VCR bezel — static, insert anim, or playback.
class VcrCrtScreen extends StatefulWidget {
  const VcrCrtScreen({
    super.key,
    required this.power,
    required this.style,
    this.tape,
    this.onRequestCleanFullscreen,
  });

  final VcrPower power;
  final PlaybackStyle style;
  final Tape? tape;
  final VoidCallback? onRequestCleanFullscreen;

  @override
  State<VcrCrtScreen> createState() => _VcrCrtScreenState();
}

class _VcrCrtScreenState extends State<VcrCrtScreen>
    with SingleTickerProviderStateMixin {
  Player? _player;
  VideoController? _controller;
  late final AnimationController _insertController;
  late final Animation<Offset> _insertSlide;

  @override
  void initState() {
    super.initState();
    _insertController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _insertSlide = Tween<Offset>(
      begin: const Offset(0, 1.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _insertController, curve: Curves.easeInOutCubic),
    );
    VhsOverlay.precacheShader();
    _syncPlayback();
  }

  @override
  void didUpdateWidget(covariant VcrCrtScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.power != widget.power ||
        oldWidget.tape?.id != widget.tape?.id ||
        oldWidget.style != widget.style) {
      _syncPlayback();
    }
  }

  void _ensurePlayer() {
    if (_player != null) return;
    _player = Player();
    _controller = VideoController(_player!);
  }

  Future<void> _syncPlayback() async {
    switch (widget.power) {
      case VcrPower.off:
        await _player?.stop();
        _insertController.value = 0;
      case VcrPower.inserting:
        await _player?.stop();
        await _insertController.forward(from: 0);
      case VcrPower.playing:
        _insertController.value = 1;
        final tape = widget.tape;
        if (tape == null) return;
        _ensurePlayer();
        await _player!.open(Media(tape.streamUrl));
        await _player!.play();
        if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _insertController.dispose();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            if (widget.power == VcrPower.off) const StaticScreen(),
            if (widget.power == VcrPower.inserting)
              SlideTransition(
                position: _insertSlide,
                child: _InsertingTapeLabel(title: widget.tape?.title ?? ''),
              ),
            if (widget.power == VcrPower.playing && controller != null) ...[
              Video(
                controller: controller,
                controls: NoVideoControls,
                fill: Colors.black,
              ),
              if (widget.style == PlaybackStyle.vhsCrt)
                const VhsOverlay(config: VhsOverlayConfig.balanced()),
              Positioned(
                right: 8,
                bottom: 8,
                child: _CrtChromeButton(
                  label: 'FULL',
                  onTap: widget.onRequestCleanFullscreen,
                ),
              ),
            ],
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.55),
                    width: 2,
                  ),
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.1),
                    radius: 1.05,
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
      color: VhsColors.tapeShell,
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

class _CrtChromeButton extends StatelessWidget {
  const _CrtChromeButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: VhsColors.phosphor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
