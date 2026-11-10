import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/data/repositories/jellyfin_client.dart';
import 'package:vhsfin/features/auth/model/session.dart';
import 'package:vhsfin/features/auth/state/session_notifier.dart';
import 'package:vhsfin/features/library/data/sleeve_downscale.dart';
import 'package:vhsfin/features/library/model/sleeve_shrink_status.dart';

/// Replaces oversized `Box` images on the server (full-resolution archive
/// scans saved before 1.0.1) with the same picture as a [sleeveMaxHeight]
/// JPEG. Never re-searches, so hand-picked sleeves stay.
///
/// [check] sizes up the server, then [shrink] replaces what it found.
class SleeveShrinker {
  SleeveShrinker(this._client, this._session);

  /// Box images larger than this are re-encoded even within the height cap.
  static const maxBytes = 3000000;

  /// Over the size cap but this small (thin spine strips): not worth it.
  static const minBytes = 1000000;

  /// Jellyfin serves a PNG Box back as PNG, several times a JPEG's size.
  static const maxPngBytes = 300000;

  @visibleForTesting
  static bool isOversized({
    required int width,
    required int height,
    required int bytes,
    required bool png,
  }) =>
      bytes > maxBytes ||
      (png && bytes > maxPngBytes) ||
      (bytes > minBytes &&
          (height > sleeveMaxHeight || width > sleeveMaxWidth));
  static const _checkBatch = 6;

  final JellyfinClient _client;
  final JellyfinSession? _session;
  final status = ValueNotifier(const SleeveShrinkStatus());
  var _oversized = <({String id, int bytes})>[];
  var _disposed = false;

  bool get available => !kIsWeb && _session != null;

  Future<void> check() async {
    final session = _session;
    if (session == null || status.value.busy) return;
    _set(const SleeveShrinkStatus(phase: SleeveShrinkPhase.checking));
    try {
      if (!await _client.isAdministrator(session)) {
        _set(const SleeveShrinkStatus(phase: SleeveShrinkPhase.adminOnly));
        return;
      }
      final ids = await _client.fetchBoxImageItemIds(session);
      final oversized = <({String id, int bytes})>[];
      for (var i = 0; i < ids.length; i += _checkBatch) {
        if (_disposed) return;
        _set(
          SleeveShrinkStatus(
            phase: SleeveShrinkPhase.checking,
            progress: i,
            total: ids.length,
          ),
        );
        final batch = ids.sublist(i, math.min(i + _checkBatch, ids.length));
        final infos = await Future.wait(
          batch.map((id) => _client.boxImageInfo(session, id)),
        );
        for (var j = 0; j < batch.length; j++) {
          final info = infos[j];
          if (info == null) continue;
          if (isOversized(
            width: info.width,
            height: info.height,
            bytes: info.bytes,
            png: info.png,
          )) {
            oversized.add((id: batch[j], bytes: info.bytes));
          }
        }
      }
      _oversized = oversized;
      _set(
        SleeveShrinkStatus(
          phase: SleeveShrinkPhase.ready,
          sleeves: ids.length,
          oversized: oversized.length,
          oversizedBytes: oversized.fold(0, (sum, o) => sum + o.bytes),
        ),
      );
    } catch (err) {
      debugPrint('sleeve shrink check failed: $err');
      _set(const SleeveShrinkStatus(phase: SleeveShrinkPhase.failed));
    }
  }

  Future<void> shrink() async {
    final session = _session;
    if (session == null || status.value.phase != SleeveShrinkPhase.ready) {
      return;
    }
    var current = status.value.copyWith(
      phase: SleeveShrinkPhase.running,
      progress: 0,
      total: _oversized.length,
    );
    _set(current);
    for (final sleeve in _oversized) {
      if (_disposed) return;
      final after = await _shrink(session, sleeve.id);
      current = current.copyWith(
        progress: current.progress + 1,
        shrunk: current.shrunk + (after == null ? 0 : 1),
        failed: current.failed + (after == null ? 1 : 0),
        bytesAfter: current.bytesAfter + (after ?? sleeve.bytes),
      );
      _set(current);
    }
    _oversized = [];
    _set(current.copyWith(phase: SleeveShrinkPhase.done));
  }

  /// Forget a finished or abandoned pass so the next open checks again.
  void reset() {
    if (status.value.busy) return;
    _oversized = [];
    _set(const SleeveShrinkStatus());
  }

  void _set(SleeveShrinkStatus value) {
    if (!_disposed) status.value = value;
  }

  void dispose() {
    _disposed = true;
    status.dispose();
  }

  /// Stored size after shrinking one sleeve, or null if it was skipped.
  /// A failure skips the sleeve rather than stopping the pass.
  Future<int?> _shrink(JellyfinSession session, String itemId) async {
    try {
      final original = await _client.downloadBoxImage(session, itemId);
      final jpeg = await downscaleSleeve(original);
      if (jpeg == null || jpeg.length >= original.length) return null;
      final saved = await _client.saveBoxImage(
        session: session,
        itemId: itemId,
        jpeg: jpeg,
        overwrite: true,
      );
      return saved ? jpeg.length : null;
    } catch (err) {
      debugPrint('sleeve shrink skipped $itemId: $err');
      return null;
    }
  }
}

final sleeveShrinkerProvider = Provider<SleeveShrinker>((ref) {
  final shrinker = SleeveShrinker(
    ref.watch(jellyfinClientProvider),
    ref.watch(sessionProvider).value,
  );
  ref.onDispose(shrinker.dispose);
  return shrinker;
});
