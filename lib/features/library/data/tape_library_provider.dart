import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhsfin/features/auth/data/jellyfin_client.dart';
import 'package:vhsfin/features/auth/model/session.dart';
import 'package:vhsfin/features/library/model/media_library.dart';
import 'package:vhsfin/features/library/model/shelf.dart';
import 'package:vhsfin/features/library/model/tape.dart';

final jellyfinClientProvider = Provider<JellyfinClient>((ref) {
  return JellyfinClient();
});

final sessionProvider =
    NotifierProvider<SessionNotifier, JellyfinSession?>(SessionNotifier.new);

class SessionNotifier extends Notifier<JellyfinSession?> {
  static const _key = 'vhsfin.session';

  @override
  JellyfinSession? build() {
    _restore();
    return null;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      state = JellyfinSession.fromJson(json);
    } catch (_) {
      await prefs.remove(_key);
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
    state = session;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = null;
  }
}

final librariesProvider = FutureProvider<List<LibraryNode>>((ref) async {
  final session = ref.watch(sessionProvider);
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
  final session = ref.watch(sessionProvider);
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

final shelfSourceProvider =
    NotifierProvider<ShelfSourceNotifier, ShelfSource?>(ShelfSourceNotifier.new);

class ShelfSourceNotifier extends Notifier<ShelfSource?> {
  static const _key = 'vhsfin.shelf_source.v2';
  static const _legacyKey = 'vhsfin.selected_library';
  static const _legacyMultiKey = 'vhsfin.selected_libraries';

  @override
  ShelfSource? build() {
    _restore();
    return null;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        state = ShelfSource.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        return;
      } catch (_) {
        await prefs.remove(_key);
      }
    }

    final legacyId = prefs.getString(_legacyKey);
    if (legacyId != null && legacyId.isNotEmpty) {
      state = ShelfSource(id: legacyId, name: 'Library');
      return;
    }
    final legacyMulti = prefs.getStringList(_legacyMultiKey);
    if (legacyMulti != null && legacyMulti.isNotEmpty) {
      state = ShelfSource(id: legacyMulti.first, name: 'Library');
    }
  }

  Future<void> select(ShelfSource source) async {
    state = source;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(source.toJson()));
  }
}

final expandedSeriesIdProvider =
    NotifierProvider<ExpandedSeriesNotifier, String?>(
  ExpandedSeriesNotifier.new,
);

class ExpandedSeriesNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void toggle(String seriesId) {
    state = state == seriesId ? null : seriesId;
  }

  void clear() => state = null;
}

final shelvesProvider = FutureProvider<List<Shelf>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) {
    return [
      const Shelf(id: 'demo', title: 'Demo Reels', items: demoTapes),
    ];
  }

  final source = ref.watch(shelfSourceProvider);
  if (source == null) {
    return [
      const Shelf(
        id: 'empty',
        title: 'Pick a collection',
        items: [],
      ),
    ];
  }

  final client = ref.watch(jellyfinClientProvider);
  final items = await client.fetchShelfItems(
    session: session,
    source: source,
  );

  final shelves = <Shelf>[
    Shelf(
      id: source.id,
      title: source.name.toUpperCase(),
      items: items,
    ),
  ];

  final expandedId = ref.watch(expandedSeriesIdProvider);
  if (expandedId != null) {
    Tape? series;
    for (final item in items) {
      if (item.id == expandedId && item.kind == TapeKind.series) {
        series = item;
        break;
      }
    }
    if (series != null) {
      final episodes = await client.fetchEpisodes(
        session: session,
        seriesId: series.id,
        libraryName: series.libraryName,
      );
      shelves.add(
        Shelf(
          id: 'episodes-$expandedId',
          title: '${series.title.toUpperCase()} · EPISODES',
          items: episodes,
          parentSeriesId: expandedId,
        ),
      );
    }
  }

  return shelves;
});
