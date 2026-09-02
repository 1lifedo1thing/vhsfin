import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/constants/theme.dart';
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
          style: CrtLoadStyle.snow,
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
                shelf: shelves[i],
                loadedId: loadedId,
                loadedSeriesId: loadedSeriesId,
                embedded: embedded,
                showTitle: !embedded || shelves.length > 1,
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
  });

  final Shelf shelf;
  final String? loadedId;
  final String? loadedSeriesId;
  final bool embedded;
  final bool showTitle;

  /// Pack at upright spine thickness; tipped tapes add their own lean overhang.
  static const _spineSlotWidth = VhsSpine.nominalWidth;
  static const _rowHeight = 186.0;

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
          _cavity(
            child: Center(
              child: Text(
                shelf.id == 'empty'
                    ? 'Pick collections below'
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
              // Inner cavity width after padding (matches _cavity padding).
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
                    if (r > 0) const SizedBox(height: 12),
                    _cavity(
                      child: _ShelfTapeRow(
                        tapes: rows[r],
                        loadedId: loadedId,
                        loadedSeriesId: loadedSeriesId,
                        onTap: (tape) => _onTap(context, ref, tape),
                      ),
                    ),
                    const SizedBox(height: 4),
                    CustomPaint(
                      size: const Size(double.infinity, 8),
                      painter: ShelfLipPainter(),
                    ),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _cavity({required Widget child}) {
    return Container(
      height: _rowHeight,
      width: double.infinity,
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black.withValues(alpha: embedded ? 0.28 : 0.22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
      child: child,
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
        final tips = VhsSpine.tipsForRow(
          ids: tapes.map((t) => t.id).toList(),
          leftover: leftover,
          height: 168,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < tapes.length; i++)
              VhsSpine(
                tape: tapes[i],
                selected: tapes[i].id == loadedId ||
                    (tapes[i].kind == TapeKind.series &&
                        tapes[i].id == loadedSeriesId),
                tipRadians: tips[i],
                onTap: () => onTap(tapes[i]),
              ),
          ],
        );
      },
    );
  }
}