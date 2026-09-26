import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/widgets/tape_inspect_sheet.dart';

void main() {
  testWidgets('the tape sheet close X sits on the content right edge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showTapeInspectSheet(
              context,
              tape: const Tape(
                id: 'a',
                title: 'Big Buck Bunny',
                streamUrl: '',
                overview: 'A gentle giant rabbit.',
                productionYear: 2008,
              ),
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

    final close = tester.getRect(find.bySemanticsLabel('Close'));
    final insert = tester.getRect(
      find
          .ancestor(
            of: find.text('INSERT TAPE'),
            matching: find.byType(Container),
          )
          .last,
    );
    // Both the X and the INSERT key end on the body's right inset.
    expect(close.right, closeTo(insert.right, 0.5));
  });
}
