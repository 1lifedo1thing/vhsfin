import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:media_kit/media_kit.dart';
import 'package:web/web.dart' as web;

/// Force the real DOM <video> to fill CRT **height** inside the 4:3 frame.
///
/// Flutter's BoxFit / FittedBox are ignored by HtmlElementView on web
/// (platform views size independently).
Future<void> applyHtmlVideoObjectFitContain(
  Player player, {
  bool cover = true,
}) async {
  _ensureGlobalContainStyle();
  final playerVideo = await _videoForPlayer(player);
  if (playerVideo != null) {
    _styleVideo(
      playerVideo,
      cover: cover && web.document.fullscreenElement != playerVideo,
    );
    return;
  }

  // Fallback: style every media_kit video on the page.
  final videos = web.document.querySelectorAll('video');
  for (var i = 0; i < videos.length; i++) {
    final node = videos.item(i);
    if (node != null) {
      final video = node as web.HTMLVideoElement;
      _styleVideo(
        video,
        cover: cover && web.document.fullscreenElement != video,
      );
    }
  }
}

Future<web.HTMLVideoElement?> _videoForPlayer(Player player) async {
  try {
    final handle = await player.handle;
    final instances = globalContext.getProperty(_kInstances.toJS) as JSObject?;
    if (instances != null) {
      final byString = instances.getProperty(handle.toString().toJS);
      final byNumber = instances.getProperty(handle.toJS);
      final raw = byString ?? byNumber;
      if (raw != null) {
        return raw as web.HTMLVideoElement;
      }
    }
  } catch (_) {
    // Fall through to querySelectorAll.
  }

  return web.document.querySelector('video') as web.HTMLVideoElement?;
}

/// Fullscreens the existing DOM video instead of rebuilding Flutter's web
/// platform view. Native video controls provide a one-step exit.
Future<bool> enterHtmlVideoFullscreen(Player player) async {
  // Keep requestFullscreen in the original click task. Awaiting player.handle
  // first can consume the browser's transient user activation.
  final video = web.document.querySelector('video') as web.HTMLVideoElement?;
  if (video == null) return false;

  try {
    video.controls = true;
    _styleVideo(video, cover: false);
    await video.requestFullscreen().toDart;
  } catch (_) {
    video.controls = false;
    _styleVideo(video, cover: true);
    return false;
  }

  Timer.periodic(const Duration(milliseconds: 150), (timer) {
    if (web.document.fullscreenElement != null) return;
    timer.cancel();
    video.controls = false;
    _styleVideo(video, cover: true);
    unawaited(player.play());
  });
  return true;
}

void _styleVideo(web.HTMLVideoElement video, {required bool cover}) {
  // Fill the CRT box height; crop sides for widescreen, pillarbox if narrower.
  // object-fit: cover in a 4:3 frame ≈ fitHeight for typical 16:9 streams.
  video.style.cssText = [
    'width: 100%',
    'height: 100%',
    'max-width: 100%',
    'max-height: 100%',
    'object-fit: ${cover ? 'cover' : 'contain'} !important',
    'object-position: center center',
    'background-color: #000000',
    'border: none',
  ].join(';');
  video.style.setProperty(
    'object-fit',
    cover ? 'cover' : 'contain',
    'important',
  );
}

var _injectedStyle = false;

void _ensureGlobalContainStyle() {
  if (_injectedStyle) return;
  _injectedStyle = true;
  final style = web.HTMLStyleElement()..id = 'vhsfin-video-fit-height';
  style.textContent = '''
video,
flt-platform-view video,
flt-semantics video {
  width: 100% !important;
  height: 100% !important;
  object-fit: cover !important;
  object-position: center center !important;
  background-color: #000 !important;
}
''';
  web.document.head?.append(style);
}

const _kInstances = r'$com.alexmercerind.media_kit.instances';

/// Keep re-applying while the CRT surface is mounted (Flutter may reset styles).
class HtmlVideoContainKeeper {
  HtmlVideoContainKeeper(this.player, {this.cover = true});

  final Player player;
  final bool cover;
  Timer? _timer;

  void start() {
    _timer?.cancel();
    unawaited(applyHtmlVideoObjectFitContain(player, cover: cover));
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      unawaited(applyHtmlVideoObjectFitContain(player, cover: cover));
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
