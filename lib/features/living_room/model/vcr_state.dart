import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/data/deck_sfx.dart';
import 'package:vhsfin/features/playback/data/deck_player.dart';

enum VcrPower { off, inserting, playing, ejecting }

enum PlaybackStyle { vhsCrt, cleanFullscreen }

class VcrDeckState {
  const VcrDeckState({
    this.power = VcrPower.off,
    this.loadedTape,
    this.style = PlaybackStyle.vhsCrt,
  });

  final VcrPower power;
  final Tape? loadedTape;
  final PlaybackStyle style;

  bool get isPowered =>
      power == VcrPower.inserting ||
      power == VcrPower.playing ||
      power == VcrPower.ejecting;
  bool get isPlaying => power == VcrPower.playing;

  VcrDeckState copyWith({
    VcrPower? power,
    Tape? loadedTape,
    PlaybackStyle? style,
    bool clearTape = false,
  }) {
    return VcrDeckState(
      power: power ?? this.power,
      loadedTape: clearTape ? null : (loadedTape ?? this.loadedTape),
      style: style ?? this.style,
    );
  }
}

final vcrDeckProvider =
    NotifierProvider<VcrDeckNotifier, VcrDeckState>(VcrDeckNotifier.new);

class VcrDeckNotifier extends Notifier<VcrDeckState> {
  @override
  VcrDeckState build() => const VcrDeckState();

  Future<void> insertTape(
    Tape tape, {
    PlaybackStyle style = PlaybackStyle.vhsCrt,
  }) async {
    state = state.copyWith(
      power: VcrPower.inserting,
      loadedTape: tape,
      style: style,
    );
    // Fire-and-forget — don't delay the insert animation on audio.
    unawaited(ref.read(deckSfxProvider).playInsert());
    await Future<void>.delayed(const Duration(milliseconds: 950));
    if (!ref.mounted) return;
    state = state.copyWith(power: VcrPower.playing);
  }

  void playCleanFullscreen(Tape tape) {
    state = state.copyWith(
      power: VcrPower.playing,
      loadedTape: tape,
      style: PlaybackStyle.cleanFullscreen,
    );
  }

  Future<void> eject() async {
    final sfx = ref.read(deckSfxProvider);
    unawaited(sfx.stopShuttle());
    // Kick the clunk immediately — don't wait on deck teardown.
    final ejectSound = sfx.playEject();
    state = const VcrDeckState(power: VcrPower.ejecting);
    unawaited(ref.read(deckPlayerProvider).stop());
    await ejectSound;
    if (!ref.mounted) return;
    // …then snow.
    state = const VcrDeckState();
  }

  void setStyle(PlaybackStyle style) {
    state = state.copyWith(style: style);
  }
}
