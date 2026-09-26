import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/library/state/art_onboarding.dart';
import 'package:vhsfin/features/library/widgets/art_grab_onboarding_dialog.dart';

void main() {
  testWidgets('running art grab can continue in the background', (
    tester,
  ) async {
    var dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArtGrabOnboardingDialog(
            progress: const ArtWarmProgress(
              phase: ArtWarmPhase.running,
              completed: 136,
              total: 255,
              foundCount: 66,
            ),
            onDone: () => dismissed = true,
          ),
        ),
      ),
    );

    expect(find.text('136 / 255 · 66 found'), findsOneWidget);
    await tester.tap(find.text('CONTINUE IN BACKGROUND'));
    expect(dismissed, isTrue);
  });
}
