import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/living_room/widgets/deck_panel.dart';

void main() {
  testWidgets('press shows the moment the pointer lands; the tap is felt', (
    tester,
  ) async {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
    var pressedSeen = false;
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          // Inside a scrollable, where tap recognizers wait 100ms.
          children: [
            DeckPressable(
              onTap: () => taps++,
              builder: (context, pressed) {
                if (pressed) pressedSeen = true;
                return const SizedBox(width: 100, height: 60);
              },
            ),
          ],
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(DeckPressable)),
    );
    await tester.pump(); // one frame, no waiting
    expect(pressedSeen, isTrue);
    expect(haptics, isEmpty, reason: 'a press might still become a scroll');
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(taps, 1);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  testWidgets('a scroll that starts on a control is silent and inert', (
    tester,
  ) async {
    var felt = 0;
    var taps = 0;
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          children: [
            DeckPressable(
              onTap: () => taps++,
              haptic: () => felt++,
              builder: (context, down) {
                pressed = down;
                return const SizedBox(height: 80);
              },
            ),
            const SizedBox(height: 2000),
          ],
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(DeckPressable)),
    );
    await tester.pump();
    expect(pressed, isTrue);
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    expect(pressed, isFalse, reason: 'lets go as soon as it scrolls');
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));
    expect((felt, taps), (0, 0));
  });

  testWidgets('held keys start on press and end on release, once each', (
    tester,
  ) async {
    var starts = 0;
    var ends = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: DeckPressable(
            onTap: () {},
            onPressStart: () => starts++,
            onPressEnd: () => ends++,
            builder: (context, pressed) =>
                const SizedBox(width: 80, height: 80),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(DeckPressable)),
    );
    expect((starts, ends), (1, 0));
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect((starts, ends), (1, 1));
  });

  testWidgets('a disabled hardware key neither presses nor fires', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: DeckHardKey(label: 'EJECT', onPressed: null)),
      ),
    );
    await tester.tap(find.text('EJECT'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
