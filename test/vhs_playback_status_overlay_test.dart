import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_playback_status_overlay.dart';

void main() {
  late StreamController<bool> playing;
  late StreamController<bool> buffering;
  late StreamController<Duration> position;
  late StreamController<String> errors;

  setUp(() {
    playing = StreamController<bool>.broadcast(sync: true);
    buffering = StreamController<bool>.broadcast(sync: true);
    position = StreamController<Duration>.broadcast(sync: true);
    errors = StreamController<String>.broadcast(sync: true);
  });

  tearDown(() async {
    await playing.close();
    await buffering.close();
    await position.close();
    await errors.close();
  });

  testWidgets('shows tracking after a stalled start and clears on progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      _StatusHarness(
        playing: playing.stream,
        buffering: buffering.stream,
        position: position.stream,
        errors: errors.stream,
      ),
    );

    expect(find.text('ADJUSTING TRACKING'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('ADJUSTING TRACKING'), findsOneWidget);

    buffering.add(false);
    position.add(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('ADJUSTING TRACKING'), findsNothing);
  });

  testWidgets('shows tape error and retries playback', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _StatusHarness(
        playing: playing.stream,
        buffering: buffering.stream,
        position: position.stream,
        errors: errors.stream,
        onRetry: () async => retries++,
      ),
    );

    errors.add('HTTP 503');
    await tester.pump();

    expect(find.text('TAPE READ ERROR'), findsOneWidget);
    expect(find.textContaining('HTTP 503'), findsNothing);

    await tester.tap(find.text('RE-TRACK'));
    await tester.pump();

    expect(retries, 1);
    expect(find.text('ADJUSTING TRACKING'), findsOneWidget);
  });
}

class _StatusHarness extends StatelessWidget {
  const _StatusHarness({
    required this.playing,
    required this.buffering,
    required this.position,
    required this.errors,
    this.onRetry,
  });

  final Stream<bool> playing;
  final Stream<bool> buffering;
  final Stream<Duration> position;
  final Stream<String> errors;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          height: 240,
          child: VhsPlaybackStatusOverlay(
            playing: playing,
            buffering: buffering,
            position: position,
            errors: errors,
            initialPlaying: true,
            initialBuffering: true,
            initialPosition: Duration.zero,
            initialError: null,
            trackingDelay: const Duration(seconds: 1),
            onRetry: onRetry ?? () async {},
          ),
        ),
      ),
    );
  }
}
