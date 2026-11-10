import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vhsfin/features/library/data/sleeve_downscale.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/state/sleeve_shrink.dart';

Map<String, dynamic> _file(String name, int size, {String? format}) => {
  'name': name,
  'size': '$size',
  'format': ?format,
  'source': 'original',
};

String? _pick(List<Map<String, dynamic>> files) =>
    VhsCoverResolver.pickScanFile(files)?.name;

/// Random pixels, so the encoders can't compress the size away.
img.Image _noise(int width, int height, {bool transparent = false}) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  var seed = 7;
  for (final p in image) {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    p
      ..r = seed & 0xFF
      ..g = (seed >> 8) & 0xFF
      ..b = (seed >> 16) & 0xFF
      ..a = transparent ? 0x80 : 0xFF;
  }
  return image;
}

Future<(int, int)> _size(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = (await codec.getNextFrame()).image;
  return (frame.width, frame.height);
}

void main() {
  group('archive scan pick', () {
    test('takes the smallest copy of the largest scan', () {
      // atlantis-lost-empire-greek-vhs-cover, trimmed.
      final files = [
        _file('9. cover out 600.png', 62802573, format: 'PNG'),
        _file('1. cover out 300.png', 17435821, format: 'PNG'),
        _file('21. cover out 600.jpg', 10636005, format: 'JPEG'),
        _file('15. cover out 300.jpg', 3078139, format: 'JPEG'),
        _file('15. cover out 300.tif', 27753306, format: 'TIFF'),
        _file('15. cover out 300_thumb.jpg', 17982, format: 'JPEG Thumb'),
        _file('24. leaflet in 600.jpg', 7362510, format: 'JPEG'),
        _file('16. cover in 300.jpg', 1729443, format: 'JPEG'),
      ];
      expect(_pick(files), '15. cover out 300.jpg');
    });

    test('size words mark copies of one scan', () {
      // goodtimes-beauty-greek-vhs-cover.
      final files = [
        _file('1. Η πεντάμορφη και το τέρας small.png', 31695164),
        _file('2. Η πεντάμορφη και το τέρας.png', 225869015),
      ];
      expect(_pick(files), '1. Η πεντάμορφη και το τέρας small.png');
    });

    test('numbered pages are different scans', () {
      final files = [
        _file('scan 001.jpg', 4000000),
        _file('scan 002.jpg', 2000000),
      ];
      expect(_pick(files), 'scan 001.jpg');
    });

    test('previews never stand in for the scan', () {
      final files = [
        _file('cover 600.jpg', 9000000),
        _file('cover 72.jpg', 90000),
      ];
      expect(_pick(files), 'cover 600.jpg');
    });

    test('nothing under 50 MB skips the item', () {
      expect(_pick([_file('cover.png', 225869015)]), isNull);
    });

    test('stems drop index, dpi, size word and extension', () {
      expect(VhsCoverResolver.scanStem('9. cover out 600.png'), 'cover out');
      expect(VhsCoverResolver.scanStem('cover_300dpi.jpg'), 'cover');
      expect(VhsCoverResolver.scanStem('Box hi-res.JPG'), 'box');
      expect(VhsCoverResolver.scanStem('scan 001.jpg'), 'scan 001');
    });
  });

  group('oversized server sleeves', () {
    bool over(int width, int height, int bytes, {bool png = false}) =>
        SleeveShrinker.isOversized(
          width: width,
          height: height,
          bytes: bytes,
          png: png,
        );

    test('full-resolution scans', () {
      expect(over(6028, 4600, 62802573, png: true), isTrue);
      expect(over(3459, 2495, 13500000), isTrue);
      expect(over(2600, 1900, 1500000), isTrue);
    });

    test('already small', () {
      expect(over(2097, 1600, 1795321), isFalse);
      expect(over(2035, 1498, 2700000), isFalse);
    });

    test('thin spine strips over the height cap', () {
      expect(over(221, 1780, 51711), isFalse);
    });

    test('PNGs, which Jellyfin serves back as PNG', () {
      expect(over(993, 743, 1213193, png: true), isTrue);
      expect(over(300, 200, 90000, png: true), isFalse);
    });
  });

  group('downscaleSleeve', () {
    testWidgets('caps a large scan at 1600 px as JPEG', (tester) async {
      await tester.runAsync(() async {
        final png = img.encodePng(_noise(2400, 1800));
        final out = (await downscaleSleeve(png))!;
        expect(out.sublist(0, 2), [0xFF, 0xD8]);
        expect(await _size(out), (2133, 1600));
      });
    });

    testWidgets('converts a small PNG to JPEG', (tester) async {
      await tester.runAsync(() async {
        final png = img.encodePng(_noise(400, 300));
        final out = (await downscaleSleeve(png))!;
        expect(out.sublist(0, 2), [0xFF, 0xD8]);
        expect(await _size(out), (400, 300));
      });
    });

    testWidgets('keeps a JPEG already within bounds', (tester) async {
      await tester.runAsync(() async {
        final jpeg = img.encodeJpg(_noise(400, 300));
        expect(await downscaleSleeve(jpeg), same(jpeg));
      });
    });

    testWidgets('leaves transparent images alone', (tester) async {
      await tester.runAsync(() async {
        final png = img.encodePng(_noise(400, 300, transparent: true));
        expect(await downscaleSleeve(png), isNull);
      });
    });
  });
}
