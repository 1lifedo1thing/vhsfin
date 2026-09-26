import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/constants/feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => DeckFeedback.player = null);

  test('keys and switches sound; taps and mechanisms are felt only', () {
    final played = <DeckUiSound>[];
    DeckFeedback.player = played.add;
    DeckFeedback.tap();
    DeckFeedback.key();
    DeckFeedback.toggle();
    // The tape clips already carry the latch and clunk.
    DeckFeedback.latch();
    DeckFeedback.clunk();
    expect(played, [DeckUiSound.key, DeckUiSound.toggle]);
  });

  test('a sheet whooshes up on open and down once it is gone', () async {
    final played = <DeckUiSound>[];
    DeckFeedback.player = played.add;
    final closed = DeckFeedback.sheet<void>(() async {
      expect(played, [DeckUiSound.sheetUp], reason: 'up before it shows');
    });
    await closed;
    expect(played, [DeckUiSound.sheetUp, DeckUiSound.sheetDown]);
  });

  test('without a player attached, presses are silent', () {
    DeckFeedback.player = null;
    expect(DeckFeedback.key, returnsNormally);
  });
}
