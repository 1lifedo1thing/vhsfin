import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/living_room/presentation/static_screen.dart';

enum CrtLoadStyle {
  /// Tiny CRT static + STAND BY.
  snow,

  /// Black VHS cassette with spinning reels.
  tape,
}

/// Retro loading stand-in — spinning VHS reels or CRT snow.
class CrtLoadingIndicator extends StatelessWidget {
  const CrtLoadingIndicator({
    super.key,
    this.message = 'STAND BY',
    this.compact = false,
    this.style = CrtLoadStyle.tape,
  });

  final String message;
  final bool compact;
  final CrtLoadStyle style;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          switch (style) {
            CrtLoadStyle.snow => _SnowBadge(compact: compact),
            CrtLoadStyle.tape => VhsTapeSpinner(compact: compact),
          },
          SizedBox(height: compact ? 8 : 12),
          Text(
            message,
            style: TextStyle(
              color: VhsColors.phosphor.withValues(alpha: 0.85),
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SnowBadge extends StatelessWidget {
  const _SnowBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 72 : 120,
      height: compact ? 54 : 90,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            StaticScreen(intensity: compact ? 0.55 : 0.7),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black.withValues(alpha: 0.65)),
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top-down VHS cassette — flap, twin reel windows, center label.
class VhsTapeSpinner extends StatefulWidget {
  const VhsTapeSpinner({super.key, this.compact = false});

  final bool compact;

  @override
  State<VhsTapeSpinner> createState() => _VhsTapeSpinnerState();
}

class _VhsTapeSpinnerState extends State<VhsTapeSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Real VHS footprint ~188×104mm ≈ 1.81:1.
    final w = widget.compact ? 168.0 : 248.0;
    final h = w / 1.81;

    return AnimatedBuilder(
      animation: _spin,
      builder: (context, _) {
        final t = _spin.value * math.pi * 2;
        return SizedBox(
          width: w,
          height: h,
          child: CustomPaint(
            painter: _VhsCassettePainter(
              leftAngle: t,
              rightAngle: -t * 1.08,
            ),
          ),
        );
      },
    );
  }
}

class _VhsCassettePainter extends CustomPainter {
  _VhsCassettePainter({
    required this.leftAngle,
    required this.rightAngle,
  });

  final double leftAngle;
  final double rightAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final shell = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(3),
    );

