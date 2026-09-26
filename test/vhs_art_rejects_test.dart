import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/library/state/vhs_art_rejects.dart';

void main() {
  test('normalizeArtUrl keeps Jellyfin box tag and drops volatile params', () {
    final normalized = normalizeArtUrl(
      'http://jellyfin/Items/abc/Images/Box?tag=deadbeef&maxHeight=900&api_key=secret',
    );
    expect(normalized, contains('tag=deadbeef'));
    expect(normalized, isNot(contains('api_key')));
    expect(normalized, isNot(contains('maxHeight')));
  });

  test('fromJson treats legacy records as suppressArt', () {
    final rejection = VhsArtRejection.fromJson({
      'id': 'tape-1',
      'urls': ['https://vhscollector.com/sites/x.jpg'],
      'boxTag': 'abc',
    });
    expect(rejection.suppressArt, isTrue);
    expect(rejection.tapeId, 'tape-1');
    expect(rejection.ignoredBoxTag, 'abc');
  });

  test('shouldSuppressArt stays true after reject even when URLs differ', () {
    // Pure logic stand-in: a rejection with suppressArt means any alternate
    // collector/Box URL must not bring the sleeve back for this tape.
    const rejection = VhsArtRejection(
      tapeId: 'tape-1',
      blockedUrls: {'http://jellyfin/Items/1/Images/Box?tag=old'},
      ignoredBoxTag: 'old',
    );
    expect(rejection.suppressArt, isTrue);
    expect(
      rejection.blockedUrls.contains(
        normalizeArtUrl(
          'http://jellyfin/Items/1/Images/Box?tag=old&maxHeight=900',
        ),
      ),
      isTrue,
    );
  });
}
