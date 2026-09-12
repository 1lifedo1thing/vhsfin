import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhsfin/features/auth/state/session_notifier.dart';
import 'package:vhsfin/features/library/model/media_library.dart';
import 'package:vhsfin/features/library/model/shelf.dart';

final librariesProvider = FutureProvider<List<LibraryNode>>((ref) async {
  final session = await ref.watch(sessionProvider.future);
  if (session == null) return const [];
  return ref.watch(jellyfinClientProvider).fetchLibraries(session);
});

/// Folder browser stack for the collection picker UI.
final browseStackProvider =
    NotifierProvider<BrowseStackNotifier, List<LibraryNode>>(
      BrowseStackNotifier.new,
    );

class BrowseStackNotifier extends Notifier<List<LibraryNode>> {
  @override
  List<LibraryNode> build() => const [];

  void openRoot() => state = const [];

  void push(LibraryNode node) => state = [...state, node];

  void pop() {
    if (state.isEmpty) return;
    state = state.sublist(0, state.length - 1);
  }

  void popTo(int index) {
    if (index < 0) {
      state = const [];
      return;
    }
    state = state.sublist(0, index + 1);
  }
}

final browseChildrenProvider = FutureProvider.autoDispose<List<LibraryNode>>((
  ref,
) async {
  final session = await ref.watch(sessionProvider.future);
  if (session == null) return const [];

  final stack = ref.watch(browseStackProvider);
  final client = ref.watch(jellyfinClientProvider);

  if (stack.isEmpty) {
    return client.fetchLibraries(session);
  }

  return client.fetchBrowsableChildren(
    session: session,
    parentId: stack.last.id,
  );
});

final shelfSourcesProvider =
    NotifierProvider<ShelfSourcesNotifier, List<ShelfSource>>(
      ShelfSourcesNotifier.new,
    );

class ShelfSourcesNotifier extends Notifier<List<ShelfSource>> {
  static const _key = 'vhsfin.shelf_sources.v3';
  static const _legacySingleKey = 'vhsfin.shelf_source.v2';
  static const _legacyIdKey = 'vhsfin.selected_library';
  static const _legacyMultiKey = 'vhsfin.selected_libraries';

  int _epoch = 0;
  String? _scopedKey;

  @override
  List<ShelfSource> build() {
    final session = ref.watch(sessionProvider).value;
    final epoch = ++_epoch;
    _scopedKey = session == null ? null : '$_key.${session.preferenceScope}';
    if (session != null) _restore(epoch, _scopedKey!, session.preferenceScope);
    return const [];
  }

  Future<void> _restore(int epoch, String key, String scope) async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted || epoch != _epoch) return;
    final ownRaw = prefs.getString(key);
    final canMigrate = prefs.getString('vhsfin.shelf_legacy_owner') == scope;
    final raw = ownRaw ?? (canMigrate ? prefs.getString(_key) : null);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        state = list
            .map((e) => ShelfSource.fromJson(e as Map<String, dynamic>))
            .toList();
        if (ownRaw == null) await _persist();
        return;
      } catch (_) {
        // Malformed preferences should not prevent a new selection.
      }
    }
    if (!canMigrate || ownRaw != null) return;
    final legacySingle = prefs.getString(_legacySingleKey);
    if (legacySingle != null) {
      try {
        state = [
          ShelfSource.fromJson(
            jsonDecode(legacySingle) as Map<String, dynamic>,
          ),
        ];
        await _persist();
        return;
      } catch (_) {}
    }
    final legacyId = prefs.getString(_legacyIdKey);
    final ids = legacyId != null && legacyId.isNotEmpty
        ? [legacyId]
        : prefs.getStringList(_legacyMultiKey) ?? <String>[];
    state = [for (final id in ids) ShelfSource(id: id, name: 'Library')];
    await _persist();
  }

  Future<void> _persist() async {
    final key = _scopedKey;
    if (key == null) return;
    // Snapshot before awaiting: another account or edit may arrive meanwhile.
    final raw = jsonEncode(state.map((s) => s.toJson()).toList());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, raw);
  }

  bool containsId(String id) => state.any((s) => s.id == id);

  Future<void> toggle(ShelfSource source) async {
    _epoch++;
    if (containsId(source.id)) {
      state = state.where((s) => s.id != source.id).toList();
    } else {
      state = [...state, source];
    }
    await _persist();
  }

  Future<void> add(ShelfSource source) async {
    _epoch++;
    if (containsId(source.id)) return;
    state = [...state, source];
    await _persist();
  }

  Future<void> remove(String id) async {
    _epoch++;
    state = state.where((s) => s.id != id).toList();
    await _persist();
  }
}

final shelvesProvider = FutureProvider<List<Shelf>>((ref) async {
  final session = await ref.watch(sessionProvider.future);
  if (session == null) {
    return [const Shelf(id: 'connect', title: 'Jellyfin', items: [])];
  }

  final sources = ref.watch(shelfSourcesProvider);
  if (sources.isEmpty) {
    return [const Shelf(id: 'empty', title: 'Pick collections', items: [])];
  }

  final client = ref.watch(jellyfinClientProvider);
  final shelves = <Shelf>[];

  for (final source in sources) {
    final items = await client.fetchShelfItems(
      session: session,
      source: source,
    );
    shelves.add(
      Shelf(id: source.id, title: source.name.toUpperCase(), items: items),
    );
  }

  return shelves;
});
