import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/living_room/model/vcr_state.dart';
import 'package:vhsfin/features/living_room/presentation/vcr_crt_screen.dart';
import 'package:vhsfin/features/playback/data/deck_player.dart';

/// Compact Zenith-style all-in-one TV/VCR — CRT, cassette slot, deck buttons.
class VcrBox extends ConsumerWidget {
  const VcrBox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(vcrDeckProvider);
    final ledOn = deck.isPowered;
    final player = ref.watch(deckPlayerProvider);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF3A3A3E),
            VhsColors.vcrFace,
            VhsColors.vcrBody,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
          if (ledOn)
            BoxShadow(
              color: VhsColors.phosphor.withValues(alpha: 0.14),
              blurRadius: 22,
              spreadRadius: 1,
            ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'VHSFIN',
                style: vhsBrandStyle(size: 13).copyWith(letterSpacing: 3),
              ),
              const SizedBox(width: 8),
              Text(
                'SYSTEM',
                style: TextStyle(
                  color: VhsColors.brand.withValues(alpha: 0.45),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              _Led(on: ledOn),
              const SizedBox(width: 8),
              Text(
                ledOn ? 'PLAY' : 'STANDBY',
                style: TextStyle(
                  color: ledOn ? VhsColors.phosphor : VhsColors.phosphorDim,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: VhsColors.vcrBezel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            child: VcrCrtScreen(
              power: deck.power,
              style: deck.style,
              tape: deck.loadedTape,
            ),
          ),
          const SizedBox(height: 10),
          _CassetteSlot(
            title: deck.loadedTape?.title,
            inserting: deck.power == VcrPower.inserting,
            loaded: deck.isPowered,
          ),
          const SizedBox(height: 10),
          _DeckButtons(
            enabled: deck.isPowered,
            onRew: () => player.startRewind(),
            onRewEnd: () => player.stopShuttle(),
            onPlay: () => player.togglePlayPause(),
            onFf: () => player.startFastForward(),
            onFfEnd: () => player.stopShuttle(),
            onEject: () => ref.read(vcrDeckProvider.notifier).eject(),
            onFull: () {
              if (!deck.isPlaying) return;
              ref
                  .read(vcrDeckProvider.notifier)
                  .setStyle(PlaybackStyle.cleanFullscreen);
              context.push('/play');
            },
          ),
        ],
      ),
    );
  }
}

class _CassetteSlot extends StatelessWidget {
  const _CassetteSlot({
    required this.inserting,
    required this.loaded,
    this.title,
  });

  final String? title;
  final bool inserting;
  final bool loaded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A0A0C), Color(0xFF1A1A1E)],
            ),
            border: Border.all(color: Colors.black.withValues(alpha: 0.8)),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.04),
                blurRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // Slot mouth / lip
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 5,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
              if (loaded || inserting)
                AnimatedAlign(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  alignment:
                      inserting ? const Alignment(0, 1.4) : Alignment.center,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: VhsColors.tapeShell,
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.25),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      (title ?? 'TAPE').toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF2A1810),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                )
              else
                const Center(
                  child: Text(
                    'VHS',
                    style: TextStyle(
                      color: Color(0xFF3A3A40),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          loaded ? 'CASSETTE LOADED' : 'INSERT A TAPE FROM THE SHELF',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: VhsColors.brand.withValues(alpha: 0.4),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _DeckButtons extends StatelessWidget {
  const _DeckButtons({
    required this.enabled,
    required this.onRew,
    required this.onRewEnd,
    required this.onPlay,
    required this.onFf,
    required this.onFfEnd,
    required this.onEject,
    required this.onFull,
  });

  final bool enabled;
  final VoidCallback onRew;
  final VoidCallback onRewEnd;
  final VoidCallback onPlay;
  final VoidCallback onFf;
  final VoidCallback onFfEnd;
  final VoidCallback onEject;
  final VoidCallback onFull;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DeckKey(
          icon: Icons.fast_rewind_rounded,
          label: 'REW',
          enabled: enabled,
          onTapDown: (_) => onRew(),
          onTapUp: (_) => onRewEnd(),
          onTapCancel: onRewEnd,
        ),
        _DeckKey(
          icon: Icons.play_arrow_rounded,
          label: 'PLAY',
          enabled: enabled,
          emphasized: true,
          onTap: onPlay,
        ),
        _DeckKey(
          icon: Icons.fast_forward_rounded,
          label: 'FF',
          enabled: enabled,
          onTapDown: (_) => onFf(),
          onTapUp: (_) => onFfEnd(),
          onTapCancel: onFfEnd,
        ),
        _DeckKey(
          icon: Icons.eject_rounded,
          label: 'EJECT',
          enabled: enabled,
          onTap: onEject,
        ),
        _DeckKey(
          icon: Icons.fullscreen_rounded,
          label: 'FULL',
          enabled: enabled,
          onTap: onFull,
        ),
      ],
    );
  }
}

class _DeckKey extends StatelessWidget {
  const _DeckKey({
    required this.icon,
    required this.label,
    required this.enabled,
    this.emphasized = false,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool emphasized;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final VoidCallback? onTapCancel;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? VhsColors.brand.withValues(alpha: 0.22)
        : emphasized
            ? VhsColors.phosphor
            : VhsColors.brand.withValues(alpha: 0.8);

    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        onTapDown: enabled ? onTapDown : null,
        onTapUp: enabled ? onTapUp : null,
        onTapCancel: enabled ? onTapCancel : null,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                width: 34,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: const Color(0xFF121214),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
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
      width: 9,
      height: 9,
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
