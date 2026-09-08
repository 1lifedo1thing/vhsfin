import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/model/shelf.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/library/state/art_onboarding.dart';
import 'package:vhsfin/features/library/widgets/art_grab_onboarding_dialog.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';
import 'package:vhsfin/features/living_room/state/tape_flight_anchors.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/living_room/views/bookshelf_view.dart';
import 'package:vhsfin/features/living_room/widgets/clean_fullscreen_overlay.dart';
import 'package:vhsfin/features/living_room/widgets/crt_loading_indicator.dart';
import 'package:vhsfin/features/living_room/widgets/letterboxed_video.dart';
import 'package:vhsfin/features/living_room/widgets/tape_flight_overlay.dart';
import 'package:vhsfin/features/living_room/widgets/vcr_box.dart';
import 'package:vhsfin/features/playback/state/deck_player.dart';

/// Living-room shell — page owns Riverpod and passes props/callbacks.
class LivingRoomView extends StatelessWidget {
  const LivingRoomView({
    super.key,
    required this.deck,
    required this.player,
    required this.surfaceEpoch,
    required this.surfaceOwner,
    required this.crtSkin,
    required this.flightAnchors,
    required this.flyingTapeId,
    required this.flightSourceKey,
    required this.slotArt,
    required this.shelvesLoading,
    required this.vhsOnly,
    required this.rewinding,
    required this.onRew,
    required this.onRewEnd,
    required this.onPlay,
    required this.onFf,
    required this.onFfEnd,
    required this.onEject,
    required this.onFull,
    required this.onCloseFullscreen,
    required this.resolveSpineArt,
    required this.onTapeTap,
    required this.onFlyingTapeIdChanged,
    required this.artForFlight,
    required this.onShowRemote,
    required this.onShowSettings,
    required this.onConnectPrompt,
    required this.onArtOnboardingDone,
    this.showArtOnboarding = false,
    this.artWarmProgress = const ArtWarmProgress(),
    this.shelvesError,
    this.shelves,
  });

  final VcrDeckState deck;
  final DeckPlayerController player;
  final int surfaceEpoch;
  final DeckSurfaceOwner surfaceOwner;
  final CrtTvSkin crtSkin;
  final TapeFlightAnchors flightAnchors;
  final String? flyingTapeId;
  final String? flightSourceKey;
  final VhsSpineArt? slotArt;
  final bool shelvesLoading;
  final String? shelvesError;
  final List<Shelf>? shelves;
  final bool vhsOnly;
  final bool rewinding;
  final bool showArtOnboarding;
  final ArtWarmProgress artWarmProgress;

  final VoidCallback onRew;
  final VoidCallback onRewEnd;
  final VoidCallback onPlay;
  final VoidCallback onFf;
  final VoidCallback onFfEnd;
  final VoidCallback onEject;
  final VoidCallback onFull;
  final VoidCallback onCloseFullscreen;
  final Future<VhsSpineArt?> Function(Tape tape) resolveSpineArt;
  final void Function(Tape tape, String instanceKey) onTapeTap;
  final ValueChanged<String?> onFlyingTapeIdChanged;
  final VhsSpineArt? Function(Tape tape) artForFlight;
  final VoidCallback onShowRemote;
  final VoidCallback onShowSettings;
  final VoidCallback onConnectPrompt;
  final VoidCallback onArtOnboardingDone;

  bool get _fullscreen => deck.style == PlaybackStyle.cleanFullscreen;

