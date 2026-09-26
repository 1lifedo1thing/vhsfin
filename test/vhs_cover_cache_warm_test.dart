import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/model/tape.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stale miss is reused when allowNetwork is false', () async {
    const key = 'ghostbusters||1984|movie';
    final stale = jsonEncode({
      'miss': true,
      'at': DateTime.now()
          .toUtc()
          .subtract(const Duration(days: 60))
          .toIso8601String(),
    });
    SharedPreferences.setMockInitialValues({
      'vhsfin.spine_art.v10': jsonEncode({key: stale}),
    });

    final resolver = VhsCoverResolver();
    expect(
      await resolver.hasCachedLookup(
        title: 'Ghostbusters',
        year: 1984,
        kind: TapeKind.movie,
      ),
      isTrue,
    );
    expect(
      await resolver.spineArtFor(
        title: 'Ghostbusters',
        year: 1984,
        kind: TapeKind.movie,
        allowNetwork: false,
      ),
      isNull,
    );
  });

  test('cached hit returns without network', () async {
    const key = 'jaws||1975|movie';
    final hit = jsonEncode({'u': 'https://example.com/jaws.jpg', 'f': 0.09});
    SharedPreferences.setMockInitialValues({
      'vhsfin.spine_art.v10': jsonEncode({key: hit}),
    });

    final resolver = VhsCoverResolver();
    final art = await resolver.spineArtFor(
      title: 'Jaws',
      year: 1975,
      kind: TapeKind.movie,
      allowNetwork: false,
    );
    expect(art?.imageUrl, 'https://example.com/jaws.jpg');
  });
}
