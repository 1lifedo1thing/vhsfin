import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:vhsfin/app_orientation.dart';

import 'package:vhsfin/features/living_room/widgets/html_video_fit_stub.dart'
    if (dart.library.js_interop) 'package:vhsfin/features/living_room/widgets/html_video_fit_web.dart';

/// CRT video inside a 4:3 frame — fills the screen **height**, pillarboxing
/// narrower content or cropping wider (16:9) on the sides.
///
/// On web, Flutter layout/`BoxFit` cannot size HtmlElementView — the real
/// DOM `<video>` must use height-filling object-fit while filling the CRT.
class LetterboxedVideo extends StatefulWidget {
  const LetterboxedVideo({
    super.key,
    required this.player,
    required this.controller,
    required this.videoKey,
    this.opacity = 1,
  });

  final Player player;
  final VideoController controller;
  final GlobalKey<VideoState> videoKey;
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
    // Fill the 4:3 CRT box; fitHeight matches screen height (pillarbox / side crop).
    return ColoredBox(
      color: Colors.black,
      child: Opacity(
        opacity: widget.opacity,
        child: SizedBox.expand(
          child: ClipRect(
            child: Video(
              key: widget.videoKey,
              controller: widget.controller,
              controls: (state) => state.isFullscreen()
                  ? AdaptiveVideoControls(state)
                  : const SizedBox.shrink(),
              onEnterFullscreen: _enterFullscreen,
              onExitFullscreen: _exitFullscreen,
              fit: BoxFit.fitHeight,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _enterFullscreen() async {
    await AppOrientation.enterVideoFullscreen();
    await _resumePlaybackAfterFullscreenChange();
  }

  Future<void> _exitFullscreen() async {
    await AppOrientation.leaveVideoFullscreen();
    await _resumePlaybackAfterFullscreenChange();
  }

  Future<void> _resumePlaybackAfterFullscreenChange() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await widget.player.play();
  }
}
