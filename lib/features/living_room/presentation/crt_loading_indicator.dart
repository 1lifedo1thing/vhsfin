import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/living_room/presentation/static_screen.dart';

enum CrtLoadStyle {
  /// Tiny CRT static + STAND BY.
  snow,

  /// Plastic cassette with spinning reels.
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

/// Beige shell cassette with two windows and animated hubs.
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
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.compact ? 112.0 : 168.0;
    final h = widget.compact ? 68.0 : 100.0;

    return AnimatedBuilder(
      animation: _spin,
      builder: (context, _) {
        final t = _spin.value * math.pi * 2;
        return SizedBox(
          width: w,
          height: h,
          child: CustomPaint(
            painter: _VhsCassettePainter(
              angle: t,
              // Left reel slightly slower — looks like tape transferring.
              leftAngle: t,
              rightAngle: -t * 1.15,
            ),
          ),
        );
      },
    );
  }
}

class _VhsCassettePainter extends CustomPainter {
  _VhsCassettePainter({
    required this.angle,
    required this.leftAngle,
    required this.rightAngle,
  });

  final double angle;
  final double leftAngle;
  final double rightAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final shell = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(5),
    );

    // Shell body
    canvas.drawRRect(
      shell,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8DCC4), Color(0xFFC4B090), Color(0xFFA89070)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(
      shell,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF3A2A18),
    );

    // Label plate
    final label = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.58,
        size.width * 0.76,
        size.height * 0.28,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(label, Paint()..color = const Color(0xFFF7F0E0));
    canvas.drawRRect(
      label,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF2A1810).withValues(alpha: 0.35),
    );

    final labelCenter = label.center;
    final tp = TextPainter(
      text: TextSpan(
        text: 'LOADING',
        style: TextStyle(
          color: const Color(0xFF2A1810).withValues(alpha: 0.75),
          fontSize: size.height * 0.11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: label.width);
    tp.paint(
      canvas,
      Offset(labelCenter.dx - tp.width / 2, labelCenter.dy - tp.height / 2),
    );

    // Clear window over reels
    final window = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.12,
        size.width * 0.8,
        size.height * 0.38,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(window, Paint()..color = const Color(0xFF1A1410));
    canvas.drawRRect(
      window,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black.withValues(alpha: 0.5),
    );

    final reelY = window.center.dy;
    final reelR = size.height * 0.13;
    final left = Offset(size.width * 0.28, reelY);
    final right = Offset(size.width * 0.72, reelY);

    _drawReel(canvas, left, reelR, leftAngle, full: true);
    _drawReel(canvas, right, reelR * 0.92, rightAngle, full: false);

    // Tape path between reels
    final tapePaint = Paint()
      ..color = const Color(0xFF2A2018)
      ..strokeWidth = size.height * 0.035
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(left.dx + reelR * 0.55, reelY + reelR * 0.15),
      Offset(right.dx - reelR * 0.55, reelY + reelR * 0.15),
      tapePaint,
    );

    // Soft sheen
    canvas.drawRRect(
      shell,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.center,
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  void _drawReel(
    Canvas canvas,
    Offset c,
    double r,
    double angle, {
    required bool full,
  }) {
    // Tape pancake
    canvas.drawCircle(
      c,
      r,
      Paint()..color = full ? const Color(0xFF1A100C) : const Color(0xFF3A2A1C),
    );
    canvas.drawCircle(
      c,
      r * (full ? 0.72 : 0.45),
      Paint()..color = const Color(0xFF0C0806),
    );

    // Hub
    canvas.drawCircle(c, r * 0.28, Paint()..color = const Color(0xFFD4C4A0));
    canvas.drawCircle(
      c,
      r * 0.28,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF2A1810),
    );

    // Spokes
    final spoke = Paint()
      ..color = const Color(0xFF2A1810)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final a = angle + i * math.pi / 3;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * r * 0.08,
        c + Offset(math.cos(a), math.sin(a)) * r * 0.26,
        spoke,
      );
    }

    // Center hole
    canvas.drawCircle(c, r * 0.08, Paint()..color = const Color(0xFF1A100C));
  }

  @override
  bool shouldRepaint(covariant _VhsCassettePainter oldDelegate) {
    return oldDelegate.leftAngle != leftAngle ||
        oldDelegate.rightAngle != rightAngle;
  }
}
