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

    expect(find.text('TAPE READ ERROR'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('TAPE READ ERROR'), findsOneWidget);
    expect(find.textContaining('HTTP 503'), findsNothing);

    await tester.tap(find.text('RE-TRACK'));
    await tester.pump();

    expect(retries, 1);
    expect(find.text('ADJUSTING TRACKING'), findsOneWidget);
  });

  testWidgets(
    'pausing does not report a stalled signal; resume still detects stalls',
    (tester) async {
      await tester.pumpWidget(
        _StatusHarness(
          playing: playing.stream,
          buffering: buffering.stream,
          position: position.stream,
          errors: errors.stream,
          initialBuffering: false,
        ),
      );
      position.add(const Duration(seconds: 1));
      buffering.add(true);
      playing.add(false);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('ADJUSTING TRACKING'), findsNothing);

      playing.add(true);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('ADJUSTING TRACKING'), findsOneWidget);
      buffering.add(false);
      position.add(const Duration(seconds: 2));
      await tester.pump();
      expect(find.text('ADJUSTING TRACKING'), findsNothing);
    },
  );

  testWidgets('recognizes replay progress after position resets', (
    tester,
  ) async {
    await tester.pumpWidget(
      _StatusHarness(
        playing: playing.stream,
        buffering: buffering.stream,
        position: position.stream,
        errors: errors.stream,
        initialBuffering: false,
        initialPosition: const Duration(minutes: 10),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('ADJUSTING TRACKING'), findsOneWidget);

    position.add(const Duration(minutes: 5));
    await tester.pump();
    expect(find.text('ADJUSTING TRACKING'), findsOneWidget);

    position.add(
      const Duration(minutes: 5) + const Duration(milliseconds: 500),
    );
    await tester.pump();
    expect(find.text('ADJUSTING TRACKING'), findsNothing);
  });

  testWidgets('small CRT error stays scrollable with large text', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      _StatusHarness(
        playing: playing.stream,
        buffering: buffering.stream,
        position: position.stream,
        errors: errors.stream,
        size: const Size(220, 150),
        textScale: 2,
        onRetry: () async => retries++,
      ),
    );
    errors.add('failed');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('RE-TRACK'));
    await tester.tap(find.text('RE-TRACK'));
    await tester.pump();
    expect(retries, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not show a transient error when playback advances', (
    tester,
  ) async {
    var recoveries = 0;
    await tester.pumpWidget(
      _StatusHarness(
        playing: playing.stream,
        buffering: buffering.stream,
        position: position.stream,
        errors: errors.stream,
        initialBuffering: false,
        initialError: 'recoverable preload error',
        onRecovered: () => recoveries++,
      ),
    );

    position.add(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('TAPE READ ERROR'), findsNothing);
    expect(recoveries, 1);
  });
}

class _StatusHarness extends StatelessWidget {
  const _StatusHarness({
    required this.playing,
    required this.buffering,
    required this.position,
    required this.errors,
    this.initialBuffering = true,
    this.initialPosition = Duration.zero,
    this.initialError,
    this.onRetry,
    this.onRecovered,
    this.size = const Size(320, 240),
    this.textScale = 1,
  });

  final Stream<bool> playing;
  final Stream<bool> buffering;
  final Stream<Duration> position;
  final Stream<String> errors;
  final bool initialBuffering;
  final Duration initialPosition;
  final String? initialError;
  final Future<void> Function()? onRetry;
  final VoidCallback? onRecovered;
  final Size size;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: VhsPlaybackStatusOverlay(
            playing: playing,
            buffering: buffering,
            position: position,
            errors: errors,
            initialPlaying: true,
            initialBuffering: initialBuffering,
            initialPosition: initialPosition,
            initialError: initialError,
            trackingDelay: const Duration(seconds: 1),
            onRetry: onRetry ?? () async {},
            onRecovered: onRecovered ?? () {},
          ),
        ),
      ),
    );
  }
}
