import 'package:go_router/go_router.dart';
import 'package:vhsfin/features/auth/connect_page.dart';
import 'package:vhsfin/features/library/libraries_page.dart';
import 'package:vhsfin/features/living_room/living_room_page.dart';
import 'package:vhsfin/features/playback/clean_player_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LivingRoomPage(),
    ),
    GoRoute(
      path: '/connect',
      builder: (context, state) => const ConnectPage(),
    ),
    GoRoute(
      path: '/libraries',
      builder: (context, state) => const LibrariesPage(),
    ),
    GoRoute(
      path: '/play',
      builder: (context, state) => const CleanPlayerPage(),
    ),
  ],
);
