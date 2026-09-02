import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
    this.tipRadians,
  });

  /// Upright (non-selected) spine thickness — used for shelf packing.
  static const double nominalWidth = 28;

  /// Peak |angle| for a trailing bookend lean (~12.5°).
  static const double bookendTipAbs = 0.22;

  /// Tips large enough to kick the base opposite the lean (into empty shelf).
  static const double _kickTipThreshold = 0.055;

  /// Left-lean tip whose base kick (`h·sinθ` to the right) fits in [leftover].
  static double bookendTipFor({
    required double leftover,
    required double height,
    double maxAbs = bookendTipAbs,
    int salt = 0,
  }) {
    if (leftover <= 0) return 0;
    final maxSin = (leftover / height).clamp(0.0, 0.45);
    final maxTip = math.asin(maxSin);
    // Vary how hard this shelf leans (40%–100% of the allowed angle).
    final t = ((salt * 37) & 255) / 255.0;
    final target = maxAbs * (0.4 + 0.6 * t);
    return -math.min(target, maxTip);
  }

  /// Per-index tips for one packed row — varied so shelves don't all match.
  ///
  /// Large left leans only when there's leftover to the right (base kicks out).
  /// Smaller tips are rest-against leans with no base slide.
  static List<double?> tipsForRow({
    required List<String> ids,
    required double leftover,
    required double height,
  }) {
    final tips = List<double?>.filled(ids.length, null);
    if (ids.isEmpty) return tips;

    var seed = 0;
    for (final id in ids) {
      seed = (seed * 33 + id.hashCode) & 0x7fffffff;
    }

    // Casual micro-leans (~1/5 of tapes) — rest on a neighbor, no kick.
    for (var i = 0; i < ids.length; i++) {
      final h = ids[i].hashCode & 0xffff;
      if (h % 5 != 0) continue;
      final mag = 0.016 + (h % 5) * 0.005; // ~0.9°–2.3°
      tips[i] = h.isEven ? -mag : mag;
    }

    // Trailing lean into empty shelf — mode depends on the row's tapes.
    if (leftover > nominalWidth * 0.55) {
      final last = ids.length - 1;
      final mode = seed % 8;
      if (mode == 0) {
        // Neat row — leave casual tips only.
      } else if (mode == 1 || mode == 2) {
        tips[last] = bookendTipFor(
          leftover: leftover,
          height: height,
          maxAbs: 0.11,
          salt: seed,
        );
      } else if (mode == 3 || mode == 4) {
        tips[last] = bookendTipFor(
          leftover: leftover,
          height: height,
          maxAbs: 0.24,
          salt: seed,
        );
      } else if (mode == 5 && ids.length >= 2 && leftover > nominalWidth) {
        // Soft cascade: last two lean left, kicks share leftover.
        tips[last - 1] = bookendTipFor(
          leftover: leftover * 0.4,
          height: height,
          maxAbs: 0.09,
          salt: seed >> 2,
        );
        tips[last] = bookendTipFor(
          leftover: leftover * 0.7,
          height: height,
          maxAbs: 0.2,
          salt: seed,
        );
      } else {
        tips[last] = bookendTipFor(
          leftover: leftover,
          height: height,
          maxAbs: 0.18,
          salt: seed ^ 0xA5,
        );
      }
    }

    return tips;
  }

  final Tape tape;
  final bool selected;
  final VoidCallback? onTap;
  final double height;

  /// When set, overrides upright (e.g. bookend / casual lean).
  final double? tipRadians;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artAsync = ref.watch(vhsSpineArtProvider(tape));
    final width = selected ? 34.0 : nominalWidth;
    // Tip is visual only — layout width stays at [width] so rows never grow
    // past the shelf from leaning.
    final tip = selected ? 0.0 : (tipRadians ?? 0.0);
    // Strong left lean: top into the stack, base kicks right into empty shelf.
    final leanX = tip.abs() >= _kickTipThreshold
        ? -height * math.sin(tip)
        : 0.0;

    return Semantics(
      button: true,
      label: tape.kind == TapeKind.series
          ? 'Open series ${tape.title}'
          : 'Play ${tape.title}',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height + 8,
          child: Transform.translate(
            offset: Offset(leanX, selected ? -14 : 0),
            child: Transform.rotate(
              angle: tip,
              alignment: Alignment.bottomCenter,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: selected ? 0.55 : 0.35),
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
                        return ProceduralVhsSpine(tape: tape);
                      },
                      loading: () => ProceduralVhsSpine(tape: tape),
                      error: (_, _) => ProceduralVhsSpine(tape: tape),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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

/// Procedural VHS spine — translucent cover wash + printed title plate.
/// Shared by the bookshelf and the tape-info preview.
class ProceduralVhsSpine extends StatelessWidget {
  const ProceduralVhsSpine({super.key, required this.tape});

  final Tape tape;

  @override
  Widget build(BuildContext context) {
    // Episodes in a series share palette/plate so the box set matches.
    final styleKey = _styleKeyFor(tape);
    final palette = SpinePalette.fromTitle(styleKey);
    final hasCover = tape.imageUrl != null && tape.imageUrl!.isNotEmpty;
    final style = _ProceduralSpineStyle.fromTape(tape, palette);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasCover)
          Image.network(
            tape.imageUrl!,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, _, _) => ColoredBox(color: palette.shell),
          )
        else
          ColoredBox(color: palette.shell),
        // Dim wash — keeps the poster readable without a tinted shell cast.
        if (hasCover)
          ColoredBox(color: Colors.black.withValues(alpha: 0.48)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: hasCover ? 0.2 : 0.06),
                Colors.transparent,
                Colors.black.withValues(alpha: hasCover ? 0.35 : 0.14),
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
        // Top studio stripe
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            height: 7,
            width: double.infinity,
            color: style.stripe.withValues(alpha: hasCover ? 0.85 : 1),
          ),
        ),
        // Thin accent rail
        Positioned(
          left: 0,
          top: 7,
          bottom: 18,
          width: 3,
          child: ColoredBox(
            color: style.stripe.withValues(alpha: hasCover ? 0.7 : 1),
          ),
        ),
        // Title block — sticker / banner / ghost so it feels printed on the sleeve.
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 14, 3, 22),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Length along the spine (becomes vertical after rotate).
              final run = (constraints.maxHeight - 8).clamp(48.0, 220.0);
              return RotatedBox(
                quarterTurns: 1,
                child: SizedBox(
                  width: run,
                  child: _SpineTitlePlate(
                    title: tape.title,
                    style: style,
                    onArt: hasCover,
                  ),
                ),
              );
            },
          ),
        ),
        // Bottom catalog foot
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 18,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            color: style.foot.withValues(alpha: hasCover ? 0.78 : 1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  style.badge,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: style.footInk,
                    fontSize: 6.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    height: 1,
                  ),
                ),
                if (style.catalog.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    style.catalog,
                    maxLines: 1,
                    style: TextStyle(
                      color: style.footInk.withValues(alpha: 0.75),
                      fontSize: 5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      height: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
                right: BorderSide(
                  color: Colors.black.withValues(alpha: 0.38),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _TitlePlateKind { banner, ghost }

class _ProceduralSpineStyle {
  const _ProceduralSpineStyle({
    required this.stripe,
    required this.foot,
    required this.footInk,
    required this.badge,
    required this.catalog,
    required this.plate,
    required this.titleColor,
    required this.letterSpacing,
    required this.fontSize,
    required this.useDisplayFont,
  });

  final Color stripe;
  final Color foot;
  final Color footInk;
  final String badge;
  final String catalog;
  final _TitlePlateKind plate;
  final Color titleColor;
  final double letterSpacing;
  final double fontSize;
  final bool useDisplayFont;

  factory _ProceduralSpineStyle.fromTape(Tape tape, SpinePalette palette) {
    // Same show → same plate / wash / foot treatment.
    final seed = tape.seriesId ??
        (tape.seriesTitle != null && tape.seriesTitle!.isNotEmpty
            ? tape.seriesTitle!
            : tape.id);
    final hash = seed.codeUnits.fold<int>(0, (a, b) => (a * 33 + b) & 0xffff);
    final plate = _TitlePlateKind.values[hash % 2];
    final badges = <String>[
      if (tape.kind == TapeKind.series) 'TV SERIES',
      if (tape.kind == TapeKind.episode) (tape.subtitle ?? 'EPISODE'),
      if (tape.kind == TapeKind.movie) 'VHS',
      'HI-FI',
      'STEREO',
      if (tape.productionYear != null) '${tape.productionYear}',
      'CLAMSHELL',
    ];
    final badge = badges[hash % badges.length];
    final catalog =
        'C${(hash % 9000 + 1000)}-${(hash ~/ 7 % 90 + 10)}';

    return _ProceduralSpineStyle(
      stripe: palette.accent,
      foot: palette.label,
      footInk: palette.labelInk,
      badge: badge.toUpperCase(),
      catalog: hash % 3 == 0 ? '' : catalog,
      plate: plate,
      titleColor: VhsColors.brand,
      letterSpacing: 0.4 + (hash % 5) * 0.25,
      fontSize: 10.0 + (hash % 3),
      useDisplayFont: hash.isEven,
    );
  }
}

String _styleKeyFor(Tape tape) {
  if (tape.kind == TapeKind.episode &&
      tape.seriesTitle != null &&
      tape.seriesTitle!.isNotEmpty) {
    return tape.seriesTitle!;
  }
  return tape.title;
}

class _SpineTitlePlate extends StatelessWidget {
  const _SpineTitlePlate({
    required this.title,
    required this.style,
    required this.onArt,
  });

  final String title;
  final _ProceduralSpineStyle style;
  final bool onArt;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      title.toUpperCase(),
      maxLines: 2,
      softWrap: true,
      overflow: TextOverflow.clip,
      textAlign: TextAlign.center,
      style: (style.useDisplayFont
              ? GoogleFonts.bungee(
                  fontSize: style.fontSize,
                  letterSpacing: style.letterSpacing,
                  height: 1.05,
                )
              : TextStyle(
                  fontSize: style.fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: style.letterSpacing,
                  height: 1.05,
                ))
          .copyWith(
        color: style.titleColor,
        shadows: style.plate == _TitlePlateKind.ghost
            ? const [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 5,
                  offset: Offset(0, 1),
                ),
                Shadow(
                  color: Colors.black54,
                  blurRadius: 1,
                  offset: Offset(0, 0),
                ),
              ]
            : null,
      ),
    );

    switch (style.plate) {
      case _TitlePlateKind.banner:
        // Accent ink banner using the sleeve's stripe color.
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            color: style.stripe.withValues(alpha: onArt ? 0.82 : 0.95),
            borderRadius: BorderRadius.circular(1),
          ),
          child: text,
        );
      case _TitlePlateKind.ghost:
        // Printed directly on the art with a hard shadow — matches busy covers.
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: text,
        );
    }
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
