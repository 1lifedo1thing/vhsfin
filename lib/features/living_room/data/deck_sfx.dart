import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Deck mechanical SFX — separate from media_kit movie audio.
///
/// Assets are CC0 from BigSoundBank (Pierre SIBAN); see assets/sounds/CREDITS.txt.
class DeckSfx {
  DeckSfx() {
    _oneshot = AudioPlayer();
    _shuttle = AudioPlayer();
    _oneshot.setReleaseMode(ReleaseMode.stop);
    _shuttle.setReleaseMode(ReleaseMode.loop);
    _oneshot.setVolume(0.9);
    _shuttle.setVolume(0.55);
  }

  late final AudioPlayer _oneshot;
  late final AudioPlayer _shuttle;

  Future<void> playInsert() => _playOneshot('sounds/vhs_insert.ogg');

  /// Plays eject and completes when the clip ends (or after a short timeout).
  Future<void> playEject() => _playOneshot(
        'sounds/vhs_eject.ogg',
        waitForCompletion: true,
        fallbackMs: 2100,
      );

  Future<void> startFastForward() => _playShuttle('sounds/vhs_ff.ogg');

  Future<void> startRewind() => _playShuttle('sounds/vhs_rew.ogg');

  Future<void> stopShuttle() async {
    try {
      await _shuttle.stop();
    } catch (err) {
      debugPrint('deck-sfx stopShuttle failed: $err');
    }
  }

  Future<void> _playOneshot(
    String asset, {
    bool waitForCompletion = false,
    int fallbackMs = 2000,
  }) async {
    try {
      // play() replaces the current clip — awaiting stop() added audible lag.
      await _oneshot.play(AssetSource(asset));
      if (!waitForCompletion) return;
      try {
        await _oneshot.onPlayerComplete.first.timeout(
          Duration(milliseconds: fallbackMs),
        );
      } catch (_) {
        // Timeout / already stopped — treat as finished.
      }
    } catch (err) {
      debugPrint('deck-sfx oneshot $asset failed: $err');
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
    await _oneshot.dispose();
    await _shuttle.dispose();
  }
}

final deckSfxProvider = Provider<DeckSfx>((ref) {
  final sfx = DeckSfx();
  ref.onDispose(sfx.dispose);
  return sfx;
});
