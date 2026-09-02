import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/presentation/vhs_spine.dart';

/// Pull up a zoomed spine + front cover before inserting a tape.
Future<void> showTapeInspectSheet(
  BuildContext context, {
  required Tape tape,
  required VoidCallback onInsert,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: EdgeInsets.fromLTRB(16, 14, 16, 16 + bottom),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A2418), Color(0xFF1A100C)],
        ),
        border: Border.all(color: Colors.black.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: VhsColors.brand.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            tape.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: vhsBrandStyle(size: 18).copyWith(letterSpacing: 1.5),
          ),
          if (tape.subtitle != null && tape.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              tape.subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: VhsColors.brand.withValues(alpha: 0.65),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 280,
            child: artAsync.when(
              data: (art) => _ArtStage(tape: tape, art: art),
              loading: () => _ArtStage(tape: tape, art: null),
              error: (_, _) => _ArtStage(tape: tape, art: null),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'BACK TO SHELF',
                    style: TextStyle(
                      color: VhsColors.brand.withValues(alpha: 0.75),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: VhsColors.accent,
                    foregroundColor: VhsColors.brand,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onInsert();
                  },
                  child: const Text(
                    'INSERT TAPE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
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

class _ArtStage extends StatelessWidget {
  const _ArtStage({required this.tape, required this.art});

  final Tape tape;
  final VhsSpineArt? art;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Zoomed spine
        AspectRatio(
          aspectRatio: 0.22,
          child: _Panel(
            label: 'SPINE',
            child: art != null
                ? VhsSleeveCrop(
                    url: art!.imageUrl,
                    widthFraction: art!.centerWidthFraction,
                  )
                : _FallbackSpine(title: tape.title),
          ),
        ),
        const SizedBox(width: 12),
        // Front / right-side box art
        Expanded(
          child: _Panel(
            label: 'FRONT',
            child: _FrontArt(tape: tape, art: art),
          ),
        ),
      ],
    );
  }
}

class _FrontArt extends StatelessWidget {
  const _FrontArt({required this.tape, required this.art});

  final Tape tape;
  final VhsSpineArt? art;

  @override
  Widget build(BuildContext context) {
    final dedicated = art?.frontImageUrl;
    if (dedicated != null && dedicated.isNotEmpty) {
      return Image.network(
        dedicated,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (_, _, _) => _jellyOrEmpty(),
      );
    }

    // Wraparound sleeve: right panel is typically the front cover.
    if (art != null && art!.isWraparound) {
      return VhsSleeveCrop(
        url: art!.imageUrl,
        // Front panel is roughly the right ~40% of a J-card.
        widthFraction: 0.42,
        alignment: Alignment.centerRight,
      );
    }

    // Dedicated spine only — fall back to Jellyfin poster / empty.
    return _jellyOrEmpty();
  }

  Widget _jellyOrEmpty() {
    final url = tape.imageUrl;
    if (url == null || url.isEmpty) {
      return const ColoredBox(
        color: Color(0xFF140E0A),
        child: Center(
          child: Text(
            'No front scan',
            style: TextStyle(color: VhsColors.brand, fontSize: 12),
          ),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF140E0A)),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: VhsColors.brand.withValues(alpha: 0.55),
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

class _FallbackSpine extends StatelessWidget {
  const _FallbackSpine({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = SpinePalette.fromTitle(title);
    return ColoredBox(
      color: palette.shell,
      child: RotatedBox(
        quarterTurns: 3,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.ink,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
