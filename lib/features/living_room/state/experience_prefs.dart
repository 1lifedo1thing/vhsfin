import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhsfin/features/living_room/model/cabinet_style.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';

/// User-tunable living-room behavior (persisted).
class ExperiencePrefs {
  const ExperiencePrefs({
    this.saveTimestampOnEject = false,
    this.crtSkin = CrtTvSkin.crt90s,
    this.cabinetStyle = CabinetStyle.walnut,
    this.vhsCovers = false,
  });

  /// Remember playback position on eject; seek there on next insert.
  final bool saveTimestampOnEject;

  /// Classic CRT bezel / cabinet look.
  final CrtTvSkin crtSkin;

  /// Shelf and TV-stand furniture look.
  final CabinetStyle cabinetStyle;

  /// Show the scanned VHS front instead of the Jellyfin poster when the
  /// whole sleeve is available.
  final bool vhsCovers;

  ExperiencePrefs copyWith({
    bool? saveTimestampOnEject,
    CrtTvSkin? crtSkin,
    CabinetStyle? cabinetStyle,
    bool? vhsCovers,
  }) {
    return ExperiencePrefs(
      saveTimestampOnEject: saveTimestampOnEject ?? this.saveTimestampOnEject,
      crtSkin: crtSkin ?? this.crtSkin,
      cabinetStyle: cabinetStyle ?? this.cabinetStyle,
      vhsCovers: vhsCovers ?? this.vhsCovers,
    );
  }
}

final experiencePrefsProvider =
    NotifierProvider<ExperiencePrefsNotifier, ExperiencePrefs>(
      ExperiencePrefsNotifier.new,
    );

class ExperiencePrefsNotifier extends Notifier<ExperiencePrefs> {
  static const _saveTsKey = 'vhsfin.save_timestamp_on_eject';
  static const _crtSkinKey = 'vhsfin.crt_tv_skin.v1';
  static const _cabinetKey = 'vhsfin.cabinet_style.v1';
  static const _vhsCoversKey = 'vhsfin.vhs_covers.v1';

  int _epoch = 0;

  @override
  ExperiencePrefs build() {
    _restore();
    return const ExperiencePrefs();
  }

  Future<void> _restore() async {
    final epoch = _epoch;
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted || epoch != _epoch) return;
    final skin = CrtTvSkinLabels.fromPrefs(prefs.getString(_crtSkinKey));
    state = ExperiencePrefs(
      saveTimestampOnEject: prefs.getBool(_saveTsKey) ?? false,
      crtSkin: skin,
      cabinetStyle: CabinetStyleLabels.fromPrefs(prefs.getString(_cabinetKey)),
      vhsCovers: prefs.getBool(_vhsCoversKey) ?? false,
    );
  }

  Future<void> setSaveTimestampOnEject(bool value) async {
    _epoch++;
    state = state.copyWith(saveTimestampOnEject: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_saveTsKey, value);
  }

  Future<void> setCrtSkin(CrtTvSkin skin) async {
    if (state.crtSkin == skin) return;
    _epoch++;
    state = state.copyWith(crtSkin: skin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_crtSkinKey, skin.name);
  }

  Future<void> setVhsCovers(bool value) async {
    _epoch++;
    state = state.copyWith(vhsCovers: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vhsCoversKey, value);
  }

  Future<void> setCabinetStyle(CabinetStyle style) async {
    if (state.cabinetStyle == style) return;
    _epoch++;
    state = state.copyWith(cabinetStyle: style);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cabinetKey, style.name);
  }
}

/// Per-tape resume positions (milliseconds), used when save-on-eject is on.
final tapeResumePositionsProvider =
    NotifierProvider<TapeResumePositionsNotifier, Map<String, int>>(
      TapeResumePositionsNotifier.new,
    );

class TapeResumePositionsNotifier extends Notifier<Map<String, int>> {
  static const _key = 'vhsfin.tape_resume_ms.v1';
  late Completer<void> _ready;

  Future<void> get ready => _ready.future;

  @override
  Map<String, int> build() {
    _ready = Completer<void>();
    unawaited(_restore());
    return const {};
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      state = {for (final e in map.entries) e.key: (e.value as num).toInt()};
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } finally {
      if (!_ready.isCompleted) _ready.complete();
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
    await ready;
    if (position <= Duration.zero) {
      await clear(tapeId);
      return;
    }
    state = {...state, tapeId: position.inMilliseconds};
    await _persist();
  }

  Future<void> clear(String tapeId) async {
    await ready;
    if (!state.containsKey(tapeId)) return;
    state = {...state}..remove(tapeId);
    await _persist();
  }

  Future<void> clearAll() async {
    await ready;
    state = const {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
