import 'dart:js_interop';

import 'package:flutter/painting.dart';
import 'package:web/web.dart' as web;

/// Width ÷ height of a decoded image, when it was decoded to pixels.
///
/// Cross-origin sleeves load as `<img>` elements on web, whose [ImageInfo]
/// has no pixel image; [urlImageAspect] covers those.
double? imageInfoAspect(ImageInfo info) {
  try {
    final image = info.image;
    return image.height == 0 ? null : image.width / image.height;
  } catch (_) {
    return null;
  }
}

/// Natural proportions of [url] via an `<img>` (served from browser cache).
Future<double?> urlImageAspect(String url) async {
  try {
    final img = web.HTMLImageElement()..src = url;
    await img.decode().toDart;
    if (img.naturalHeight == 0) return null;
    return img.naturalWidth / img.naturalHeight;
  } catch (_) {
    return null;
  }
}
