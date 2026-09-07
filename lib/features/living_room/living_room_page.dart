import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vhsfin/features/auth/state/session_notifier.dart';
import 'package:vhsfin/features/library/model/shelf.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/library/state/shelf_display_prefs.dart';
import 'package:vhsfin/features/library/state/tape_library.dart';
import 'package:vhsfin/features/library/state/vhs_sleeve_actions.dart';
import 'package:vhsfin/features/library/state/vhs_spine_art.dart';
import 'package:vhsfin/features/living_room/state/deck_sfx.dart';
import 'package:vhsfin/features/living_room/state/series_episodes.dart';
import 'package:vhsfin/features/living_room/state/tape_flight_anchors.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/living_room/views/living_room_view.dart';
import 'package:vhsfin/features/living_room/widgets/_deck_settings_bar.dart';
import 'package:vhsfin/features/living_room/widgets/episode_picker_sheet.dart';
import 'package:vhsfin/features/living_room/widgets/tape_inspect_sheet.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_remote.dart';
import 'package:vhsfin/features/playback/state/deck_player.dart';

class LivingRoomPage extends ConsumerWidget {
  const LivingRoomPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final displayPrefs = ref.watch(shelfDisplayPrefsProvider);
    final shelvesAsync = ref.watch(shelvesProvider);
    // Art-index warm only matters for VHS-only filtering — skip the extra
    // rebuild storm while browsing the full shelf.
    final vhsArtIds = displayPrefs.vhsOnly
        ? ref.watch(vhsArtIndexProvider)
        : const <String>{};
    if (displayPrefs.vhsOnly) {
      ref.watch(vhsArtWarmProvider);
    }
    final deck = ref.watch(vcrDeckProvider);
    final flightAnchors = ref.watch(tapeFlightAnchorsProvider);
    final flyingTapeId = ref.watch(flyingTapeIdProvider);
    final flightSourceKey = ref.watch(flightSourceKeyProvider);
    final player = ref.watch(deckPlayerProvider);
    final surfaceEpoch = ref.watch(deckSurfaceEpochProvider);
    final slotArt = deck.loadedTape == null
        ? null
        : ref.watch(vhsSpineArtProvider(deck.loadedTape!)).asData?.value;
    final sfx = ref.watch(deckSfxProvider);

    final shelves = shelvesAsync.asData?.value;
    final filteredShelves = shelves == null
        ? null
        : [
            for (final shelf in shelves)
              Shelf(
                id: shelf.id,
                title: shelf.title,
                items: applyShelfDisplayPrefs(
                  shelf.items,
                  displayPrefs,
                  vhsArtIds: vhsArtIds,
                ),
                parentSeriesId: shelf.parentSeriesId,
              ),
          ];

    return LivingRoomView(
      deck: deck,
      player: player,
      surfaceEpoch: surfaceEpoch,
      flightAnchors: flightAnchors,
      flyingTapeId: flyingTapeId,
      flightSourceKey: flightSourceKey,
      slotArt: slotArt,
      shelvesLoading: shelvesAsync.isLoading && !shelvesAsync.hasValue,
      shelvesError: shelvesAsync.hasError ? '${shelvesAsync.error}' : null,
      shelves: filteredShelves,
      vhsOnly: displayPrefs.vhsOnly,
      connected: session != null,
      userName: session?.userName,
      sortLabel: displayPrefs.sort.buttonLabel,
      onRew: () {
        player.startRewind();
        sfx.startRewind();
      },
      onRewEnd: () {
        player.stopShuttle();
        sfx.stopShuttle();
      },
      onPlay: () => player.togglePlayPause(),
      onFf: () {
        player.startFastForward();
        sfx.startFastForward();
      },
      onFfEnd: () {
        player.stopShuttle();
        sfx.stopShuttle();
      },
      onEject: () => ref.read(vcrDeckProvider.notifier).eject(),
      onFull: () {
        if (!deck.isPlaying) return;
        ref
            .read(vcrDeckProvider.notifier)
            .setStyle(PlaybackStyle.cleanFullscreen);
        context.push('/play');
      },
      resolveSpineArt: (tape) => ref.read(vhsSpineArtProvider(tape).future),
      onTapeTap: (tape, instanceKey) =>
          _onTapeTap(context, ref, tape, instanceKey),
      onFlyingTapeIdChanged: (id) =>
          ref.read(flyingTapeIdProvider.notifier).set(id),
      artForFlight: (tape) =>
          ref.read(vhsSpineArtProvider(tape)).asData?.value,
      onShowRemote: () => _showRemote(context, ref),
      onCollection: () => context.push('/libraries'),
      onConnect: () => context.push('/connect'),
      onSignOut: () => ref.read(sessionProvider.notifier).signOut(),
      onVhsOnlyChanged: (value) =>
          ref.read(shelfDisplayPrefsProvider.notifier).setVhsOnly(value),
      onOpenSort: () => showShelfSortSheet(
        context,
        current: displayPrefs.sort,
        onSelect: (mode) =>
            ref.read(shelfDisplayPrefsProvider.notifier).setSort(mode),
      ),
    );
  }

  void _showRemote(BuildContext context, WidgetRef ref) {
    final deck = ref.read(vcrDeckProvider);
    final player = ref.read(deckPlayerProvider);
    final sfx = ref.read(deckSfxProvider);
    showVhsRemote(
      context,
      title: deck.loadedTape?.title,
      live: deck.isPlaying,
      powered: deck.isPowered,
      onRewStart: () {
        player.startRewind();
        sfx.startRewind();
      },
      onRewEnd: () {
        player.stopShuttle();
        sfx.stopShuttle();
      },
      onPlay: () => player.togglePlayPause(),
      onFfStart: () {
        player.startFastForward();
        sfx.startFastForward();
      },
      onFfEnd: () {
        player.stopShuttle();
        sfx.stopShuttle();
      },
      onFullScreen: () {
        ref
            .read(vcrDeckProvider.notifier)
            .setStyle(PlaybackStyle.cleanFullscreen);
        context.push('/play');
      },
      onEject: () => ref.read(vcrDeckProvider.notifier).eject(),
    );
  }

  void _onTapeTap(
    BuildContext context,
    WidgetRef ref,
    Tape tape,
    String instanceKey,
  ) {
    ref.read(flightSourceKeyProvider.notifier).select(instanceKey);
    if (tape.kind == TapeKind.series) {
      showEpisodePicker(
        context,
        series: tape,
        loadedId: ref.read(vcrDeckProvider).loadedTape?.id,
        loadEpisodes: () => ref.read(seriesEpisodesProvider(tape).future),
        resolveArt: (episode) =>
            ref.read(vhsSpineArtProvider(episode).future),
        onInsert: (episode) =>
            ref.read(vcrDeckProvider.notifier).insertTape(episode),
        onRejectSleeve: (episode) =>
            rejectTapeSleeveArt(ref.container, episode),
      );
      return;
    }
    showTapeInspectSheet(
      context,
      tape: tape,
      art: ref.read(vhsSpineArtProvider(tape)).asData?.value,
      loadArt: () => ref.read(vhsSpineArtProvider(tape).future),
      onRejectSleeve: () => rejectTapeSleeveArt(ref.container, tape),
      onInsert: () => ref.read(vcrDeckProvider.notifier).insertTape(tape),
    );
  }
}
