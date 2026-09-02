import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/tape_library_provider.dart';
import 'package:vhsfin/features/library/model/shelf.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/model/vcr_state.dart';
import 'package:vhsfin/features/living_room/presentation/vhs_spine.dart';

class BookshelfView extends ConsumerWidget {
  const BookshelfView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelvesAsync = ref.watch(shelvesProvider);
    final loadedId = ref.watch(vcrDeckProvider).loadedTape?.id;
    final expandedId = ref.watch(expandedSeriesIdProvider);

    return shelvesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
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
              if (i > 0) const SizedBox(height: 22),
              _ShelfRow(
                shelf: shelves[i],
                loadedId: loadedId,
                expandedSeriesId: expandedId,
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
  });

  final Shelf shelf;
  final String? loadedId;
  final String? expandedSeriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShelfPlank(
      title: shelf.title,
      child: shelf.items.isEmpty
          ? Center(
              child: Text(
                shelf.id == 'empty'
                    ? 'Pick libraries under SHELVES'
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
            ),
    );
  }

  void _onTap(WidgetRef ref, Tape tape) {
    if (tape.kind == TapeKind.series) {
      ref.read(expandedSeriesIdProvider.notifier).toggle(tape.id);
      return;
    }
    ref.read(vcrDeckProvider.notifier).insertTape(tape);
  }
}
