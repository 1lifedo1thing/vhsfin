import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';
import 'package:vhsfin/features/living_room/widgets/vcr_crt_screen.dart';
import 'package:vhsfin/features/living_room/widgets/classic_vcr_box.dart';
import 'package:vhsfin/features/playback/state/deck_player.dart';

/// A real generated CRT cabinet is the living-room centerpiece. The playback
/// surface is placed into the glass aperture while the cassette bay and deck
/// controls remain interactive overlays below it.
class VcrBox extends StatelessWidget {
  const VcrBox({
    super.key,
    required this.deck,
    required this.player,
    required this.surfaceEpoch,
    required this.surfaceOwner,
    this.crtSkin = CrtTvSkin.skeuomorphic,
    required this.slotKey,
    required this.flyingTapeId,
    required this.slotArt,
    required this.onRew,
    required this.onRewEnd,
    required this.onPlay,
    required this.onFf,
    required this.onFfEnd,
    required this.onEject,
    required this.onFull,
    required this.onRemote,
    this.rewinding = false,
    this.videoSurface,
  });

  final VcrDeckState deck;
  final DeckPlayerController player;
  final int surfaceEpoch;
  final DeckSurfaceOwner surfaceOwner;
  final CrtTvSkin crtSkin;
  final GlobalKey slotKey;
  final String? flyingTapeId;
  final VhsSpineArt? slotArt;
  final VoidCallback onRew;
  final VoidCallback onRewEnd;
  final VoidCallback onPlay;
  final VoidCallback onFf;
  final VoidCallback onFfEnd;
  final VoidCallback onEject;
  final VoidCallback onFull;
  final VoidCallback onRemote;
  final bool rewinding;
  final Widget? videoSurface;

