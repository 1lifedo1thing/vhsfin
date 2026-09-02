import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/tape_library_provider.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/model/vcr_state.dart';
import 'package:vhsfin/features/living_room/presentation/vhs_cassette.dart';

class TapeShelf extends ConsumerWidget {
  const TapeShelf({super.key, required this.onSelect});

  final ValueChanged<Tape> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tapesAsync = ref.watch(tapeLibraryProvider);
    final loadedId = ref.watch(vcrDeckProvider).loadedTape?.id;

    return tapesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: VhsColors.phosphor),
      ),
      error: (error, _) => Text('Could not load tapes: $error'),
      data: (tapes) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PICK A TAPE',
              style: vhsBrandStyle(size: 18).copyWith(letterSpacing: 3),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tapes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final tape = tapes[index];
                  return VhsCassette(
                    tape: tape,
                    selected: tape.id == loadedId,
                    onTap: () => onSelect(tape),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
