import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/living_room/model/vcr_state.dart';
import 'package:vhsfin/features/living_room/presentation/vcr_crt_screen.dart';

/// Big living-room VCR / TV combo. Tap the deck to open clean fullscreen.
class VcrBox extends ConsumerWidget {
  const VcrBox({super.key, this.onOpenClean});

  final VoidCallback? onOpenClean;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(vcrDeckProvider);
    final ledOn = deck.isPowered;

    return GestureDetector(
      onTap: deck.isPlaying ? onOpenClean : null,
      child: Semantics(
        button: deck.isPlaying,
        label: deck.isPlaying
            ? 'Open fullscreen player'
            : 'VCR is ${deck.power.name}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                VhsColors.vcrFace,
                VhsColors.vcrBody,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
              if (ledOn)
                BoxShadow(
                  color: VhsColors.phosphor.withValues(alpha: 0.18),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'VHSFIN',
                    style: vhsBrandStyle(size: 16).copyWith(letterSpacing: 3),
                  ),
                  const Spacer(),
                  _Led(on: ledOn),
                  const SizedBox(width: 8),
                  Text(
                    ledOn ? 'PLAY' : 'STANDBY',
                    style: TextStyle(
                      color: ledOn ? VhsColors.phosphor : VhsColors.phosphorDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: VhsColors.vcrBezel,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
                child: VcrCrtScreen(
                  power: deck.power,
                  style: deck.style,
                  tape: deck.loadedTape,
                  onRequestCleanFullscreen: onOpenClean,
                ),
              ),
              const SizedBox(height: 14),
              const _DeckControls(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Led extends StatelessWidget {
  const _Led({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? VhsColors.ledOn : VhsColors.ledOff,
        boxShadow: on
            ? [
                BoxShadow(
                  color: VhsColors.ledOn.withValues(alpha: 0.7),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }
}

class _DeckControls extends ConsumerWidget {
  const _DeckControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(vcrDeckProvider);

    return Row(
      children: [
        _DeckButton(
          icon: Icons.stop_rounded,
          label: 'EJECT',
          enabled: deck.isPowered,
          onTap: () => ref.read(vcrDeckProvider.notifier).eject(),
        ),
        const SizedBox(width: 10),
        _DeckButton(
          icon: Icons.tv_rounded,
          label: 'VHS',
          enabled: deck.isPlaying,
          active: deck.style == PlaybackStyle.vhsCrt,
          onTap: () => ref
              .read(vcrDeckProvider.notifier)
              .setStyle(PlaybackStyle.vhsCrt),
        ),
        const SizedBox(width: 10),
        _DeckButton(
          icon: Icons.fullscreen_rounded,
          label: 'CLEAN',
          enabled: deck.isPlaying,
          active: deck.style == PlaybackStyle.cleanFullscreen,
          onTap: () {
            ref
                .read(vcrDeckProvider.notifier)
                .setStyle(PlaybackStyle.cleanFullscreen);
            // Parent opens route via onOpenClean when tapping the box;
            // button also flips style for in-bezel clean (no overlay).
          },
        ),
        const Spacer(),
        if (deck.loadedTape != null)
          Flexible(
            child: Text(
              deck.loadedTape!.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: VhsColors.brand,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _DeckButton extends StatelessWidget {
  const _DeckButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? VhsColors.brand.withValues(alpha: 0.25)
        : active
            ? VhsColors.phosphor
            : VhsColors.brand.withValues(alpha: 0.75);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
