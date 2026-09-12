import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhsfin/data/repositories/jellyfin_client.dart';
import 'package:vhsfin/features/auth/model/session.dart';

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
      final session = JellyfinSession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      // Claim unscoped shelf preferences for the account that created them.
      if (!prefs.containsKey('vhsfin.shelf_legacy_owner')) {
        await prefs.setString(
          'vhsfin.shelf_legacy_owner',
          session.preferenceScope,
        );
      }
      return session;
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
    // Finish restoring the previous account before replacing its session.
    await future;
    final client = ref.read(jellyfinClientProvider);
    final session = await client.authenticate(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    if (!prefs.containsKey('vhsfin.shelf_legacy_owner')) {
      await prefs.setString('vhsfin.shelf_legacy_owner', '');
    }
    await prefs.setString(_key, jsonEncode(session.toJson()));
    if (ref.mounted) state = AsyncData(session);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    if (ref.mounted) state = const AsyncData(null);
  }
}
