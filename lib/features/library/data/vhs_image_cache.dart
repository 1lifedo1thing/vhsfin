import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart'
    show ImageRenderMethodForWeb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// On-disk cache for VHS sleeve / poster bytes.
///
/// Flutter's [ImageCache] is memory-only and dies with the process. Closing the
/// app from Android recents wiped every spine until the next network fetch;
/// this keeps resized source files across launches.
///
/// On web, disk resize/fetch hits CORS for Archive.org / VHSCollector, while
/// HTML `<img>` loads work — so web warms via [precacheImage] only.
class VhsImageCache {
  VhsImageCache._();

  static const String key = 'vhsfin_sleeve_art_v2';

  /// Cap stored pixels — enough for shelf (~168dp) + inspect (~220dp) at ~3x.
  static const int diskMaxHeight = 768;
  static const int diskMaxWidth = 2048;

  /// Decode height shared by shelf spines + inspect so memory keys match.
  static const int sharedDecodeHeight = 640;

  static final CacheManager manager = VhsArtCacheManager();

  static ImageProvider provider(String url, {int? cacheHeight}) {
    final network = CachedNetworkImageProvider(
      url,
      cacheManager: manager,
      maxHeight: kIsWeb ? null : diskMaxHeight,
      maxWidth: kIsWeb ? null : diskMaxWidth,
      imageRenderMethodForWeb: ImageRenderMethodForWeb.HtmlImage,
    );
    final height = cacheHeight ?? sharedDecodeHeight;
    return ResizeImage(network, height: height);
  }

  /// Ensure [url] is in Flutter's image cache (and disk cache on mobile).
  static Future<void> warm(
    String url, {
    BuildContext? context,
  }) async {
    if (!kIsWeb) {
      try {
        final imageManager = manager as VhsArtCacheManager;
        await imageManager
            .getImageFile(
              url,
              maxHeight: diskMaxHeight,
              maxWidth: diskMaxWidth,
            )
            .firstWhere((response) => response is FileInfo);
      } catch (_) {
        // Still try [precacheImage] below.
      }
    }
    if (context == null || !context.mounted) return;
    await precacheImage(provider(url), context);
  }

  /// Drop memory + disk copies after a sleeve is marked wrong.
  static Future<void> evict(String url) async {
    await CachedNetworkImage.evictFromCache(
      url,
      cacheManager: manager,
    );
    imageCache.evict(provider(url));
    try {
      await manager.removeFile(url);
    } catch (_) {}
  }

  static Widget image({
    required String url,
    BoxFit fit = BoxFit.fitHeight,
    double? width,
    double? height,
    Alignment alignment = Alignment.center,
    int? memCacheHeight = sharedDecodeHeight,
    FilterQuality filterQuality = FilterQuality.medium,
    Widget Function(BuildContext, String, Object)? errorBuilder,
  }) {
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: manager,
      maxHeightDiskCache: kIsWeb ? null : diskMaxHeight,
      maxWidthDiskCache: kIsWeb ? null : diskMaxWidth,
      imageRenderMethodForWeb: ImageRenderMethodForWeb.HtmlImage,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      memCacheHeight: memCacheHeight,
      filterQuality: filterQuality,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      errorWidget: (context, failedUrl, error) {
        if (errorBuilder != null) {
          return errorBuilder(context, failedUrl, error);
        }
        return const ColoredBox(color: Colors.black);
      },
      placeholder: (_, _) => const ColoredBox(color: Colors.transparent),
    );
  }
}

class VhsArtCacheManager extends CacheManager with ImageCacheManager {
  VhsArtCacheManager()
      : super(
          Config(
            VhsImageCache.key,
            stalePeriod: const Duration(days: 365),
            maxNrOfCacheObjects: 800,
          ),
        );
}
