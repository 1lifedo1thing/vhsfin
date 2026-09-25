import 'package:flutter/painting.dart';

/// Width ÷ height of a decoded image, when it was decoded to pixels.
double? imageInfoAspect(ImageInfo info) {
  try {
    final image = info.image;
    return image.height == 0 ? null : image.width / image.height;
  } catch (_) {
    return null;
  }
}

/// Web-only fallback for images the engine kept as `<img>` elements.
Future<double?> urlImageAspect(String url) async => null;
