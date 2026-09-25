import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/state/tape_flight_anchors.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/living_room/widgets/tape_flight_overlay.dart';

void main() {
  group('cassette pose', _poseTests);

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

void _poseTests() {
  const shelf = Rect.fromLTWH(100, 500, 28, 168);
  const slot = Rect.fromLTWH(300, 300, 240, 24);

  test('flight starts exactly on the shelf spine, standing', () {
    final p = CassettePose.at(0, shelf: shelf, slot: slot);
    expect(p.center, shelf.center);
    expect(p.stand, closeTo(math.pi / 2, 1e-9));
    expect(p.scale, closeTo(1, 1e-9));
    expect(p.depth, 0);
    expect(p.inSlot, 0);
  });

  test('flight ends level, centred in the slot, fully inside', () {
    final p = CassettePose.at(1, shelf: shelf, slot: slot);
    expect(p.center, slot.center);
    expect(p.stand, closeTo(0, 1e-9));
    expect(p.roll, closeTo(0, 1e-9));
    expect(p.inSlot, 1);
    expect(p.depth, greaterThan(0), reason: 'receding into the deck');
    expect(p.scale * CassetteGeometry.length, closeTo(slot.width * 0.94, 1e-6));
  });

  test('flight path is continuous and lifts above both ends', () {
    var previous = CassettePose.at(0, shelf: shelf, slot: slot).center;
    var highest = previous.dy;
    // A jump would be a large fraction of the trip; eased peak speed is not.
    final maxStep = (slot.center - shelf.center).distance * 0.05;
    for (var i = 1; i <= 200; i++) {
      final c = CassettePose.at(i / 200, shelf: shelf, slot: slot).center;
      expect(
        (c - previous).distance,
        lessThan(maxStep),
        reason: 't=${i / 200}',
      );
      highest = math.min(highest, c.dy);
      previous = c;
    }
    expect(highest, lessThan(slot.top));
  });
}
