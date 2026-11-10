import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:vhsfin/constants/feedback.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/model/shelf.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/library/state/art_onboarding.dart';
import 'package:vhsfin/features/library/widgets/art_grab_onboarding_dialog.dart';
import 'package:vhsfin/features/living_room/model/cabinet_style.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';
import 'package:vhsfin/features/living_room/state/tape_flight_anchors.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/living_room/views/bookshelf_view.dart';
import 'package:vhsfin/features/living_room/widgets/cabinet_material.dart';
import 'package:vhsfin/features/living_room/widgets/html_video_fit_stub.dart'
    if (dart.library.js_interop) 'package:vhsfin/features/living_room/widgets/html_video_fit_web.dart';
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
    required this.flightAnchors,
    required this.flyingTapeId,
    required this.flightSourceKey,
    required this.shelvesLoading,
    required this.vhsOnly,
    required this.rewinding,
    required this.onRew,
    required this.onRewEnd,
    required this.onPlay,
    required this.onFf,
    required this.onFfEnd,
    required this.onEject,
    required this.resolveSpineArt,
    required this.onTapeTap,
    required this.onFlyingTapeIdChanged,
    required this.artForFlight,
    required this.onShowRemote,
    required this.onShowSettings,
    required this.onConnectPrompt,
    required this.onRetryShelves,
    required this.onArtOnboardingDone,
    this.showArtOnboarding = false,
    this.artWarmProgress = const ArtWarmProgress(),
    this.shelvesRetrying = false,
    this.shelvesError,
    this.shelves,
    this.crtSkin = CrtTvSkin.crtIcon,
    this.cabinetStyle = CabinetStyle.walnut,
  });

  final VcrDeckState deck;
  final DeckPlayerController player;
  final int surfaceEpoch;
  final DeckSurfaceOwner surfaceOwner;
  final TapeFlightAnchors flightAnchors;
  final String? flyingTapeId;
  final String? flightSourceKey;
  final CrtTvSkin crtSkin;
  final CabinetStyle cabinetStyle;
  final bool shelvesLoading;
  final bool shelvesRetrying;
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
  final Future<VhsSpineArt?> Function(Tape tape) resolveSpineArt;
  final void Function(Tape tape, String instanceKey) onTapeTap;
  final ValueChanged<String?> onFlyingTapeIdChanged;
  final VhsSpineArt? Function(Tape tape) artForFlight;
  final VoidCallback onShowRemote;
  final VoidCallback onShowSettings;
  final VoidCallback onConnectPrompt;
  final VoidCallback onRetryShelves;
  final VoidCallback onArtOnboardingDone;

  @override
  Widget build(BuildContext context) {
    final controller = player.controllerOrNull;
    final videoKey = GlobalObjectKey<VideoState>(player);
    player.bindFullscreen(() async {
      if (await enterHtmlVideoFullscreen(player.player)) return;
      final videoState = videoKey.currentState;
      if (videoState != null) await videoState.enterFullscreen();
    });
    final videoSurface = controller == null
        ? null
        : LetterboxedVideo(
            player: player.player,
            controller: controller,
            videoKey: videoKey,
            opacity: deck.power == VcrPower.playing ? 1 : 0.15,
          );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.2,
                colors: [VhsColors.roomGlow, VhsColors.room, Color(0xFF030404)],
                stops: [0, 0.55, 1],
              ),
            ),
            // The shelves scroll under the home indicator instead of being
            // clipped at the bottom inset; the scroll padding clears it.
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, outer) {
                  // Tablets draw the whole console larger; everything below is
                  // laid out at the unscaled size, then scaled evenly.
                  final scale = consoleScaleFor(outer.biggest);
                  final constraints = outer / scale;
                  const maxConsole = 800.0;
                  final wide = constraints.maxWidth > 820;
                  final pad = wide ? 32.0 : 12.0;
                  // The TV's body spans the shelf below it (the shelf panel is
                  // inset 8 each side), capped so tall screens keep room for
                  // tapes. Its transparent edge may run into the page margin.
                  final shelfWidth =
                      math.min(constraints.maxWidth - pad * 2, maxConsole) - 16;
                  final maxTv = [
                    shelfWidth / crtSkin.bodyWidthFraction,
                    constraints.maxWidth,
                    (constraints.maxHeight * 0.53).clamp(300.0, 530.0),
                  ].reduce(math.min);

                  final console = Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxConsole + pad * 2,
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              pad + 8,
                              0,
                              pad + 4,
                              14,
                            ),
                            child: Row(
                              children: [
                                const Spacer(),
                                IconButton(
                                  onPressed: () {
                                    DeckFeedback.tap();
                                    onShowRemote();
                                  },
                                  tooltip: 'Remote',
                                  color: VhsColors.inkMuted,
                                  icon: const Icon(
                                    Icons.settings_remote_rounded,
                                    size: 21,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    DeckFeedback.tap();
                                    onShowSettings();
                                  },
                                  tooltip: 'Settings',
                                  color: VhsColors.inkMuted,
                                  icon: const Icon(
                                    Icons.tune_rounded,
                                    size: 21,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CabinetScope(
                            style: cabinetStyle,
                            child: _EntertainmentCenter(
                              maxTvWidth: maxTv,
                              sidePadding: pad,
                              vcr: VcrBox(
                                deck: deck,
                                player: player,
                                surfaceEpoch: surfaceEpoch,
                                surfaceOwner: surfaceOwner,
                                crtSkin: crtSkin,
                                slotKey: flightAnchors.slotKey,
                                flyingTapeId: flyingTapeId,
                                rewinding: rewinding,
                                onRew: onRew,
                                onRewEnd: onRewEnd,
                                onPlay: onPlay,
                                onFf: onFf,
                                onFfEnd: onFfEnd,
                                onEject: onEject,
                                onFull: player.enterFullscreen,
                                onRemote: onShowRemote,
                                videoSurface: videoSurface,
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
                                onRetryShelves: onRetryShelves,
                                shelvesRetrying: shelvesRetrying,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: (wide ? 28 : 0) * scale,
                      bottom: 40 * scale + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: scale == 1
                        ? console
                        : FittedBox(
                            fit: BoxFit.fitWidth,
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              child: console,
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
        ],
      ),
    );
  }
}

/// How much larger tablets draw the living room. Phones and small tablets
/// (shortest side under 760pt, e.g. iPad mini) keep the designed size; a
/// 13-inch iPad gets about 1.36x so the TV and shelf fill the screen.
double consoleScaleFor(Size size) =>
    (size.shortestSide / 760).clamp(1.0, 1.45).toDouble();

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
    required this.onRetryShelves,
    this.shelvesRetrying = false,
    this.shelvesError,
    this.shelves,
  });

  final bool shelvesLoading;
  final bool shelvesRetrying;
  final VoidCallback onRetryShelves;
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
      return ShelfLoadingBox(
        // A first try failed and another is on its way.
        message: shelvesRetrying ? 'TRYING YOUR SERVER' : 'STAND BY',
      );
    }
    if (shelvesError != null) {
      return ShelfNotice(
        title: 'The shelves are dark',
        message: shelvesError,
        actionLabel: 'TRY AGAIN',
        onAction: onRetryShelves,
      );
    }
    final loadedIntoDeck =
        deck.power == VcrPower.playing || deck.power == VcrPower.ejecting
        ? deck.loadedTape?.id
        : null;
    return BookshelfView(
      embedded: true,
      shelves: shelves!,
      loadedId: loadedIntoDeck,
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
  const _EntertainmentCenter({
    required this.vcr,
    required this.bookshelf,
    required this.maxTvWidth,
    required this.sidePadding,
  });

  final Widget vcr;
  final Widget bookshelf;
  final double maxTvWidth;

  /// Page margin around the cabinet; the TV is centred without it.
  final double sidePadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The cabinet art is drawn from slightly above, so the shelf shows its
        // top and the feet stand on it, a little behind the front edge.
        LayoutBuilder(
          builder: (context, constraints) {
            // CabinetShelf's default top depth and ledge height.
            const depth = 16.0;
            const ledge = 16.0;
            const feetFromFront = depth * 0.35;
            final tvWidth = math.min(maxTvWidth, constraints.maxWidth);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: sidePadding,
                  right: sidePadding,
                  bottom: 0,
                  child: const CabinetShelf(grain: Alignment(-0.6, 0.4)),
                ),
                // Contact shadow under the deck.
                Positioned(
                  left: (constraints.maxWidth - tvWidth * 0.9) / 2,
                  width: tvWidth * 0.9,
                  bottom: ledge + feetFromFront,
                  height: 4,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xCC000000),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: ledge + feetFromFront),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxTvWidth),
                      child: vcr,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePadding + 8),
          child: CabinetPanel(
            grain: const Alignment(0.2, -0.7),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: bookshelf,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePadding + 4),
          child: const CabinetLedge(height: 16, grain: Alignment(0.8, 0.9)),
        ),
        const SizedBox(height: 12),
        Text(
          'BE KIND. REWIND.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.18),
            fontSize: 8,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
