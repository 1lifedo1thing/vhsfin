import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/constants/feedback.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/living_room/widgets/vcr_box.dart';
import 'package:vhsfin/features/playback/state/deck_player.dart';

void main() {
  tearDown(() => DeckFeedback.player = null);

  testWidgets('TV keys click with no tape in, but do nothing', (tester) async {
    final played = <DeckUiSound>[];
    DeckFeedback.player = played.add;
    var plays = 0;
    final player = DeckPlayerController();
    addTearDown(player.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            child: VcrBox(
              deck: const VcrDeckState(),
              player: player,
              surfaceEpoch: 0,
              surfaceOwner: DeckSurfaceOwner.crt,
              crtSkin: CrtTvSkin.crt90s,
              slotKey: GlobalKey(),
              flyingTapeId: null,
              onRew: () {},
              onRewEnd: () {},
              onPlay: () => plays++,
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
    await tester.tap(find.byTooltip('PLAY'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(played, [DeckUiSound.key]);
    expect(plays, 0);
  });
}
