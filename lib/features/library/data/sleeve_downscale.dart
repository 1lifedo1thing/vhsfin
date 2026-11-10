import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Tallest sleeve stored on the server. Spines draw at ~500–660 px, so this
/// keeps 2x+ headroom while turning 60 MB archive scans into ~1 MB JPEGs.
const sleeveMaxHeight = 1600;
const sleeveMaxWidth = 4096;
const _jpegQuality = 88;

/// [bytes] as a JPEG no larger than [sleeveMaxHeight] x [sleeveMaxWidth], or
/// unchanged when it is a JPEG already within bounds or smaller than the
/// re-encode. Null if undecodable.
Future<Uint8List?> downscaleSleeve(Uint8List bytes) async {
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? frame;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final width = descriptor.width;
    final height = descriptor.height;
    final scale = [
      1.0,
      sleeveMaxHeight / height,
      sleeveMaxWidth / width,
    ].reduce((a, b) => a < b ? a : b);
    if (scale == 1.0 && _isJpeg(bytes)) return bytes;

    final targetWidth = (width * scale).round();
    final targetHeight = (height * scale).round();
    codec = await descriptor.instantiateCodec(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    frame = (await codec.getNextFrame()).image;
    final rgba = await frame.toByteData();
    if (rgba == null) return null;
    final jpeg = await compute(_encodeJpeg, (
      width: frame.width,
      height: frame.height,
      rgba: rgba.buffer.asUint8List(),
    ));
    // A tight JPEG can grow when re-encoded; keep it then.
    return _isJpeg(bytes) && bytes.length <= jpeg.length ? bytes : jpeg;
  } catch (err) {
    debugPrint('sleeve downscale failed: $err');
    return null;
  } finally {
    frame?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}

bool _isJpeg(Uint8List bytes) =>
    bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;

Uint8List _encodeJpeg(({int width, int height, Uint8List rgba}) raw) {
  final image = img.Image.fromBytes(
    width: raw.width,
    height: raw.height,
    bytes: raw.rgba.buffer,
    numChannels: 4,
  );
  return img.encodeJpg(image, quality: _jpegQuality);
}
