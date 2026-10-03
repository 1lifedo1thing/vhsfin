import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_spine.dart';

void main() {
  const w = VhsSpine.nominalWidth;
  const h = VhsSpine.nominalHeight;
  const gap = 2.0;

  // Top corners in the leaning spine's frame (its upright centre at x = 0).
  double topLeft(double tip, double shift) =>
      shift - (w / 2) * math.cos(tip) + h * math.sin(tip);
  double neighbourTopRight(double tip, double shift) =>
      -(w + gap) + shift + (w / 2) * math.cos(tip) + h * math.sin(tip);

  for (final neighbourTip in [0.0, -0.03, 0.03]) {
    test('end tape rests on a neighbour tipped $neighbourTip', () {
      const lean = -0.2;
      final offsets = VhsSpine.restingOffsetsForRow(
        tips: [null, neighbourTip, lean],
        widths: const [w, w, w],
        gap: gap,
        height: h,
      );
      final corner = topLeft(lean, offsets[2]!);
      final target = neighbourTopRight(neighbourTip, 0);
      // Touching, with the sub-pixel overlap that hides the seam.
      expect(corner, closeTo(target - 0.75, 0.01));
    });
  }

  test('upright and micro-tipped spines keep their default', () {
    final offsets = VhsSpine.restingOffsetsForRow(
      tips: const [null, 0.02, null],
      widths: const [w, w, w],
      gap: gap,
      height: h,
    );
    expect(offsets, everyElement(isNull));
  });
}
