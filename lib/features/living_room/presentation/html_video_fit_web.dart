import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:media_kit/media_kit.dart';
import 'package:web/web.dart' as web;

/// Force letterboxing on the real DOM <video> — Flutter's BoxFit / FittedBox
/// are ignored by HtmlElementView on web (platform views size independently).
Future<void> applyHtmlVideoObjectFitContain(Player player) async {
  _ensureGlobalContainStyle();
  try {
    final handle = await player.handle;
    final instances =
        globalContext.getProperty(_kInstances.toJS) as JSObject?;
    if (instances != null) {
      final byString = instances.getProperty(handle.toString().toJS);
      final byNumber = instances.getProperty(handle.toJS);
      final raw = byString ?? byNumber;
      if (raw != null) {
        _styleVideo(raw as web.HTMLVideoElement);
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
      _styleVideo(node as web.HTMLVideoElement);
    }
  }
}

void _styleVideo(web.HTMLVideoElement video) {
  // cssText wins over piecemeal sets Flutter may overwrite next frame.
  video.style.cssText = [
    'width: 100%',
    'height: 100%',
    'max-width: 100%',
    'max-height: 100%',
    'object-fit: contain !important',
    'object-position: center center',
    'background-color: #000000',
    'border: none',
  ].join(';');
  video.style.setProperty('object-fit', 'contain', 'important');
}

var _injectedStyle = false;

void _ensureGlobalContainStyle() {
  if (_injectedStyle) return;
  _injectedStyle = true;
  final style = web.HTMLStyleElement()..id = 'vhsfin-video-contain';
  style.textContent = '''
video,
flt-platform-view video,
flt-semantics video {
  object-fit: contain !important;
  object-position: center center !important;
  background-color: #000 !important;
}
''';
  web.document.head?.append(style);
}

const _kInstances = r'$com.alexmercerind.media_kit.instances';

/// Keep re-applying while the CRT surface is mounted (Flutter may reset styles).
class HtmlVideoContainKeeper {
  HtmlVideoContainKeeper(this.player);

  final Player player;
  Timer? _timer;

  void start() {
    _timer?.cancel();
    unawaited(applyHtmlVideoObjectFitContain(player));
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      unawaited(applyHtmlVideoObjectFitContain(player));
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
