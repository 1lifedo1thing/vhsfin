import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vhsfin/constants/feedback.dart';
import 'package:vhsfin/features/auth/state/session_notifier.dart';
import 'package:vhsfin/features/library/model/shelf.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/library/state/art_onboarding.dart';
import 'package:vhsfin/features/library/state/shelf_display_prefs.dart';
import 'package:vhsfin/features/library/state/sleeve_shrink.dart';
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
    final shrinker = ref.read(sleeveShrinkerProvider);
    showDeckSettingsSheet(
      context,
      connected: session != null,
      userName: session?.userName,
      vhsOnly: displayPrefs.vhsOnly,
      vhsCollector: displayPrefs.vhsCollector,
      sortLabel: displayPrefs.sort.buttonLabel,
      saveTimestampOnEject: experience.saveTimestampOnEject,
      jellyfinPosters: experience.jellyfinPosters,
      soundEffects: experience.soundEffects,
      onSoundEffectsChanged: (value) =>
          ref.read(experiencePrefsProvider.notifier).setSoundEffects(value),
      onJellyfinPostersChanged: (value) =>
          ref.read(experiencePrefsProvider.notifier).setJellyfinPosters(value),
      crtSkin: experience.crtSkin,
      cabinetStyle: experience.cabinetStyle,
      onCollection: () => context.push('/libraries'),
      onConnect: () => context.push('/connect'),
      onSignOut: () async {
        ref.invalidate(vcrDeckProvider);
        await ref.read(deckPlayerProvider).stop();
        if (!context.mounted) return;
        await ref.read(deckSfxProvider).stopShuttle();
        if (!context.mounted) return;
        await ref.read(sessionProvider.notifier).signOut();
      },
      onVhsOnlyChanged: (value) =>
          ref.read(shelfDisplayPrefsProvider.notifier).setVhsOnly(value),
      onVhsCollectorChanged: (value) =>
          ref.read(shelfDisplayPrefsProvider.notifier).setVhsCollector(value),
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
      onCabinetStyleChanged: (style) =>
          ref.read(experiencePrefsProvider.notifier).setCabinetStyle(style),
      onOpenLink: (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
      sleeveShrink: shrinker.available ? shrinker.status : null,
      onShrinkSleeves: shrinker.run,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayPrefs = ref.watch(shelfDisplayPrefsProvider);
    final shelvesAsync = ref.watch(shelvesProvider);
    final artWarm = ref.watch(artWarmProgressProvider);
    final shuttle = ref.watch(deckShuttleProvider);
    final experience = ref.watch(experiencePrefsProvider);

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
        // Seed Box-backed ids immediately so VHS-only filtering works before
        // the slower warm pass finishes (and on devices that skip warm).
        ref
            .read(vhsArtIndexProvider.notifier)
            .seedFromTapes(value.expand((s) => s.items));
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
      flightAnchors: flightAnchors,
      flyingTapeId: flyingTapeId,
      flightSourceKey: flightSourceKey,
      crtSkin: experience.crtSkin,
      cabinetStyle: experience.cabinetStyle,
      // Riverpod retries a failed load on its own; only show the failure
      // once it has stopped retrying, and keep any shelves already shown.
      shelvesLoading:
          !shelvesAsync.hasValue &&
          (shelvesAsync.isLoading || shelvesAsync.retrying),
      shelvesRetrying: !shelvesAsync.hasValue && shelvesAsync.hasError,
      shelvesError:
          shelvesAsync.hasError &&
              !shelvesAsync.hasValue &&
              !shelvesAsync.retrying &&
              !shelvesAsync.isLoading
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
      onPlay: player.togglePlayPause,
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
      onConnectPrompt: () => context.push(
        ref.read(sessionProvider).value == null ? '/connect' : '/libraries',
      ),
      onRetryShelves: () => ref.invalidate(shelvesProvider),
      onArtOnboardingDone: () {
        ref.read(artOnboardingDoneProvider.notifier).markDone();
        ref.read(artOnboardingUiProvider.notifier).dismiss();
      },
    );
  }

  Future<void> _kickArtWarm(WidgetRef ref) async {
    // Demo shelves are open movies with no retail sleeves to find.
    if (vhsfinDemoMode && ref.read(sessionProvider).value == null) return;
    await ref.read(artOnboardingDoneProvider.notifier).ready;
    // Page may have been disposed while prefs loaded.
    try {
      var needOnboarding = !ref.read(artOnboardingDoneProvider);
      final shelves = ref.read(shelvesProvider).asData?.value;
      if (shelves != null) {
        ref
            .read(vhsArtIndexProvider.notifier)
            .seedFromTapes(shelves.expand((s) => s.items));
      }
      if (needOnboarding &&
          shelves != null &&
          hasExistingAccountVhsArt(shelves)) {
        // Local preferences do not follow a Jellyfin account to a new device.
        // Existing server-side Box art proves this account has already run the
        // onboarding pass, so keep any remaining warm-up in the background.
        await ref.read(artOnboardingDoneProvider.notifier).markDone();
        needOnboarding = false;
      }
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
      playing: player.isReady ? player.player.stream.playing : null,
      initiallyPlaying: player.isReady && player.player.state.playing,
      onRewStart: () {
        player.startRewind();
        sfx.startRewind();
      },
      onRewEnd: () {
        player.stopShuttle();
        sfx.stopShuttle();
      },
      onPlay: player.togglePlayPause,
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
    // Pulling a tape off the shelf is felt, not clicked; its sheet whooshes.
    DeckFeedback.pick();
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
    final experience = ref.read(experiencePrefsProvider);
    showTapeInspectSheet(
      context,
      tape: tape,
      useVhsCover: !experience.jellyfinPosters,
      cabinetStyle: experience.cabinetStyle,
      art: ref.read(vhsSpineArtProvider(tape)).asData?.value,
      loadArt: () => ref.read(vhsSpineArtProvider(tape).future),
      onRejectSleeve: () => rejectTapeSleeveArt(ref.container, tape),
      onInsert: () => ref.read(vcrDeckProvider.notifier).insertTape(tape),
    );
  }
}
