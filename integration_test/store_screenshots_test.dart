// Store screenshots from the open-movie demo shelf (no server, no cover art).
// Run with tool/store_screenshots.sh, which captures each scene on the host.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhsfin/features/library/state/art_onboarding.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_spine.dart';
import 'package:vhsfin/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    // Draw every frame like a real device, so animations and reveals finish.
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> wait(WidgetTester tester, int ms) async {
    await Future<void>.delayed(Duration(milliseconds: ms));
    await tester.pump();
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await wait(tester, 1500);
    await binding.takeScreenshot(name);
  }

  Future<void> closeSheet(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Close').last);
    await wait(tester, 1200);
  }

  testWidgets('store screenshots', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool(ArtOnboardingDoneNotifier.prefsKey, true);
    // Oldest first puts Big Buck Bunny second, so taking it leaves a gap
    // mid-shelf rather than an empty far left.
    await prefs.setString('vhsfin.shelf_sort', 'yearOldest');

    await app.main();
    await wait(tester, 5000);
    await shot(tester, '01-living-room');

    final bunny = find.byWidgetPredicate(
      (w) =>
          w is VhsSpine &&
          w.tape.title == 'Big Buck Bunny' &&
          w.onTap != null &&
          !w.ghosted,
    );
    final c = tester.getCenter(bunny.last);
    await tester.tapAt(c);
    await wait(tester, 2500);
    await shot(tester, '02-tape');

    await tester.tap(find.text('INSERT TAPE'));
    await wait(tester, 20000);
    await shot(tester, '03-playing');

    await tester.tap(find.byTooltip('Remote'));
    await wait(tester, 1500);
    await shot(tester, '04-remote');
    await closeSheet(tester);

    await tester.tap(find.byTooltip('Settings'));
    await wait(tester, 1500);
    await shot(tester, '05-settings');
    await closeSheet(tester);

    await tester.tap(find.byTooltip('Settings'));
    await wait(tester, 1500);
    await tester.drag(find.text('OPTIONS'), const Offset(0, -900));
    await wait(tester, 800);
    await tester.tap(find.text('SIGN IN'));
    await wait(tester, 2500);
    FocusManager.instance.primaryFocus?.unfocus();
    await shot(tester, '06-connect');
  });
}
