import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vhsfin/app_orientation.dart';
import 'package:vhsfin/constants/feedback.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/playback/state/deck_player.dart';
import 'package:vhsfin/features/playback/views/clean_player_view.dart';

/// Clean fullscreen playback using the same shared deck player.
///
/// Surface handoff: this page claims fullscreen on enter and only
/// [releaseSurface]s before pop. The living room awaits [GoRouter.push] and
/// reattaches the CRT — never reattach here after pop (State is disposing).
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
    unawaited(AppOrientation.enterVideoFullscreen());
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
      await deck.load(tape.streamUrl);
    });
  }

  @override
  void dispose() {
    unawaited(AppOrientation.leaveVideoFullscreen());
    super.dispose();
  }

  Future<void> _waitFrames(int count) async {
    for (var i = 0; i < count; i++) {
      await SchedulerBinding.instance.endOfFrame;
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Unbind fullscreen Video, release ownership, pop.
  ///
  /// CRT remount is owned by [LivingRoomPage] after [push] completes.
  Future<void> _backToVcr() async {
    if (_leaving) return;
    _leaving = true;

    final deck = ref.read(deckPlayerProvider);
    await deck.stopShuttle();

    if (mounted) setState(() => _bindVideo = false);
    deck.releaseSurface();
    await _waitFrames(2);
    await Future<void>.delayed(const Duration(milliseconds: 64));

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tape = ref.watch(vcrDeckProvider).loadedTape;
    final player = ref.watch(deckPlayerProvider);
    final surfaceEpoch = ref.watch(deckSurfaceEpochProvider);
    final owner = ref.watch(deckSurfaceOwnerProvider);
    final controller = player.controllerOrNull;
    final showVideo =
        _bindVideo &&
        !_leaving &&
        owner == DeckSurfaceOwner.fullscreen &&
        controller != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        DeckFeedback.tap();
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
