import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/library/views/libraries_view.dart';

void main() {
  testWidgets('system back on the shelves goes up a folder with a tick', (
    tester,
  ) async {
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    var backs = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: LibrariesView(
          connected: true,
          heading: 'MOVIES',
          breadcrumb: const ['Movies'],
          selected: const [],
          childrenLoading: false,
          children: const [],
          onBack: () => backs++,
          onDone: () {},
          onOpenRoot: () {},
          onCrumbTap: (_) {},
          onRemoveSource: (_) {},
          onToggleNode: (_) {},
          onOpenNode: (_) {},
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(backs, 1);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });
}
