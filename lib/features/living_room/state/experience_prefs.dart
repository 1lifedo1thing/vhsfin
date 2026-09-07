import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-tunable living-room behavior (persisted).
class ExperiencePrefs {
  const ExperiencePrefs({
    this.saveTimestampOnEject = false,
  });

  /// Remember playback position on eject; seek there on next insert.
  final bool saveTimestampOnEject;

  ExperiencePrefs copyWith({bool? saveTimestampOnEject}) {
    return ExperiencePrefs(
      saveTimestampOnEject:
          saveTimestampOnEject ?? this.saveTimestampOnEject,
    );
  }
}

final experiencePrefsProvider =
    NotifierProvider<ExperiencePrefsNotifier, ExperiencePrefs>(
  ExperiencePrefsNotifier.new,
);

class ExperiencePrefsNotifier extends Notifier<ExperiencePrefs> {
  static const _saveTsKey = 'vhsfin.save_timestamp_on_eject';

  int _epoch = 0;

  @override
  ExperiencePrefs build() {
    _restore();
    return const ExperiencePrefs();
  }

  Future<void> _restore() async {
    final epoch = _epoch;
    final prefs = await SharedPreferences.getInstance();
    if (epoch != _epoch) return;
    state = ExperiencePrefs(
      saveTimestampOnEject: prefs.getBool(_saveTsKey) ?? false,
    );
  }

  Future<void> setSaveTimestampOnEject(bool value) async {
    _epoch++;
    state = state.copyWith(saveTimestampOnEject: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_saveTsKey, value);
  }
}

/// Per-tape resume positions (milliseconds), used when save-on-eject is on.
final tapeResumePositionsProvider =
    NotifierProvider<TapeResumePositionsNotifier, Map<String, int>>(
  TapeResumePositionsNotifier.new,
);

class TapeResumePositionsNotifier extends Notifier<Map<String, int>> {
  static const _key = 'vhsfin.tape_resume_ms.v1';

  @override
  Map<String, int> build() {
    _restore();
    return const {};
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      state = {
        for (final e in map.entries) e.key: (e.value as num).toInt(),
      };
    } catch (_) {
      await prefs.remove(_key);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state));
  }

  Duration? positionFor(String tapeId) {
    final ms = state[tapeId];
    if (ms == null || ms <= 0) return null;
    return Duration(milliseconds: ms);
  }

  Future<void> save(String tapeId, Duration position) async {
    if (position <= Duration.zero) {
      await clear(tapeId);
      return;
    }
    state = {...state, tapeId: position.inMilliseconds};
    await _persist();
  }

  Future<void> clear(String tapeId) async {
    if (!state.containsKey(tapeId)) return;
    state = {...state}..remove(tapeId);
    await _persist();
  }

  Future<void> clearAll() async {
    state = const {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
