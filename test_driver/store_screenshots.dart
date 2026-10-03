// Host side of integration_test/store_screenshots_test.dart: saves each
// takeScreenshot() image. They arrive after the test ends, so the app's own
// capture is used rather than a host-side simulator screenshot.
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() {
  final out = Platform.environment['SHOT_DIR'] ?? 'build/store_screenshots';
  Directory(out).createSync(recursive: true);
  return integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      File('$out/$name.png').writeAsBytesSync(bytes);
      return true;
    },
  );
}
