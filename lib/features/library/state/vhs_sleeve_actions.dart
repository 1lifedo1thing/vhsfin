import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/features/auth/state/session_notifier.dart';
import 'package:vhsfin/features/library/data/vhs_image_cache.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/library/state/shelf_display_prefs.dart';
import 'package:vhsfin/features/library/state/tape_library.dart';
import 'package:vhsfin/features/library/state/vhs_art_rejects.dart';
import 'package:vhsfin/features/library/state/vhs_spine_art.dart';

/// Reject the sleeve currently shown for [tape] — local blacklist + optional
/// Jellyfin Box delete + long-lived resolver miss so the wrong match
/// (e.g. 1989 Catch Me If You Can on the 2002 title) does not come back.
Future<void> rejectTapeSleeveArt(ProviderContainer container, Tape tape) async {
  final art = container.read(vhsSpineArtProvider(tape)).asData?.value;
  if (art == null) return;

  final boxTag = boxTagFromUrl(tape.boxImageUrl);
  final hadOwnBox = tape.hasBoxImage;
  await container.read(vhsArtRejectsProvider.notifier).reject(
        tapeId: tape.id,
        imageUrl: art.imageUrl,
        boxImageUrl: tape.boxImageUrl,
        boxTag: boxTag,
      );

  // Remapped TV episodes share a season-level cache key. Rejecting an episode's
  // own Jellyfin Box must not mark the whole season as a miss.
  final sharesSeasonLookup = tape.kind == TapeKind.episode;
  if (!(hadOwnBox && sharesSeasonLookup)) {
    await container.read(vhsCoverResolverProvider).forceMiss(
          title: tape.title,
          year: tape.productionYear,
          seriesTitle: tape.seriesTitle,
          seasonNumber: tape.seasonNumber,
          kind: tape.kind,
        );
  }

  final session = container.read(sessionProvider).value;
  if (session != null && hadOwnBox) {
    await container.read(jellyfinClientProvider).deleteBoxImage(
          session: session,
          itemId: tape.id,
        );
  }

  // Drop decoded/disk copies so a later URL reuse doesn't flash the old sleeve.
  await VhsImageCache.evict(art.imageUrl);
  if (tape.boxImageUrl != null && tape.boxImageUrl!.isNotEmpty) {
    await VhsImageCache.evict(tape.boxImageUrl!);
  }

  container.read(vhsArtIndexProvider.notifier).mark(tape.id, hasVhsArt: false);
  container.invalidate(vhsSpineArtProvider(tape));
  container.invalidate(shelvesProvider);
}
