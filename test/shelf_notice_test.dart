import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/living_room/views/bookshelf_view.dart';

void main() {
  testWidgets('an unreachable server gets a shelf message with TRY AGAIN', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShelfNotice(
            title: 'The shelves are dark',
            message: "Can't reach your Jellyfin server.",
            actionLabel: 'TRY AGAIN',
            onAction: () => retries++,
          ),
        ),
      ),
    );
    expect(find.text('The shelves are dark'), findsOneWidget);
    expect(find.text("Can't reach your Jellyfin server."), findsOneWidget);
    await tester.tap(find.text('TRY AGAIN'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(retries, 1);
  });
}
