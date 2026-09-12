import 'package:flutter/material.dart';

/// Walnut at a fixed physical scale: crop and tile, never stretch the grain.
class WalnutSurface extends StatelessWidget {
  const WalnutSurface({
    super.key,
    required this.child,
    this.recessed = false,
    this.radius = 3,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final bool recessed;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: const Color(0xFF3D281B),
      image: const DecorationImage(
        image: ExactAssetImage('assets/branding/walnut.jpg', scale: 2),
        fit: BoxFit.none,
        repeat: ImageRepeat.repeat,
        alignment: Alignment.topLeft,
        filterQuality: FilterQuality.medium,
      ),
      boxShadow: recessed
          ? null
          : const [
              BoxShadow(
                color: Color(0xAA080503),
                blurRadius: 3,
                offset: Offset(0, 3),
              ),
            ],
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: recessed
              ? const [Color(0xD9000000), Color(0x70000000), Color(0xB0000000)]
              : const [Color(0x407E5C38), Color(0x08000000), Color(0x70000000)],
          stops: const [0, 0.22, 1],
        ),
        border: Border.all(
          color: recessed ? const Color(0xB0000000) : const Color(0x407C6248),
        ),
      ),
      child: Padding(padding: padding, child: child),
    ),
  );
}

/// A rounded solid-wood front edge with a lit upper bevel.
class CabinetLedge extends StatelessWidget {
  const CabinetLedge({super.key, this.height = 18});
  final double height;

  @override
  Widget build(BuildContext context) => WalnutSurface(
    radius: 3,
    child: SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x50D7AD78), Color(0x007D522E), Color(0xCC160B05)],
            stops: [0, 0.25, 1],
          ),
          border: const Border(
            top: BorderSide(color: Color(0xA8D3A16C), width: 1),
            bottom: BorderSide(color: Color(0xD00E0704), width: 1),
          ),
        ),
      ),
    ),
  );
}
