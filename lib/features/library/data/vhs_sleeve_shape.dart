import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/data/vhs_image_cache.dart';
import 'package:vhsfin/features/library/data/image_aspect_stub.dart'
    if (dart.library.js_interop) 'package:vhsfin/features/library/data/image_aspect_web.dart';

/// What a sleeve scan actually contains, judged by its proportions.
///
/// A VHS box is about 105 × 190 mm with a 25 mm spine, so a lone spine is
/// very tall and thin (≈0.13), a front is portrait (≈0.55), and a flat
/// BACK | SPINE | FRONT wraparound is landscape (≈1.25).
enum SleeveShape {
  spine,
  front,
  wraparound;

  static SleeveShape fromAspect(double aspect) => aspect < 0.35
      ? spine
      : aspect < 0.95
      ? front
      : wraparound;
}

/// Learns each sleeve image's proportions as it decodes, so a spine-only scan
/// saved as a Jellyfin Box isn't cropped like a wraparound, and a front cover
/// is only offered when the full sleeve exists.
abstract final class VhsSleeveShapes {
  static final Map<String, SleeveShape> _known = {};
  static final Map<String, Future<SleeveShape?>> _pending = {};

  static SleeveShape? of(String url) => _known[url];

  /// Resolves through the shared image cache, so a sleeve already on the
  /// shelf answers immediately.
  static Future<SleeveShape?> resolve(String url) {
    final known = _known[url];
    if (known != null) return SynchronousFuture(known);
    return _pending.putIfAbsent(url, () {
      final done = Completer<SleeveShape?>();
      final stream = VhsImageCache.provider(url)
          .resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) async {
          stream.removeListener(listener);
          final decoded = imageInfoAspect(info);
          try {
            info.dispose(); // listeners own the info they're handed
          } catch (_) {}
          final aspect = decoded ?? await urlImageAspect(url);
          final shape = aspect == null ? null : SleeveShape.fromAspect(aspect);
          if (shape != null) _known[url] = shape;
          if (!done.isCompleted) done.complete(shape);
        },
        onError: (_, _) {
          if (!done.isCompleted) done.complete(null);
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      return done.future.whenComplete(() => _pending.remove(url));
    });
  }

  /// Width fraction to crop from [art] for its spine, corrected by shape.
  static double spineFraction(VhsSpineArt art) =>
      of(art.imageUrl) == SleeveShape.spine ? 1 : art.centerWidthFraction;

  @visibleForTesting
  static void debugRecord(String url, SleeveShape shape) => _known[url] = shape;

  @visibleForTesting
  static void debugReset() {
    _known.clear();
    _pending.clear();
  }
}

/// The front of a VHS sleeve, when the art includes one.
typedef VhsFrontCover = ({String url, double widthFraction, Alignment align});

/// A dedicated front scan, or the right-hand panel of a confirmed wraparound.
/// Null for spine-only art or art whose shape isn't known yet.
VhsFrontCover? vhsFrontCoverOf(VhsSpineArt art) {
  final front = art.frontImageUrl;
  if (front != null && front.isNotEmpty) {
    return (url: front, widthFraction: 1, align: Alignment.center);
  }
  if (VhsSleeveShapes.of(art.imageUrl) != SleeveShape.wraparound) return null;
  final spine = art.isWraparound
      ? art.centerWidthFraction
      : VhsCoverResolver.wraparoundSpineFraction;
  return (
    url: art.imageUrl,
    widthFraction: (1 - spine) / 2,
    align: Alignment.centerRight,
  );
}
