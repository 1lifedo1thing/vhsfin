import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

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
  void Function(int epoch)? onSurfaceChanged;

  bool get isReady => _player != null;
  VideoController? get controllerOrNull => _controller;
  String? get loadedUrl => _loadedUrl;
  int get surfaceEpoch => _surfaceEpoch;

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
  void reattachSurface() {
    if (_player == null) return;
    _controller = VideoController(_player!);
    _surfaceEpoch++;
    onSurfaceChanged?.call(_surfaceEpoch);
  }

  Future<void> load(String url, {bool play = true}) async {
    stopShuttle();
    _ensure();
    if (_loadedUrl == url) {
      if (play) await _player!.play();
      return;
    }
    _loadedUrl = url;
    await _player!.open(Media(url), play: play);
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
    stopShuttle();
    _player!.setRate(2.5);
  }

  void startRewind() {
    if (_player == null) return;
    stopShuttle();
    _shuttleTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      final position = _player!.state.position;
      final next = position - const Duration(milliseconds: 900);
      await _player!.seek(next < Duration.zero ? Duration.zero : next);
    });
  }

  Future<void> stopShuttle() async {
    _shuttleTimer?.cancel();
    _shuttleTimer = null;
    if (_player == null) return;
    await _player!.setRate(1);
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

final deckPlayerProvider = Provider<DeckPlayerController>((ref) {
  final deck = DeckPlayerController();
  deck.onSurfaceChanged = (epoch) {
    ref.read(deckSurfaceEpochProvider.notifier).bump(epoch);
  };
  ref.onDispose(deck.dispose);
  return deck;
});
