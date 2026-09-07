import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vhsfin/constants/theme.dart';

/// Animated TV static for a powered-off CRT.
class StaticScreen extends StatefulWidget {
  const StaticScreen({super.key, this.intensity = 1});

  final double intensity;

  @override
  State<StaticScreen> createState() => _StaticScreenState();
}

class _StaticScreenState extends State<StaticScreen>
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
    return ColoredBox(
      color: Colors.black,
      child: CustomPaint(
        painter: _StaticPainter(time: _time, intensity: widget.intensity),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _StaticPainter extends CustomPainter {
  _StaticPainter({required this.time, required this.intensity});

  final double time;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random((time * 60).floor());
    final cell = 3.0;
    final cols = (size.width / cell).ceil();
    final rows = (size.height / cell).ceil();
    final paint = Paint();

    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final v = random.nextDouble();
        final grey = (40 + v * 200 * intensity).clamp(0, 255).toInt();
        paint.color = Color.fromARGB(255, grey, grey, grey);
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5),
          paint,
        );
      }
    }

    // Soft phosphor wash so it still feels like a CRT.
    final wash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          VhsColors.phosphor.withValues(alpha: 0.04),
          Colors.transparent,
          VhsColors.phosphor.withValues(alpha: 0.06),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wash);
  }

  @override
  bool shouldRepaint(covariant _StaticPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.intensity != intensity;
  }
}
