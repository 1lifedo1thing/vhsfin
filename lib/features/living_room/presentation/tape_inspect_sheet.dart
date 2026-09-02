import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/data/vhs_sleeve_actions.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/presentation/vhs_spine.dart';

/// Movie-info style popup: front poster + spine, then insert.
Future<void> showTapeInspectSheet(
  BuildContext context, {
  required Tape tape,
  required VoidCallback onInsert,
}) {
  // Warm the image cache with the same URLs the shelf already resolved so the
  // popup spine doesn't flash empty while Image.network re-decodes.
  final images = <String>{
    if (tape.imageUrl != null && tape.imageUrl!.isNotEmpty) tape.imageUrl!,
    if (tape.boxImageUrl != null && tape.boxImageUrl!.isNotEmpty)
      tape.boxImageUrl!,
  };
  for (final url in images) {
    precacheImage(NetworkImage(url), context);
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (context) => _TapeInspectSheet(tape: tape, onInsert: onInsert),
  );
}

class _TapeInspectSheet extends ConsumerWidget {
  const _TapeInspectSheet({
    required this.tape,
    required this.onInsert,
  });

  final Tape tape;
  final VoidCallback onInsert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artAsync = ref.watch(vhsSpineArtProvider(tape));
    // Prefer already-resolved art — don't blank to procedural while refreshing.
    final art = artAsync.asData?.value;
    final spineUrl = art?.imageUrl;
    if (spineUrl != null) {
      precacheImage(NetworkImage(spineUrl), context);
      final front = art?.frontImageUrl;
      if (front != null) {
        precacheImage(NetworkImage(front), context);
      }
    }
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.82;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 520, maxHeight: maxH),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3E2A1E),
                    Color(0xFF241610),
                    Color(0xFF140E0A),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF6A4A32),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: VhsColors.phosphor.withValues(alpha: 0.06),
                    blurRadius: 18,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _PopupHeader(),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: _InfoBody(tape: tape, art: art),
                      ),
                    ),
                    _ActionBar(
                      showWrongSleeve: art != null,
                      onBack: () => Navigator.of(context).pop(),
                      onWrongSleeve: () async {
                        await rejectTapeSleeveArt(ref, tape);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Sleeve marked as a mismatch — using printed spine instead.',
                            ),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                      onInsert: () {
                        Navigator.of(context).pop();
                        onInsert();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PopupHeader extends StatelessWidget {
  const _PopupHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.45)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VhsColors.ledOn,
              boxShadow: [
                BoxShadow(
                  color: VhsColors.ledOn.withValues(alpha: 0.55),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'TAPE INFO',
            style: TextStyle(
              color: VhsColors.phosphor.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
            ),
          ),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: VhsColors.brand.withValues(alpha: 0.7),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBody extends StatelessWidget {
  const _InfoBody({required this.tape, required this.art});

  final Tape tape;
  final VhsSpineArt? art;

  static const _shelfLip = 7.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 400;
        final sleeve = _SleeveArt(
          tape: tape,
          art: art,
          height: wide ? 220 : 200,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sleeve,
                  const SizedBox(width: 16),
                  Expanded(child: _TapeTitleBlock(tape: tape)),
                ],
              )
            else
              Center(child: sleeve),
            // Full-width shelf — same content width as the title.
            CustomPaint(
              size: Size(constraints.maxWidth, 3),
              painter: const _ShelfSitLinePainter(),
            ),
            CustomPaint(
              size: Size(constraints.maxWidth, _shelfLip),
              painter: ShelfLipPainter(),
            ),
            const SizedBox(height: 14),
            if (!wide) ...[
              _TapeTitleBlock(tape: tape),
              const SizedBox(height: 14),
            ],
            _TapeMetaBlock(tape: tape),
          ],
        );
      },
    );
  }
}

/// Spine tilted against the Jellyfin cover — like a tape sitting on a shelf.
class _SleeveArt extends StatelessWidget {
  const _SleeveArt({
    required this.tape,
    required this.art,
    required this.height,
  });

  final Tape tape;
  final VhsSpineArt? art;
  final double height;

  static const _spineLean = 0.1; // ~5.7° into the cover
  static const _depthFace = 5.0;
  /// Open-edge clamshell curve — right side only; spine edge stays square.
  static const _vhsCorner = 14.0;

