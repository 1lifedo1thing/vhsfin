import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/tape_library_provider.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/model/vcr_state.dart';

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
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: Material(
            color: const Color(0xFF2A2A2E),
            borderRadius: BorderRadius.circular(12),
            elevation: 18,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF5A5A60)),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF3A3A40),
                    Color(0xFF1E1E22),
                    Color(0xFF141418),
                  ],
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
                                'EPISODE SELECT',
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
                  Container(
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF6A6A70),
                          Color(0xFFC8C8D0),
                          Color(0xFF5A5A60),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                              'No episodes in this box.',
                              style: TextStyle(
                                color: VhsColors.brand.withValues(alpha: 0.6),
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                          itemCount: episodes.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                          itemBuilder: (context, index) {
                            final episode = episodes[index];
                            final playing = episode.id == loadedId;
                            return ListTile(
                              dense: true,
                              selected: playing,
                              selectedTileColor:
                                  VhsColors.phosphor.withValues(alpha: 0.08),
                              leading: Container(
                                width: 44,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF101012),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: playing
                                        ? VhsColors.phosphor
                                        : Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Text(
                                  episode.subtitle ?? 'EP',
                                  style: TextStyle(
                                    color: playing
                                        ? VhsColors.phosphor
                                        : VhsColors.brand,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              title: Text(
                                episode.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: playing
                                      ? VhsColors.phosphor
                                      : VhsColors.brand,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Icon(
                                playing
                                    ? Icons.play_arrow_rounded
                                    : Icons.eject_rounded,
                                color: playing
                                    ? VhsColors.phosphor
                                    : VhsColors.brand.withValues(alpha: 0.45),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                ref
                                    .read(vcrDeckProvider.notifier)
                                    .insertTape(episode);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Text(
                      'Pick an episode to load into the VCR',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: VhsColors.brand.withValues(alpha: 0.4),
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
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
