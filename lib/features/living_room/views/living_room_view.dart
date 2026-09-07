import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/model/shelf.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/library/state/art_onboarding.dart';
import 'package:vhsfin/features/library/widgets/art_grab_onboarding_dialog.dart';
import 'package:vhsfin/features/living_room/state/tape_flight_anchors.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/living_room/views/bookshelf_view.dart';
import 'package:vhsfin/features/living_room/widgets/_deck_settings_bar.dart';
import 'package:vhsfin/features/living_room/widgets/crt_loading_indicator.dart';
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
    required this.slotArt,
    required this.shelvesLoading,
    required this.vhsOnly,
    required this.connected,
    required this.sortLabel,
    required this.saveTimestampOnEject,
    required this.rewinding,
    required this.onRew,
    required this.onRewEnd,
    required this.onPlay,
    required this.onFf,
    required this.onFfEnd,
    required this.onEject,
    required this.onFull,
    required this.resolveSpineArt,
    required this.onTapeTap,
    required this.onFlyingTapeIdChanged,
    required this.artForFlight,
    required this.onShowRemote,
    required this.onCollection,
    required this.onConnect,
    required this.onSignOut,
    required this.onVhsOnlyChanged,
    required this.onOpenSort,
    required this.onSaveTimestampChanged,
    required this.onReplayArtGrab,
    required this.onArtOnboardingDone,
    this.showArtOnboarding = false,
    this.artWarmProgress = const ArtWarmProgress(),
    this.shelvesError,
    this.shelves,
    this.userName,
  });

  final VcrDeckState deck;
  final DeckPlayerController player;
  final int surfaceEpoch;
  final DeckSurfaceOwner surfaceOwner;
  final TapeFlightAnchors flightAnchors;
  final String? flyingTapeId;
  final String? flightSourceKey;
  final VhsSpineArt? slotArt;
  final bool shelvesLoading;
  final String? shelvesError;
  final List<Shelf>? shelves;
  final bool vhsOnly;
  final bool connected;
  final String? userName;
  final String sortLabel;
  final bool saveTimestampOnEject;
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
  final Future<VhsSpineArt?> Function(Tape tape) resolveSpineArt;
  final void Function(Tape tape, String instanceKey) onTapeTap;
  final ValueChanged<String?> onFlyingTapeIdChanged;
  final VhsSpineArt? Function(Tape tape) artForFlight;
  final VoidCallback onShowRemote;
  final VoidCallback onCollection;
  final VoidCallback onConnect;
  final VoidCallback onSignOut;
  final ValueChanged<bool> onVhsOnlyChanged;
  final VoidCallback onOpenSort;
  final ValueChanged<bool> onSaveTimestampChanged;
  final VoidCallback onReplayArtGrab;
  final VoidCallback onArtOnboardingDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: onShowRemote,
        backgroundColor: const Color(0xFF2A2A28),
        foregroundColor: VhsColors.brand,
        tooltip: 'Remote',
        child: const Icon(Icons.settings_remote_rounded),
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
                  // Furniture-scale console — wide enough for spines, not a
                  // stretched living-room void on ultrawide monitors.
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
                            onConnectPrompt: onConnect,
                          ),
                          settings: DeckSettingsBar(
                            embedded: true,
                            connected: connected,
                            userName: userName,
                            vhsOnly: vhsOnly,
                            sortLabel: sortLabel,
                            saveTimestampOnEject: saveTimestampOnEject,
                            onCollection: onCollection,
                            onConnect: onConnect,
                            onSignOut: onSignOut,
                            onVhsOnlyChanged: onVhsOnlyChanged,
                            onOpenSort: onOpenSort,
                            onSaveTimestampChanged: onSaveTimestampChanged,
                            onReplayArtGrab: onReplayArtGrab,
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

/// VCR + shelf bay + deck drawer as one wooden entertainment center.
class _EntertainmentCenter extends StatelessWidget {
  const _EntertainmentCenter({
    required this.vcr,
    required this.bookshelf,
    required this.settings,
  });

  final Widget vcr;
  final Widget bookshelf;
  final Widget settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5A3A24),
            Color(0xFF3A2416),
            Color(0xFF24160E),
          ],
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          vcr,
          const SizedBox(height: 14),
          bookshelf,
          const SizedBox(height: 12),
          settings,
        ],
      ),
    );
  }
}
