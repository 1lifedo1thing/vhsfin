// The landing-page film: a tape goes from the shelf into the deck and plays.
// Record it with tool/site_film.sh; this test only performs the scene.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhsfin/features/library/state/art_onboarding.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_spine.dart';
import 'package:vhsfin/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> wait(WidgetTester tester, int ms) async {
    await Future<void>.delayed(Duration(milliseconds: ms));
    await tester.pump();
  }

  testWidgets('site film', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool(ArtOnboardingDoneNotifier.prefsKey, true);

    await app.main();
    await wait(tester, 8000);
    debugPrint('FILM tap-tape');
    final bunny = find.byWidgetPredicate(
      (w) => w is VhsSpine && w.tape.title == 'Big Buck Bunny' && !w.ghosted,
    );
    await tester.tapAt(tester.getCenter(bunny.last));
    await wait(tester, 2500);
    debugPrint('FILM insert');
    await tester.tap(find.text('INSERT TAPE'));
    await wait(tester, 40000);
    debugPrint('FILM done');
  });
}
