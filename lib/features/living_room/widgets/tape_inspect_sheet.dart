import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vhsfin/constants/feedback.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/data/vhs_image_cache.dart';
import 'package:vhsfin/features/library/data/vhs_sleeve_shape.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/model/cabinet_style.dart';
import 'package:vhsfin/features/living_room/widgets/cabinet_material.dart';
import 'package:vhsfin/features/living_room/widgets/deck_panel.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_spine.dart';

/// Movie-info style popup: front poster + spine, then insert.
Future<void> showTapeInspectSheet(
  BuildContext context, {
  required Tape tape,
  required VoidCallback onInsert,
  required Future<void> Function() onRejectSleeve,
  VhsSpineArt? art,
  Future<VhsSpineArt?> Function()? loadArt,
  bool useVhsCover = true,
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
    return DeckFeedback.sheet(
      () => showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.72),
        builder: (_) => content,
      ),
    );
  }
  return DeckFeedback.sheet(
    () => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => content,
    ),
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
    // Phones: rises from the bottom edge with no gap. Desktop: a dialog.
    final outerPadding = widget.desktop
        ? const EdgeInsets.all(24)
        : EdgeInsets.zero;

    return Padding(
      padding: outerPadding,
      child: Align(
        alignment: widget.desktop ? Alignment.center : Alignment.bottomCenter,
        heightFactor: widget.desktop ? null : 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 520, maxHeight: maxH),
          child: Material(
            type: MaterialType.transparency,
            child: DeckPanel(
              attachedToBottom: !widget.desktop,
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PopupHeader(
                    year: widget.tape.productionYear,
                    showWrongSleeve: art != null,
                    onWrongSleeve: () async {
                      await widget.onRejectSleeve();
                      if (!mounted) return;
                      setState(() => _art = null);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Wrong sleeve removed.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
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
                    bottomInset: widget.desktop ? 0 : bottom,
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
    );
  }
}

class _PopupHeader extends StatelessWidget {
  const _PopupHeader({
    required this.showWrongSleeve,
    this.year,
    this.onWrongSleeve,
  });

  final bool showWrongSleeve;
  final int? year;
  final VoidCallback? onWrongSleeve;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Same side insets as the body, so the X sits on its right edge.
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: DeckSheetHeader(
        title: 'TAPE INFO',
        detail: year?.toString(),
        onClose: () => Navigator.of(context).pop(),
        actions: [
          if (showWrongSleeve && onWrongSleeve != null)
            PopupMenuButton<_TapeMenuAction>(
              tooltip: 'More',
              enableFeedback: false,
              onOpened: DeckFeedback.tap,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 180),
              icon: const Icon(
                Icons.more_vert_rounded,
                color: VhsColors.inkMuted,
              ),
              color: VhsColors.surfaceRaised,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(),
              ),
              onSelected: (action) {
                DeckFeedback.tap();
                if (action == _TapeMenuAction.wrongSleeve) onWrongSleeve!();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _TapeMenuAction.wrongSleeve,
                  child: Text(
                    'Wrong sleeve',
                    style: TextStyle(
                      color: VhsColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
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
class _SleeveArt extends StatefulWidget {
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

  @override
  State<_SleeveArt> createState() => _SleeveArtState();
}

class _SleeveArtState extends State<_SleeveArt> {
  static const _spineLean = 0.1; // ~5.7° into the cover
  static const _depthFace = 5.0;

  /// Open-edge clamshell curve — right side only; spine edge stays square.
  static const _vhsCorner = 14.0;

  /// Jellyfin posters are 2:3; the box front is drawn a touch wider.
  static const _posterAspect = 0.72;

  var _measuring = false;

  Tape get tape => widget.tape;
  VhsSpineArt? get art => widget.art;

  @override
  void initState() {
    super.initState();
    _measure();
  }

  @override
  void didUpdateWidget(_SleeveArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.art?.imageUrl != widget.art?.imageUrl ||
        oldWidget.useVhsCover != widget.useVhsCover) {
      _measure();
    }
  }

  /// With VHS covers on, learn whether the scan has a front before choosing
  /// between it and the poster. Only the scan that could hold the front is
  /// measured: a dedicated spine goes straight to the poster.
  void _measure() {
    final art = widget.art;
    if (!widget.useVhsCover || art == null) return;
    final front = art.frontImageUrl;
    final url = front != null && front.isNotEmpty
        ? front
        : art.isWraparound
        ? art.imageUrl
        : null;
    if (url == null || VhsSleeveShapes.aspectOf(url) != null) return;
    _measuring = true;
    VhsSleeveShapes.resolve(url).whenComplete(() {
      if (mounted) setState(() => _measuring = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cover = widget.useVhsCover && art != null
        ? vhsFrontCoverOf(art!)
        : null;
    final sleeveH = widget.height;
    final spineW = sleeveH * 0.17;
    // The VHS front keeps its own proportions, so nothing is cropped off it.
    final frontW = sleeveH * (cover?.aspect.clamp(0.4, 1.2) ?? _posterAspect);
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
              child: _FrontArt(tape: tape, cover: cover, measuring: _measuring),
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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            // Recessed into the panel, like the tape window.
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B0C0E), Color(0xFF16181B)],
              ),
              border: Border.all(),
              boxShadow: const [
                BoxShadow(color: Color(0x14FFFFFF), offset: Offset(0, 1)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SYNOPSIS',
                  style: TextStyle(
                    color: Color(0xFFC9D1D4),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.6,
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
  const _ActionBar({
    required this.onBack,
    required this.onInsert,
    this.bottomInset = 0,
  });

  final VoidCallback onBack;
  final VoidCallback onInsert;

  /// Home-indicator clearance when the sheet runs into the bottom edge.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 8, 18, 18 + bottomInset),
      child: Row(
        children: [
          Expanded(
            child: DeckHardKey(label: 'BACK', onPressed: onBack),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: DeckHardKey(
              label: 'INSERT TAPE',
              tone: DeckKeyTone.record,
              onPressed: onInsert,
            ),
          ),
        ],
      ),
    );
  }
}

/// Jellyfin's poster, or the sleeve's own front when [cover] is set.
class _FrontArt extends StatelessWidget {
  const _FrontArt({
    required this.tape,
    required this.cover,
    required this.measuring,
  });

  final Tape tape;
  final VhsFrontCover? cover;

  /// Still learning whether the scan has a front — hold a blank face rather
  /// than flash the poster and swap it.
  final bool measuring;

  @override
  Widget build(BuildContext context) {
    final front = cover;
    if (front != null) {
      return SleeveRegion(
        url: front.url,
        imageAspect: VhsSleeveShapes.aspectOf(front.url)!,
        left: front.left,
        right: front.right,
      );
    }
    // Still learning whether the scan has a front: hold the blank box rather
    // than flash the poster and swap it.
    if (measuring) return const _BlankCassetteBox();
    final url = tape.imageUrl;
    if (url == null || url.isEmpty) {
      return const _BlankCassetteBox(noCover: true);
    }
    // Same decode size as the preload in showTapeInspectSheet, so an image
    // that's already warm paints at once; otherwise the blank box shows until
    // it arrives and the poster fades in over it.
    return VhsImageCache.image(
      url: url,
      fit: BoxFit.cover,
      placeholder: const _BlankCassetteBox(),
      fadeIn: const Duration(milliseconds: 150),
      errorBuilder: (_, _, _) => const _BlankCassetteBox(noCover: true),
    );
  }
}

/// A plain black video box with the format mark pressed into it — shown
/// while a cover loads, or when there's none.
class _BlankCassetteBox extends StatelessWidget {
  const _BlankCassetteBox({this.noCover = false});

  final bool noCover;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0D0E10),
      child: Center(
        child: Text(
          'VHS',
          semanticsLabel: noCover ? 'No cover' : 'Cover loading',
          style: vhsBrandStyle(size: 30).copyWith(
            color: const Color(0xFF1C1E21),
            letterSpacing: 4,
            shadows: const [
              Shadow(color: Color(0x14FFFFFF), offset: Offset(0, 1)),
              Shadow(color: Color(0xCC000000), offset: Offset(0, -1)),
            ],
          ),
        ),
      ),
    );
  }
}
