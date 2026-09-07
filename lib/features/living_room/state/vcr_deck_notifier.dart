import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/state/deck_sfx.dart';
import 'package:vhsfin/features/living_room/state/experience_prefs.dart';
import 'package:vhsfin/features/living_room/state/tape_flight_anchors.dart';
import 'package:vhsfin/features/playback/state/deck_player.dart';

enum VcrPower { off, inserting, playing, ejecting }

enum PlaybackStyle { vhsCrt, cleanFullscreen }

class VcrDeckState {
  const VcrDeckState({
    this.power = VcrPower.off,
    this.loadedTape,
    this.style = PlaybackStyle.vhsCrt,
    this.resumeAt,
  });

  final VcrPower power;
  final Tape? loadedTape;
  final PlaybackStyle style;

  /// Seek target after insert when save-timestamp-on-eject is enabled.
  final Duration? resumeAt;

  bool get isPowered =>
      power == VcrPower.inserting ||
      power == VcrPower.playing ||
      power == VcrPower.ejecting;
  bool get isPlaying => power == VcrPower.playing;

  VcrDeckState copyWith({
    VcrPower? power,
    Tape? loadedTape,
    PlaybackStyle? style,
    Duration? resumeAt,
    bool clearTape = false,
    bool clearResume = false,
  }) {
    return VcrDeckState(
      power: power ?? this.power,
      loadedTape: clearTape ? null : (loadedTape ?? this.loadedTape),
      style: style ?? this.style,
      resumeAt: clearResume ? null : (resumeAt ?? this.resumeAt),
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
    Duration? resumeAt;
    if (ref.read(experiencePrefsProvider).saveTimestampOnEject) {
      resumeAt = ref.read(tapeResumePositionsProvider.notifier).positionFor(
            tape.id,
          );
    }

    // Wait until the clunk is actually playing, then fly.
    await ref.read(deckSfxProvider).playInsert();
    if (!ref.mounted) return;
    state = state.copyWith(
      power: VcrPower.inserting,
      loadedTape: tape,
      style: style,
      resumeAt: resumeAt,
      clearResume: resumeAt == null,
    );
    await Future<void>.delayed(const Duration(milliseconds: 780));
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
    final player = ref.read(deckPlayerProvider);
    final tape = state.loadedTape;

    if (tape != null &&
        ref.read(experiencePrefsProvider).saveTimestampOnEject) {
      await ref.read(tapeResumePositionsProvider.notifier).save(
            tape.id,
            player.position,
          );
    }

    unawaited(sfx.stopShuttle());
    unawaited(player.stop());
    // Start the clunk, then fly out — don't wait for the whole clip.
    await sfx.playEject();
    if (!ref.mounted) return;
    state = state.copyWith(power: VcrPower.ejecting);
    await Future<void>.delayed(const Duration(milliseconds: 780));
    if (!ref.mounted) return;
    ref.read(flyingTapeIdProvider.notifier).set(null);
    state = const VcrDeckState();
  }

  void setStyle(PlaybackStyle style) {
    state = state.copyWith(style: style);
  }
}