  @override
  Widget build(BuildContext context) {
    final sleeveH = height;
    final spineW = sleeveH * 0.17;
    final frontW = sleeveH * 0.72;
    // Room for the spine base to kick left when it leans into the poster.
    final leanPad = sleeveH * math.sin(_spineLean) + 6;
    // Same lean; less tuck so the spine sits further left of the cover.
    const tuck = 3.0;
    final totalW = leanPad + spineW + frontW - tuck + _depthFace;

    return SizedBox(
      width: totalW,
      height: sleeveH + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Soft contact shadow under the sleeve footprint.
          Positioned(
            left: leanPad * 0.2,
            right: 2,
            bottom: 1,
            height: 16,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: Colors.black.withValues(alpha: 0.18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: -1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: _depthFace,
            bottom: 0,
            child: _FrontSleeve(
              width: frontW,
              height: sleeveH,
              depth: _depthFace,
              cornerRadius: _vhsCorner,
              child: _FrontArt(tape: tape),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Transform.rotate(
              angle: _spineLean,
              alignment: Alignment.bottomCenter,
              child: _ArtFrame(
                width: spineW,
                height: sleeveH,
                elevated: true,
                borderRadius: BorderRadius.circular(2),
                child: art != null
                    ? VhsSleeveCrop(
                        url: art!.imageUrl,
                        widthFraction: art!.centerWidthFraction,
                      )
                    : ProceduralVhsSpine(tape: tape),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin highlight/shadow seam under the tape base.
class _ShelfSitLinePainter extends CustomPainter {
  const _ShelfSitLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.45;
    final glow = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.55),
          Colors.black.withValues(alpha: 0.7),
          Colors.black.withValues(alpha: 0.55),
          Colors.transparent,
        ],
        stops: const [0, 0.12, 0.5, 0.88, 1],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(2, y + 0.6), Offset(size.width - 2, y + 0.6), glow);

    final highlight = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF8A6A48).withValues(alpha: 0.55),
          const Color(0xFFC4A07A).withValues(alpha: 0.7),
          const Color(0xFF8A6A48).withValues(alpha: 0.55),
          Colors.transparent,
        ],
        stops: const [0, 0.1, 0.5, 0.9, 1],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), highlight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Front cover with a cardboard thickness face so it matches the spine’s depth.
class _FrontSleeve extends StatelessWidget {
  const _FrontSleeve({
    required this.width,
    required this.height,
    required this.depth,
    required this.cornerRadius,
    required this.child,
  });

  final double width;
  final double height;
  final double depth;
  final double cornerRadius;
  final Widget child;

  /// Square on the spine edge; rounded only on the open right edge.
  BorderRadius get _faceRadius => BorderRadius.only(
        topRight: Radius.circular(cornerRadius),
        bottomRight: Radius.circular(cornerRadius),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width + depth,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Right-edge thickness — short cardboard face of the clamshell.
          Positioned(
            right: 0,
            top: cornerRadius * 0.45,
            bottom: 1,
            width: depth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(cornerRadius * 0.35),
                ),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF3A281C),
                    const Color(0xFF1E140E),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 5,
                    offset: const Offset(2, 1),
                  ),
                ],
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: _ArtFrame(
              width: width,
              height: height,
              elevated: true,
              borderRadius: _faceRadius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  child,
                  // Plastic sleeve sheen.
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(cornerRadius - 1),
                          bottomRight: Radius.circular(cornerRadius - 1),
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.07),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.14),
                          ],
                          stops: const [0, 0.45, 1],
                        ),
                      ),
                    ),
                  ),
                  // Edge bevels (no radius — parent already clips).
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          right: BorderSide(
                            color: Colors.black.withValues(alpha: 0.42),
                          ),
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          bottom: BorderSide(
                            color: Colors.black.withValues(alpha: 0.28),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtFrame extends StatelessWidget {
  const _ArtFrame({
    required this.width,
    required this.height,
    required this.child,
    this.elevated = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(3)),
  });

  final double width;
  final double height;
  final Widget child;
  final bool elevated;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: borderRadius,
        border: Border.all(color: const Color(0xFF4A3828)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: elevated ? 0.58 : 0.45),
            blurRadius: elevated ? 16 : 10,
            offset: Offset(elevated ? 4 : 2, elevated ? 8 : 4),
          ),
          if (elevated)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 3,
              offset: const Offset(1, 2),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _TapeTitleBlock extends StatelessWidget {
  const _TapeTitleBlock({required this.tape});

  final Tape tape;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tape.title,
          style: vhsBrandStyle(size: 22).copyWith(
            letterSpacing: 1.1,
            height: 1.15,
          ),
        ),
        if (tape.subtitle != null && tape.subtitle!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            tape.subtitle!,
            style: TextStyle(
              color: VhsColors.brand.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _TapeMetaBlock extends StatelessWidget {
  const _TapeMetaBlock({required this.tape});

  final Tape tape;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetaChip(label: _kindLabel(tape)),
            if (tape.productionYear != null)
              _MetaChip(label: '${tape.productionYear}'),
            if (tape.duration != null)
              _MetaChip(label: _formatDuration(tape.duration!)),
            if (tape.episodeCount != null)
              _MetaChip(label: '${tape.episodeCount} EPS'),
            if (tape.officialRating != null &&
                tape.officialRating!.isNotEmpty)
              _MetaChip(label: tape.officialRating!),
            if (tape.communityRating != null)
              _MetaChip(label: _formatRating(tape.communityRating!)),
            for (final genre in tape.genres.take(3))
              _MetaChip(label: genre.toUpperCase(), dim: true),
            if (tape.libraryName != null && tape.libraryName!.isNotEmpty)
              _MetaChip(label: tape.libraryName!.toUpperCase(), dim: true),
          ],
        ),
        const SizedBox(height: 16),
        if (tape.overview != null && tape.overview!.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SYNOPSIS',
                  style: TextStyle(
                    color: VhsColors.phosphor.withValues(alpha: 0.75),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tape.overview!,
                  style: TextStyle(
                    color: VhsColors.brand.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          )
        else if (tape.genres.isNotEmpty)
          Text(
            tape.genres.take(4).join(' · '),
            style: TextStyle(
              color: VhsColors.brand.withValues(alpha: 0.55),
              fontSize: 12,
              height: 1.4,
            ),
          ),
      ],
    );
  }

  static String _kindLabel(Tape tape) {
    return switch (tape.kind) {
      TapeKind.movie => 'MOVIE',
      TapeKind.series => 'SERIES',
      TapeKind.episode => 'EPISODE',
    };
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}H ${m.toString().padLeft(2, '0')}M';
    return '${m}M';
  }

  static String _formatRating(double rating) {
    final rounded = (rating * 10).round() / 10;
    if (rounded == rounded.roundToDouble()) {
      return '${rounded.toInt()}/10';
    }
    return '${rounded.toStringAsFixed(1)}/10';
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.dim = false});

  final String label;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: dim
            ? Colors.black.withValues(alpha: 0.35)
            : VhsColors.phosphor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: dim
              ? Colors.white.withValues(alpha: 0.08)
              : VhsColors.phosphor.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: dim
              ? VhsColors.brand.withValues(alpha: 0.55)
              : VhsColors.phosphor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onBack,
    required this.onInsert,
    required this.showWrongSleeve,
    this.onWrongSleeve,
  });

  final VoidCallback onBack;
  final VoidCallback onInsert;
  final bool showWrongSleeve;
  final VoidCallback? onWrongSleeve;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1410),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showWrongSleeve && onWrongSleeve != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onWrongSleeve,
                style: TextButton.styleFrom(
                  foregroundColor: VhsColors.brand.withValues(alpha: 0.55),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'WRONG SLEEVE · not this tape',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VhsColors.brand,
                    side: BorderSide(
                      color: VhsColors.brand.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: onBack,
                  child: const Text(
                    'BACK',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: VhsColors.accent,
                    foregroundColor: VhsColors.brand,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: onInsert,
                  child: const Text(
                    'INSERT TAPE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FrontArt extends StatelessWidget {
  const _FrontArt({required this.tape});

  final Tape tape;

  @override
  Widget build(BuildContext context) {
    final url = tape.imageUrl;
    if (url == null || url.isEmpty) {
      return const ColoredBox(
        color: Color(0xFF140E0A),
        child: Center(
          child: Text(
            'No cover',
            style: TextStyle(color: VhsColors.brand, fontSize: 12),
          ),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF140E0A)),
    );
  }
}
