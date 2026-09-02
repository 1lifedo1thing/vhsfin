import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/tape_library_provider.dart';
import 'package:vhsfin/features/library/model/shelf.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/model/vcr_state.dart';
import 'package:vhsfin/features/living_room/presentation/vhs_spine.dart';

class BookshelfView extends ConsumerWidget {
  const BookshelfView({super.key, this.embedded = false});

  /// When true, sits inside the wooden entertainment center (no outer plank chrome).
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelvesAsync = ref.watch(shelvesProvider);
    final loadedId = ref.watch(vcrDeckProvider).loadedTape?.id;
    final expandedId = ref.watch(expandedSeriesIdProvider);

    return shelvesAsync.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: VhsColors.phosphor),
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
              if (i > 0) const SizedBox(height: 16),
              _ShelfRow(
                shelf: shelves[i],
                loadedId: loadedId,
                expandedSeriesId: expandedId,
                embedded: embedded,
                showTitle: !embedded || shelves[i].isEpisodeShelf || shelves.length > 1,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ShelfRow extends ConsumerWidget {
  const _ShelfRow({
    required this.shelf,
    required this.loadedId,
    required this.expandedSeriesId,
    required this.embedded,
    required this.showTitle,
  });

  final Shelf shelf;
  final String? loadedId;
  final String? expandedSeriesId;
  final bool embedded;
  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = shelf.items.isEmpty
        ? Center(
            child: Text(
              shelf.id == 'empty'
                  ? 'Pick a collection below'
                  : 'Empty shelf',
              style: TextStyle(
                color: VhsColors.brand.withValues(alpha: 0.55),
              ),
            ),
          )
        : ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: shelf.items.length,
            itemBuilder: (context, index) {
              final tape = shelf.items[index];
              final selected = tape.id == loadedId ||
                  (tape.kind == TapeKind.series &&
                      tape.id == expandedSeriesId);
              return VhsSpine(
                tape: tape,
                selected: selected,
                onTap: () => _onTap(ref, tape),
              );
            },
          );

    if (embedded) {
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
          Container(
            height: 188,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black.withValues(alpha: 0.28),
              border: Border.all(color: Colors.black.withValues(alpha: 0.35)),
            ),
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
            child: body,
          ),
          const SizedBox(height: 6),
          CustomPaint(
            size: const Size(double.infinity, 8),
            painter: ShelfLipPainter(),
          ),
        ],
      );
    }

    return ShelfPlank(title: shelf.title, child: SizedBox.expand(child: body));
  }

  void _onTap(WidgetRef ref, Tape tape) {
    if (tape.kind == TapeKind.series) {
      ref.read(expandedSeriesIdProvider.notifier).toggle(tape.id);
      return;
    }
    ref.read(vcrDeckProvider.notifier).insertTape(tape);
  }
}
