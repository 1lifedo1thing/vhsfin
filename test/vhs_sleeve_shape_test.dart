import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/data/vhs_sleeve_shape.dart';

void main() {
  setUp(VhsSleeveShapes.debugReset);

  test('sleeve proportions classify spine, front, and wraparound scans', () {
    expect(SleeveShape.fromAspect(25 / 190), SleeveShape.spine);
    expect(SleeveShape.fromAspect(105 / 190), SleeveShape.front);
    expect(SleeveShape.fromAspect(2 / 3), SleeveShape.front);
    expect(SleeveShape.fromAspect(235 / 190), SleeveShape.wraparound);
  });

  test('a dedicated front scan is the cover, whatever the spine is', () {
    const art = VhsSpineArt(
      imageUrl: 'spine.jpg',
      centerWidthFraction: 1,
      frontImageUrl: 'front.jpg',
    );
    final cover = vhsFrontCoverOf(art)!;
    expect(cover.url, 'front.jpg');
    expect(cover.widthFraction, 1);
  });

  test('only a measured wraparound yields its right-hand front panel', () {
    const art = VhsSpineArt(
      imageUrl: 'box.jpg',
      centerWidthFraction: VhsCoverResolver.wraparoundSpineFraction,
    );
    expect(vhsFrontCoverOf(art), isNull, reason: 'shape not known yet');

    VhsSleeveShapes.debugRecord('box.jpg', SleeveShape.spine);
    expect(vhsFrontCoverOf(art), isNull, reason: 'spine-only Box');
    expect(VhsSleeveShapes.spineFraction(art), 1, reason: 'show it whole');

    VhsSleeveShapes.debugRecord('box.jpg', SleeveShape.wraparound);
    final cover = vhsFrontCoverOf(art)!;
    expect(cover.align, Alignment.centerRight);
    expect(cover.widthFraction, closeTo((1 - 0.09) / 2, 1e-9));
  });
}
