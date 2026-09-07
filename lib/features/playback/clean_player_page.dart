import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  var _bindVideo = false;

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
      final deck = ref.read(deckPlayerProvider);
      // CRT already released ownership on the way in — claim fullscreen on a
      // fresh controller so web gets a clean <video> attach.
      deck.reattachSurface(DeckSurfaceOwner.fullscreen);
      if (!mounted) return;
      setState(() => _bindVideo = true);
      await deck.load(tape.streamUrl, play: true);
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _waitFrames(int count) async {
    for (var i = 0; i < count; i++) {
      await SchedulerBinding.instance.endOfFrame;
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Hand the surface back to the CRT without two [Video]s on one controller.
  ///
  /// Order matters on web: unbind fullscreen → pop → wait for HtmlElementView
  /// teardown → new [VideoController] → CRT style → play.
  Future<void> _backToVcr() async {
    if (_leaving) return;
    _leaving = true;

    final deck = ref.read(deckPlayerProvider);
    final vcr = ref.read(vcrDeckProvider.notifier);
    await deck.stopShuttle();

    // 1) Unmount fullscreen Video while this route is still up.
    if (mounted) setState(() => _bindVideo = false);
    deck.releaseSurface();
    await _waitFrames(2);
    await Future<void>.delayed(const Duration(milliseconds: 64));

    // 2) Pop so the route (and any platform view) is gone.
    if (mounted) context.pop();

    // 3) Wait for HtmlElementView / <video> teardown after route dispose.
    await _waitFrames(2);
    await Future<void>.delayed(const Duration(milliseconds: 120));

    // 4) Fresh controller for CRT, then allow the bezel to bind.
    deck.reattachSurface(DeckSurfaceOwner.crt);
    vcr.setStyle(PlaybackStyle.vhsCrt);

    await _waitFrames(2);
    await Future<void>.delayed(const Duration(milliseconds: 32));
    await deck.play();
  }

  @override
  Widget build(BuildContext context) {
    final tape = ref.watch(vcrDeckProvider).loadedTape;
    final player = ref.watch(deckPlayerProvider);
    final surfaceEpoch = ref.watch(deckSurfaceEpochProvider);
    final owner = ref.watch(deckSurfaceOwnerProvider);
    final controller = player.controllerOrNull;
    final showVideo = _bindVideo &&
        !_leaving &&
        owner == DeckSurfaceOwner.fullscreen &&
        controller != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _backToVcr();
      },
      child: CleanPlayerView(
        title: tape?.title ?? '',
        surfaceEpoch: surfaceEpoch,
        controller: showVideo ? controller : null,
        onBack: _backToVcr,
      ),
    );
  }
}
