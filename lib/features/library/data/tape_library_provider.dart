import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhsfin/features/auth/data/jellyfin_client.dart';
import 'package:vhsfin/features/auth/model/session.dart';
import 'package:vhsfin/features/library/model/media_library.dart';
import 'package:vhsfin/features/library/model/shelf.dart';

final jellyfinClientProvider = Provider<JellyfinClient>((ref) {
  return JellyfinClient();
});

final sessionProvider =
    AsyncNotifierProvider<SessionNotifier, JellyfinSession?>(
  SessionNotifier.new,
);

class SessionNotifier extends AsyncNotifier<JellyfinSession?> {
  static const _key = 'vhsfin.session';

  @override
  Future<JellyfinSession?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return JellyfinSession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      await prefs.remove(_key);
      return null;
    }
  }

  Future<void> signIn({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final client = ref.read(jellyfinClientProvider);
    final session = await client.authenticate(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(session.toJson()));
    state = AsyncData(session);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = const AsyncData(null);
  }
}

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

final browseChildrenProvider =
    FutureProvider.autoDispose<List<LibraryNode>>((ref) async {
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

  @override
  List<ShelfSource> build() {
    _restore();
    return const [];
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        state = list
            .map((e) => ShelfSource.fromJson(e as Map<String, dynamic>))
            .toList();
        return;
      } catch (_) {
        await prefs.remove(_key);
      }
    }

    final legacySingle = prefs.getString(_legacySingleKey);
    if (legacySingle != null) {
      try {
        state = [
          ShelfSource.fromJson(jsonDecode(legacySingle) as Map<String, dynamic>),
        ];
        await _persist();
        return;
      } catch (_) {}
    }

    final legacyId = prefs.getString(_legacyIdKey);
    if (legacyId != null && legacyId.isNotEmpty) {
      state = [ShelfSource(id: legacyId, name: 'Library')];
      await _persist();
      return;
    }

    final legacyMulti = prefs.getStringList(_legacyMultiKey);
    if (legacyMulti != null && legacyMulti.isNotEmpty) {
      state = [
        for (final id in legacyMulti) ShelfSource(id: id, name: 'Library'),
      ];
      await _persist();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state.map((s) => s.toJson()).toList()),
    );
  }

  bool containsId(String id) => state.any((s) => s.id == id);

  Future<void> toggle(ShelfSource source) async {
    if (containsId(source.id)) {
      state = state.where((s) => s.id != source.id).toList();
    } else {
      state = [...state, source];
    }
    await _persist();
  }

  Future<void> add(ShelfSource source) async {
    if (containsId(source.id)) return;
    state = [...state, source];
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((s) => s.id != id).toList();
    await _persist();
  }
}

final shelvesProvider = FutureProvider<List<Shelf>>((ref) async {
  final session = await ref.watch(sessionProvider.future);
  if (session == null) {
    return [
      const Shelf(
        id: 'connect',
        title: 'Jellyfin',
        items: [],
      ),
    ];
  }

  final sources = ref.watch(shelfSourcesProvider);
  if (sources.isEmpty) {
    return [
      const Shelf(
        id: 'empty',
        title: 'Pick collections',
        items: [],
      ),
    ];
  }

  final client = ref.watch(jellyfinClientProvider);
  final shelves = <Shelf>[];

  for (final source in sources) {
    final items = await client.fetchShelfItems(
      session: session,
      source: source,
    );
    shelves.add(
      Shelf(
        id: source.id,
        title: source.name.toUpperCase(),
        items: items,
      ),
    );
  }

  return shelves;
});
