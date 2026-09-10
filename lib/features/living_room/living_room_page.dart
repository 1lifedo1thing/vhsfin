import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vhsfin/features/auth/state/session_notifier.dart';
import 'package:vhsfin/features/library/model/shelf.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/library/state/art_onboarding.dart';
import 'package:vhsfin/features/library/state/shelf_display_prefs.dart';
import 'package:vhsfin/features/library/state/tape_library.dart';
import 'package:vhsfin/features/library/state/vhs_sleeve_actions.dart';
import 'package:vhsfin/features/library/state/vhs_spine_art.dart';
import 'package:vhsfin/features/living_room/state/deck_sfx.dart';
import 'package:vhsfin/features/living_room/state/experience_prefs.dart';
import 'package:vhsfin/features/living_room/state/series_episodes.dart';
import 'package:vhsfin/features/living_room/state/tape_flight_anchors.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/living_room/views/living_room_view.dart';
import 'package:vhsfin/features/living_room/widgets/deck_settings_sheet.dart';
import 'package:vhsfin/features/living_room/widgets/episode_picker_sheet.dart';
import 'package:vhsfin/features/living_room/widgets/tape_inspect_sheet.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_remote.dart';
import 'package:vhsfin/features/playback/state/deck_player.dart';
import 'package:vhsfin/user_facing_error.dart';

class LivingRoomPage extends ConsumerWidget {
  const LivingRoomPage({super.key});

