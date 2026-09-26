import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vhsfin/constants/theme.dart';

/// Classic CRT fast-rewind look — snow, scanlines, and REW chevrons.
class CrtRewindOverlay extends StatefulWidget {
  const CrtRewindOverlay({super.key});

  @override
  State<CrtRewindOverlay> createState() => _CrtRewindOverlayState();
}

class _CrtRewindOverlayState extends State<CrtRewindOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _time = elapsed.inMilliseconds / 1000);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _RewindPainter(time: _time),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RewindPainter extends CustomPainter {
  _RewindPainter({required this.time});

  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    // Dim the picture so chevrons read clearly.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // Coarse snow / dropouts.
    final random = math.Random((time * 48).floor());
    const cell = 4.0;
    final cols = (size.width / cell).ceil();
    final rows = (size.height / cell).ceil();
    final snow = Paint();
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        if (random.nextDouble() > 0.12) continue;
        final grey = (80 + random.nextDouble() * 160).toInt();
        snow.color = Color.fromARGB(140, grey, grey, grey);
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5),
          snow,
        );
      }
    }

    // Heavy scanlines.
    final scan = Paint()..color = Colors.black.withValues(alpha: 0.28);
    for (var y = 0.0; y < size.height; y += 2.5) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1.2), scan);
    }

    // Rolling bar.
    final roll = ((time * 55) % (size.height + 40)) - 20;
    canvas.drawRect(
      Rect.fromLTWH(0, roll, size.width, 22),
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );

    // REW chevrons sweeping left.
    final chevronPaint = Paint()
      ..color = VhsColors.accent.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeJoin = StrokeJoin.round;

    final midY = size.height * 0.5;
    final amplitude = size.height * 0.18;
    final spacing = size.width * 0.14;
    final phase = (time * 2.8) % 1.0;

    for (var i = -1; i < 8; i++) {
      final cx = size.width - ((i + phase) * spacing);
      if (cx < -spacing || cx > size.width + spacing) continue;
      final path = Path()
        ..moveTo(cx + 18, midY - amplitude)
        ..lineTo(cx, midY)
        ..lineTo(cx + 18, midY + amplitude);
      canvas.drawPath(path, chevronPaint);
    }

    // OSD corner label.
    final tp = TextPainter(
      text: TextSpan(
        text: '◀◀ REW',
        style: TextStyle(
          color: VhsColors.accent.withValues(alpha: 0.9),
          fontSize: math.max(11, size.width * 0.045),
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width * 0.06, size.height * 0.08));
  }

  @override
  bool shouldRepaint(covariant _RewindPainter oldDelegate) =>
      oldDelegate.time != time;
}
