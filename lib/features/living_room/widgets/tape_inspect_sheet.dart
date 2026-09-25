import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_spine.dart';

/// Movie-info style popup: the tape's spine and details, then insert.
Future<void> showTapeInspectSheet(
  BuildContext context, {
  required Tape tape,
  required VoidCallback onInsert,
  required Future<void> Function() onRejectSleeve,
  VhsSpineArt? art,
  Future<VhsSpineArt?> Function()? loadArt,
}) {
  // Warm memory with the same ResizeImage keys the shelf already used so the
  // popup spine doesn't re-decode (disk cache still helps across launches).
  final images = <String>{
    if (tape.boxImageUrl != null && tape.boxImageUrl!.isNotEmpty)
      tape.boxImageUrl!,
    if (art?.imageUrl != null) art!.imageUrl,
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
    this.initialArt,
    this.loadArt,
  });

  final Tape tape;
  final VoidCallback onInsert;
  final Future<void> Function() onRejectSleeve;
  final bool desktop;
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
          constraints: BoxConstraints(
            maxWidth: widget.desktop ? 640 : 520,
            maxHeight: maxH,
          ),
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
                        child: _InfoBody(tape: widget.tape, art: art),
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
  const _InfoBody({required this.tape, required this.art});

  final Tape tape;
  final VhsSpineArt? art;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StandingSpine(tape: tape, art: art, height: wide ? 300 : 210),
            SizedBox(width: wide ? 28 : 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TapeTitleBlock(tape: tape),
                  SizedBox(height: wide ? 18 : 14),
                  _TapeMetaBlock(tape: tape),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The tape's spine standing upright — the one piece of sleeve art every
/// tape has, whether its scan is a full wraparound or a lone spine.
class _StandingSpine extends StatelessWidget {
  const _StandingSpine({
    required this.tape,
    required this.art,
    required this.height,
  });

  final Tape tape;
  final VhsSpineArt? art;
  final double height;

  @override
  Widget build(BuildContext context) {
    final width = height * VhsSpine.nominalWidth / VhsSpine.nominalHeight;
    return Semantics(
      image: true,
      label: '${tape.title} spine',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 18,
                  offset: const Offset(3, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (art != null)
                  VhsSleeveCrop(
                    url: art!.imageUrl,
                    widthFraction: art!.centerWidthFraction,
                  )
                else
                  ProceduralVhsSpine(tape: tape),
                // Plastic sleeve: a lit left edge and a soft sheen.
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.16),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.22),
                        ],
                        stops: const [0, 0.35, 1],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contact shadow on a sliver of shelf.
          Container(
            width: width + 24,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.14),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
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
