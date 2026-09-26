import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/constants/feedback.dart';
import 'package:vhsfin/features/living_room/state/experience_prefs.dart';

/// Deck mechanical SFX — separate from media_kit movie audio.
///
/// Assets are CC0 from BigSoundBank (Pierre SIBAN); see assets/sounds/CREDITS.txt.
class DeckSfx {
  DeckSfx() {
    _shuttle = AudioPlayer();
    _shuttle.setReleaseMode(ReleaseMode.loop);
    _shuttle.setVolume(0.55);
    // One preloaded player per clip: starting a clip is then a seek + resume
    // with no fetch/decode in the way, so it lands on its animation beat.
    _insert = _preloaded('sounds/vhs_insert.ogg');
    _eject = _preloaded('sounds/vhs_eject.ogg');
    _ui = {
      DeckUiSound.tick: _preloaded('sounds/ui_tick.wav', volume: 0.35),
      DeckUiSound.key: _preloaded('sounds/ui_key.wav', volume: 0.55),
      DeckUiSound.toggle: _preloaded('sounds/ui_switch.wav', volume: 0.7),
    };
  }

  late final AudioPlayer _insert;
  late final AudioPlayer _eject;
  late final AudioPlayer _shuttle;
  late final Map<DeckUiSound, AudioPlayer> _ui;

  /// The SOUND EFFECTS setting: off silences every deck sound.
  bool enabled = true;

  /// Press sounds for keys, switches, and choices (see [DeckFeedback]).
  void playUi(DeckUiSound sound) {
    if (!enabled) return;
    final player = _ui[sound];
    if (player == null) return;
    unawaited(() async {
      try {
        // stop + resume retriggers in every mode (low-latency can't seek).
        await player.stop();
        await player.resume();
      } catch (err) {
        debugPrint('deck-sfx ui $sound failed: $err');
      }
    }());
  }

  static AudioPlayer _preloaded(String asset, {double volume = 0.9}) {
    final player = AudioPlayer()
      ..setReleaseMode(ReleaseMode.stop)
      ..setVolume(volume);
    // Android's SoundPool path: no decode on each press. (Not on web.)
    if (!kIsWeb && asset.endsWith('.wav')) {
      unawaited(player.setPlayerMode(PlayerMode.lowLatency));
    }
    unawaited(
      player.setSource(AssetSource(asset)).catchError((Object err) {
        debugPrint('deck-sfx preload $asset failed: $err');
      }),
    );
    return player;
  }

  Future<void> playInsert() => _fire(_insert, 'sounds/vhs_insert.ogg');

  /// Starts the eject clunk (does not wait for the clip to finish).
  Future<void> playEject() => _fire(_eject, 'sounds/vhs_eject.ogg');

  Future<void> _fire(AudioPlayer player, String asset) async {
    if (!enabled) return;
    try {
      if (player.source == null) {
        await player.play(AssetSource(asset));
        return;
      }
      await player.seek(Duration.zero);
      await player.resume();
    } catch (err) {
      debugPrint('deck-sfx $asset failed: $err');
    }
  }

  Future<void> startFastForward() => _playShuttle('sounds/vhs_ff.ogg');

  Future<void> startRewind() => _playShuttle('sounds/vhs_rew.ogg');

  Future<void> stopShuttle() async {
    try {
      await _shuttle.stop();
    } catch (err) {
      debugPrint('deck-sfx stopShuttle failed: $err');
    }
  }

  Future<void> _playShuttle(String asset) async {
    if (!enabled) return;
    try {
      await _shuttle.stop();
      await _shuttle.setReleaseMode(ReleaseMode.loop);
      await _shuttle.play(AssetSource(asset));
    } catch (err) {
      debugPrint('deck-sfx shuttle $asset failed: $err');
    }
  }

  Future<void> dispose() async {
    await _insert.dispose();
    await _eject.dispose();
    for (final player in _ui.values) {
      await player.dispose();
    }
    await _shuttle.dispose();
  }
}

final deckSfxProvider = Provider<DeckSfx>((ref) {
  final sfx = DeckSfx();
  ref.listen<bool>(
    experiencePrefsProvider.select((prefs) => prefs.soundEffects),
    (_, on) {
      sfx.enabled = on;
      if (!on) unawaited(sfx.stopShuttle());
    },
    fireImmediately: true,
  );
  // Presses across the app play through this deck.
  DeckFeedback.player = sfx.playUi;
  ref.onDispose(() {
    if (DeckFeedback.player == sfx.playUi) DeckFeedback.player = null;
    unawaited(sfx.dispose());
  });
  return sfx;
});
