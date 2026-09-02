import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhsfin/features/auth/data/jellyfin_client.dart';
import 'package:vhsfin/features/auth/model/session.dart';
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

final tapeLibraryProvider = FutureProvider<List<Tape>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return demoTapes;

  final client = ref.watch(jellyfinClientProvider);
  try {
    final tapes = await client.fetchKidsMovies(session);
    if (tapes.isEmpty) return demoTapes;
    return tapes;
  } catch (_) {
    return demoTapes;
  }
});
