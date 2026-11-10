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
class SleeveShrinker {
  SleeveShrinker(this._client, this._session);

  /// Box images larger than this are re-encoded even within the height cap.
  static const maxBytes = 3000000;

  final JellyfinClient _client;
  final JellyfinSession? _session;
  final status = ValueNotifier(const SleeveShrinkStatus());
  var _disposed = false;

  bool get available => !kIsWeb && _session != null;

  Future<void> run() async {
    final session = _session;
    if (session == null || status.value.busy) return;
    _set(const SleeveShrinkStatus(phase: SleeveShrinkPhase.checking));
    try {
      if (!await _client.isAdministrator(session)) {
        _set(const SleeveShrinkStatus(phase: SleeveShrinkPhase.adminOnly));
        return;
      }
      final ids = await _client.fetchBoxImageItemIds(session);
      var shrunk = 0;
      for (var i = 0; i < ids.length; i++) {
        if (_disposed) return;
        _set(
          SleeveShrinkStatus(
            phase: SleeveShrinkPhase.running,
            checked: i,
            total: ids.length,
            shrunk: shrunk,
          ),
        );
        if (await _shrink(session, ids[i])) shrunk++;
      }
      _set(
        SleeveShrinkStatus(
          phase: SleeveShrinkPhase.done,
          checked: ids.length,
          total: ids.length,
          shrunk: shrunk,
        ),
      );
    } catch (err) {
      debugPrint('sleeve shrink failed: $err');
      _set(const SleeveShrinkStatus(phase: SleeveShrinkPhase.failed));
    }
  }

  void _set(SleeveShrinkStatus value) {
    if (!_disposed) status.value = value;
  }

  void dispose() {
    _disposed = true;
    status.dispose();
  }

  /// One item; a failure skips it rather than stopping the pass.
  Future<bool> _shrink(JellyfinSession session, String itemId) async {
    try {
      final info = await _client.boxImageInfo(session, itemId);
      if (info == null) return false;
      if (info.height <= sleeveMaxHeight &&
          info.width <= sleeveMaxWidth &&
          info.bytes <= maxBytes) {
        return false;
      }
      final original = await _client.downloadBoxImage(session, itemId);
      final jpeg = await downscaleSleeve(original);
      if (jpeg == null || jpeg.length >= original.length) return false;
      return await _client.saveBoxImage(
        session: session,
        itemId: itemId,
        jpeg: jpeg,
        overwrite: true,
      );
    } catch (err) {
      debugPrint('sleeve shrink skipped $itemId: $err');
      return false;
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
