import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/living_room/widgets/crt_sprite_bezel.dart';
import 'package:vhsfin/features/living_room/widgets/vcr_box.dart';
import 'package:vhsfin/features/living_room/widgets/vcr_crt_screen.dart';
import 'package:vhsfin/features/playback/state/deck_player.dart';

void main() {
  testWidgets('changing CRT cabinet preserves the live screen state', (
    tester,
  ) async {
    final player = DeckPlayerController();
    final slot = GlobalKey();
    addTearDown(player.dispose);
    Widget room(CrtTvSkin skin) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 320,
            child: VcrBox(
              deck: const VcrDeckState(),
              player: player,
              surfaceEpoch: 0,
              surfaceOwner: DeckSurfaceOwner.crt,
              crtSkin: skin,
              slotKey: slot,
              flyingTapeId: null,
              onRew: () {},
              onRewEnd: () {},
              onPlay: () {},
              onFf: () {},
              onFfEnd: () {},
              onEject: () {},
              onFull: () {},
              onRemote: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(room(CrtTvSkin.crtIcon));
    final screen = tester.state(find.byType(VcrCrtScreen));
    for (final skin in [...CrtTvSkin.values.skip(1), CrtTvSkin.crtIcon]) {
      await tester.pumpWidget(room(skin));
      expect(tester.takeException(), isNull, reason: skin.name);
      expect(
        identical(tester.state(find.byType(VcrCrtScreen)), screen),
        isTrue,
      );
      expect(find.byType(CrtSpriteBezel), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
