import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/living_room/model/crt_sprite_layout.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/living_room/widgets/crt_sprite_bezel.dart';
import 'package:vhsfin/features/living_room/widgets/vcr_crt_screen.dart';
import 'package:vhsfin/features/playback/state/deck_player.dart';

/// A cabinet from the CRT atlas is the living-room centerpiece. Playback sits
/// in the transparent screen hole; the cassette bay and deck keys stay as
/// interactive overlays on the painted fascia.
class VcrBox extends StatelessWidget {
  const VcrBox({
    super.key,
    required this.deck,
    required this.player,
    required this.surfaceEpoch,
    required this.surfaceOwner,
    this.crtSkin = CrtTvSkin.crt90s,
    required this.slotKey,
    required this.flyingTapeId,
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
    CrtSpriteBezel.precacheAll(context);
    final layout = CrtSpriteLayout.of(crtSkin);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final naturalHeight =
            width * layout.sourceRect.height / layout.sourceRect.width;
        // Drop the feet a few pixels into the shelf ledge so the cabinet
        // reads as planted instead of hovering above the bevel.
        final plant = (width * CrtSpriteLayout.shelfPlant).clamp(2.0, 6.0);
        final height = naturalHeight - plant;
        Rect box(Rect frac) => Rect.fromLTWH(
          width * frac.left,
          naturalHeight * frac.top,
          width * frac.width,
          naturalHeight * frac.height,
        );
        final screen = box(layout.screen);
        final slot = box(layout.slot);
        final keys = box(layout.keys);
        final remote = box(layout.remote);
        final full = box(layout.full);
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fromRect(
                rect: screen,
                child: GestureDetector(
                  onTap: deck.isPowered ? onPlay : null,
                  onDoubleTap: deck.isPowered ? onFull : null,
                  // Fill the glass hole; [layout.screen] is centered on the
                  // transparent aperture so playback stays behind the bezel.
                  child: SizedBox.expand(
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
              ),
              Positioned(
                left: 0,
                top: 0,
                width: width,
                height: naturalHeight,
                child: IgnorePointer(child: CrtSpriteBezel(skin: crtSkin)),
              ),
              Positioned.fromRect(
                rect: remote,
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
              Positioned.fromRect(
                rect: full,
                child: Semantics(
                  button: true,
                  enabled: deck.isPowered,
                  label: 'FULL',
                  child: Tooltip(
                    message: 'FULL',
                    excludeFromSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: deck.isPowered ? onFull : null,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: slot,
                child: SizedBox(
                  key: slotKey,
                  child:
                      deck.loadedTape != null &&
                          (deck.power == VcrPower.playing ||
                              deck.power == VcrPower.ejecting) &&
                          flyingTapeId != deck.loadedTape!.id
                      ? Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
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
                              color: VhsColors.accent.withValues(alpha: 0.8),
                              fontSize: (width * 0.018).clamp(7.0, 11.0),
                              letterSpacing: 1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              Positioned.fromRect(
                rect: keys,
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
                            ? const Color(0xFF0F3A3D)
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
