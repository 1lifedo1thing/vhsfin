import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhsfin/features/library/state/shelf_display_prefs.dart';
import 'package:vhsfin/features/library/state/tape_library.dart';
import 'package:vhsfin/features/library/state/vhs_spine_art.dart';

/// Whether the first-time VHS art-grab tour has been finished.
final artOnboardingDoneProvider =
    NotifierProvider<ArtOnboardingDoneNotifier, bool>(
  ArtOnboardingDoneNotifier.new,
);

class ArtOnboardingDoneNotifier extends Notifier<bool> {
  static const prefsKey = 'vhsfin.art_onboarding_done.v1';

  int _epoch = 0;

  @override
  bool build() {
    _restore();
    return false;
  }

  Future<void> _restore() async {
    final epoch = _epoch;
    final prefs = await SharedPreferences.getInstance();
    if (epoch != _epoch) return;
    state = prefs.getBool(prefsKey) ?? false;
  }

  Future<void> markDone() async {
    _epoch++;
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }

  /// Clears the flag so the art-grab popup can run again (demo / QA).
  Future<void> resetForDemo() async {
    _epoch++;
    state = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, false);
  }
}

enum ArtWarmPhase { idle, running, done }

class ArtWarmProgress {
  const ArtWarmProgress({
    this.phase = ArtWarmPhase.idle,
    this.completed = 0,
    this.total = 0,
    this.foundCount = 0,
  });

  final ArtWarmPhase phase;
  final int completed;
  final int total;
  final int foundCount;

  double get fraction {
    if (total <= 0) return 0;
    return (completed / total).clamp(0.0, 1.0);
  }

  ArtWarmProgress copyWith({
    ArtWarmPhase? phase,
    int? completed,
    int? total,
    int? foundCount,
  }) {
    return ArtWarmProgress(
      phase: phase ?? this.phase,
      completed: completed ?? this.completed,
      total: total ?? this.total,
      foundCount: foundCount ?? this.foundCount,
    );
  }
}

final artWarmProgressProvider =
    NotifierProvider<ArtWarmProgressNotifier, ArtWarmProgress>(
  ArtWarmProgressNotifier.new,
);

/// Resolves sleeve art for shelf tapes with progress for the onboarding UI.
class ArtWarmProgressNotifier extends Notifier<ArtWarmProgress> {
  var _running = false;
  var _generation = 0;

  @override
  ArtWarmProgress build() => const ArtWarmProgress();

  /// Starts a warm pass if idle (or [force] even when already done).
  Future<void> ensureRunning({bool force = false}) async {
    if (_running) return;
    if (!force && state.phase == ArtWarmPhase.done) return;
    await _run();
  }

  /// Clears progress and re-runs (demo onboarding).
  Future<void> resetAndRerun() async {
    _generation++;
    _running = false;
    state = const ArtWarmProgress();
    await _run();
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;
    final gen = ++_generation;

    try {
      final shelves = await ref.read(shelvesProvider.future);
      if (gen != _generation) return;

      final tapes = shelves.expand((s) => s.items).toList();
      final index = ref.read(vhsArtIndexProvider.notifier);
      index.seedFromTapes(tapes);

      if (tapes.isEmpty) {
        state = const ArtWarmProgress(
          phase: ArtWarmPhase.done,
          completed: 0,
          total: 0,
          foundCount: 0,
        );
        return;
      }

      state = ArtWarmProgress(
        phase: ArtWarmPhase.running,
        completed: 0,
        total: tapes.length,
        foundCount: ref.read(vhsArtIndexProvider).length,
      );

      const chunk = 8;
      var completed = 0;
      for (var i = 0; i < tapes.length; i += chunk) {
        if (gen != _generation) return;
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
        if (gen != _generation) return;

        index.markMany(batch);
        completed += slice.length;
        state = ArtWarmProgress(
          phase: ArtWarmPhase.running,
          completed: completed,
          total: tapes.length,
          foundCount: ref.read(vhsArtIndexProvider).length,
        );
      }

      if (gen != _generation) return;
      state = ArtWarmProgress(
        phase: ArtWarmPhase.done,
        completed: tapes.length,
        total: tapes.length,
        foundCount: ref.read(vhsArtIndexProvider).length,
      );
    } finally {
      if (gen == _generation) _running = false;
    }
  }
}
