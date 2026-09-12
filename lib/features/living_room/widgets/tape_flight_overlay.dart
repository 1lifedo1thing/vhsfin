import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/state/tape_flight_anchors.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_spine.dart';

enum _FlightKind { insert, eject }

class _FlightSpec {
  const _FlightSpec({
    required this.tape,
    required this.kind,
    required this.shelf,
    required this.slot,
    this.art,
  });

  final Tape tape;
  final _FlightKind kind;
  final Rect shelf;
  final Rect slot;
  final VhsSpineArt? art;
}

/// Full-screen overlay — simple cassette flight shelf ↔ bay.
class TapeFlightOverlay extends StatefulWidget {
  const TapeFlightOverlay({
    super.key,
    required this.deck,
    required this.anchors,
    required this.flightSourceKey,
    required this.onFlyingTapeIdChanged,
    required this.artFor,
  });

  final VcrDeckState deck;
  final TapeFlightAnchors anchors;
  final String? flightSourceKey;
  final ValueChanged<String?> onFlyingTapeIdChanged;
  final VhsSpineArt? Function(Tape tape) artFor;

  @override
  State<TapeFlightOverlay> createState() => _TapeFlightOverlayState();
}

class _TapeFlightOverlayState extends State<TapeFlightOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final GlobalKey _layerKey = GlobalKey(debugLabel: 'tapeFlightLayer');
  _FlightSpec? _flight;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TapeFlightOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.deck;
    final next = widget.deck;
    final finishedInsert =
        previous.power == VcrPower.inserting && next.power == VcrPower.playing;
    final finishedEject =
        previous.power == VcrPower.ejecting && next.power == VcrPower.off;
    if (finishedInsert || finishedEject) {
      _finishFlight();
      return;
    }
    if (previous.power == next.power &&
        previous.loadedTape?.id == next.loadedTape?.id) {
      return;
    }
    final tape = next.loadedTape;
    if (tape == null) return;
    if (next.power == VcrPower.inserting &&
        previous.power != VcrPower.inserting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.deck.power != VcrPower.inserting ||
            widget.deck.loadedTape?.id != tape.id) {
          return;
        }
        _beginFlight(tape: tape, kind: _FlightKind.insert);
      });
    } else if (next.power == VcrPower.ejecting &&
        previous.power != VcrPower.ejecting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.deck.power != VcrPower.ejecting ||
            widget.deck.loadedTape?.id != tape.id) {
          return;
        }
        _beginFlight(tape: tape, kind: _FlightKind.eject);
      });
    }
  }

  Rect? _localRect(Rect? global) {
    if (global == null) return null;
    final box = _layerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final topLeft = box.globalToLocal(global.topLeft);
    final bottomRight = box.globalToLocal(global.bottomRight);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  Rect _fallbackSlotLocal() {
    final size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.26),
      width: VhsSpine.nominalHeight,
      height: VhsSpine.nominalWidth,
    );
  }

  Rect _fallbackShelfLocal(Rect slot) {
    return Rect.fromCenter(
      center: Offset(slot.center.dx, slot.bottom + 140),
      width: VhsSpine.nominalWidth,
      height: VhsSpine.nominalHeight,
    );
  }

  void _beginFlight({required Tape tape, required _FlightKind kind}) {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    final expectedPower = kind == _FlightKind.insert
        ? VcrPower.inserting
        : VcrPower.ejecting;
    if (widget.deck.power != expectedPower ||
        widget.deck.loadedTape?.id != tape.id) {
      return;
    }

    final anchors = widget.anchors;
    final sourceKey = widget.flightSourceKey;
    final slotGlobal = anchors.globalRectOf(anchors.slotKey);
    final spineGlobal = anchors.spineRectForTape(tape.id, sourceKey: sourceKey);

    var slot = _localRect(slotGlobal) ?? _fallbackSlotLocal();
    slot = Rect.fromCenter(
      center: slot.center,
      width: math.min(slot.width, VhsSpine.nominalHeight * 1.5),
      height: math.min(slot.height, VhsSpine.nominalWidth),
    );

    var spine = _localRect(spineGlobal) ?? _fallbackShelfLocal(slot);
    spine = Rect.fromCenter(
      center: spine.center,
      width: VhsSpine.nominalWidth,
      height: math.min(spine.height, VhsSpine.nominalHeight),
    );

    final art = widget.artFor(tape);
    if (!mounted) return;

    _notifyFlyingTapeId(tape.id);
    setState(() {
      _flight = _FlightSpec(
        tape: tape,
        kind: kind,
        shelf: spine,
        slot: slot,
        art: art,
      );
    });
    _controller.value = 0;
    _controller.forward();
  }

  void _notifyFlyingTapeId(String? tapeId) {
    if (!mounted) return;
    widget.onFlyingTapeIdChanged(tapeId);
  }

  void _finishFlight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onFlyingTapeIdChanged(null);
      setState(() => _flight = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final flight = _flight;
    return IgnorePointer(
      child: Stack(
        key: _layerKey,
        fit: StackFit.expand,
        children: [
          if (flight != null)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final raw = _controller.value;
                return _FlyingCassette(
                  progress: raw,
                  kind: flight.kind,
                  shelf: flight.shelf,
                  slot: flight.slot,
                  tape: flight.tape,
                  art: flight.art,
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Lift and turn the sleeve, then draw the cassette into the physical slot.
/// Eject reverses the same motion so both endpoints stay attached to the room.
class _FlyingCassette extends StatelessWidget {
  const _FlyingCassette({
    required this.progress,
    required this.kind,
    required this.shelf,
    required this.slot,
    required this.tape,
    this.art,
  });

  final double progress;
  final _FlightKind kind;
  final Rect shelf;
  final Rect slot;
  final Tape tape;
  final VhsSpineArt? art;

  static const _length = VhsSpine.nominalHeight;
  static const _thickness = VhsSpine.nominalWidth;

  @override
  Widget build(BuildContext context) {
    // Always shelf→slot; eject runs it backward.
    final t = kind == _FlightKind.insert ? progress : 1.0 - progress;

    final travel = Curves.easeInOutCubic.transform((t / 0.82).clamp(0.0, 1.0));
    final feed = Curves.easeIn.transform(((t - 0.82) / 0.18).clamp(0.0, 1.0));
    final pos = Offset.lerp(shelf.center, slot.center, travel)!;
    // Horizontal mesh; π/2 = standing spine on the shelf.
    final stand = (1.0 - travel) * (math.pi / 2);
    final scale =
        (shelf.height / _length) * (1 - travel) +
        (slot.width / _length) * travel;
    return Positioned(
      left: pos.dx - _length / 2,
      top: pos.dy - _thickness / 2,
      width: _length,
      height: _thickness,
      child: Transform.rotate(
        angle: stand,
        child: Transform.scale(
          scaleX: scale,
          scaleY: scale * (1 - feed * 0.98),
          child: _CassetteFace(tape: tape, art: art),
        ),
      ),
    );
  }
}

class _CassetteFace extends StatelessWidget {
  const _CassetteFace({required this.tape, this.art});

  final Tape tape;
  final VhsSpineArt? art;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: VhsColors.tapeShell,
        border: Border.all(color: Colors.black.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(2, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Same spine treatment as the shelf / bay cassette — never the poster.
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: SizedBox(
                      width: h,
                      height: w,
                      child: art != null
                          ? VhsSleeveCrop(
                              url: art!.imageUrl,
                              widthFraction: art!.centerWidthFraction,
                            )
                          : ProceduralVhsSpine(tape: tape),
                    ),
                  ),
                );
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  bottom: BorderSide(
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
