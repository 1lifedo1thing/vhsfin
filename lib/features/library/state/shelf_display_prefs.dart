import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhsfin/features/library/state/tape_library.dart';
import 'package:vhsfin/features/library/state/vhs_spine_art.dart';
import 'package:vhsfin/features/library/model/tape.dart';

enum ShelfSortMode {
  titleAsc,
  yearNewest,
  yearOldest,
}

extension ShelfSortModeLabel on ShelfSortMode {
  String get buttonLabel => switch (this) {
        ShelfSortMode.titleAsc => 'A–Z',
        ShelfSortMode.yearNewest => 'YEAR ↓',
        ShelfSortMode.yearOldest => 'YEAR ↑',
      };

  String get menuTitle => switch (this) {
        ShelfSortMode.titleAsc => 'Title A–Z',
        ShelfSortMode.yearNewest => 'Year — newest first',
        ShelfSortMode.yearOldest => 'Year — oldest first',
      };
}

class ShelfDisplayPrefs {
  const ShelfDisplayPrefs({
    this.vhsOnly = false,
    this.sort = ShelfSortMode.titleAsc,
  });

  /// When true, only titles with real VHS sleeve art (Box / resolved scan).
  final bool vhsOnly;
  final ShelfSortMode sort;

  ShelfDisplayPrefs copyWith({
    bool? vhsOnly,
    ShelfSortMode? sort,
  }) {
    return ShelfDisplayPrefs(
      vhsOnly: vhsOnly ?? this.vhsOnly,
      sort: sort ?? this.sort,
    );
  }
}

final shelfDisplayPrefsProvider =
    NotifierProvider<ShelfDisplayPrefsNotifier, ShelfDisplayPrefs>(
  ShelfDisplayPrefsNotifier.new,
);

class ShelfDisplayPrefsNotifier extends Notifier<ShelfDisplayPrefs> {
  static const _vhsOnlyKey = 'vhsfin.box_art_only';
  static const _sortKey = 'vhsfin.shelf_sort';

  /// Bumped to ignore in-flight SharedPreferences restores after user edits.
  int _epoch = 0;

  @override
  ShelfDisplayPrefs build() {
    _restore();
    return const ShelfDisplayPrefs();
  }

  Future<void> _restore() async {
    final epoch = _epoch;
    final prefs = await SharedPreferences.getInstance();
    if (epoch != _epoch) return;
    final sortName = prefs.getString(_sortKey);
    final sort = ShelfSortMode.values.firstWhere(
      (m) => m.name == sortName,
      orElse: () => ShelfSortMode.titleAsc,
    );
    state = ShelfDisplayPrefs(
      vhsOnly: prefs.getBool(_vhsOnlyKey) ?? false,
      sort: sort,
    );
  }

  Future<void> setVhsOnly(bool value) async {
    _epoch++;
    state = state.copyWith(vhsOnly: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vhsOnlyKey, value);
  }

  Future<void> setSort(ShelfSortMode sort) async {
    if (state.sort == sort) return;
    _epoch++;
    state = state.copyWith(sort: sort);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortKey, sort.name);
  }
}

/// Tape ids known to have real VHS sleeve art (Jellyfin Box or resolver hit).
final vhsArtIndexProvider =
    NotifierProvider<VhsArtIndexNotifier, Set<String>>(VhsArtIndexNotifier.new);

class VhsArtIndexNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void mark(String tapeId, {required bool hasVhsArt}) {
    final has = state.contains(tapeId);
    if (hasVhsArt == has) return;
    if (hasVhsArt) {
      state = {...state, tapeId};
    } else {
      state = {...state}..remove(tapeId);
    }
  }

  /// One state write for a chunk of warm lookups (avoids N bookshelf rebuilds).
  void markMany(Map<String, bool> results) {
    if (results.isEmpty) return;
    final next = {...state};
    var changed = false;
    for (final entry in results.entries) {
      final has = next.contains(entry.key);
      if (entry.value == has) continue;
      changed = true;
      if (entry.value) {
        next.add(entry.key);
      } else {
        next.remove(entry.key);
      }
    }
    if (changed) state = next;
  }

  void seedFromTapes(Iterable<Tape> tapes) {
    final ids = <String>{
      ...state,
      for (final t in tapes)
        if (t.hasBoxImage || t.isDemo) t.id,
    };
    if (ids.length == state.length && ids.containsAll(state)) return;
    state = ids;
  }
}

List<Tape> applyShelfDisplayPrefs(
  List<Tape> items,
  ShelfDisplayPrefs prefs, {
  Set<String> vhsArtIds = const {},
}) {
  var out = List<Tape>.of(items);
  if (prefs.vhsOnly) {
    out = out
        .where(
          (t) => t.hasBoxImage || t.isDemo || vhsArtIds.contains(t.id),
        )
        .toList();
  }
  switch (prefs.sort) {
    case ShelfSortMode.titleAsc:
      out.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    case ShelfSortMode.yearNewest:
      out.sort((a, b) {
        final ay = a.productionYear ?? 0;
        final by = b.productionYear ?? 0;
        final c = by.compareTo(ay);
        if (c != 0) return c;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    case ShelfSortMode.yearOldest:
      out.sort((a, b) {
        final ay = a.productionYear ?? 9999;
        final by = b.productionYear ?? 9999;
        final c = ay.compareTo(by);
        if (c != 0) return c;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
  }
  return out;
}

/// Resolve sleeve art for every shelf tape so VHS-only filtering isn't limited
/// to currently mounted spines.
final vhsArtWarmProvider = FutureProvider.autoDispose<void>((ref) async {
  final shelves = await ref.watch(shelvesProvider.future);
  final tapes = shelves.expand((s) => s.items).toList();
  final index = ref.read(vhsArtIndexProvider.notifier);
  index.seedFromTapes(tapes);

  // Bound concurrency so we don't stampede VHSCollector / the IA proxy.
  const chunk = 8;
  for (var i = 0; i < tapes.length; i += chunk) {
    final slice = tapes.sublist(i, math.min(i + chunk, tapes.length));
    final batch = <String, bool>{};
    await Future.wait(slice.map((tape) async {
      try {
        final art = await ref.read(vhsSpineArtProvider(tape).future);
        batch[tape.id] = art != null || tape.hasBoxImage || tape.isDemo;
      } catch (_) {
        batch[tape.id] = tape.hasBoxImage || tape.isDemo;
      }
    }));
    index.markMany(batch);
  }
});

