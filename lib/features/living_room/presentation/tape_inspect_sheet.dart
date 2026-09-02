import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/presentation/vhs_spine.dart';

/// Movie-info style popup: front poster + spine, then insert.
Future<void> showTapeInspectSheet(
  BuildContext context, {
  required Tape tape,
  required VoidCallback onInsert,
}) {
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
                        child: artAsync.when(
                          data: (art) => _InfoBody(tape: tape, art: art),
                          loading: () => _InfoBody(tape: tape, art: null),
                          error: (_, _) => _InfoBody(tape: tape, art: null),
                        ),
                      ),
                    ),
                    _ActionBar(
                      onBack: () => Navigator.of(context).pop(),
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 400;
        final sleeve = _SleeveArt(tape: tape, art: art, height: wide ? 220 : 200);

        final details = _DetailsColumn(tape: tape);

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sleeve,
              const SizedBox(width: 16),
              Expanded(child: details),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: sleeve),
            const SizedBox(height: 16),
            details,
          ],
        );
      },
    );
  }
}

/// Spine tilted against the Jellyfin cover — like a tape propped on the counter.
class _SleeveArt extends StatelessWidget {
  const _SleeveArt({
    required this.tape,
    required this.art,
    required this.height,
  });

  final Tape tape;
  final VhsSpineArt? art;
  final double height;

  static const _spineLean = 0.11; // ~6° into the cover

  @override
  Widget build(BuildContext context) {
    final spineW = height * 0.17;
    final frontW = height * 0.72;
    // Room for the spine base to kick left when it leans into the poster.
    final leanPad = height * math.sin(_spineLean) + 6;

    return SizedBox(
      width: leanPad + spineW + frontW - 8,
      height: height + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: _ArtFrame(
              width: frontW,
              height: height,
              child: _FrontArt(tape: tape),
            ),
          ),
          Positioned(
            left: leanPad * 0.15,
            bottom: 0,
            child: Transform.translate(
              offset: Offset(height * math.sin(_spineLean) * 0.15, 0),
              child: Transform.rotate(
                angle: _spineLean,
                alignment: Alignment.bottomCenter,
                child: _ArtFrame(
                  width: spineW,
                  height: height,
                  elevated: true,
                  child: art != null
                      ? VhsSleeveCrop(
                          url: art!.imageUrl,
                          widthFraction: art!.centerWidthFraction,
                        )
                      : ProceduralVhsSpine(tape: tape),
                ),
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
  });

  final double width;
  final double height;
  final Widget child;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF4A3828)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: elevated ? 0.55 : 0.45),
            blurRadius: elevated ? 14 : 10,
            offset: Offset(elevated ? 3 : 2, elevated ? 6 : 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }
}

class _DetailsColumn extends StatelessWidget {
  const _DetailsColumn({required this.tape});

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
        const SizedBox(height: 14),
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
            if (tape.libraryName != null && tape.libraryName!.isNotEmpty)
              _MetaChip(label: tape.libraryName!.toUpperCase(), dim: true),
          ],
        ),
        const SizedBox(height: 16),
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
                'READY TO LOAD',
                style: TextStyle(
                  color: VhsColors.phosphor.withValues(alpha: 0.75),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Press INSERT to feed this cassette into the deck. '
                'Playback stays on the CRT unless you go fullscreen.',
                style: TextStyle(
                  color: VhsColors.brand.withValues(alpha: 0.55),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
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
  const _ActionBar({required this.onBack, required this.onInsert});

  final VoidCallback onBack;
  final VoidCallback onInsert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1410),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: VhsColors.brand,
                side: BorderSide(
                  color: VhsColors.brand.withValues(alpha: 0.35),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
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
