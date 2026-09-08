import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

enum DeckShuttle { idle, rewind, fastForward }

/// Who may mount a [Video] on the shared deck controller.
///
/// Exactly one surface at a time — two [Video]s on one controller blanks the
/// web texture (audio keeps going). Use [none] while transferring ownership.
enum DeckSurfaceOwner { none, crt, fullscreen }

/// Pure ownership ledger (no media_kit) — release before claim; claim bumps epoch.
class DeckSurfaceLedger {
  var epoch = 0;
  var owner = DeckSurfaceOwner.crt;

  void release() {
    if (owner == DeckSurfaceOwner.none) return;
    owner = DeckSurfaceOwner.none;
  }

  void claim(DeckSurfaceOwner next) {
    assert(next != DeckSurfaceOwner.none, 'claim needs a real owner');
    owner = next;
    epoch++;
  }
}

/// One shared deck player for the CRT bezel and fullscreen.
///
/// Only one [Video] should bind to [controller] at a time — hide the CRT
/// surface while fullscreen is open, then [reattachSurface] on the way back.
class DeckPlayerController {
  Player? _player;
  VideoController? _controller;
  String? _loadedUrl;
  Timer? _shuttleTimer;
  final _surface = DeckSurfaceLedger();
  DeckShuttle _shuttle = DeckShuttle.idle;
  var _surfaceTransferInProgress = false;
  void Function(int epoch)? onSurfaceChanged;
  void Function(DeckShuttle shuttle)? onShuttleChanged;

  bool get isReady => _player != null;
  VideoController? get controllerOrNull => _controller;
  String? get loadedUrl => _loadedUrl;
  int get surfaceEpoch => _surface.epoch;
  DeckSurfaceOwner get surfaceOwner => _surface.owner;
  DeckShuttle get shuttle => _shuttle;
  bool get surfaceTransferInProgress => _surfaceTransferInProgress;
  Duration get position => _player?.state.position ?? Duration.zero;

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

  /// Drop ownership so every [Video] unmounts before a transfer.
  void releaseSurface() {
    if (_surface.owner == DeckSurfaceOwner.none) return;
    _surface.release();
    onSurfaceChanged?.call(_surface.epoch);
  }

  /// Prevent overlapping enter/exit taps from racing surface ownership.
  bool beginSurfaceTransfer() {
    if (_surfaceTransferInProgress) return false;
    _surfaceTransferInProgress = true;
    return true;
  }

  void endSurfaceTransfer() {
    _surfaceTransferInProgress = false;
  }

  /// Claim the persistent controller after the previous [Video] unmounts.
  ///
  /// A [VideoController] supports one output and is intended to live alongside
  /// its [Player]. Recreating it during every handoff can pause or detach web
  /// playback. The epoch remounts the [Video] without replacing its controller.
  void reattachSurface(DeckSurfaceOwner owner) {
    assert(owner != DeckSurfaceOwner.none, 'reattach needs a real owner');
    _ensure();
    _surface.claim(owner);
    onSurfaceChanged?.call(_surface.epoch);
  }

  Future<void> load(String url, {bool play = true, Duration? seekTo}) async {
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
    _shuttleTimer = Timer.periodic(const Duration(milliseconds: 200), (
      _,
    ) async {
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

final deckSurfaceOwnerProvider =
    NotifierProvider<DeckSurfaceOwnerNotifier, DeckSurfaceOwner>(
      DeckSurfaceOwnerNotifier.new,
    );

class DeckSurfaceOwnerNotifier extends Notifier<DeckSurfaceOwner> {
  @override
  DeckSurfaceOwner build() => DeckSurfaceOwner.crt;

  void set(DeckSurfaceOwner owner) => state = owner;
}

final deckShuttleProvider = NotifierProvider<DeckShuttleNotifier, DeckShuttle>(
  DeckShuttleNotifier.new,
);

class DeckShuttleNotifier extends Notifier<DeckShuttle> {
  @override
  DeckShuttle build() => DeckShuttle.idle;

  void set(DeckShuttle value) => state = value;
}

final deckPlayerProvider = Provider<DeckPlayerController>((ref) {
  final deck = DeckPlayerController();
  deck.onSurfaceChanged = (epoch) {
    ref.read(deckSurfaceEpochProvider.notifier).bump(epoch);
    ref.read(deckSurfaceOwnerProvider.notifier).set(deck.surfaceOwner);
  };
  deck.onShuttleChanged = (shuttle) {
    ref.read(deckShuttleProvider.notifier).set(shuttle);
  };
  ref.onDispose(deck.dispose);
  return deck;
});
