import 'package:flutter/services.dart';

/// Owns app-level orientation and system chrome transitions.
abstract final class AppOrientation {
  static Future<void> lockPortrait() {
    return Future.wait([
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
    ]);
  }

  static Future<void> enterVideoFullscreen() {
    return Future.wait([
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: const [],
      ),
    ]);
  }

  static Future<void> leaveVideoFullscreen() => lockPortrait();
}
