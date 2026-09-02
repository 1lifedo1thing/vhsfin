import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/shelf_display_prefs.dart';
import 'package:vhsfin/features/library/data/tape_library_provider.dart';
import 'package:vhsfin/features/library/model/shelf.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/model/vcr_state.dart';
import 'package:vhsfin/features/living_room/presentation/crt_loading_indicator.dart';
import 'package:vhsfin/features/living_room/presentation/episode_picker_sheet.dart';
import 'package:vhsfin/features/living_room/presentation/tape_inspect_sheet.dart';
import 'package:vhsfin/features/living_room/presentation/vhs_spine.dart';

class BookshelfView extends ConsumerWidget {
  const BookshelfView({super.key, this.embedded = false});

  /// When true, sits inside the wooden entertainment center.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelvesAsync = ref.watch(shelvesProvider);
    final displayPrefs = ref.watch(shelfDisplayPrefsProvider);
    // Art-index warm only matters for VHS-only filtering — skip the extra
    // rebuild storm while browsing the full shelf.
    final vhsArtIds = displayPrefs.vhsOnly
        ? ref.watch(vhsArtIndexProvider)
        : const <String>{};
    if (displayPrefs.vhsOnly) {
      ref.watch(vhsArtWarmProvider);
    }
    final loadedId = ref.watch(vcrDeckProvider).loadedTape?.id;
    final loadedSeriesId = ref.watch(vcrDeckProvider).loadedTape?.seriesId;

    return shelvesAsync.when(
      // Keep prior shelves visible while refreshing so episode picks don't
      // blank the console with a spinner.
      skipLoadingOnReload: true,
      loading: () => const SizedBox(
        height: 180,
        child: CrtLoadingIndicator(
          compact: true,
          style: CrtLoadStyle.tape,
          message: 'STAND BY',
        ),
      ),
      error: (error, _) => Text('Could not load shelves: $error'),
      data: (shelves) {
        if (shelves.isEmpty) {
          return const Text('No tapes on these shelves yet.');
        }
        return Column(
          children: [
            for (var i = 0; i < shelves.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              _ShelfBlock(
                shelf: Shelf(
                  id: shelves[i].id,
                  title: shelves[i].title,
                  items: applyShelfDisplayPrefs(
                    shelves[i].items,
                    displayPrefs,
                    vhsArtIds: vhsArtIds,
                  ),
                  parentSeriesId: shelves[i].parentSeriesId,
                ),
                loadedId: loadedId,
                loadedSeriesId: loadedSeriesId,
                embedded: embedded,
                showTitle: !embedded || shelves.length > 1,
                vhsOnly: displayPrefs.vhsOnly,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ShelfBlock extends ConsumerWidget {
  const _ShelfBlock({
    required this.shelf,
    required this.loadedId,
    required this.loadedSeriesId,
    required this.embedded,
    required this.showTitle,
    required this.vhsOnly,
  });

  final Shelf shelf;
  final String? loadedId;
  final String? loadedSeriesId;
  final bool embedded;
  final bool showTitle;
  final bool vhsOnly;

  /// Pack at upright spine thickness; tipped tapes add their own lean overhang.
  static const _spineSlotWidth = VhsSpine.nominalWidth;
  // Room for upright spines + lean slack inside the bay.
  static const _rowHeight = 192.0;
  static const _lipHeight = 8.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              shelf.title,
              style: vhsBrandStyle(size: 13).copyWith(letterSpacing: 2),
            ),
          ),
        if (shelf.items.isEmpty)
          _shelfBay(
            child: Center(
              child: Text(
                shelf.id == 'empty'
                    ? 'Pick collections below'
                    : vhsOnly
                        ? 'No VHS titles on this shelf'
                        : 'Empty shelf',
                style: TextStyle(
                  color: VhsColors.brand.withValues(alpha: 0.55),
                ),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              // Inner cavity width after horizontal padding.
              const padH = 16.0;
              final inner = (constraints.maxWidth - padH).clamp(1.0, 4000.0);
              final perRow = (inner / _spineSlotWidth).floor().clamp(1, 100);
              final rows = <List<Tape>>[];
              for (var i = 0; i < shelf.items.length; i += perRow) {
                final end = (i + perRow < shelf.items.length)
                    ? i + perRow
                    : shelf.items.length;
                rows.add(shelf.items.sublist(i, end));
              }

              return Column(
                children: [
                  for (var r = 0; r < rows.length; r++) ...[
                    if (r > 0) const SizedBox(height: 10),
                    _shelfBay(
                      child: _ShelfTapeRow(
                        tapes: rows[r],
                        loadedId: loadedId,
                        loadedSeriesId: loadedSeriesId,
                        onTap: (tape) => _onTap(context, ref, tape),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }

  /// Cavity + lip as one unit so spine bases sit on the wood edge.
  Widget _shelfBay({required Widget child}) {
    return SizedBox(
      height: _rowHeight + _lipHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: _lipHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                color: Colors.black.withValues(alpha: embedded ? 0.28 : 0.22),
                border: Border.all(color: Colors.black.withValues(alpha: 0.35)),
              ),
              child: Padding(
                // No bottom pad — spines rest on the cavity floor / lip seam.
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                child: child,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _lipHeight,
            child: const CustomPaint(painter: ShelfLipPainter()),
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, Tape tape) {
    if (tape.kind == TapeKind.series) {
      showEpisodePicker(context, series: tape);
      return;
    }
    showTapeInspectSheet(
      context,
      tape: tape,
      onInsert: () => ref.read(vcrDeckProvider.notifier).insertTape(tape),
    );
  }
}

/// Packed left-aligned spines; trailing tape bookends left when space remains.
class _ShelfTapeRow extends StatelessWidget {
  const _ShelfTapeRow({
    required this.tapes,
    required this.loadedId,
    required this.loadedSeriesId,
    required this.onTap,
  });

  final List<Tape> tapes;
  final String? loadedId;
  final String? loadedSeriesId;
  final ValueChanged<Tape> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var used = 0.0;
        for (final tape in tapes) {
          final selected = tape.id == loadedId ||
              (tape.kind == TapeKind.series && tape.id == loadedSeriesId);
          used += selected ? 34.0 : VhsSpine.nominalWidth;
        }
        final leftover = constraints.maxWidth - used;
        const baseHeight = 168.0;
        final tips = VhsSpine.tipsForRow(
          ids: tapes.map((t) => t.id).toList(),
          leftover: leftover,
          height: baseHeight,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < tapes.length; i++)
              RepaintBoundary(
                child: VhsSpine(
                  tape: tapes[i],
                  height: baseHeight,
                  selected: tapes[i].id == loadedId ||
                      (tapes[i].kind == TapeKind.series &&
                          tapes[i].id == loadedSeriesId),
                  tipRadians: tips[i],
                  onTap: () => onTap(tapes[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}
