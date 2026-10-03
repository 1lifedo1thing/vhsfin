import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/library/data/vhs_image_cache.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/library/state/vhs_spine_art.dart';

void main() {
  test('every demo tape has a bundled spine and front cover', () {
    for (final tape in demoTapes) {
      final art = demoSleeveArt(tape);
      expect(art, isNotNull, reason: tape.title);
      expect(art!.centerWidthFraction, 1, reason: 'dedicated spine');
      for (final url in [art.imageUrl, art.frontImageUrl!]) {
        expect(url, startsWith(VhsImageCache.assetScheme));
        final path = url.substring(VhsImageCache.assetScheme.length);
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    }
  });

  test('library tapes get no demo sleeve', () {
    const tape = Tape(id: 'abc123', title: 'Jaws', streamUrl: '');
    expect(demoSleeveArt(tape), isNull);
  });
}
