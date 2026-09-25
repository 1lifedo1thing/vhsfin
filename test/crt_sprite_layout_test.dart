import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/living_room/model/crt_sprite_layout.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';

void main() {
  test('sprite layouts stay inside their assets and unit square', () {
    for (final skin in CrtTvSkin.values) {
      final layout = CrtSpriteLayout.of(skin);
      final bounds = Offset.zero & layout.assetSize;
      expect(
        bounds.expandToInclude(layout.sourceRect),
        bounds,
        reason: skin.name,
      );
      for (final rect in [
        layout.screen,
        layout.slot,
        layout.keys,
        layout.remote,
        layout.full,
      ]) {
        expect(rect.left, inInclusiveRange(0, 1), reason: skin.name);
        expect(rect.top, inInclusiveRange(0, 1), reason: skin.name);
        expect(rect.right, inInclusiveRange(0, 1), reason: skin.name);
        expect(rect.bottom, inInclusiveRange(0, 1), reason: skin.name);
      }
    }
  });

  test('fromPrefs maps current and legacy cabinet names', () {
    expect(CrtTvSkinLabels.fromPrefs(null), CrtTvSkin.crt90s);
    expect(CrtTvSkinLabels.fromPrefs('skeuomorphic'), CrtTvSkin.crt90s);
    expect(CrtTvSkinLabels.fromPrefs('wegaSilver'), CrtTvSkin.ivory);
    expect(CrtTvSkinLabels.fromPrefs('woodConsole'), CrtTvSkin.knob);
    expect(CrtTvSkinLabels.fromPrefs('walnutGrille'), CrtTvSkin.knob2);
    expect(CrtTvSkinLabels.fromPrefs('crt90s'), CrtTvSkin.crt90s);
  });

  test('sprite layouts keep the cassette mouth under the screen', () {
    for (final skin in CrtTvSkin.values) {
      final layout = CrtSpriteLayout.of(skin);
      expect(
        layout.slot.top,
        greaterThan(layout.screen.bottom - 0.02),
        reason: skin.name,
      );
      expect(
        layout.keys.top,
        greaterThanOrEqualTo(layout.slot.bottom - 0.01),
        reason: skin.name,
      );
      expect(layout.slot.width, greaterThan(0.35), reason: skin.name);
      expect(layout.slot.height, lessThan(0.10), reason: skin.name);
    }
  });

  test('screen aperture stays centered on the glass hole', () {
    for (final skin in CrtTvSkin.values) {
      final layout = CrtSpriteLayout.of(skin);
      // Screen is a hair larger than the alpha hole but must share its center
      // so playback does not drift under the bezel.
      expect(layout.screen.center.dx, closeTo(0.5, 0.12), reason: skin.name);
      expect(
        layout.screen.center.dy,
        lessThan(layout.slot.top - 0.05),
        reason: skin.name,
      );
      expect(layout.screen.width, greaterThan(0.5), reason: skin.name);
      expect(layout.screen.height, greaterThan(0.4), reason: skin.name);
    }
  });

  test('six CRT looks are available', () {
    expect(CrtTvSkin.values, hasLength(6));
  });
}
