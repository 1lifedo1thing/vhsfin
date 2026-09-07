import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:vhsfin/features/living_room/widgets/html_video_fit_stub.dart'
    if (dart.library.js_interop) 'package:vhsfin/features/living_room/widgets/html_video_fit_web.dart';

/// CRT video that letterboxes inside a 4:3 frame.
///
/// On web, Flutter layout/`BoxFit` cannot letterbox HtmlElementView — the real
/// DOM `<video>` must use `object-fit: contain` while filling the CRT.
class LetterboxedVideo extends StatefulWidget {
  const LetterboxedVideo({
    super.key,
    required this.player,
    required this.controller,
    this.opacity = 1,
  });

  final Player player;
  final VideoController controller;
  final double opacity;

  @override
  State<LetterboxedVideo> createState() => _LetterboxedVideoState();
}

class _LetterboxedVideoState extends State<LetterboxedVideo> {
  HtmlVideoContainKeeper? _keeper;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _keeper = HtmlVideoContainKeeper(widget.player)..start();
    }
  }

  @override
  void didUpdateWidget(covariant LetterboxedVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) {
      _keeper?.stop();
      if (kIsWeb) {
        _keeper = HtmlVideoContainKeeper(widget.player)..start();
      }
    }
  }

  @override
  void dispose() {
    _keeper?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Web: fill the 4:3 CRT; browser letterboxes via object-fit:contain.
    // Native: FittedBox/BoxFit.contain works — still fill parent.
    return ColoredBox(
      color: Colors.black,
      child: Opacity(
        opacity: widget.opacity,
        child: Video(
          controller: widget.controller,
          controls: NoVideoControls,
          fill: Colors.black,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
