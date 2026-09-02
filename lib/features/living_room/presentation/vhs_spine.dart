import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/model/tape.dart';

/// Bookshelf VHS spine — real sleeve crop when IA has art, else procedural.
class VhsSpine extends ConsumerWidget {
  const VhsSpine({
    super.key,
    required this.tape,
    this.selected = false,
    this.onTap,
    this.height = 168,
  });

  final Tape tape;
  final bool selected;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = SpinePalette.fromTitle(tape.title);
    final artAsync = ref.watch(vhsSpineArtProvider(tape));
    final width = selected ? 34.0 : 28.0;
    final tip = selected ? 0.0 : _tipRadians(tape.id);
    // Rotation around the bottom swings the top into neighbors — reserve that
    // horizontal room so tipped spines don't overlap.
    final swing = height * tip.abs();
    final slotWidth = width + swing * 2 + 10;

    return Semantics(
      button: true,
      label: tape.kind == TapeKind.series
          ? 'Open series ${tape.title}'
          : 'Play ${tape.title}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: slotWidth,
          height: height + 8,
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: Offset(0, selected ? -14 : 0),
            child: Transform.rotate(
              angle: tip,
              alignment: Alignment.bottomCenter,
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: selected ? 0.55 : 0.35),
                      blurRadius: selected ? 14 : 8,
                      offset: Offset(selected ? 4 : 2, selected ? 8 : 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: artAsync.when(
                    data: (art) {
                      if (art != null) {
                        return _RealSpine(art: art);
                      }
                      return _ProceduralSpine(tape: tape, palette: palette);
                    },
                    loading: () =>
                        _ProceduralSpine(tape: tape, palette: palette),
                    error: (_, _) =>
                        _ProceduralSpine(tape: tape, palette: palette),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A few spines lean slightly — kept small so neighbors don't collide.
  static double _tipRadians(String id) {
    final hash = id.codeUnits.fold<int>(0, (a, b) => (a * 33 + b) & 0xffff);
    if (hash % 6 != 0) return 0;
    final magnitude = 0.018 + (hash % 4) * 0.006; // ~1°–2.3°
    return hash.isEven ? magnitude : -magnitude;
  }
}
class _RealSpine extends StatelessWidget {
  const _RealSpine({required this.art});

  final VhsSpineArt art;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        VhsSleeveCrop(
          url: art.imageUrl,
          widthFraction: art.centerWidthFraction,
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
                right: BorderSide(
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.12),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows a vertical strip of a VHS sleeve scan (spine) or a side panel (front).
class VhsSleeveCrop extends StatelessWidget {
  const VhsSleeveCrop({
    super.key,
    required this.url,
    required this.widthFraction,
    this.alignment = Alignment.center,
  });

  final String url;

  /// Horizontal fraction of the source image to keep.
  final double widthFraction;

  /// Which part of the source to keep when cropping (center = spine,
  /// centerRight ≈ front panel on a BACK|SPINE|FRONT wraparound).
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final fraction = widthFraction.clamp(0.02, 1.0);
        final dpr = MediaQuery.devicePixelRatioOf(context);
        if (fraction >= 0.99) {
          return Image.network(
            url,
            fit: BoxFit.fitHeight,
            width: w,
            height: h,
            alignment: Alignment.center,
            cacheHeight: (h * dpr).ceil().clamp(64, 1600),
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black),
          );
        }

        return ClipRect(
          child: Align(
            alignment: alignment,
            widthFactor: fraction,
            heightFactor: 1,
            child: SizedBox(
              height: h,
              child: Image.network(
                url,
                height: h,
                fit: BoxFit.fitHeight,
                alignment: Alignment.center,
                cacheHeight: (h * dpr).ceil().clamp(160, 1600),
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: Colors.black),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProceduralSpine extends StatelessWidget {
  const _ProceduralSpine({
    required this.tape,
    required this.palette,
  });

  final Tape tape;
  final SpinePalette palette;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: palette.shell),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 7,
          child: tape.imageUrl == null
              ? ColoredBox(color: palette.accent)
              : Image.network(
                  tape.imageUrl!,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerLeft,
                  errorBuilder: (_, _, _) =>
                      ColoredBox(color: palette.accent),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(9, 10, 4, 10),
          child: RotatedBox(
            quarterTurns: 3,
            child: Text(
              tape.title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                height: 1,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 16,
            width: double.infinity,
            color: palette.label,
            alignment: Alignment.center,
            child: Text(
              tape.kind == TapeKind.series
                  ? 'TV'
                  : tape.kind == TapeKind.episode
                      ? (tape.subtitle ?? 'EP')
                      : 'VHS',
              style: TextStyle(
                color: palette.labelInk,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                right: BorderSide(
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SpinePalette {
  const SpinePalette({
    required this.shell,
    required this.ink,
    required this.accent,
    required this.label,
    required this.labelInk,
  });

  final Color shell;
  final Color ink;
  final Color accent;
  final Color label;
  final Color labelInk;

  static SpinePalette fromTitle(String title) {
    final hash = title.toLowerCase().codeUnits.fold<int>(
      0,
      (value, unit) => (value * 31 + unit) & 0x7fffffff,
    );
    const shells = <Color>[
      Color(0xFF1A1A1C),
      Color(0xFF2B241C),
      Color(0xFF243038),
      Color(0xFF3A1E1A),
      Color(0xFF1E2A22),
      Color(0xFF2A2430),
      Color(0xFFE7DCC8),
      Color(0xFFD9D3C5),
    ];
    const accents = <Color>[
      VhsColors.accent,
      Color(0xFF2F6FED),
      Color(0xFFD4A017),
      Color(0xFF2E8B57),
      Color(0xFF8B4513),
      Color(0xFF6A5ACD),
    ];
    final shell = shells[hash % shells.length];
    final light = shell.computeLuminance() > 0.45;
    return SpinePalette(
      shell: shell,
      ink: light ? const Color(0xFF1A120C) : VhsColors.brand,
      accent: accents[(hash ~/ 7) % accents.length],
      label: accents[(hash ~/ 13) % accents.length],
      labelInk: VhsColors.brand,
    );
  }
}

/// Wood plank under a row of spines.
class ShelfPlank extends StatelessWidget {
  const ShelfPlank({super.key, required this.child, required this.title});

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: vhsBrandStyle(size: 15).copyWith(letterSpacing: 2.5),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4A2E1C),
                Color(0xFF2A1810),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          child: Column(
            children: [
              SizedBox(height: 180, child: child),
              const SizedBox(height: 8),
              CustomPaint(
                size: const Size(double.infinity, 10),
                painter: ShelfLipPainter(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ShelfLipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6A4228), Color(0xFF3A2416)],
      ).createShader(Offset.zero & size);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - 4, size.height)
      ..lineTo(4, size.height)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
