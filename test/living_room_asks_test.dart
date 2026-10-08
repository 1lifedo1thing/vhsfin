import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/model/shelf.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/library/state/shelf_display_prefs.dart';
import 'package:vhsfin/features/living_room/model/cabinet_style.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';
import 'package:vhsfin/features/living_room/state/tape_flight_anchors.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/living_room/views/bookshelf_view.dart';
import 'package:vhsfin/features/living_room/views/living_room_view.dart';
import 'package:vhsfin/features/living_room/widgets/deck_settings_sheet.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_spine.dart';
import 'package:vhsfin/features/playback/state/deck_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('living room: settings opens sheet; no strip / REPLAY ART GRAB', (
    tester,
  ) async {
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
          flightAnchors: TapeFlightAnchors(),
          flyingTapeId: null,
          flightSourceKey: null,
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
          onRetryShelves: () {},
          onArtOnboardingDone: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('REPLAY ART GRAB'), findsNothing);
    expect(find.text('DECK SETTINGS'), findsNothing);
    expect(find.byTooltip('PLAY'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    expect(settingsOpened, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('settings sheet: VHS controls and working CRT look selector', (
    tester,
  ) async {
    CrtTvSkin? selected;
    CabinetStyle? cabinet;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDeckSettingsSheet(
                context,
                connected: false,
                vhsOnly: true,
                vhsCollector: false,
                sortLabel: 'A–Z',
                saveTimestampOnEject: false,
                jellyfinPosters: false,
                soundEffects: true,
                onSoundEffectsChanged: (_) {},
                onJellyfinPostersChanged: (_) {},
                crtSkin: CrtTvSkin.crtIcon,
                onCollection: () {},
                onConnect: () {},
                onSignOut: () {},
                onVhsOnlyChanged: (_) {},
                onVhsCollectorChanged: (_) {},
                onOpenSort: () {},
                onSaveTimestampChanged: (_) {},
                onCrtSkinChanged: (skin) => selected = skin,
                cabinetStyle: CabinetStyle.walnut,
                onCabinetStyleChanged: (style) => cabinet = style,
                onOpenLink: (_) {},
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
    expect(find.text('SHELF'), findsOneWidget);
    await tester.tap(find.text('FLAT'));
    await tester.pump();
    expect(cabinet, CabinetStyle.flat);
    expect(find.text('TV'), findsOneWidget);
    expect(find.text('ICON'), findsOneWidget);
    expect(find.text('90S'), findsOneWidget);
    expect(find.text('GRAPHITE'), findsNothing);
    await tester.ensureVisible(find.text('CRIMSON'));
    await tester.tap(find.text('CRIMSON'));
    await tester.pump();
    expect(selected, CrtTvSkin.crimson);
    expect(find.text('REPLAY ART GRAB'), findsNothing);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text('SETTINGS'), findsNothing);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('SETTINGS'), findsNothing, reason: 'Escape closes');
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

  testWidgets('shelves stay a compact loader until their art is warm', (
    tester,
  ) async {
    final art = Completer<VhsSpineArt?>();
    final tapes = [
      for (var i = 0; i < 40; i++)
        Tape(id: 'movie$i', title: 'Movie $i', streamUrl: 'stream'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BookshelfView(
              shelves: [Shelf(id: 'movies', title: 'Movies', items: tapes)],
              loadedId: null,
              loadedSeriesId: null,
              vhsOnly: false,
              flightAnchors: TapeFlightAnchors(),
              flyingTapeId: null,
              flightSourceKey: null,
              resolveSpineArt: (_) => art.future,
              onTapeTap: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ShelfLoadingBox), findsOneWidget);
    expect(find.byType(VhsSpine), findsNothing, reason: 'no tall empty bays');
    expect(tester.getSize(find.byType(BookshelfView)).height, 180);

    art.complete(null);
    await tester.pump();
    // Let the crossfade finish; the spinner never settles on its own.
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ShelfLoadingBox), findsNothing);
    expect(find.byType(VhsSpine), findsWidgets);
  });

  test('ShelfDisplayPrefs defaults vhsOnly ON for new installs', () {
    expect(const ShelfDisplayPrefs().vhsOnly, isTrue);
  });

  test('ShelfDisplayPrefs keeps VHSCollector lookups off by default', () {
    expect(const ShelfDisplayPrefs().vhsCollector, isFalse);
  });

  test('TV picker offers six labeled skins', () {
    expect(selectableCrtTvSkins, hasLength(6));
    for (final skin in selectableCrtTvSkins) {
      expect(skin.settingsLabel, isNotEmpty);
    }
  });
}
