import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/data/vhs_image_cache.dart';
import 'package:vhsfin/features/library/data/vhs_sleeve_shape.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/model/cabinet_style.dart';
import 'package:vhsfin/features/living_room/widgets/cabinet_material.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_spine.dart';

/// Movie-info style popup: front poster + spine, then insert.
Future<void> showTapeInspectSheet(
  BuildContext context, {
  required Tape tape,
  required VoidCallback onInsert,
  required Future<void> Function() onRejectSleeve,
  VhsSpineArt? art,
  Future<VhsSpineArt?> Function()? loadArt,
  bool useVhsCover = false,
  CabinetStyle cabinetStyle = CabinetStyle.walnut,
}) {
  // Warm memory with the same ResizeImage keys the shelf already used so the
  // popup spine doesn't re-decode (disk cache still helps across launches).
  final images = <String>{
    if (tape.imageUrl != null && tape.imageUrl!.isNotEmpty) tape.imageUrl!,
    if (tape.boxImageUrl != null && tape.boxImageUrl!.isNotEmpty)
      tape.boxImageUrl!,
    if (art?.imageUrl != null) art!.imageUrl,
    if (art?.frontImageUrl != null) art!.frontImageUrl!,
  };
  for (final url in images) {
    precacheImage(VhsSleeveCrop.providerFor(url), context);
  }

  final desktop = MediaQuery.sizeOf(context).width >= 720;
  final content = _TapeInspectSheet(
    tape: tape,
    onInsert: onInsert,
    onRejectSleeve: onRejectSleeve,
    initialArt: art,
    loadArt: loadArt,
    desktop: desktop,
    useVhsCover: useVhsCover,
    cabinetStyle: cabinetStyle,
  );
  if (desktop) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => content,
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (_) => content,
  );
}

class _TapeInspectSheet extends StatefulWidget {
  const _TapeInspectSheet({
    required this.tape,
    required this.onInsert,
    required this.onRejectSleeve,
    required this.desktop,
    required this.useVhsCover,
    required this.cabinetStyle,
    this.initialArt,
    this.loadArt,
  });

  final Tape tape;
  final VoidCallback onInsert;
  final Future<void> Function() onRejectSleeve;
  final bool desktop;
  final bool useVhsCover;
  final CabinetStyle cabinetStyle;
  final VhsSpineArt? initialArt;
  final Future<VhsSpineArt?> Function()? loadArt;

  @override
  State<_TapeInspectSheet> createState() => _TapeInspectSheetState();
}

class _TapeInspectSheetState extends State<_TapeInspectSheet> {
  late VhsSpineArt? _art = widget.initialArt;

