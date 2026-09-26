import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/model/tape.dart';

void main() {
  group('VhsCoverResolver.lookupIdentity', () {
    test('movies pass through', () {
      final id = VhsCoverResolver.lookupIdentity(title: 'Jumanji', year: 1995);
      expect(id.title, 'Jumanji');
      expect(id.year, 1995);
      expect(id.kind, TapeKind.movie);
      expect(id.seriesTitle, isNull);
    });

    test('episodes remap to season title', () {
      final id = VhsCoverResolver.lookupIdentity(
        title: 'The One with the Blackout',
        year: 1994,
        seriesTitle: 'Friends',
        seasonNumber: 1,
        kind: TapeKind.episode,
      );
      expect(id.title, 'Season 1');
      expect(id.seriesTitle, 'Friends');
      expect(id.year, isNull);
      expect(id.kind, TapeKind.series);
    });

    test('episodes without season fall back to show title', () {
      final id = VhsCoverResolver.lookupIdentity(
        title: 'Pilot',
        year: 1994,
        seriesTitle: 'Friends',
        kind: TapeKind.episode,
      );
      expect(id.title, 'Friends');
      expect(id.seriesTitle, isNull);
      expect(id.kind, TapeKind.series);
    });

    test('series boxes pass through', () {
      final id = VhsCoverResolver.lookupIdentity(
        title: 'Arthur',
        year: 1996,
        kind: TapeKind.series,
      );
      expect(id.title, 'Arthur');
      expect(id.kind, TapeKind.series);
    });
  });
}
