import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/living_room/model/vcr_state.dart';

/// Clean fullscreen playback — no VHS effect, normal controls.
class CleanPlayerPage extends ConsumerStatefulWidget {
  const CleanPlayerPage({super.key});

  @override
  ConsumerState<CleanPlayerPage> createState() => _CleanPlayerPageState();
}

class _CleanPlayerPageState extends ConsumerState<CleanPlayerPage> {
  late final Player _player;
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    final tape = ref.read(vcrDeckProvider).loadedTape;
    if (tape == null) {
      if (mounted) context.pop();
      return;
    }
    await _player.open(Media(tape.streamUrl));
    await _player.play();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tape = ref.watch(vcrDeckProvider).loadedTape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Video(controller: _controller),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
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
                      onPressed: () {
                        ref
                            .read(vcrDeckProvider.notifier)
                            .setStyle(PlaybackStyle.vhsCrt);
                        context.pop();
                      },
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
