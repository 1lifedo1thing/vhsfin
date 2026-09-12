import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/main.dart';

void main() {
  testWidgets('living room chrome appears', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VhsFinApp()));
    await tester.pump();
    expect(find.text('HOME VIDEO'), findsOneWidget);
    // Tear down so shelf-art warm timers are cancelled before the binding
    // checks for pending timers.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