  @override
  Widget build(BuildContext context) {
    if (crtSkin != CrtTvSkin.skeuomorphic) {
      return ClassicVcrBox(
        screenKey: _CrtScreenKey(player),
        deck: deck,
        player: player,
        surfaceEpoch: surfaceEpoch,
        surfaceOwner: surfaceOwner,
        crtSkin: crtSkin,
        slotKey: slotKey,
        flyingTapeId: flyingTapeId,
        slotArt: slotArt,
        onRew: onRew,
        onRewEnd: onRewEnd,
        onPlay: onPlay,
        onFf: onFf,
        onFfEnd: onFfEnd,
        onEject: onEject,
        onFull: onFull,
        rewinding: rewinding,
        videoSurface: videoSurface,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        // Artwork is square, but the feet end at 97.3% of its canvas. Removing
        // that transparent tail puts the feet directly on the shelf surface.
        return SizedBox(
          height: size * 0.973,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: size * 0.09,
                top: size * 0.095,
                width: size * 0.82,
                height: size * 0.60,
                child: GestureDetector(
                  onTap: deck.isPowered ? onPlay : null,
                  onDoubleTap: deck.isPowered ? onFull : null,
                  child: VcrCrtScreen(
                    key: _CrtScreenKey(player),
                    power: deck.power,
                    style: deck.style,
                    tape: deck.loadedTape,
                    player: player,
                    surfaceEpoch: surfaceEpoch,
                    surfaceOwner: surfaceOwner,
                    resumeAt: deck.resumeAt,
                    rewinding: rewinding,
                    screenRadius: 0,
                    videoSurface: videoSurface,
                  ),
                ),
              ),
              // The alpha aperture owns the visible contour, not a guessed
              // screen radius. Playback extends behind the opaque bezel on every side.
              Positioned(
                left: 0,
                top: 0,
                width: size,
                height: size,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/branding/crt-90s.png',
                    excludeFromSemantics: true,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              Positioned(
                left: size * 0.05,
                top: size * 0.785,
                width: size * 0.09,
                height: size * 0.09,
                child: Semantics(
                  button: true,
                  label: 'Open remote controls',
                  child: Tooltip(
                    message: 'Open remote controls',
                    excludeFromSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onRemote,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: size * 0.23,
                top: size * 0.767,
                width: size * 0.54,
                height: size * 0.062,
                child: SizedBox(
                  key: slotKey,
                  child:
                      deck.loadedTape != null &&
                          deck.power == VcrPower.playing &&
                          flyingTapeId != deck.loadedTape!.id
                      ? Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF151511),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: const Color(0xFF3F3C30)),
                          ),
                          child: Text(
                            deck.loadedTape!.title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: VhsColors.phosphor.withValues(alpha: 0.8),
                              fontSize: (size * 0.018).clamp(7.0, 11.0),
                              letterSpacing: 1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                left: size * 0.263,
                right: size * 0.263,
                top: size * 0.827,
                height: size * 0.116,
                child: StreamBuilder<bool>(
                  stream: player.isReady ? player.player.stream.playing : null,
                  initialData: player.isReady
                      ? player.player.state.playing
                      : false,
                  builder: (context, snapshot) => _DeckButtons(
                    enabled: deck.isPowered,
                    playing: snapshot.data ?? false,
                    rewinding: rewinding,
                    onRew: onRew,
                    onRewEnd: onRewEnd,
                    onPlay: onPlay,
                    onFf: onFf,
                    onFfEnd: onFfEnd,
                    onEject: onEject,
                    onFull: onFull,
                  ),
                ),
              ),
              Positioned(
                top: size * 0.712,
                left: size * 0.18,
                right: size * 0.18,
                child: Center(
                  child: Text(
                    'VHSFIN',
                    style: vhsBrandStyle(size: (size * 0.018).clamp(7.0, 11.0))
                        .copyWith(
                          color: const Color(0xFFB0A28A),
                          letterSpacing: 2.5,
                        ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Reparent the live screen when switching cabinets, preserving playback,
// current position, pause state and the platform video surface.
class _CrtScreenKey extends GlobalObjectKey {
  const _CrtScreenKey(super.value);
}

class _DeckButtons extends StatelessWidget {
  const _DeckButtons({
    required this.enabled,
    required this.playing,
    required this.rewinding,
    required this.onRew,
    required this.onRewEnd,
    required this.onPlay,
    required this.onFf,
    required this.onFfEnd,
    required this.onEject,
    required this.onFull,
  });

  final bool enabled;
  final bool playing;
  final bool rewinding;
  final VoidCallback onRew;
  final VoidCallback onRewEnd;
  final VoidCallback onPlay;
  final VoidCallback onFf;
  final VoidCallback onFfEnd;
  final VoidCallback onEject;
  final VoidCallback onFull;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DeckKey(
          icon: Icons.fast_rewind_rounded,
          label: 'REW',
          enabled: enabled,
          emphasized: rewinding,
          onTapDown: (_) => onRew(),
          onTapUp: (_) => onRewEnd(),
          onTapCancel: onRewEnd,
        ),
        _DeckKey(
          icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          label: playing ? 'PAUSE' : 'PLAY',
          enabled: enabled,
          emphasized: true,
          onTap: onPlay,
        ),
        _DeckKey(
          icon: Icons.fast_forward_rounded,
          label: 'FF',
          enabled: enabled,
          onTapDown: (_) => onFf(),
          onTapUp: (_) => onFfEnd(),
          onTapCancel: onFfEnd,
        ),
        _DeckKey(
          icon: Icons.eject_rounded,
          label: 'EJECT',
          enabled: enabled,
          onTap: onEject,
        ),
        _DeckKey(
          icon: Icons.fullscreen_rounded,
          label: 'FULL',
          enabled: enabled,
          onTap: onFull,
        ),
      ],
    );
  }
}

/// The bitmap supplies the keycap; this supplies its symbol and interaction.
/// Touch targets extend above/below the cap without drawing a second button.
class _DeckKey extends StatefulWidget {
  const _DeckKey({
    required this.icon,
    required this.label,
    required this.enabled,
    this.emphasized = false,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool emphasized;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final VoidCallback? onTapCancel;

  @override
  State<_DeckKey> createState() => _DeckKeyState();
}

class _DeckKeyState extends State<_DeckKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        label: widget.label,
        onTap: widget.enabled ? widget.onTap : null,
        child: Tooltip(
          message: widget.label,
          excludeFromSemantics: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              excludeFromSemantics: true,
              onTap: widget.enabled ? widget.onTap : null,
              onTapDown: widget.enabled ? widget.onTapDown : null,
              onTapUp: widget.enabled ? widget.onTapUp : null,
              onTapCancel: widget.enabled ? widget.onTapCancel : null,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: .75,
                  heightFactor: .30,
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 80),
                    transform: Matrix4.translationValues(
                      0,
                      _pressed ? 1 : 0,
                      0,
                    ),
                    decoration: BoxDecoration(
                      color: _pressed ? Colors.black26 : Colors.transparent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Icon(
                        widget.icon,
                        size: 17,
                        color: widget.enabled && widget.emphasized
                            ? const Color(0xFF183B23)
                            : const Color(0xFF171A1C)
                                  .withValues(alpha: widget.enabled ? 1 : .5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
