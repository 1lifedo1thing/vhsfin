import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/library/model/shelf.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/library/state/shelf_display_prefs.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/living_room/views/bookshelf_view.dart';
import 'package:vhsfin/features/living_room/views/living_room_view.dart';
import 'package:vhsfin/features/living_room/widgets/deck_settings_sheet.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_spine.dart';
import 'package:vhsfin/features/living_room/state/tape_flight_anchors.dart';
import 'package:vhsfin/features/playback/state/deck_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'living room: settings FAB opens sheet; no strip / REPLAY ART GRAB',
    (tester) async {
      var settingsOpened = false;
      final player = DeckPlayerController();
      addTearDown(player.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: LivingRoomView(
            deck: const VcrDeckState(),
            player: player,
            surfaceEpoch: 0,
            surfaceOwner: DeckSurfaceOwner.crt,
            crtSkin: CrtTvSkin.zenith,
            flightAnchors: TapeFlightAnchors(),
            flyingTapeId: null,
            flightSourceKey: null,
            slotArt: null,
            shelvesLoading: false,
            shelves: const [],
            vhsOnly: true,
            rewinding: false,
            onRew: () {},
            onRewEnd: () {},
            onPlay: () {},
            onFf: () {},
            onFfEnd: () {},
            onEject: () {},
            resolveSpineArt: (_) async => null,
            onTapeTap: (tape, key) {},
            onFlyingTapeIdChanged: (_) {},
            artForFlight: (_) => null,
            onShowRemote: () {},
            onShowSettings: () => settingsOpened = true,
            onConnectPrompt: () {},
            onArtOnboardingDone: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('REPLAY ART GRAB'), findsNothing);
      expect(find.text('DECK SETTINGS'), findsNothing);
      expect(find.text('PLAY/PAUSE'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);

      await tester.tap(find.byTooltip('Settings'));
      await tester.pump();
      expect(settingsOpened, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('settings sheet: VHS only + CRT skins; no REPLAY ART GRAB', (
    tester,
  ) async {
    CrtTvSkin? chosen;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDeckSettingsSheet(
                context,
                connected: false,
                vhsOnly: true,
                sortLabel: 'A–Z',
                saveTimestampOnEject: false,
                crtSkin: CrtTvSkin.zenith,
                onCollection: () {},
                onConnect: () {},
                onSignOut: () {},
                onVhsOnlyChanged: (_) {},
                onOpenSort: () {},
                onSaveTimestampChanged: (_) {},
                onCrtSkinChanged: (s) => chosen = s,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('VHS ONLY'), findsOneWidget);
    expect(find.text('Only titles with scanned VHS artwork.'), findsOneWidget);
    expect(
      find.text('Keeps your place. Rewinding is still on you.'),
      findsOneWidget,
    );
    expect(find.text('CRT LOOK'), findsOneWidget);
    expect(find.text('ZENITH'), findsOneWidget);
    expect(find.text('WEGA'), findsOneWidget);
    expect(find.text('TUBE'), findsOneWidget);
    expect(find.text('AQUA'), findsOneWidget);
    expect(find.text('REPLAY ART GRAB'), findsNothing);

    await tester.tap(find.text('AQUA'));
    await tester.pump();
    expect(chosen, CrtTvSkin.aquaGraphite);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('loaded tape stays absent from its shelf', (tester) async {
    const tape = Tape(id: 'movie', title: 'Movie', streamUrl: 'stream');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookshelfView(
            shelves: const [
              Shelf(id: 'movies', title: 'Movies', items: [tape]),
            ],
            loadedId: tape.id,
            loadedSeriesId: null,
            vhsOnly: false,
            flightAnchors: TapeFlightAnchors(),
            flyingTapeId: null,
            flightSourceKey: null,
            resolveSpineArt: (_) async => null,
            onTapeTap: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pump();

    final spine = tester.widget<VhsSpine>(find.byType(VhsSpine));
    expect(spine.ghosted, isTrue);
    expect(spine.selected, isFalse);
  });

  test('ShelfDisplayPrefs defaults vhsOnly ON for new installs', () {
    expect(const ShelfDisplayPrefs().vhsOnly, isTrue);
  });

  test('all CRT skins are selectable labels', () {
    expect(CrtTvSkin.values.length, greaterThanOrEqualTo(4));
    for (final skin in CrtTvSkin.values) {
      expect(skin.settingsLabel, isNotEmpty);
    }
  });
}
