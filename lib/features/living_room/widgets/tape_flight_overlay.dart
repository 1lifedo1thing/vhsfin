import 'dart:math' as math;
import 'dart:ui' as ui;

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
  var _flightGen = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 700),
        )..addStatusListener((status) {
          if (status != AnimationStatus.completed) return;
          if (!mounted) return;
          final kind = _flight?.kind;
          setState(() => _flight = null);
          if (kind != _FlightKind.eject) {
            widget.onFlyingTapeIdChanged(null);
          }
        });
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
        _beginFlight(tape: tape, kind: _FlightKind.insert);
      });
    } else if (next.power == VcrPower.ejecting &&
        previous.power != VcrPower.ejecting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
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
      width: size.width * 0.62,
      height: 36,
    );
  }

  Rect _fallbackShelfLocal(Rect slot) {
    return Rect.fromCenter(
      center: Offset(slot.center.dx, slot.bottom + 140),
      width: 28,
      height: 168,
    );
  }

  Future<void> _beginFlight({
    required Tape tape,
    required _FlightKind kind,
  }) async {
    final gen = ++_flightGen;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || gen != _flightGen) return;
    await Future<void>.delayed(const Duration(milliseconds: 24));
    if (!mounted || gen != _flightGen) return;

    final anchors = widget.anchors;
    final sourceKey = widget.flightSourceKey;
    final slotGlobal = anchors.globalRectOf(anchors.slotKey);
    final spineGlobal = anchors.spineRectForTape(tape.id, sourceKey: sourceKey);

    var slot = _localRect(slotGlobal) ?? _fallbackSlotLocal();
    slot = Rect.fromCenter(
      center: slot.center,
      width: slot.width * 0.9,
      height: 34,
    );

    var spine = _localRect(spineGlobal) ?? _fallbackShelfLocal(slot);
    spine = Rect.fromCenter(
      center: spine.center,
      width: 28,
      height: math.min(spine.height, 168),
    );

    final art = widget.artFor(tape);
    if (!mounted || gen != _flightGen) return;

    widget.onFlyingTapeIdChanged(tape.id);
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
    await _controller.forward();
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
                final raw = Curves.easeInOut.transform(_controller.value);
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

/// Straight shelf ↔ slot move. One rotation from upright to flat. No arcs.
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

  static const _length = 200.0;
  static const _thickness = 32.0;

  @override
  Widget build(BuildContext context) {
    // Always shelf→slot; eject runs it backward.
    final t = kind == _FlightKind.insert ? progress : 1.0 - progress;

    final pos = Offset.lerp(shelf.center, slot.center, t)!;
    // Horizontal mesh; π/2 = standing spine on the shelf.
    final stand = (1.0 - t) * (math.pi / 2);
    final scale = ui.lerpDouble(0.6, 1.0, t)!;
    final opacity = progress < 0.92 ? 1.0 : (1.0 - (progress - 0.92) / 0.08);

    return Positioned(
      left: pos.dx - _length * scale / 2,
      top: pos.dy - _thickness * scale / 2,
      width: _length * scale,
      height: _thickness * scale,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: -stand,
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
