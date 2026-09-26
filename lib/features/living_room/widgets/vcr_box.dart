import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vhsfin/constants/feedback.dart';
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
    this.crtSkin = CrtTvSkin.crtIcon,
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
                child: Semantics(
                  label: 'TV screen',
                  hint: deck.isPowered
                      ? 'Tap to play or pause, double-tap for full screen'
                      : null,
                  button: deck.isPowered,
                  onTap: deck.isPowered ? onPlay : null,
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
                      ? Semantics(
                          button: true,
                          label: 'Eject ${deck.loadedTape!.title}',
                          excludeSemantics: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onEject,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF151511),
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(
                                  color: const Color(0xFF3F3C30),
                                ),
                              ),
                              child: Text(
                                deck.loadedTape!.title.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: VhsColors.accent.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontSize: (width * 0.018).clamp(7.0, 11.0),
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              // Keys sit exactly on the caps painted in the cabinet art.
              Positioned.fill(
                child: StreamBuilder<bool>(
                  stream: player.isReady ? player.player.stream.playing : null,
                  initialData: player.isReady
                      ? player.player.state.playing
                      : false,
                  builder: (context, snapshot) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final cap in layout.keys)
                        _DeckKey(
                          cap: cap,
                          capRect: box(cap.rect),
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
                    ],
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

/// One transport key laid over its painted cap. The art supplies the cap;
/// this adds the symbol (unless printed), press feedback, and a touch target
/// taller than the cap.
class _DeckKey extends StatefulWidget {
  const _DeckKey({
    required this.cap,
    required this.capRect,
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

  final DeckKeycap cap;
  final Rect capRect;
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
  State<_DeckKey> createState() => _DeckKeyState();
}

class _DeckKeyState extends State<_DeckKey> {
  bool _pressed = false;

  DeckKeyAction get _action => widget.cap.action;

  String get _label => switch (_action) {
    DeckKeyAction.playPause => widget.playing ? 'PAUSE' : 'PLAY',
    _ => _action.label,
  };

  IconData get _icon => switch (_action) {
    DeckKeyAction.rewind => Icons.fast_rewind_rounded,
    DeckKeyAction.play => Icons.play_arrow_rounded,
    DeckKeyAction.pause => Icons.pause_rounded,
    DeckKeyAction.playPause =>
      widget.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
    DeckKeyAction.fastForward => Icons.fast_forward_rounded,
    DeckKeyAction.eject => Icons.eject_rounded,
  };

  /// Lit while its function is active (rewinding, or the tape is playing).
  bool get _lit => switch (_action) {
    DeckKeyAction.rewind => widget.rewinding,
    DeckKeyAction.play || DeckKeyAction.playPause => widget.playing,
    _ => false,
  };

  VoidCallback? get _onTap => switch (_action) {
    DeckKeyAction.play => () {
      if (!widget.playing) widget.onPlay();
    },
    DeckKeyAction.pause => () {
      if (widget.playing) widget.onPlay();
    },
    DeckKeyAction.playPause => widget.onPlay,
    DeckKeyAction.eject => widget.onEject,
    _ => null,
  };

  /// Shuttle keys run while held.
  (VoidCallback, VoidCallback)? get _hold => switch (_action) {
    DeckKeyAction.rewind => (widget.onRew, widget.onRewEnd),
    DeckKeyAction.fastForward => (widget.onFf, widget.onFfEnd),
    _ => null,
  };

  void _release((VoidCallback, VoidCallback)? hold) {
    if (!_pressed) return;
    setState(() => _pressed = false);
    hold?.$2();
  }

  @override
  Widget build(BuildContext context) {
    final cap = widget.capRect;
    // Grow the target to at least 36px tall without moving the cap.
    final padY = math.max((36 - cap.height) / 2, cap.height * 0.3);
    final hit = Rect.fromLTRB(
      cap.left - 2,
      cap.top - padY,
      cap.right + 2,
      cap.bottom + padY,
    );
    final hold = widget.enabled ? _hold : null;
    final radius = BorderRadius.circular(cap.height * 0.18);

    return Positioned.fromRect(
      rect: hit,
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        label: _label,
        onTap: widget.enabled ? _onTap : null,
        child: Tooltip(
          message: _label,
          excludeFromSemantics: true,
          // Press, feel, and shuttle start on pointer-down: the tap recognizer
          // waits up to 100ms inside the scrolling room.
          child: Listener(
            onPointerDown: widget.enabled
                ? (_) {
                    DeckFeedback.key();
                    setState(() => _pressed = true);
                    hold?.$1();
                  }
                : null,
            onPointerUp: (_) => _release(hold),
            onPointerCancel: (_) => _release(hold),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: widget.enabled ? _onTap : null,
              child: Center(
                child: SizedBox.fromSize(
                  size: cap.size,
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 70),
                    transform: Matrix4.translationValues(
                      0,
                      _pressed ? 1 : 0,
                      0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      color: _pressed
                          ? Colors.black.withValues(alpha: 0.28)
                          : Colors.transparent,
                    ),
                    alignment: Alignment.center,
                    child: widget.cap.printed
                        ? null
                        : Icon(
                            _icon,
                            size: cap.height * 0.62,
                            color: _lit && widget.enabled
                                ? const Color(0xFF0F3A3D)
                                : const Color(0xFF171A1C).withValues(
                                    alpha: widget.enabled ? 0.9 : 0.45,
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
