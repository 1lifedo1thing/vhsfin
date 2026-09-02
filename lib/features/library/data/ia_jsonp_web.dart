import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

var _callbackSeq = 0;

@JS('JSON.stringify')
external JSString _jsonStringify(JSAny? value);

/// JSONP fetch — archive.org search/metadata omit CORS, but support callback=.
Future<Map<String, dynamic>> iaJsonp(String url) async {
  final name = 'vhsfin_ia_cb_${_callbackSeq++}';
  final completer = Completer<Map<String, dynamic>>();
  final sep = url.contains('?') ? '&' : '?';
  final src = '$url${sep}callback=$name';

  final script = web.HTMLScriptElement()..async = true;

  void cleanup() {
    globalContext.setProperty(name.toJS, null);
    script.remove();
  }

  final jsCb = ((JSAny? data) {
    try {
      final raw = _jsonStringify(data).toDart;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (!completer.isCompleted) completer.complete(decoded);
    } catch (err) {
      if (!completer.isCompleted) completer.completeError(err);
    } finally {
      cleanup();
    }
  }).toJS;

  globalContext.setProperty(name.toJS, jsCb);
  script.src = src;
  script.onError.listen((_) {
    cleanup();
    if (!completer.isCompleted) {
      completer.completeError(StateError('JSONP failed: $src'));
    }
  });
  web.document.head?.append(script);

  return completer.future.timeout(
    const Duration(seconds: 15),
    onTimeout: () {
      cleanup();
      throw TimeoutException('JSONP timeout: $src');
    },
  );
}