  @override
  Widget build(BuildContext context) {
    final controller = player.controllerOrNull;
    final videoSurface = controller == null
        ? null
        : LetterboxedVideo(
            key: GlobalObjectKey(player),
            player: player.player,
            controller: controller,
            opacity: deck.power == VcrPower.playing ? 1 : 0.15,
            fullscreen: _fullscreen,
          );

    return Scaffold(
      floatingActionButton: _fullscreen
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'vhsfin_settings',
                  onPressed: onShowSettings,
                  backgroundColor: const Color(0xFF2A2A28),
                  foregroundColor: VhsColors.brand,
                  tooltip: 'Settings',
                  child: const Icon(Icons.tune_rounded),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'vhsfin_remote',
                  onPressed: onShowRemote,
                  backgroundColor: const Color(0xFF2A2A28),
                  foregroundColor: VhsColors.brand,
                  tooltip: 'Remote',
                  child: const Icon(Icons.settings_remote_rounded),
                ),
              ],
            ),
      body: Stack(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.2,
                colors: [
                  Color(0xFF3A2418),
                  VhsColors.woodDeep,
                  Color(0xFF070504),
                ],
                stops: [0, 0.55, 1],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 820;
                  final pad = wide ? 32.0 : 12.0;
                  final maxConsole = wide ? 920.0 : double.infinity;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(pad, wide ? 28 : 16, pad, 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxConsole),
                        child: _EntertainmentCenter(
                          vcr: VcrBox(
                            deck: deck,
                            player: player,
                            surfaceEpoch: surfaceEpoch,
                            surfaceOwner: surfaceOwner,
                            crtSkin: crtSkin,
                            slotKey: flightAnchors.slotKey,
                            flyingTapeId: flyingTapeId,
                            slotArt: slotArt,
                            rewinding: rewinding,
                            onRew: onRew,
                            onRewEnd: onRewEnd,
                            onPlay: onPlay,
                            onFf: onFf,
                            onFfEnd: onFfEnd,
                            onEject: onEject,
                            onFull: onFull,
                            videoSurface: _fullscreen ? null : videoSurface,
                          ),
                          bookshelf: _BookshelfBody(
                            shelvesLoading: shelvesLoading,
                            shelvesError: shelvesError,
                            shelves: shelves,
                            deck: deck,
                            vhsOnly: vhsOnly,
                            flightAnchors: flightAnchors,
                            flyingTapeId: flyingTapeId,
                            flightSourceKey: flightSourceKey,
                            resolveSpineArt: resolveSpineArt,
                            onTapeTap: onTapeTap,
                            onConnectPrompt: onConnectPrompt,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned.fill(
            child: TapeFlightOverlay(
              deck: deck,
              anchors: flightAnchors,
              flightSourceKey: flightSourceKey,
              onFlyingTapeIdChanged: onFlyingTapeIdChanged,
              artFor: artForFlight,
            ),
          ),
          if (showArtOnboarding)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.55),
                child: Center(
                  child: ArtGrabOnboardingDialog(
                    progress: artWarmProgress,
                    onDone: onArtOnboardingDone,
                  ),
                ),
              ),
            ),
          if (_fullscreen)
            Positioned.fill(
              child: PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (didPop) return;
                  onCloseFullscreen();
                },
                child: CleanFullscreenOverlay(
                  title: deck.loadedTape?.title ?? '',
                  videoSurface: videoSurface,
                  onBack: onCloseFullscreen,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BookshelfBody extends StatelessWidget {
  const _BookshelfBody({
    required this.shelvesLoading,
    required this.deck,
    required this.vhsOnly,
    required this.flightAnchors,
    required this.flyingTapeId,
    required this.flightSourceKey,
    required this.resolveSpineArt,
    required this.onTapeTap,
    required this.onConnectPrompt,
    this.shelvesError,
    this.shelves,
  });

  final bool shelvesLoading;
  final String? shelvesError;
  final List<Shelf>? shelves;
  final VcrDeckState deck;
  final bool vhsOnly;
  final TapeFlightAnchors flightAnchors;
  final String? flyingTapeId;
  final String? flightSourceKey;
  final Future<VhsSpineArt?> Function(Tape tape) resolveSpineArt;
  final void Function(Tape tape, String instanceKey) onTapeTap;
  final VoidCallback onConnectPrompt;

  @override
  Widget build(BuildContext context) {
    if (shelvesLoading || shelves == null && shelvesError == null) {
      return const SizedBox(
        height: 180,
        child: CrtLoadingIndicator(
          compact: true,
          style: CrtLoadStyle.tape,
          message: 'STAND BY',
        ),
      );
    }
    if (shelvesError != null) {
      return Text('Could not load shelves: $shelvesError');
    }
    return BookshelfView(
      embedded: true,
      shelves: shelves!,
      loadedId: deck.loadedTape?.id,
      loadedSeriesId: deck.loadedTape?.seriesId,
      vhsOnly: vhsOnly,
      flightAnchors: flightAnchors,
      flyingTapeId: flyingTapeId,
      flightSourceKey: flightSourceKey,
      resolveSpineArt: resolveSpineArt,
      onTapeTap: onTapeTap,
      onConnectPrompt: onConnectPrompt,
    );
  }
}

/// VCR + shelf bay as one wooden entertainment center (no fat settings drawer).
class _EntertainmentCenter extends StatelessWidget {
  const _EntertainmentCenter({required this.vcr, required this.bookshelf});

  final Widget vcr;
  final Widget bookshelf;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5A3A24), Color(0xFF3A2416), Color(0xFF24160E)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [vcr, const SizedBox(height: 14), bookshelf],
      ),
    );
  }
}