  void _showSettings(BuildContext context, WidgetRef ref) {
    final session = ref.read(sessionProvider).value;
    final displayPrefs = ref.read(shelfDisplayPrefsProvider);
    final experience = ref.read(experiencePrefsProvider);
    showDeckSettingsSheet(
      context,
      connected: session != null,
      userName: session?.userName,
      vhsOnly: displayPrefs.vhsOnly,
      sortLabel: displayPrefs.sort.buttonLabel,
      saveTimestampOnEject: experience.saveTimestampOnEject,
      crtSkin: experience.crtSkin,
      onCollection: () => context.push('/libraries'),
      onConnect: () => context.push('/connect'),
      onSignOut: () => ref.read(sessionProvider.notifier).signOut(),
      onVhsOnlyChanged: (value) =>
          ref.read(shelfDisplayPrefsProvider.notifier).setVhsOnly(value),
      onOpenSort: () => showShelfSortSheet(
        context,
        current: ref.read(shelfDisplayPrefsProvider).sort,
        onSelect: (mode) =>
            ref.read(shelfDisplayPrefsProvider.notifier).setSort(mode),
      ),
      onSaveTimestampChanged: (value) => ref
          .read(experiencePrefsProvider.notifier)
          .setSaveTimestampOnEject(value),
      onCrtSkinChanged: (skin) =>
          ref.read(experiencePrefsProvider.notifier).setCrtSkin(skin),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayPrefs = ref.watch(shelfDisplayPrefsProvider);
    final experience = ref.watch(experiencePrefsProvider);
    final shelvesAsync = ref.watch(shelvesProvider);
    final artWarm = ref.watch(artWarmProgressProvider);
    final shuttle = ref.watch(deckShuttleProvider);

    // Art-index warm only matters for VHS-only filtering — skip the extra
    // rebuild storm while browsing the full shelf (unless onboarding).
    final vhsArtIds = displayPrefs.vhsOnly
        ? ref.watch(vhsArtIndexProvider)
        : const <String>{};

    final shelves = shelvesAsync.asData?.value;
    final hasShelfItems =
        shelves != null && shelves.any((s) => s.items.isNotEmpty);

    // Kick off art warm for first-time onboarding and/or VHS-only filtering.
    // Wait for the onboarding prefs flag so we don't flash the popup again
    // after a prior CONTINUE (or auto-mark from a finished warm).
    ref.listen<AsyncValue<List<Shelf>>>(shelvesProvider, (prev, next) {
      next.whenData((value) {
        if (!value.any((s) => s.items.isNotEmpty)) return;
        Future(() => _kickArtWarm(ref));
      });
    });
    ref.listen(shelfDisplayPrefsProvider, (prev, next) {
      if (!next.vhsOnly) return;
      final loaded = ref.read(shelvesProvider).asData?.value;
      if (loaded == null || !loaded.any((s) => s.items.isNotEmpty)) return;
      Future(() => _kickArtWarm(ref));
    });
    if (hasShelfItems && artWarm.phase == ArtWarmPhase.idle) {
      Future(() => _kickArtWarm(ref));
    }

    final deck = ref.watch(vcrDeckProvider);
    final flightAnchors = ref.watch(tapeFlightAnchorsProvider);
    final flyingTapeId = ref.watch(flyingTapeIdProvider);
    final flightSourceKey = ref.watch(flightSourceKeyProvider);
    final player = ref.watch(deckPlayerProvider);
    final surfaceEpoch = ref.watch(deckSurfaceEpochProvider);
    final surfaceOwner = ref.watch(deckSurfaceOwnerProvider);
    final slotArt = deck.loadedTape == null
        ? null
        : ref.watch(vhsSpineArtProvider(deck.loadedTape!)).asData?.value;
    final sfx = ref.watch(deckSfxProvider);
    final showArtOnboardingUi = ref.watch(artOnboardingUiProvider);

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

    final showArtOnboarding =
        showArtOnboardingUi &&
        hasShelfItems &&
        (artWarm.phase == ArtWarmPhase.running ||
            artWarm.phase == ArtWarmPhase.done);

    return LivingRoomView(
      deck: deck,
      player: player,
      surfaceEpoch: surfaceEpoch,
      surfaceOwner: surfaceOwner,
      crtSkin: experience.crtSkin,
      flightAnchors: flightAnchors,
      flyingTapeId: flyingTapeId,
      flightSourceKey: flightSourceKey,
      slotArt: slotArt,
      shelvesLoading: shelvesAsync.isLoading && !shelvesAsync.hasValue,
      shelvesError: shelvesAsync.hasError
          ? userFacingError(shelvesAsync.error)
          : null,
      shelves: filteredShelves,
      vhsOnly: displayPrefs.vhsOnly,
      rewinding: shuttle == DeckShuttle.rewind,
      showArtOnboarding: showArtOnboarding,
      artWarmProgress: artWarm,
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
      resolveSpineArt: (tape) => ref.read(vhsSpineArtProvider(tape).future),
      onTapeTap: (tape, instanceKey) =>
          _onTapeTap(context, ref, tape, instanceKey),
      onFlyingTapeIdChanged: (id) =>
          ref.read(flyingTapeIdProvider.notifier).set(id),
      artForFlight: (tape) => ref.read(vhsSpineArtProvider(tape)).asData?.value,
      onShowRemote: () => _showRemote(context, ref),
      onShowSettings: () => _showSettings(context, ref),
      onConnectPrompt: () => context.push('/connect'),
      onArtOnboardingDone: () {
        ref.read(artOnboardingDoneProvider.notifier).markDone();
        ref.read(artOnboardingUiProvider.notifier).dismiss();
      },
    );
  }

  Future<void> _kickArtWarm(WidgetRef ref) async {
    await ref.read(artOnboardingDoneProvider.notifier).ready;
    // Page may have been disposed while prefs loaded.
    try {
      final needOnboarding = !ref.read(artOnboardingDoneProvider);
      final vhsOnly = ref.read(shelfDisplayPrefsProvider).vhsOnly;
      if (!needOnboarding && !vhsOnly) return;
      if (needOnboarding) {
        ref.read(artOnboardingUiProvider.notifier).show();
      }
      await ref.read(artWarmProgressProvider.notifier).ensureRunning();
    } catch (_) {
      // Ref disposed — ignore.
    }
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
      onFullScreen: () async {
        await Navigator.of(context).maybePop();
        await player.enterFullscreen();
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
        resolveArt: (episode) => ref.read(vhsSpineArtProvider(episode).future),
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
