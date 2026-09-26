import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stable [GlobalKey]s for shelf spines and the VCR cassette bay.
class TapeFlightAnchors {
  final GlobalKey slotKey = GlobalKey(debugLabel: 'vcrCassetteSlot');
  final Map<String, GlobalKey> _spineKeys = {};

  /// Unique per shelf placement so duplicate movies don't share one GlobalKey.
  static String instanceKey({
    required String shelfId,
    required int row,
    required int index,
    required String tapeId,
  }) => '$shelfId|$row|$index|$tapeId';

  GlobalKey spineKeyFor(String instanceKey) {
    return _spineKeys.putIfAbsent(
      instanceKey,
      () => GlobalKey(debugLabel: 'vhsSpine-$instanceKey'),
    );
  }

  Rect? globalRectOf(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  /// Prefer [sourceKey]; else first mounted instance for [tapeId] (top shelf).
  Rect? spineRectForTape(String tapeId, {String? sourceKey}) {
    if (sourceKey != null) {
      final rect = globalRectOf(spineKeyFor(sourceKey));
      if (rect != null) return rect;
    }
    for (final entry in _spineKeys.entries) {
      if (!entry.key.endsWith('|$tapeId')) continue;
      final rect = globalRectOf(entry.value);
      if (rect != null) return rect;
    }
    return null;
  }
}

final tapeFlightAnchorsProvider = Provider<TapeFlightAnchors>((ref) {
  return TapeFlightAnchors();
});

/// Which shelf spine instance the user tapped (survives duplicate titles).
final flightSourceKeyProvider =
    NotifierProvider<FlightSourceKeyNotifier, String?>(
      FlightSourceKeyNotifier.new,
    );

class FlightSourceKeyNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String instanceKey) => state = instanceKey;

  void clear() => state = null;
}

/// Tape id currently mid-flight (shelf ↔ slot). Spines hide while set.
final flyingTapeIdProvider = NotifierProvider<FlyingTapeIdNotifier, String?>(
  FlyingTapeIdNotifier.new,
);

class FlyingTapeIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}
