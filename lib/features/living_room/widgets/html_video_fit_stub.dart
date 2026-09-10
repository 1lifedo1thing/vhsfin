import 'package:media_kit/media_kit.dart';

Future<void> applyHtmlVideoObjectFitContain(
  Player player, {
  bool cover = true,
}) async {}

Future<bool> enterHtmlVideoFullscreen(Player player) async => false;

class HtmlVideoContainKeeper {
  HtmlVideoContainKeeper(this.player, {this.cover = true});
  final Player player;
  final bool cover;
  void start() {}
  void stop() {}
}
