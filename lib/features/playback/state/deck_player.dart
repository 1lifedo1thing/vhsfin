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
  // Winding from pause runs the tape and parks it again on release, like a
  // deck's picture search.
  var _pauseAfterShuttle = false;
  StreamSubscription<String>? _errorSubscription;
  final _errors = StreamController<String>.broadcast();
  final _surface = DeckSurfaceLedger();
  DeckShuttle _shuttle = DeckShuttle.idle;
  var _surfaceTransferInProgress = false;
  void Function(int epoch)? onSurfaceChanged;
  void Function(DeckShuttle shuttle)? onShuttleChanged;
  Future<void> Function()? _enterFullscreen;
  String? _lastError;

  bool get isReady => _player != null;
  VideoController? get controllerOrNull => _controller;
  String? get loadedUrl => _loadedUrl;
  int get surfaceEpoch => _surface.epoch;
  DeckSurfaceOwner get surfaceOwner => _surface.owner;
  DeckShuttle get shuttle => _shuttle;
  bool get surfaceTransferInProgress => _surfaceTransferInProgress;
  Duration get position => _player?.state.position ?? Duration.zero;
  String? get lastError => _lastError;
  Stream<String> get errors => _errors.stream;

  void clearLastError() {
    _lastError = null;
  }

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
    _player = Player(configuration: const PlayerConfiguration(title: 'VHSFin'));
    _errorSubscription = _player!.stream.error.listen((error) {
      if (_loadedUrl == null || error.trim().isEmpty) return;
      _lastError = error;
      _errors.add(error);
    });
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
    await stopShuttle();
    _ensure();
    if (_loadedUrl == url) {
      // A prepared web video must be playing before setting currentTime.
      // Seeking first can abort Jellyfin's progressive transcode response.
      if (play) await _player!.play();
      if (seekTo != null && seekTo > Duration.zero) {
        await _player!.seek(seekTo);
      }
      return;
    }
    _loadedUrl = url;
    _lastError = null;
    try {
      await _player!.open(Media(url), play: play);
    } catch (error) {
      _loadedUrl = null;
      _lastError = error.toString();
      rethrow;
    }
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
    await stopShuttle();
    await _player!.playOrPause();
  }

  void bindFullscreen(Future<void> Function() enterFullscreen) {
    _enterFullscreen = enterFullscreen;
  }

  Future<void> enterFullscreen() async {
    final enter = _enterFullscreen;
    if (enter == null) return;
    try {
      await enter();
    } catch (_) {
      // Browser fullscreen may be denied by policy; don't surface an
      // unhandled async exception from a deck-button tap.
    }
  }

  Future<void> stop() async {
    await stopShuttle();
    if (_player == null) return;
    _loadedUrl = null;
    _lastError = null;
    await _player!.stop();
    await _player!.setRate(1);
  }

  void startFastForward() {
    if (_player == null) return;
    _shuttleTimer?.cancel();
    _shuttleTimer = null;
    _setShuttle(DeckShuttle.fastForward);
    if (!_player!.state.playing) {
      _pauseAfterShuttle = true;
      unawaited(_player!.play());
    }
    unawaited(_player!.setRate(2.5));
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
    final pause = _pauseAfterShuttle;
    _pauseAfterShuttle = false;
    if (_player == null) return;
    await _player!.setRate(1);
    if (pause) await _player!.pause();
  }

  void _setShuttle(DeckShuttle next) {
    if (_shuttle == next) return;
    _shuttle = next;
    onShuttleChanged?.call(next);
  }

  void dispose() {
    stopShuttle();
    final errorSubscription = _errorSubscription;
    _errorSubscription = null;
    unawaited(() async {
      await errorSubscription?.cancel();
      await _errors.close();
    }());
    _player?.dispose();
    _player = null;
    _controller = null;
    _lastError = null;
    _enterFullscreen = null;
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