  @override
  void initState() {
    super.initState();
    if (_art == null && widget.loadArt != null) {
      widget.loadArt!().then((art) {
        if (!mounted || art == null) return;
        setState(() => _art = art);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final art = _art;
    // Prefer already-resolved art — don't blank to procedural while refreshing.
    final spineUrl = art?.imageUrl;
    if (spineUrl != null) {
      precacheImage(VhsSleeveCrop.providerFor(spineUrl), context);
      final front = art?.frontImageUrl;
      if (front != null) {
        precacheImage(VhsSleeveCrop.providerFor(front), context);
      }
    }
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.82;
    final outerPadding = widget.desktop
        ? const EdgeInsets.all(24)
        : EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom);

    return Padding(
      padding: outerPadding,
      child: Align(
        alignment: widget.desktop ? Alignment.center : Alignment.bottomCenter,
        heightFactor: widget.desktop ? null : 1,
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
                    VhsColors.surfaceRaised,
                    VhsColors.surface,
                    VhsColors.surface,
                  ],
                ),
                border: Border.all(color: VhsColors.line),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: VhsColors.accent.withValues(alpha: 0.06),
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
                    _PopupHeader(
                      showWrongSleeve: art != null,
                      onWrongSleeve: () async {
                        await widget.onRejectSleeve();
                        if (!mounted) return;
                        setState(() => _art = null);
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
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: CabinetScope(
                          style: widget.cabinetStyle,
                          child: _InfoBody(
                            tape: widget.tape,
                            art: art,
                            useVhsCover: widget.useVhsCover,
                          ),
                        ),
                      ),
                    ),
                    _ActionBar(
                      onBack: () => Navigator.of(context).pop(),
                      onInsert: () {
                        Navigator.of(context).pop();
                        widget.onInsert();
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
  const _PopupHeader({required this.showWrongSleeve, this.onWrongSleeve});

  final bool showWrongSleeve;
  final VoidCallback? onWrongSleeve;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 10),
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
              color: VhsColors.accent.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
            ),
          ),
          const Spacer(),
          if (showWrongSleeve && onWrongSleeve != null)
            PopupMenuButton<_TapeMenuAction>(
              tooltip: 'More',
              padding: EdgeInsets.zero,
              offset: const Offset(0, 36),
              color: VhsColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              icon: Icon(
                Icons.more_vert_rounded,
                color: VhsColors.ink.withValues(alpha: 0.7),
                size: 22,
              ),
              onSelected: (action) {
                if (action == _TapeMenuAction.wrongSleeve) {
                  onWrongSleeve!();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _TapeMenuAction.wrongSleeve,
                  child: Text(
                    'Wrong sleeve',
                    style: TextStyle(
                      color: VhsColors.ink.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: VhsColors.ink.withValues(alpha: 0.7),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

enum _TapeMenuAction { wrongSleeve }

class _InfoBody extends StatelessWidget {
  const _InfoBody({
    required this.tape,
    required this.art,
    required this.useVhsCover,
  });

  final Tape tape;
  final VhsSpineArt? art;
  final bool useVhsCover;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: _SleeveArt(
            tape: tape,
            art: art,
            useVhsCover: useVhsCover,
            height: 210,
          ),
        ),
        // The tape stands on a strip of the same shelf as the living room.
        const CabinetLedge(height: 9, grain: Alignment(0.4, -0.3)),
        const SizedBox(height: 14),
        _TapeTitleBlock(tape: tape),
        const SizedBox(height: 14),
        _TapeMetaBlock(tape: tape),
      ],
    );
  }
}

/// Spine tilted against the Jellyfin cover — like a tape sitting on a shelf.
class _SleeveArt extends StatelessWidget {
  const _SleeveArt({
    required this.tape,
    required this.art,
    required this.useVhsCover,
    required this.height,
  });

  final Tape tape;
  final VhsSpineArt? art;
  final bool useVhsCover;
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
              child: _FrontArt(tape: tape, art: useVhsCover ? art : null),
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
                    const Color(0xFF2B2E31),
                    const Color(0xFF16181A),
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
        border: Border.all(color: VhsColors.line),
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
          style: vhsBrandStyle(size: 22)
              .copyWith(letterSpacing: 1.1, height: 1.15),
        ),
        if (tape.subtitle != null && tape.subtitle!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            tape.subtitle!,
            style: TextStyle(
              color: VhsColors.ink.withValues(alpha: 0.7),
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
            if (tape.officialRating != null && tape.officialRating!.isNotEmpty)
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
                    color: VhsColors.accent.withValues(alpha: 0.75),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tape.overview!,
                  style: TextStyle(
                    color: VhsColors.ink.withValues(alpha: 0.7),
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
              color: VhsColors.ink.withValues(alpha: 0.55),
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
            : VhsColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: dim
              ? Colors.white.withValues(alpha: 0.08)
              : VhsColors.accent.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: dim ? VhsColors.ink.withValues(alpha: 0.55) : VhsColors.accent,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onBack, required this.onInsert});

  final VoidCallback onBack;
  final VoidCallback onInsert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: VhsColors.surfaceSunken,
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: VhsColors.ink,
                side: BorderSide(color: VhsColors.ink.withValues(alpha: 0.35)),
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
                backgroundColor: VhsColors.record,
                foregroundColor: VhsColors.ink,
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
    );
  }
}

/// Jellyfin's poster, or — with VHS covers on — the sleeve's own front when
/// the scan includes one. Spine-only scans keep the poster.
class _FrontArt extends StatefulWidget {
  const _FrontArt({required this.tape, this.art});

  final Tape tape;
  final VhsSpineArt? art;

  @override
  State<_FrontArt> createState() => _FrontArtState();
}

class _FrontArtState extends State<_FrontArt> {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _learnShape();
  }

  @override
  void didUpdateWidget(_FrontArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.art?.imageUrl != widget.art?.imageUrl) _learnShape();
  }

  void _learnShape() {
    final art = widget.art;
    if (art == null || art.frontImageUrl != null) return;
    if (VhsSleeveShapes.of(art.imageUrl) != null) return;
    _checking = true;
    VhsSleeveShapes.resolve(art.imageUrl).then((_) {
      if (mounted) setState(() => _checking = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final art = widget.art;
    final cover = art == null ? null : vhsFrontCoverOf(art);
    if (cover != null) {
      return cover.widthFraction >= 0.99
          ? VhsImageCache.image(
              url: cover.url,
              fit: BoxFit.cover,
              memCacheHeight: null,
              errorBuilder: (_, _, _) => _poster(),
            )
          : VhsSleeveCrop(
              url: cover.url,
              widthFraction: cover.widthFraction,
              alignment: cover.align,
            );
    }
    // Hold a blank face for the moment it takes to measure the scan, rather
    // than flashing the poster and swapping it.
    if (_checking) return const ColoredBox(color: VhsColors.surfaceSunken);
    return _poster();
  }

  Widget _poster() {
    final url = widget.tape.imageUrl;
    if (url == null || url.isEmpty) {
      return const ColoredBox(
        color: VhsColors.surfaceSunken,
        child: Center(
          child: Text(
            'No cover',
            style: TextStyle(color: VhsColors.inkMuted, fontSize: 12),
          ),
        ),
      );
    }
    return VhsImageCache.image(
      url: url,
      fit: BoxFit.cover,
      memCacheHeight: null,
      errorBuilder: (_, _, _) =>
          const ColoredBox(color: VhsColors.surfaceSunken),
    );
  }
}
