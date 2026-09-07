import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/features/auth/state/session_notifier.dart';
import 'package:vhsfin/features/library/model/tape.dart';

final seriesEpisodesProvider =
    FutureProvider.autoDispose.family<List<Tape>, Tape>((ref, series) async {
  final session = await ref.watch(sessionProvider.future);
  if (session == null) return const [];
  return ref.watch(jellyfinClientProvider).fetchEpisodes(
        session: session,
        seriesId: series.id,
        libraryName: series.libraryName,
        seriesTitle: series.title,
      );
});
