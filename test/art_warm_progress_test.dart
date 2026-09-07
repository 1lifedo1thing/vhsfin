import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/library/state/art_onboarding.dart';

void main() {
  test('ArtWarmProgress fraction clamps and handles empty total', () {
    expect(const ArtWarmProgress().fraction, 0);
    expect(
      const ArtWarmProgress(completed: 5, total: 10).fraction,
      0.5,
    );
    expect(
      const ArtWarmProgress(completed: 12, total: 10).fraction,
      1.0,
    );
  });

  test('ArtWarmProgress copyWith preserves fields', () {
    const base = ArtWarmProgress(
      phase: ArtWarmPhase.running,
      completed: 2,
      total: 8,
      foundCount: 1,
    );
    final next = base.copyWith(completed: 4, foundCount: 3);
    expect(next.phase, ArtWarmPhase.running);
    expect(next.completed, 4);
    expect(next.total, 8);
    expect(next.foundCount, 3);
  });
}
