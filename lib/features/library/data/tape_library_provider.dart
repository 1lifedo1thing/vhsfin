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

final librariesProvider = FutureProvider<List<MediaLibrary>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return const [];
  return ref.watch(jellyfinClientProvider).fetchLibraries(session);
});

final selectedLibraryIdsProvider =
    NotifierProvider<SelectedLibraryIdsNotifier, Set<String>>(
  SelectedLibraryIdsNotifier.new,
);

class SelectedLibraryIdsNotifier extends Notifier<Set<String>> {
  static const _key = 'vhsfin.selected_libraries';

  @override
  Set<String> build() {
    _restore();
    return {};
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key);
    if (ids != null) {
      state = ids.toSet();
      return;
    }
    // First run after connect: select nothing until user picks, unless we
    // can auto-hint kids/movies libraries once views load.
  }

  Future<void> setIds(Set<String> ids) async {
    state = ids;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.toList()..sort());
  }

  Future<void> toggle(String id) async {
    final next = {...state};
    if (!next.add(id)) next.remove(id);
    await setIds(next);
  }

  Future<void> preferDefaults(List<MediaLibrary> libraries) async {
    if (state.isNotEmpty || libraries.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_key)) return;

    final kidsish = libraries.where((lib) {
      final name = lib.name.toLowerCase();
      return name.contains('kid') ||
          name.contains('child') ||
          name.contains('family') ||
          lib.isMovies;
    }).map((lib) => lib.id);

    final pick = kidsish.isNotEmpty
        ? kidsish.toSet()
        : {libraries.first.id};
    await setIds(pick);
  }
}

final expandedSeriesIdProvider = NotifierProvider<ExpandedSeriesNotifier, String?>(
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

  final libraries = await ref.watch(librariesProvider.future);
  await ref.read(selectedLibraryIdsProvider.notifier).preferDefaults(libraries);

  final selected = ref.watch(selectedLibraryIdsProvider);
  final active = libraries.where((lib) => selected.contains(lib.id)).toList();

  if (active.isEmpty) {
    return [
      const Shelf(
        id: 'empty',
        title: 'No libraries selected',
        items: [],
      ),
    ];
  }

  final client = ref.watch(jellyfinClientProvider);
  final shelves = <Shelf>[];

  for (final library in active) {
    final items = await client.fetchLibraryShelfItems(
      session: session,
      library: library,
    );
    shelves.add(
      Shelf(
        id: library.id,
        title: library.name.toUpperCase(),
        items: items,
      ),
    );
  }

  final expandedId = ref.watch(expandedSeriesIdProvider);
  if (expandedId != null) {
    Tape? series;
    for (final shelf in shelves) {
      for (final item in shelf.items) {
        if (item.id == expandedId && item.kind == TapeKind.series) {
          series = item;
          break;
        }
      }
    }
    if (series != null) {
      final episodes = await client.fetchEpisodes(
        session: session,
        seriesId: series.id,
        libraryName: series.libraryName,
      );
      final insertAt = shelves.indexWhere(
        (shelf) => shelf.items.any((t) => t.id == series!.id),
      );
      final episodeShelf = Shelf(
        id: 'episodes-$expandedId',
        title: '${series.title.toUpperCase()} · EPISODES',
        items: episodes,
        parentSeriesId: expandedId,
      );
      if (insertAt >= 0) {
        shelves.insert(insertAt + 1, episodeShelf);
      } else {
        shelves.add(episodeShelf);
      }
    }
  }

  return shelves;
});
