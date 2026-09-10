import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/state/tape_flight_anchors.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/living_room/widgets/tape_flight_overlay.dart';

void main() {
  testWidgets('starting tape flight defers provider write until after build', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    const tape = Tape(id: 'movie', title: 'Movie', streamUrl: 'stream');

    Widget app(VcrDeckState deck) {
      return UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: TapeFlightOverlay(
              deck: deck,
              anchors: TapeFlightAnchors(),
              flightSourceKey: null,
              onFlyingTapeIdChanged: (id) {
                container.read(flyingTapeIdProvider.notifier).set(id);
              },
              artFor: (_) => null,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(app(const VcrDeckState()));
    await tester.pumpWidget(
      app(const VcrDeckState(power: VcrPower.inserting, loadedTape: tape)),
    );

    expect(tester.takeException(), isNull);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(container.read(flyingTapeIdProvider), tape.id);
    expect(find.byType(Opacity), findsNothing);

    await tester.pumpWidget(
      app(const VcrDeckState(power: VcrPower.playing, loadedTape: tape)),
    );
    await tester.pump();
    await tester.pump();
    expect(container.read(flyingTapeIdProvider), isNull);

    await tester.pumpWidget(
      app(const VcrDeckState(power: VcrPower.ejecting, loadedTape: tape)),
    );
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(container.read(flyingTapeIdProvider), tape.id);

    await tester.pumpWidget(app(const VcrDeckState()));
    await tester.pump();
    await tester.pump();

    expect(container.read(flyingTapeIdProvider), isNull);
    expect(tester.takeException(), isNull);
  });
}
