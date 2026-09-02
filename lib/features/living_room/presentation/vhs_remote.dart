import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/living_room/model/vcr_state.dart';
import 'package:vhsfin/features/playback/data/deck_player.dart';

/// Chunky 90s IR remote — fullscreen, wind, play/pause, eject. No skips.
Future<void> showVhsRemote(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const VhsRemoteSheet(),
  );
}

class VhsRemoteSheet extends ConsumerWidget {
  const VhsRemoteSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(vcrDeckProvider);
    final player = ref.watch(deckPlayerProvider);
    final live = deck.isPlaying;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Material(
            color: const Color(0xFF2A2A28),
            borderRadius: BorderRadius.circular(28),
            elevation: 16,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF353532), Color(0xFF1C1C1A)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'REMOTE',
                    style: vhsBrandStyle(size: 18).copyWith(letterSpacing: 4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    live
                        ? (deck.loadedTape?.title ?? 'PLAYING')
                        : 'NO TAPE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: VhsColors.brand.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RemoteKey(
                        label: 'REW',
                        icon: Icons.fast_rewind_rounded,
                        enabled: live,
                        onTapDown: (_) => player.startRewind(),
                        onTapUp: (_) => player.stopShuttle(),
                        onTapCancel: () => player.stopShuttle(),
                      ),
                      _RemoteKey(
                        label: 'PLAY',
                        icon: Icons.play_arrow_rounded,
                        enabled: live,
                        large: true,
                        onTap: () => player.togglePlayPause(),
                      ),
                      _RemoteKey(
                        label: 'FF',
                        icon: Icons.fast_forward_rounded,
                        enabled: live,
                        onTapDown: (_) => player.startFastForward(),
                        onTapUp: (_) => player.stopShuttle(),
                        onTapCancel: () => player.stopShuttle(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _RemoteWideButton(
                          label: 'FULL SCREEN',
                          enabled: live,
                          onTap: () {
                            Navigator.pop(context);
                            ref
                                .read(vcrDeckProvider.notifier)
                                .setStyle(PlaybackStyle.cleanFullscreen);
                            context.push('/play');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RemoteWideButton(
                          label: 'EJECT',
                          enabled: deck.isPowered,
                          onTap: () {
                            ref.read(vcrDeckProvider.notifier).eject();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Hold REW / FF to wind the tape',
                    style: TextStyle(
                      color: VhsColors.brand.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RemoteKey extends StatelessWidget {
  const _RemoteKey({
    required this.label,
    required this.icon,
    required this.enabled,
    this.large = false,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final bool large;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final VoidCallback? onTapCancel;

  @override
  Widget build(BuildContext context) {
    final size = large ? 72.0 : 58.0;
    final color = enabled
        ? VhsColors.brand
        : VhsColors.brand.withValues(alpha: 0.25);

    return Column(
      children: [
        Material(
          color: const Color(0xFF121210),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onTap : null,
            onTapDown: enabled ? onTapDown : null,
            onTapUp: enabled ? onTapUp : null,
            onTapCancel: enabled ? onTapCancel : null,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: color, size: large ? 36 : 28),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _RemoteWideButton extends StatelessWidget {
  const _RemoteWideButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? const Color(0xFF121210) : const Color(0xFF1A1A18),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: enabled
                  ? VhsColors.phosphor
                  : VhsColors.brand.withValues(alpha: 0.25),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
