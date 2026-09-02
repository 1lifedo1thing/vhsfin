import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/features/library/model/tape.dart';

enum VcrPower { off, inserting, playing }

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

  bool get isPowered => power != VcrPower.off;
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

  Future<void> insertTape(Tape tape, {PlaybackStyle style = PlaybackStyle.vhsCrt}) async {
    state = state.copyWith(
      power: VcrPower.inserting,
      loadedTape: tape,
      style: style,
    );
    await Future<void>.delayed(const Duration(milliseconds: 1100));
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

  void eject() {
    state = const VcrDeckState();
  }

  void setStyle(PlaybackStyle style) {
    state = state.copyWith(style: style);
  }
}
