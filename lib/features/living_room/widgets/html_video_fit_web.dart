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
  try {
    final handle = await player.handle;
    final instances = globalContext.getProperty(_kInstances.toJS) as JSObject?;
    if (instances != null) {
      final byString = instances.getProperty(handle.toString().toJS);
      final byNumber = instances.getProperty(handle.toJS);
      final raw = byString ?? byNumber;
      if (raw != null) {
        _styleVideo(raw as web.HTMLVideoElement, cover: cover);
      }
    }
  } catch (_) {
    // Fall through to querySelectorAll.
  }

  // Fallback: style every media_kit video on the page.
  final videos = web.document.querySelectorAll('video');
  for (var i = 0; i < videos.length; i++) {
    final node = videos.item(i);
    if (node != null) {
      _styleVideo(node as web.HTMLVideoElement, cover: cover);
    }
  }
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
