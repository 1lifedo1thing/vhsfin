import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

enum DeckShuttle { idle, rewind, fastForward }

/// One shared deck player for the CRT bezel and fullscreen.
///
/// Only one [Video] should bind to [controller] at a time — hide the CRT
/// surface while fullscreen is open, then [reattachSurface] on the way back.
class DeckPlayerController {
  Player? _player;
  VideoController? _controller;
  String? _loadedUrl;
  Timer? _shuttleTimer;
  var _surfaceEpoch = 0;
  DeckShuttle _shuttle = DeckShuttle.idle;
  void Function(int epoch)? onSurfaceChanged;
  void Function(DeckShuttle shuttle)? onShuttleChanged;

  bool get isReady => _player != null;
  VideoController? get controllerOrNull => _controller;
  String? get loadedUrl => _loadedUrl;
  int get surfaceEpoch => _surfaceEpoch;
  DeckShuttle get shuttle => _shuttle;
  Duration get position =>
      _player?.state.position ?? Duration.zero;

  Player get player {
    _ensure();
    return _player!;
  }

  VideoController get controller {
    _ensure();
    return _controller!;
  }

  void _ensure() {
    if (_player != null) return;
    _player = Player(
      configuration: const PlayerConfiguration(
        title: 'VHSFin',
        bufferSize: 32 * 1024 * 1024,
      ),
    );
    _controller = VideoController(_player!);
  }

  /// Fresh video surface after fullscreen — web loses the old texture otherwise.
  ///
  /// Call only after the fullscreen [Video] has been disposed (no second
  /// [Video] mounted yet). Then bump [surfaceEpoch] so the CRT remounts.
  void reattachSurface() {
    if (_player == null) return;
    _controller = VideoController(_player!);
    _surfaceEpoch++;
    onSurfaceChanged?.call(_surfaceEpoch);
  }

  Future<void> load(
    String url, {
    bool play = true,
    Duration? seekTo,
  }) async {
    stopShuttle();
    _ensure();
    if (_loadedUrl == url) {
      if (seekTo != null && seekTo > Duration.zero) {
        await _player!.seek(seekTo);
      }
      if (play) await _player!.play();
      return;
    }
    _loadedUrl = url;
    await _player!.open(Media(url), play: play);
    if (seekTo != null && seekTo > Duration.zero) {
      await _player!.seek(seekTo);
    }
  }

  Future<void> play() async {
    if (_player == null) return;
    await _player!.play();
  }

  Future<void> pause() async {
    if (_player == null) return;
    await _player!.pause();
  }

  Future<void> togglePlayPause() async {
    if (_player == null) return;
    stopShuttle();
    await _player!.playOrPause();
  }

  Future<void> stop() async {
    stopShuttle();
    if (_player == null) return;
    _loadedUrl = null;
    await _player!.stop();
    await _player!.setRate(1);
  }

  void startFastForward() {
    if (_player == null) return;
    _shuttleTimer?.cancel();
    _shuttleTimer = null;
    _setShuttle(DeckShuttle.fastForward);
    _player!.setRate(2.5);
  }

  void startRewind() {
    if (_player == null) return;
    _shuttleTimer?.cancel();
    _setShuttle(DeckShuttle.rewind);
    _shuttleTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      final position = _player!.state.position;
      final next = position - const Duration(milliseconds: 900);
      await _player!.seek(next < Duration.zero ? Duration.zero : next);
    });
  }

  Future<void> stopShuttle() async {
    _shuttleTimer?.cancel();
    _shuttleTimer = null;
    _setShuttle(DeckShuttle.idle);
    if (_player == null) return;
    await _player!.setRate(1);
  }

  void _setShuttle(DeckShuttle next) {
    if (_shuttle == next) return;
    _shuttle = next;
    onShuttleChanged?.call(next);
  }

  void dispose() {
    stopShuttle();
    _player?.dispose();
    _player = null;
    _controller = null;
  }
}

final deckSurfaceEpochProvider =
    NotifierProvider<DeckSurfaceEpochNotifier, int>(
  DeckSurfaceEpochNotifier.new,
);

class DeckSurfaceEpochNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump(int epoch) => state = epoch;
}

final deckShuttleProvider =
    NotifierProvider<DeckShuttleNotifier, DeckShuttle>(DeckShuttleNotifier.new);

class DeckShuttleNotifier extends Notifier<DeckShuttle> {
  @override
  DeckShuttle build() => DeckShuttle.idle;

  void set(DeckShuttle value) => state = value;
}

final deckPlayerProvider = Provider<DeckPlayerController>((ref) {
  final deck = DeckPlayerController();
  deck.onSurfaceChanged = (epoch) {
    ref.read(deckSurfaceEpochProvider.notifier).bump(epoch);
  };
  deck.onShuttleChanged = (shuttle) {
    ref.read(deckShuttleProvider.notifier).set(shuttle);
  };
  ref.onDispose(deck.dispose);
  return deck;
});
