import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/tape_library_provider.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/model/vcr_state.dart';
import 'package:vhsfin/features/living_room/presentation/tape_inspect_sheet.dart';
import 'package:vhsfin/features/living_room/presentation/vhs_spine.dart';

/// VCR-themed episode catalog for a TV series box set.
Future<void> showEpisodePicker(BuildContext context, {required Tape series}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => EpisodePickerSheet(series: series),
  );
}

final seriesEpisodesProvider =
    FutureProvider.autoDispose.family<List<Tape>, Tape>((ref, series) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return const [];
  return ref.watch(jellyfinClientProvider).fetchEpisodes(
        session: session,
        seriesId: series.id,
        libraryName: series.libraryName,
        seriesTitle: series.title,
      );
});

class EpisodePickerSheet extends ConsumerWidget {
  const EpisodePickerSheet({super.key, required this.series});

  final Tape series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesAsync = ref.watch(seriesEpisodesProvider(series));
    final loadedId = ref.watch(vcrDeckProvider).loadedTape?.id;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(context).height * 0.78,
          ),
          child: Material(
            color: const Color(0xFF2A1810),
            borderRadius: BorderRadius.circular(14),
            elevation: 18,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withValues(alpha: 0.45)),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3A2418), Color(0xFF1A100C)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TAPE SELECT',
                                style: TextStyle(
                                  color: VhsColors.brand.withValues(alpha: 0.5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                series.title.toUpperCase(),
                                style: vhsBrandStyle(size: 18)
                                    .copyWith(letterSpacing: 1.5),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: VhsColors.brand),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Text(
                      'Each episode is its own VHS — tap a spine for the art',
                      style: TextStyle(
                        color: VhsColors.brand.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: episodesAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: VhsColors.phosphor,
                        ),
                      ),
                      error: (error, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Could not load episodes.\n$error',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: VhsColors.brand.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                      data: (episodes) {
                        if (episodes.isEmpty) {
                          return Center(
                            child: Text(
                              'No tapes in this box.',
                              style: TextStyle(
                                color: VhsColors.brand.withValues(alpha: 0.6),
                              ),
                            ),
                          );
                        }
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            const padH = 20.0;
                            final inner =
                                (constraints.maxWidth - padH).clamp(1.0, 4000.0);
                            final perRow =
                                (inner / VhsSpine.nominalWidth).floor().clamp(1, 100);
                            final rows = <List<Tape>>[];
                            for (var i = 0; i < episodes.length; i += perRow) {
                              final end = (i + perRow < episodes.length)
                                  ? i + perRow
                                  : episodes.length;
                              rows.add(episodes.sublist(i, end));
                            }

                            return ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(10, 0, 10, 16),
                              itemCount: rows.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, rowIndex) {
                                final row = rows[rowIndex];
                                return SizedBox(
                                  height: 196,
                                  child: _EpisodeShelfRow(
                                    episodes: row,
                                    loadedId: loadedId,
                                    onTap: (episode) {
                                      showTapeInspectSheet(
                                        context,
                                        tape: episode,
                                        onInsert: () {
                                          Navigator.pop(context);
                                          ref
                                              .read(vcrDeckProvider.notifier)
                                              .insertTape(episode);
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
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

class _EpisodeShelfRow extends StatelessWidget {
  const _EpisodeShelfRow({
    required this.episodes,
    required this.loadedId,
    required this.onTap,
  });

  final List<Tape> episodes;
  final String? loadedId;
  final ValueChanged<Tape> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var used = 0.0;
        for (final episode in episodes) {
          used += episode.id == loadedId ? 34.0 : VhsSpine.nominalWidth;
        }
        final leftover = constraints.maxWidth - used;
        final bookend = leftover > VhsSpine.nominalWidth * 0.75;
        const spineHeight = 148.0;
        final bookendTip = bookend
            ? VhsSpine.bookendTipFor(leftover: leftover, height: spineHeight)
            : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < episodes.length; i++)
                  VhsSpine(
                    tape: episodes[i],
                    height: spineHeight,
                    selected: episodes[i].id == loadedId,
                    tipRadians:
                        bookend && i == episodes.length - 1 && bookendTip != 0
                            ? bookendTip
                            : null,
                    onTap: () => onTap(episodes[i]),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final episode in episodes)
                  SizedBox(
                    width: episode.id == loadedId
                        ? 34
                        : VhsSpine.nominalWidth,
                    child: Text(
                      episode.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: episode.id == loadedId
                            ? VhsColors.phosphor
                            : VhsColors.brand,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
