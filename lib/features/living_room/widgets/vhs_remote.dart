import 'package:flutter/material.dart';
import 'package:vhsfin/constants/feedback.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/living_room/widgets/deck_panel.dart';

/// Chunky 90s IR remote — fullscreen, wind, play/pause, eject. No skips.
Future<void> showVhsRemote(
  BuildContext context, {
  required String? title,
  required bool live,
  required bool powered,
  required VoidCallback onRewStart,
  required VoidCallback onRewEnd,
  required VoidCallback onPlay,
  required VoidCallback onFfStart,
  required VoidCallback onFfEnd,
  required VoidCallback onFullScreen,
  required VoidCallback onEject,
  Stream<bool>? playing,
  bool initiallyPlaying = false,
}) {
  return DeckFeedback.sheet(
    () => showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DismissOnEscape(
        child: VhsRemoteSheet(
          title: title,
          live: live,
          powered: powered,
          onRewStart: onRewStart,
          onRewEnd: onRewEnd,
          onPlay: onPlay,
          onFfStart: onFfStart,
          onFfEnd: onFfEnd,
          onFullScreen: onFullScreen,
          onEject: onEject,
          playing: playing,
          initiallyPlaying: initiallyPlaying,
        ),
      ),
    ),
  );
}

class VhsRemoteSheet extends StatelessWidget {
  const VhsRemoteSheet({
    super.key,
    required this.title,
    required this.live,
    required this.powered,
    required this.onRewStart,
    required this.onRewEnd,
    required this.onPlay,
    required this.onFfStart,
    required this.onFfEnd,
    required this.onFullScreen,
    required this.onEject,
    this.playing,
    this.initiallyPlaying = false,
  });

  final String? title;
  final bool live;
  final bool powered;
  final VoidCallback onRewStart;
  final VoidCallback onRewEnd;
  final VoidCallback onPlay;
  final VoidCallback onFfStart;
  final VoidCallback onFfEnd;
  final VoidCallback onFullScreen;
  final VoidCallback onEject;

  /// Whether the tape is running (not paused), live from the player.
  final Stream<bool>? playing;
  final bool initiallyPlaying;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    // Rises from the bottom edge like the other sheets: no gap below.
    return Padding(
      padding: EdgeInsets.zero,
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            type: MaterialType.transparency,
            child: DeckPanel(
              radius: 30,
              screws: false,
              attachedToBottom: true,
              padding: EdgeInsets.fromLTRB(22, 12, 22, 22 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StreamBuilder<bool>(
                    stream: playing,
                    initialData: initiallyPlaying,
                    builder: (context, snapshot) {
                      final running = live && (snapshot.data ?? false);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DeckSheetHeader(
                            title: live
                                ? (title ?? 'PLAYING').toUpperCase()
                                : 'NO TAPE',
                            detail: live ? (running ? 'PLAY' : 'PAUSE') : null,
                            onClose: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _RubberKey(
                                label: 'REW',
                                icon: Icons.fast_rewind_rounded,
                                enabled: live,
                                onPressStart: onRewStart,
                                onPressEnd: onRewEnd,
                              ),
                              _RubberKey(
                                label: running ? 'PAUSE' : 'PLAY',
                                icon: running
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                enabled: live,
                                large: true,
                                onTap: onPlay,
                              ),
                              _RubberKey(
                                label: 'FF',
                                icon: Icons.fast_forward_rounded,
                                enabled: live,
                                onPressStart: onFfStart,
                                onPressEnd: onFfEnd,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: DeckHardKey(
                          label: 'FULL SCREEN',
                          onPressed: live
                              ? () {
                                  Navigator.pop(context);
                                  onFullScreen();
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DeckHardKey(
                          label: 'EJECT',
                          tone: DeckKeyTone.record,
                          onPressed: powered
                              ? () {
                                  onEject();
                                  Navigator.pop(context);
                                }
                              : null,
                        ),
                      ),
                    ],
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

/// A round rubber key: it sits in a socket with its side showing and sinks
/// when pressed. Wind keys act for as long as they're held.
class _RubberKey extends StatelessWidget {
  const _RubberKey({
    required this.label,
    required this.icon,
    required this.enabled,
    this.large = false,
    this.onTap,
    this.onPressStart,
    this.onPressEnd,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final bool large;
  final VoidCallback? onTap;
  final VoidCallback? onPressStart;
  final VoidCallback? onPressEnd;

  static const _travel = 4.0;

  @override
  Widget build(BuildContext context) {
    final size = large ? 68.0 : 54.0;
    final ink = enabled
        ? (large ? VhsColors.accent : VhsColors.ink)
        : VhsColors.inkFaint;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: DeckPressable(
        // Like a real remote, a key clicks with no tape in; it just
        // doesn't do anything.
        onTap: () {
          if (enabled) onTap?.call();
        },
        onPressStart: enabled ? onPressStart : null,
        onPressEnd: enabled ? onPressEnd : null,
        haptic: DeckFeedback.key,
        feedbackOnPress: true,
        builder: (context, down) {
          final side = down ? 1.0 : _travel;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                // Socket.
                width: size + 6,
                height: size + 6 + _travel,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF020303), Color(0xFF0B0C0D)],
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1AFFFFFF), offset: Offset(0, 1)),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: _travel - side),
                  child: Container(
                    // The key's side, showing below its face.
                    height: size + side,
                    alignment: Alignment.topCenter,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E0F11),
                      borderRadius: BorderRadius.circular(size),
                    ),
                    child: Container(
                      width: size,
                      height: size,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.3, -0.45),
                          colors: down
                              ? const [Color(0xFF34373B), Color(0xFF1C1D20)]
                              : const [Color(0xFF4A4D52), Color(0xFF232529)],
                        ),
                      ),
                      child: Icon(icon, color: ink, size: large ? 34 : 26),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: enabled ? const Color(0xFFC9D1D4) : VhsColors.inkFaint,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
