import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  }

  late final AudioPlayer _insert;
  late final AudioPlayer _eject;
  late final AudioPlayer _shuttle;

  static AudioPlayer _preloaded(String asset) {
    final player = AudioPlayer()
      ..setReleaseMode(ReleaseMode.stop)
      ..setVolume(0.9);
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
    await _shuttle.dispose();
  }
}

final deckSfxProvider = Provider<DeckSfx>((ref) {
  final sfx = DeckSfx();
  ref.onDispose(sfx.dispose);
  return sfx;
});
