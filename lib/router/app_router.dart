import 'package:go_router/go_router.dart';
import 'package:vhsfin/features/auth/presentation/connect_page.dart';
import 'package:vhsfin/features/living_room/presentation/living_room_page.dart';
import 'package:vhsfin/features/playback/presentation/clean_player_page.dart';

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
      path: '/play',
      builder: (context, state) => const CleanPlayerPage(),
    ),
  ],
);
