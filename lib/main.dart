import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:vhsfin/app_orientation.dart';
import 'package:vhsfin/constants/feedback.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DeckFeedback.richHaptics = true;
  MediaKit.ensureInitialized();
  await AppOrientation.lockPortrait();
  runApp(const ProviderScope(child: VhsFinApp()));
}

class VhsFinApp extends StatelessWidget {
  const VhsFinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VHSFin',
      debugShowCheckedModeBanner: false,
      theme: buildVhsTheme(),
      routerConfig: appRouter,
    );
  }
}
