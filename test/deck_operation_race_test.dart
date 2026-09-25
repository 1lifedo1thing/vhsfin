import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/state/deck_sfx.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';

class _SilentSfx implements DeckSfx {
  @override
  Future<void> playInsert() async {}
  @override
  Future<void> playEject() async {}
  @override
  Future<void> stopShuttle() async {}
  @override
  Future<void> startFastForward() async {}
  @override
  Future<void> startRewind() async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const first = Tape(id: 'one', title: 'One', streamUrl: '');
  const second = Tape(id: 'two', title: 'Two', streamUrl: '');

  testWidgets(
    'eject during insertion cannot be overwritten by insert completion',
    (tester) async {
      final container = ProviderContainer(
        overrides: [deckSfxProvider.overrideWithValue(_SilentSfx())],
      );
      addTearDown(container.dispose);
      final deck = container.read(vcrDeckProvider.notifier);
      final insertion = deck.insertTape(first);
      await tester.pump();
      final ejection = deck.eject();
      await tester.pump(DeckTiming.insertFlight);
      expect(container.read(vcrDeckProvider).power, VcrPower.ejecting);
      await tester.pump(DeckTiming.ejectMechanism + DeckTiming.ejectFlight);
      await insertion;
      await ejection;
      expect(container.read(vcrDeckProvider).power, VcrPower.off);
      expect(container.read(vcrDeckProvider).loadedTape, isNull);
    },
  );

  testWidgets('old eject completion cannot remove a newly inserted tape', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [deckSfxProvider.overrideWithValue(_SilentSfx())],
    );
    addTearDown(container.dispose);
    final deck = container.read(vcrDeckProvider.notifier);
    deck.playCleanFullscreen(first);
    final ejection = deck.eject();
    await tester.pump(DeckTiming.ejectMechanism);
    final insertion = deck.insertTape(second);
    await tester.pump();
    await tester.pump(DeckTiming.ejectFlight);
    await ejection;
    expect(container.read(vcrDeckProvider).loadedTape?.id, 'two');
    expect(container.read(vcrDeckProvider).power, VcrPower.inserting);
    await tester.pump(DeckTiming.insertFlight);
    await insertion;
    expect(container.read(vcrDeckProvider).power, VcrPower.playing);
    expect(container.read(vcrDeckProvider).loadedTape?.id, 'two');
  });
}
