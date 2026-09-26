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
  static final Map<String, double> _aspects = {};
  static final Map<String, Future<double?>> _pending = {};

  /// Width ÷ height of [url], once it has been measured.
  static double? aspectOf(String url) => _aspects[url];

  static SleeveShape? of(String url) {
    final aspect = _aspects[url];
    return aspect == null ? null : SleeveShape.fromAspect(aspect);
  }

  /// Resolves through the shared image cache, so a sleeve already on the
  /// shelf answers immediately.
  static Future<double?> resolve(String url) {
    final known = _aspects[url];
    if (known != null) return SynchronousFuture(known);
    return _pending.putIfAbsent(url, () {
      final done = Completer<double?>();
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
          if (aspect != null) _aspects[url] = aspect;
          if (!done.isCompleted) done.complete(aspect);
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
  static void debugRecord(String url, double aspect) => _aspects[url] = aspect;

  @visibleForTesting
  static void debugReset() {
    _aspects.clear();
    _pending.clear();
  }
}

/// A horizontal strip of a sleeve image, as fractions of its width, with the
/// strip's own proportions so it can be shown without distortion.
typedef VhsFrontCover = ({
  String url,
  double left,
  double right,
  double aspect,
});

/// The front of a VHS sleeve, when the art includes one: a dedicated front
/// scan, or — on a measured BACK | SPINE | FRONT wraparound — the panel that
/// starts at the spine's right edge. Null for spine-only or unmeasured art.
VhsFrontCover? vhsFrontCoverOf(VhsSpineArt art) {
  final front = art.frontImageUrl;
  if (front != null && front.isNotEmpty) {
    final aspect = VhsSleeveShapes.aspectOf(front);
    if (aspect == null) return null;
    return (url: front, left: 0, right: 1, aspect: aspect);
  }
  final sleeve = VhsSleeveShapes.aspectOf(art.imageUrl);
  if (sleeve == null ||
      SleeveShape.fromAspect(sleeve) != SleeveShape.wraparound) {
    return null;
  }
  final spine = art.isWraparound
      ? art.centerWidthFraction
      : VhsCoverResolver.wraparoundSpineFraction;
  // The spine is the middle strip; the front is everything right of it.
  final left = 0.5 + spine / 2;
  return (
    url: art.imageUrl,
    left: left,
    right: 1.0,
    aspect: (1 - left) * sleeve,
  );
}
