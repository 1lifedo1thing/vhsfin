import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/constants/feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => DeckFeedback.player = null);

  test('each kind of press plays its own sound; mechanisms stay silent', () {
    final played = <DeckUiSound>[];
    DeckFeedback.player = played.add;
    DeckFeedback.tap();
    DeckFeedback.key();
    DeckFeedback.toggle();
    // The tape clips already carry the latch and clunk.
    DeckFeedback.latch();
    DeckFeedback.clunk();
    expect(played, [DeckUiSound.tick, DeckUiSound.key, DeckUiSound.toggle]);
  });

  test('without a player attached, presses are silent', () {
    DeckFeedback.player = null;
    expect(DeckFeedback.tap, returnsNormally);
  });
}
