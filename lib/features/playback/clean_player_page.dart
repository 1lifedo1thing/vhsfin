import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/playback/state/deck_player.dart';
import 'package:vhsfin/features/playback/views/clean_player_view.dart';

/// Clean fullscreen playback using the same shared deck player.
class CleanPlayerPage extends ConsumerStatefulWidget {
  const CleanPlayerPage({super.key});

  @override
  ConsumerState<CleanPlayerPage> createState() => _CleanPlayerPageState();
}

class _CleanPlayerPageState extends ConsumerState<CleanPlayerPage> {
  var _leaving = false;

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

  /// Pop fullscreen *before* CRT binds video — two [Video]s on one controller
  /// blanks the web surface (audio keeps going).
  Future<void> _backToVcr() async {
    if (_leaving) return;
    _leaving = true;
    final deck = ref.read(deckPlayerProvider);
    final vcr = ref.read(vcrDeckProvider.notifier);
    await deck.stopShuttle();
    if (!mounted) return;
    context.pop();
    // Wait for HtmlElementView / <video> teardown.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    deck.reattachSurface();
    vcr.setStyle(PlaybackStyle.vhsCrt);
    await Future<void>.delayed(const Duration(milliseconds: 32));
    await deck.play();
  }

  @override
  Widget build(BuildContext context) {
    final tape = ref.watch(vcrDeckProvider).loadedTape;
    final player = ref.watch(deckPlayerProvider);
    final surfaceEpoch = ref.watch(deckSurfaceEpochProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _backToVcr();
      },
      child: CleanPlayerView(
        title: tape?.title ?? '',
        surfaceEpoch: surfaceEpoch,
        controller: player.controller,
        onBack: _backToVcr,
      ),
    );
  }
}
