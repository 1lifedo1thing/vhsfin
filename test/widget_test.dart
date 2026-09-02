import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/main.dart';

void main() {
  testWidgets('VHSFin brand appears on living room', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VhsFinApp()));
    await tester.pump();
    expect(find.text('VHSFIN'), findsWidgets);
  });
}
