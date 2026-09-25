import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/state/deck_sfx.dart';
import 'package:vhsfin/features/living_room/state/experience_prefs.dart';
import 'package:vhsfin/features/playback/state/deck_player.dart';

enum VcrPower { off, inserting, playing, ejecting }

/// Deck choreography, lined up with the mechanical sound clips.
abstract final class DeckTiming {
  /// Shelf → slot flight while [VcrPower.inserting].
  static const insertFlight = Duration(milliseconds: 1300);

  /// The insert clip's flap click is 0.30s in (seat clunk 1.14s). Starting it
  /// here lands the click as the cassette meets the slot mouth (84% of the
  /// flight) and the clunk just after it disappears inside.
  static const insertSfxAt = Duration(milliseconds: 790);

  /// Eject button click (0.07s into the clip) → mechanism. The tape starts
  /// sliding out here, so it clears the mouth on the clip's pop at 0.97s.
  static const ejectMechanism = Duration(milliseconds: 900);

  /// Slot → shelf flight after [ejectMechanism].
  static const ejectFlight = Duration(milliseconds: 1150);
}

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

final vcrDeckProvider = NotifierProvider<VcrDeckNotifier, VcrDeckState>(
  VcrDeckNotifier.new,
);

class VcrDeckNotifier extends Notifier<VcrDeckState> {
  int _operation = 0;

  @override
  VcrDeckState build() {
    _operation++;
    return const VcrDeckState();
  }

  Future<void> insertTape(
    Tape tape, {
    PlaybackStyle style = PlaybackStyle.vhsCrt,
  }) async {
    final operation = ++_operation;
    Duration? resumeAt;
    if (ref.read(experiencePrefsProvider).saveTimestampOnEject) {
      final positions = ref.read(tapeResumePositionsProvider.notifier);
      await positions.ready;
      if (!ref.mounted || operation != _operation) return;
      resumeAt = positions.positionFor(tape.id);
    }

    state = state.copyWith(
      power: VcrPower.inserting,
      loadedTape: tape,
      style: style,
      resumeAt: resumeAt,
      clearResume: resumeAt == null,
    );
    final sfx = ref.read(deckSfxProvider);
    await Future<void>.delayed(DeckTiming.insertSfxAt);
    if (!ref.mounted || operation != _operation) return;
    unawaited(sfx.playInsert());
    await Future<void>.delayed(
      DeckTiming.insertFlight - DeckTiming.insertSfxAt,
    );
    if (!ref.mounted || operation != _operation) return;
    state = state.copyWith(power: VcrPower.playing);
  }

  void playCleanFullscreen(Tape tape) {
    _operation++;
    state = state.copyWith(
      power: VcrPower.playing,
      loadedTape: tape,
      style: PlaybackStyle.cleanFullscreen,
    );
  }

  Future<void> eject() async {
    final operation = ++_operation;
    final sfx = ref.read(deckSfxProvider);
    final player = ref.read(deckPlayerProvider);
    final tape = state.loadedTape;

    if (tape != null &&
        ref.read(experiencePrefsProvider).saveTimestampOnEject) {
      await ref
          .read(tapeResumePositionsProvider.notifier)
          .save(tape.id, player.position);
    }

    if (!ref.mounted || operation != _operation) return;
    unawaited(sfx.stopShuttle());
    // Request the clunk, then leave playback before the intentional stop can
    // be mistaken for a stream failure.
    unawaited(sfx.playEject());
    state = state.copyWith(power: VcrPower.ejecting);
    await Future<void>.delayed(
      DeckTiming.ejectMechanism + DeckTiming.ejectFlight,
    );
    if (!ref.mounted || operation != _operation) return;
    state = const VcrDeckState();
  }

  void setStyle(PlaybackStyle style) {
    state = state.copyWith(style: style);
  }
}
