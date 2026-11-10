import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/constants/build_flags.dart';
import 'package:vhsfin/features/auth/state/session_notifier.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/data/vhs_image_cache.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/library/state/shelf_display_prefs.dart';
import 'package:vhsfin/features/library/state/vhs_art_rejects.dart';

/// Bundled sleeves for the open-movie demo shelf (`assets/demo_sleeves/`):
/// a dedicated spine and a front cover per film.
VhsSpineArt? demoSleeveArt(Tape tape) {
  const prefix = 'demo-';
  if (!tape.id.startsWith(prefix)) return null;
  final slug = tape.id.substring(prefix.length);
  const base = '${VhsImageCache.assetScheme}assets/demo_sleeves';
  return VhsSpineArt(
    imageUrl: '$base/$slug-spine.webp',
    centerWidthFraction: 1,
    frontImageUrl: '$base/$slug-front.webp',
  );
}

final vhsCoverResolverProvider = Provider<VhsCoverResolver>((ref) {
  final useCollector = ref.watch(
    shelfDisplayPrefsProvider.select((p) => p.vhsCollector),
  );
  return VhsCoverResolver(useCollector: vhsCollectorBuild && useCollector);
});

/// Resolves spine art for a tape: Jellyfin Box image first, else remote lookup.
///
/// Ordinary TV episodes reuse one season-level lookup (see
/// [VhsCoverResolver.lookupIdentity]). Auto-saves remote hits as Jellyfin
/// `Box` for **movies only** — never for series/episodes (same-name film
/// collisions like Arthur), and never overwrites an existing Box.
///
/// User rejections ([vhsArtRejectsProvider]) skip a bad Box tag and block the
/// matched URL; the resolver title key is forced to a long-lived miss.
final vhsSpineArtProvider = FutureProvider.family<VhsSpineArt?, Tape>((
  ref,
  tape,
) async {
  final rejectsNotifier = ref.watch(vhsArtRejectsProvider.notifier);
  ref.watch(vhsArtRejectsProvider);
  await rejectsNotifier.ready;

  // "Wrong sleeve" — never resurrect via Box, season cache, or collector HIT.
  if (rejectsNotifier.shouldSuppressArt(tape.id)) {
    return null;
  }

  final ignoreBox = rejectsNotifier.shouldIgnoreBox(tape.id, tape.boxImageUrl);

  if (tape.hasBoxImage && !ignoreBox) {
    return VhsSpineArt(imageUrl: tape.boxImageUrl!);
  }

  // Open-movie samples never had a retail VHS release: they get the bundled
  // sleeves made for them, and never a remote lookup.
  if (tape.isDemo) return demoSleeveArt(tape);

  final art = await ref
      .watch(vhsCoverResolverProvider)
      .spineArtFor(
        title: tape.title,
        year: tape.productionYear,
        seriesTitle: tape.seriesTitle,
        seasonNumber: tape.seasonNumber,
        kind: tape.kind,
      );
  if (art == null) return art;

  if (rejectsNotifier.isUrlBlocked(tape.id, art.imageUrl)) {
    return null;
  }

  // Don't write series/episode Box back to Jellyfin — a deleted wrong match
  // would otherwise keep resurrecting (Arthur PBS ← Arthur movie).
  if (tape.kind != TapeKind.movie) return art;

  // Re-check after the await — a reject may have landed during lookup/save.
  if (rejectsNotifier.shouldSuppressArt(tape.id) ||
      rejectsNotifier.isUrlBlocked(tape.id, art.imageUrl)) {
    return null;
  }

  final session = ref.watch(sessionProvider).value;
  if (session == null) return art;

  final client = ref.watch(jellyfinClientProvider);
  // saveBoxImageFromUrl also re-checks ImageTags and refuses overwrite.
  final saved = await client.saveBoxImageFromUrl(
    session: session,
    itemId: tape.id,
    imageUrl: art.imageUrl,
  );
  if (saved) {
    if (rejectsNotifier.shouldSuppressArt(tape.id)) {
      // Race: user rejected while the upload was in flight — drop the Box.
      await client.deleteBoxImage(session: session, itemId: tape.id);
      return null;
    }
    debugPrint('vhs-spine saved Box to Jellyfin for "${tape.title}"');
    return VhsSpineArt(
      imageUrl:
          '${session.normalizedServerUrl}/Items/${tape.id}/Images/Box'
          '?maxHeight=900&quality=85&ApiKey=${session.accessToken}',
      centerWidthFraction: art.centerWidthFraction,
    );
  }
  return art;
});
