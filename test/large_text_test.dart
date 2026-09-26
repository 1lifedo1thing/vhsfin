import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/library/state/shelf_display_prefs.dart';
import 'package:vhsfin/features/living_room/model/cabinet_style.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';
import 'package:vhsfin/features/living_room/widgets/deck_settings_sheet.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_remote.dart';

/// Sheets must lay out without overflow on a small phone at 2× text.
void main() {
  Widget host(void Function(BuildContext) open) => MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(2)),
      child: child!,
    ),
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => open(context),
          child: const Text('open'),
        ),
      ),
    ),
  );

  Future<void> openOn(
    WidgetTester tester,
    void Function(BuildContext) open,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(open));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('settings', (tester) async {
    await openOn(
      tester,
      (context) => showDeckSettingsSheet(
        context,
        connected: true,
        userName: 'A long account name',
        vhsOnly: true,
        sortLabel: 'YEAR ↓',
        saveTimestampOnEject: false,
        vhsCovers: true,
        soundEffects: true,
        onSoundEffectsChanged: (_) {},
        onVhsCoversChanged: (_) {},
        crtSkin: CrtTvSkin.crtIcon,
        cabinetStyle: CabinetStyle.walnut,
        onCabinetStyleChanged: (_) {},
        onCollection: () {},
        onConnect: () {},
        onSignOut: () {},
        onVhsOnlyChanged: (_) {},
        onOpenSort: () {},
        onSaveTimestampChanged: (_) {},
        onCrtSkinChanged: (_) {},
      ),
    );
    await tester.drag(find.text('OPTIONS'), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('sort', (tester) async {
    await openOn(
      tester,
      (context) => showShelfSortSheet(
        context,
        current: ShelfSortMode.titleAsc,
        onSelect: (_) {},
      ),
    );
  });

  testWidgets('remote', (tester) async {
    await openOn(
      tester,
      (context) => showVhsRemote(
        context,
        title: 'A very long tape title that will not fit',
        live: true,
        powered: true,
        onRewStart: () {},
        onRewEnd: () {},
        onPlay: () {},
        onFfStart: () {},
        onFfEnd: () {},
        onFullScreen: () {},
        onEject: () {},
      ),
    );
  });
}
