import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/constants/feedback.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/widgets/tape_inspect_sheet.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_remote.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => DeckFeedback.player = null);

  test('each kind of control has its own sound', () {
    final played = <DeckUiSound>[];
    DeckFeedback.player = played.add;
    DeckFeedback.tap(); // icons, close, menus, rows
    DeckFeedback.check(); // checkboxes
    DeckFeedback.select(); // shelf / TV / sort choices
    DeckFeedback.pick(); // pulling a tape: felt only
    DeckFeedback.key(); // hardware keys
    DeckFeedback.toggle(); // switches
    DeckFeedback.latch(); // tape mechanism: its clip carries the sound
    DeckFeedback.clunk();
    expect(played, [
      DeckUiSound.tick,
      DeckUiSound.tick,
      DeckUiSound.select,
      DeckUiSound.key,
      DeckUiSound.toggle,
    ]);
  });

  test('a sheet whooshes up on open and down once it is gone', () async {
    final played = <DeckUiSound>[];
    DeckFeedback.player = played.add;
    await DeckFeedback.sheet<void>(() async {
      expect(played, [DeckUiSound.sheetUp], reason: 'up before it shows');
    });
    expect(played, [DeckUiSound.sheetUp, DeckUiSound.sheetDown]);
  });

  testWidgets('INSERT TAPE clicks the moment it goes down', (tester) async {
    final played = <DeckUiSound>[];
    DeckFeedback.player = played.add;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showTapeInspectSheet(
              context,
              tape: const Tape(id: 'a', title: 'Sintel', streamUrl: ''),
              onInsert: () {},
              onRejectSleeve: () async {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    played.clear();
    final press = await tester.startGesture(
      tester.getCenter(find.text('INSERT TAPE')),
    );
    await tester.pump();
    expect(played, [DeckUiSound.key], reason: 'before the finger lifts');
    await press.up();
    await tester.pumpAndSettle();
  });

  testWidgets('the remote rises from the bottom edge with no gap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showVhsRemote(
              context,
              title: null,
              live: false,
              powered: false,
              onRewStart: () {},
              onRewEnd: () {},
              onPlay: () {},
              onFfStart: () {},
              onFfEnd: () {},
              onFullScreen: () {},
              onEject: () {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final remote = tester.getRect(find.byType(VhsRemoteSheet));
    expect(remote.bottom, 800);
    final panel = find.descendant(
      of: find.byType(VhsRemoteSheet),
      matching: find.byType(ClipRRect),
    );
    expect(tester.getRect(panel.first).bottom, 800);
  });
}
