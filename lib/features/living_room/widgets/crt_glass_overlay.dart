import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vhsfin/constants/theme.dart';

/// Lightweight CRT look that does NOT use BackdropFilter/ImageFilter —
/// those often blank media_kit video on web.
class CrtGlassOverlay extends StatefulWidget {
  const CrtGlassOverlay({super.key, this.enabled = true});

  final bool enabled;

  @override
  State<CrtGlassOverlay> createState() => _CrtGlassOverlayState();
}

class _CrtGlassOverlayState extends State<CrtGlassOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _time = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _time.value = elapsed.inMilliseconds / 1000;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant CrtGlassOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  void _syncTicker() {
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _CrtPainter(time: _time),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _CrtPainter extends CustomPainter {
  _CrtPainter({required this.time}) : super(repaint: time);

  final ValueNotifier<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scan = Paint()..color = Colors.black.withValues(alpha: 0.12);
    for (var y = 0.0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), scan);
    }

    final roll = ((time.value * 28) % size.height);
    canvas.drawRect(
      Rect.fromLTWH(0, roll, size.width, 18),
      Paint()..color = Colors.white.withValues(alpha: 0.03),
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.05),
          radius: 1.05,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = VhsColors.phosphor.withValues(alpha: 0.04),
    );
  }

  @override
  bool shouldRepaint(covariant _CrtPainter oldDelegate) =>
      oldDelegate.time != time;
}
