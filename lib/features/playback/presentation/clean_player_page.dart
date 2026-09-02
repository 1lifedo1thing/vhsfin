import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/living_room/model/vcr_state.dart';
import 'package:vhsfin/features/playback/data/deck_player.dart';

/// Clean fullscreen playback using the same shared deck player.
class CleanPlayerPage extends ConsumerStatefulWidget {
  const CleanPlayerPage({super.key});

  @override
  ConsumerState<CleanPlayerPage> createState() => _CleanPlayerPageState();
}

class _CleanPlayerPageState extends ConsumerState<CleanPlayerPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final tape = ref.read(vcrDeckProvider).loadedTape;
      if (tape == null) {
        if (mounted) context.pop();
        return;
      }
      await ref.read(deckPlayerProvider).load(tape.streamUrl, play: true);
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _backToVcr() async {
    final deck = ref.read(deckPlayerProvider);
    await deck.stopShuttle();
    deck.reattachSurface();
    ref.read(vcrDeckProvider.notifier).setStyle(PlaybackStyle.vhsCrt);
    if (!mounted) return;
    context.pop();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    await deck.play();
  }

  @override
  Widget build(BuildContext context) {
    final tape = ref.watch(vcrDeckProvider).loadedTape;
    final player = ref.watch(deckPlayerProvider);
    final surfaceEpoch = ref.watch(deckSurfaceEpochProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Video(
            key: ValueKey('full-$surfaceEpoch'),
            controller: player.controller,
            fit: BoxFit.contain,
            fill: Colors.black,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _backToVcr,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tape?.title ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: VhsColors.brand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _backToVcr,
                      child: const Text(
                        'BACK TO VCR',
                        style: TextStyle(
                          color: VhsColors.phosphor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
