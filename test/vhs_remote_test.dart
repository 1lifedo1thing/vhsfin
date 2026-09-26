import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_remote.dart';

void main() {
  testWidgets('the remote PLAY key becomes PAUSE while the tape runs', (
    tester,
  ) async {
    final playing = StreamController<bool>.broadcast();
    addTearDown(playing.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showVhsRemote(
              context,
              title: 'Sintel',
              live: true,
              powered: true,
              playing: playing.stream,
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
    expect(find.text('PLAY'), findsWidgets);
    expect(find.text('PAUSE'), findsWidgets, reason: 'display readout');

    playing.add(true);
    await tester.pump();
    await tester.pump();
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);

    playing.add(false);
    await tester.pump();
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });
}
