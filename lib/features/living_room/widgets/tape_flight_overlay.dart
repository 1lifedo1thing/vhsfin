import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
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

/// Full-screen overlay — a 3D cassette travelling shelf ↔ deck slot.
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
  Timer? _ejectDelay;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _ejectDelay?.cancel();
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
      _ejectDelay?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_stillIn(VcrPower.inserting, tape)) return;
        _beginFlight(tape: tape, kind: _FlightKind.insert);
      });
    } else if (next.power == VcrPower.ejecting &&
        previous.power != VcrPower.ejecting) {
      // The tape stays in the deck while the mechanism unlatches.
      _ejectDelay?.cancel();
      _ejectDelay = Timer(DeckTiming.ejectMechanism, () {
        if (!_stillIn(VcrPower.ejecting, tape)) return;
        _beginFlight(tape: tape, kind: _FlightKind.eject);
      });
    }
  }

  bool _stillIn(VcrPower power, Tape tape) =>
      mounted &&
      widget.deck.power == power &&
      widget.deck.loadedTape?.id == tape.id;

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

    final anchors = widget.anchors;
    final slotGlobal = anchors.globalRectOf(anchors.slotKey);
    final spineGlobal = anchors.spineRectForTape(
      tape.id,
      sourceKey: widget.flightSourceKey,
    );

    // The console may be drawn scaled (tablets); a spine's slot is its height
    // plus 8, so its measured height gives the scale.
    final scale = spineGlobal == null
        ? 1.0
        : (spineGlobal.height / (VhsSpine.nominalHeight + 8)).clamp(0.5, 3.0);

    var slot = _localRect(slotGlobal) ?? _fallbackSlotLocal();
    slot = Rect.fromCenter(
      center: slot.center,
      width: math.min(slot.width, VhsSpine.nominalHeight * 1.5 * scale),
      height: slot.height,
    );

    var spine = _localRect(spineGlobal) ?? _fallbackShelfLocal(slot);
    spine = Rect.fromCenter(
      center: spine.center,
      width: VhsSpine.nominalWidth * scale,
      height: math.min(spine.height, VhsSpine.nominalHeight * scale),
    );

    _notifyFlyingTapeId(tape.id);
    setState(() {
      _flight = _FlightSpec(
        tape: tape,
        kind: kind,
        shelf: spine,
        slot: slot,
        art: widget.artFor(tape),
      );
    });
    _controller
      ..duration = kind == _FlightKind.insert
          ? DeckTiming.insertFlight
          : DeckTiming.ejectFlight
      ..value = 0
      ..forward();
  }

  void _notifyFlyingTapeId(String? tapeId) {
    if (!mounted) return;
    widget.onFlyingTapeIdChanged(tapeId);
  }

  void _finishFlight() {
    _ejectDelay?.cancel();
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
                // Eject replays the insert path backwards.
                final t = flight.kind == _FlightKind.insert
                    ? _controller.value
                    : 1 - _controller.value;
                return _FlyingCassette(
                  pose: CassettePose.at(
                    t,
                    shelf: flight.shelf,
                    slot: flight.slot,
                  ),
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

/// Where the cassette is and how it is turned at one moment of the flight.
///
/// `t` runs 0 → 1 from standing on the shelf to seated in the deck:
///   0.00–0.20  pull straight out of the shelf toward the viewer, tipping;
///   0.20–0.74  arc up and over, turning to horizontal with its top showing;
///   0.74–0.84  level off in front of the slot mouth;
///   0.84–1.00  slide into the deck (away from the viewer) and out of sight.
@immutable
class CassettePose {
  const CassettePose({
    required this.center,
    required this.scale,
    required this.depth,
    required this.stand,
    required this.pitch,
    required this.yaw,
    required this.roll,
    required this.inSlot,
    required this.lift,
  });

  /// Screen position of the cassette's centre.
  final Offset center;

  /// Size relative to [CassetteGeometry] (1 = shelf-spine size).
  final double scale;

  /// Distance along the view axis; negative is toward the viewer.
  final double depth;

  /// In-plane rotation; π/2 stands the cassette upright like a shelf spine.
  final double stand;

  /// Tip about the screen's horizontal axis (top edge toward the viewer).
  final double pitch;

  /// Swing about the screen's vertical axis.
  final double yaw;

  /// Turn about the cassette's own long axis; positive shows its top face.
  final double roll;

  /// 0 until the cassette meets the slot, 1 once it is fully inside.
  final double inSlot;

  /// 0 on a surface, 1 at the top of the arc — drives the cast shadow.
  final double lift;

  static const _pullEnd = 0.20;
  static const _arcEnd = 0.74;
  static const _alignEnd = 0.84;

  static CassettePose at(double t, {required Rect shelf, required Rect slot}) {
    t = t.clamp(0.0, 1.0);
    final shelfScale = shelf.height / CassetteGeometry.length;
    final slotScale = slot.width * 0.94 / CassetteGeometry.length;
    // Hover just above the mouth, then drop in level with it.
    final approach = slot.center.translate(0, -slot.height * 0.9);

    double seg(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

    final pull = Curves.easeOutCubic.transform(seg(0, _pullEnd));
    final arc = Curves.easeInOutCubic.transform(seg(_pullEnd, _arcEnd));
    final align = Curves.easeInOutSine.transform(seg(_arcEnd, _alignEnd));
    final feed = Curves.easeInCubic.transform(seg(_alignEnd, 1));

    // Quadratic Bézier arc; the control point rides above both ends.
    final top = math.min(shelf.top, slot.top) - 90;
    final control = Offset((shelf.center.dx + approach.dx) / 2, top);
    Offset bezier(double u) {
      final a = Offset.lerp(shelf.center, control, u)!;
      final b = Offset.lerp(control, approach, u)!;
      return Offset.lerp(a, b, u)!;
    }

    final hump = math.sin(arc * math.pi); // 0 → 1 → 0 across the arc
    // Nudge up as it clears the shelf lip.
    final center = Offset.lerp(
      bezier(arc).translate(0, -10 * pull * (1 - arc)),
      slot.center,
      align,
    )!;
    final scale =
        _lerp(shelfScale, shelfScale * 1.06, pull) * (1 - arc) +
        slotScale * arc;

    return CassettePose(
      center: center,
      scale: scale,
      depth:
          -130 * pull * (1 - arc) -
          60 * hump +
          feed * CassetteGeometry.depth * slotScale * 1.4,
      stand: (math.pi / 2) * (1 - arc),
      pitch: 0.34 * pull * (1 - arc),
      yaw: -0.28 * hump,
      roll: (0.62 * hump + 0.3 * arc) * (1 - align),
      inSlot: feed,
      lift: math.max(pull * (1 - arc), hump) * (1 - align),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

/// Cassette proportions in shelf-spine pixels (a VHS shell is 187×103×25 mm;
/// the spine face matches [VhsSpine] so the hand-off from the shelf is exact).
abstract final class CassetteGeometry {
  static const length = VhsSpine.nominalHeight;
  static const thickness = VhsSpine.nominalWidth;
  static const depth = length * 103 / 187;
}

class _FlyingCassette extends StatelessWidget {
  const _FlyingCassette({
    required this.pose,
    required this.slot,
    required this.tape,
    this.art,
  });

  final CassettePose pose;
  final Rect slot;
  final Tape tape;
  final VhsSpineArt? art;

  // Perspective strength: eye sits 1 / _perspective px in front of the screen.
  static const _perspective = 0.0012;
  static final _light = Vector3(-0.35, -0.7, -0.62)..normalize();

  @override
  Widget build(BuildContext context) {
    const l = CassetteGeometry.length;
    const w = CassetteGeometry.thickness;
    const d = CassetteGeometry.depth;

    final world = Matrix4.identity()
      ..translateByDouble(0, 0, pose.depth, 1)
      ..rotateX(pose.pitch)
      ..rotateY(pose.yaw)
      ..rotateZ(pose.stand)
      ..rotateX(pose.roll)
      ..scaleByDouble(pose.scale, pose.scale, pose.scale, 1);

    // Each face is drawn in the XY plane facing -Z, then moved into place.
    final faces = <_Face>[
      _Face(
        size: const Size(l, w),
        local: Matrix4.translationValues(0, 0, -d / 2),
        child: _SpineFace(tape: tape, art: art),
      ),
      _Face(
        size: const Size(l, d),
        local: Matrix4.translationValues(0, -w / 2, 0)..rotateX(-math.pi / 2),
        child: const CustomPaint(painter: _ShellTopPainter()),
      ),
      _Face(
        size: const Size(l, d),
        local: Matrix4.translationValues(0, w / 2, 0)..rotateX(math.pi / 2),
        child: const CustomPaint(painter: _ShellTopPainter(underside: true)),
      ),
      _Face(
        size: const Size(d, w),
        local: Matrix4.translationValues(-l / 2, 0, 0)..rotateY(math.pi / 2),
        child: const _PlasticFace(),
      ),
      _Face(
        size: const Size(d, w),
        local: Matrix4.translationValues(l / 2, 0, 0)..rotateY(-math.pi / 2),
        child: const _PlasticFace(),
      ),
      _Face(
        size: const Size(l, w),
        local: Matrix4.translationValues(0, 0, d / 2)..rotateY(math.pi),
        child: const _PlasticFace(),
      ),
    ];

    final eye = Vector3(0, 0, -1 / _perspective);
    final visible = <(double, Widget)>[];
    for (final face in faces) {
      final m = world.multiplied(face.local);
      final centre = m.transform3(Vector3.zero());
      final normal = m.transform3(Vector3(0, 0, -1)) - centre;
      normal.normalize();
      // Cull faces turned away from the eye.
      if (normal.dot(centre - eye) >= 0) continue;
      final shade = (0.55 + 0.45 * math.max(0.0, -normal.dot(_light))).clamp(
        0.0,
        1.0,
      );
      final projected = Matrix4.identity()
        ..setEntry(3, 2, _perspective)
        ..multiply(m);
      visible.add((
        centre.z,
        Positioned(
          left: -face.size.width / 2,
          top: -face.size.height / 2,
          width: face.size.width,
          height: face.size.height,
          child: Transform(
            alignment: Alignment.center,
            transform: projected,
            child: Stack(
              fit: StackFit.expand,
              children: [
                face.child,
                // Lambert shading plus the slot's darkness as it slides in.
                ColoredBox(
                  color: Colors.black.withValues(
                    alpha: ((1 - shade) + pose.inSlot * 0.75).clamp(0.0, 0.92),
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
    }
    // Painter's algorithm: farthest first.
    visible.sort((a, b) => b.$1.compareTo(a.$1));

    final cassette = Positioned(
      left: pose.center.dx,
      top: pose.center.dy,
      child: SizedBox.shrink(
        child: Stack(
          clipBehavior: Clip.none,
          children: [for (final f in visible) f.$2],
        ),
      ),
    );

    // The footprint turns with the tape: its thickness while standing, its
    // length once horizontal.
    final upright = (pose.stand / (math.pi / 2)).clamp(0.0, 1.0);
    final footprint = w + (l - w) * (1 - upright);
    final shadowWidth = footprint * pose.scale * (0.9 + 0.4 * pose.lift);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Soft cast shadow that spreads and fades as the tape rises.
        if (pose.inSlot == 0)
          Positioned(
            left: pose.center.dx - shadowWidth / 2,
            top:
                pose.center.dy +
                (l / 2 * upright + w / 2 * (1 - upright)) * pose.scale -
                6 +
                50 * pose.lift,
            width: shadowWidth,
            height: 14 + 10 * pose.lift,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.45 * (1 - 0.6 * pose.lift),
                    ),
                    blurRadius: 18 + 22 * pose.lift,
                  ),
                ],
              ),
            ),
          ),
        if (pose.inSlot > 0)
          // Once it meets the mouth, only what's inside the slot shows.
          ClipRect(
            clipper: _RectClipper(slot.inflate(2)),
            child: Stack(fit: StackFit.expand, children: [cassette]),
          )
        else
          cassette,
      ],
    );
  }
}

class _Face {
  const _Face({required this.size, required this.local, required this.child});

  final Size size;
  final Matrix4 local;
  final Widget child;
}

class _RectClipper extends CustomClipper<Rect> {
  const _RectClipper(this.rect);
  final Rect rect;

  @override
  Rect getClip(Size size) => rect;

  @override
  bool shouldReclip(_RectClipper oldClipper) => oldClipper.rect != rect;
}

/// The label end — the same art the shelf shows, turned to lie along the face.
class _SpineFace extends StatelessWidget {
  const _SpineFace({required this.tape, this.art});

  final Tape tape;
  final VhsSpineArt? art;

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (art != null)
            VhsSleeveCrop(
              url: art!.imageUrl,
              widthFraction: art!.centerWidthFraction,
            )
          else
            ProceduralVhsSpine(tape: tape),
          const DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0x33FFFFFF)),
                right: BorderSide(color: Color(0x55000000)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlasticFace extends StatelessWidget {
  const _PlasticFace();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF26272A), Color(0xFF141416)],
      ),
    ),
  );
}

/// Black VHS shell seen from above: label strip along the spine edge and a
/// smoked window over the two tape packs.
class _ShellTopPainter extends CustomPainter {
  const _ShellTopPainter({this.underside = false});

  final bool underside;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shell = Offset.zero & size;
    canvas.drawRect(
      shell,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2B2F), Color(0xFF161618), Color(0xFF0E0E10)],
        ).createShader(shell),
    );
    // Moulded rim.
    canvas.drawRect(
      shell.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x22FFFFFF),
    );
    if (underside) {
      // Underside: the two hub holes and the ribbed grip.
      for (final x in [w * 0.3, w * 0.7]) {
        canvas.drawCircle(
          Offset(x, h * 0.5),
          h * 0.11,
          Paint()..color = const Color(0xFF050506),
        );
      }
      return;
    }

    // rotateX(-π/2) swings this face's bottom edge to the spine side.
    final label = Rect.fromLTWH(w * 0.08, h * 0.64, w * 0.84, h * 0.28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(label, const Radius.circular(2)),
      Paint()..color = const Color(0xFFEDE6D6),
    );
    final rule = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 0.8;
    for (var i = 1; i <= 3; i++) {
      final y = label.top + label.height * i / 4;
      canvas.drawLine(
        Offset(label.left + 6, y),
        Offset(label.right - 6, y),
        rule,
      );
    }

    final window = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.2, h * 0.14, w * 0.6, h * 0.4),
      const Radius.circular(3),
    );
    canvas.drawRRect(window, Paint()..color = const Color(0xFF09090A));
    canvas.save();
    canvas.clipRRect(window);
    for (final (x, pack) in [(w * 0.33, 0.62), (w * 0.67, 0.4)]) {
      final c = Offset(x, window.center.dy);
      canvas.drawCircle(
        c,
        h * 0.24 * pack + h * 0.07,
        Paint()..color = const Color(0xFF3B2A20),
      );
      canvas.drawCircle(c, h * 0.07, Paint()..color = const Color(0xFFE9E6DF));
      canvas.drawCircle(c, h * 0.025, Paint()..color = const Color(0xFF111111));
    }
    // Smoked plastic glint.
    canvas.drawRect(
      window.outerRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.transparent,
            Colors.white.withValues(alpha: 0.05),
          ],
          stops: const [0, 0.4, 1],
        ).createShader(window.outerRect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShellTopPainter oldDelegate) =>
      oldDelegate.underside != underside;
}
