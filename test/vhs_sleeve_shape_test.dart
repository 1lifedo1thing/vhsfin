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

  test('a dedicated front scan is the whole cover once measured', () {
    const art = VhsSpineArt(
      imageUrl: 'spine.jpg',
      centerWidthFraction: 1,
      frontImageUrl: 'front.jpg',
    );
    expect(vhsFrontCoverOf(art), isNull, reason: 'not measured yet');
    VhsSleeveShapes.debugRecord('front.jpg', 0.56);
    final cover = vhsFrontCoverOf(art)!;
    expect(cover.url, 'front.jpg');
    expect((cover.left, cover.right, cover.aspect), (0, 1, 0.56));
  });

  test('spine-only and unmeasured sleeves have no front', () {
    const art = VhsSpineArt(
      imageUrl: 'box.jpg',
      centerWidthFraction: VhsCoverResolver.wraparoundSpineFraction,
    );
    expect(vhsFrontCoverOf(art), isNull);
    VhsSleeveShapes.debugRecord('box.jpg', 0.14);
    expect(vhsFrontCoverOf(art), isNull);
    expect(VhsSleeveShapes.spineFraction(art), 1, reason: 'show it whole');
  });

  test('a wraparound front starts at the spine and is one box-front wide', () {
    const spine = VhsCoverResolver.wraparoundSpineFraction;
    const art = VhsSpineArt(imageUrl: 'wrap.jpg', centerWidthFraction: spine);
    const sleeveAspect = 1.25;
    VhsSleeveShapes.debugRecord('wrap.jpg', sleeveAspect);

    final cover = vhsFrontCoverOf(art)!;
    expect(
      cover.left,
      closeTo(0.5 + spine / 2, 1e-9),
      reason: 'right of spine',
    );
    expect(cover.right, lessThanOrEqualTo(1));
    expect(cover.aspect, closeTo(vhsFrontAspect, 1e-9));
    expect(
      (cover.right - cover.left) * sleeveAspect,
      closeTo(cover.aspect, 1e-9),
    );
  });
}