    // Charcoal body
    canvas.drawRRect(
      shell,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C2C2E), Color(0xFF161618), Color(0xFF0E0E10)],
        ).createShader(Offset.zero & size),
    );

    // Horizontal ribbing across the face (below the flap)
    final ribPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    final ribDark = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    final ribTop = size.height * 0.2;
    final ribBottom = size.height * 0.96;
    for (var y = ribTop; y < ribBottom; y += 3.2) {
      canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), ribPaint);
      canvas.drawLine(Offset(4, y + 1), Offset(size.width - 4, y + 1), ribDark);
    }

    canvas.drawRRect(
      shell,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF050506),
    );

    // —— Protective flap (top edge) ——
    final flap = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height * 0.175),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(
      flap,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A3A3E), Color(0xFF1A1A1C)],
        ).createShader(flap.outerRect),
    );
    // Hinge seam under flap
    canvas.drawLine(
      Offset(size.width * 0.04, flap.outerRect.bottom - 0.5),
      Offset(size.width * 0.96, flap.outerRect.bottom - 0.5),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..strokeWidth = 1.2,
    );

    // Embossed flap copy
    final flapStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.22),
      fontSize: size.height * 0.055,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
    final leftFlap = TextPainter(
      text: TextSpan(text: 'Insert this side into recorder', style: flapStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: size.width * 0.42);
    leftFlap.paint(
      canvas,
      Offset(size.width * 0.05, flap.center.dy - leftFlap.height / 2 - 1),
    );

    // Center arrow
    final arrowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;
    final ax = size.width * 0.5;
    final ay = flap.center.dy;
    final path = Path()
      ..moveTo(ax, ay - size.height * 0.035)
      ..lineTo(ax, ay + size.height * 0.03)
      ..moveTo(ax - size.width * 0.018, ay - size.height * 0.01)
      ..lineTo(ax, ay - size.height * 0.035)
      ..lineTo(ax + size.width * 0.018, ay - size.height * 0.01);
    canvas.drawPath(path, arrowPaint);

    final rightFlap = TextPainter(
      text: TextSpan(text: 'Do not touch the tape inside', style: flapStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: size.width * 0.4);
    rightFlap.paint(
      canvas,
      Offset(
        size.width * 0.95 - rightFlap.width,
        flap.center.dy - rightFlap.height / 2 - 1,
      ),
    );

    // —— Twin reel windows + center label ——
    final winTop = size.height * 0.28;
    final winH = size.height * 0.52;
    final winW = size.width * 0.26;
    final leftWin = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.06, winTop, winW, winH),
      const Radius.circular(3),
    );
    final rightWin = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.68, winTop, winW, winH),
      const Radius.circular(3),
    );
    final label = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.34,
        size.height * 0.32,
        size.width * 0.32,
        size.height * 0.44,
      ),
      const Radius.circular(3),
    );

    _drawWindow(canvas, leftWin);
    _drawWindow(canvas, rightWin);

    // Center paper label
    canvas.drawRRect(
      label,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF4F0E8), Color(0xFFE6E0D4)],
        ).createShader(label.outerRect),
    );
    canvas.drawRRect(
      label,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF2A2A28).withValues(alpha: 0.35),
    );
    final loadTp = TextPainter(
      text: TextSpan(
        text: 'LOADING',
        style: TextStyle(
          color: const Color(0xFF2A1810).withValues(alpha: 0.55),
          fontSize: size.height * 0.09,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: label.width);
    loadTp.paint(
      canvas,
      Offset(
        label.center.dx - loadTp.width / 2,
        label.center.dy - loadTp.height / 2,
      ),
    );

    // Reels inside windows (supply full, take-up emptier)
    final reelR = math.min(winW, winH) * 0.38;
    _drawReel(
      canvas,
      leftWin.center,
      reelR,
      leftAngle,
      fill: 0.92,
    );
    _drawReel(
      canvas,
      rightWin.center,
      reelR * 0.95,
      rightAngle,
      fill: 0.28,
    );

    // Soft sheen
    canvas.drawRRect(
      shell,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.center,
          colors: [
            Colors.white.withValues(alpha: 0.07),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  void _drawWindow(Canvas canvas, RRect window) {
    canvas.drawRRect(window, Paint()..color = const Color(0xFF08080A));
    canvas.drawRRect(
      window,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = Colors.black.withValues(alpha: 0.75),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        window.outerRect.deflate(1.5),
        const Radius.circular(2),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.06),
    );
  }

  void _drawReel(
    Canvas canvas,
    Offset c,
    double r,
    double angle, {
    required double fill,
  }) {
    // Dark magnetic tape pancake
    canvas.drawCircle(
      c,
      r,
      Paint()..color = const Color(0xFF12100E),
    );
    final tapeR = r * (0.38 + 0.55 * fill.clamp(0.0, 1.0));
    canvas.drawCircle(
      c,
      tapeR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF1A100C),
            const Color(0xFF0A0806),
            Colors.black.withValues(alpha: 0.9),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: tapeR)),
    );

    // Gloss on tape
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: tapeR * 0.92),
      -0.9,
      0.7,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12,
    );

    // White plastic hub
    final hubR = r * 0.34;
    canvas.drawCircle(c, hubR, Paint()..color = const Color(0xFFECE8E0));
    canvas.drawCircle(
      c,
      hubR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = const Color(0xFF2A1810).withValues(alpha: 0.45),
    );

    final spoke = Paint()
      ..color = const Color(0xFF3A3028).withValues(alpha: 0.7)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final a = angle + i * math.pi / 3;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * hubR * 0.25,
        c + Offset(math.cos(a), math.sin(a)) * hubR * 0.88,
        spoke,
      );
    }
    canvas.drawCircle(c, hubR * 0.28, Paint()..color = const Color(0xFF2A2824));
    canvas.drawCircle(c, hubR * 0.12, Paint()..color = const Color(0xFF0C0C0E));
  }

  @override
  bool shouldRepaint(covariant _VhsCassettePainter oldDelegate) {
    return oldDelegate.leftAngle != leftAngle ||
        oldDelegate.rightAngle != rightAngle;
  }
}
