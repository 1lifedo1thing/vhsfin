import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhsfin/data/repositories/jellyfin_client.dart';
import 'package:vhsfin/features/auth/connect_page.dart';
import 'package:vhsfin/features/auth/model/session.dart';
import 'package:vhsfin/features/auth/state/session_notifier.dart';
import 'package:vhsfin/features/library/libraries_page.dart';
import 'package:vhsfin/features/library/model/media_library.dart';
import 'package:vhsfin/features/library/state/tape_library.dart';

const _alice = JellyfinSession(
  serverUrl: 'https://example.test',
  userId: 'alice',
  userName: 'Alice',
  accessToken: 'test',
  deviceId: 'device',
);
const _bob = JellyfinSession(
  serverUrl: 'https://example.test',
  userId: 'bob',
  userName: 'Bob',
  accessToken: 'test',
  deviceId: 'device',
);

class _Client extends JellyfinClient {
  Completer<JellyfinSession>? pending;
  @override
  Future<JellyfinSession> authenticate({
    required String serverUrl,
    required String username,
    required String password,
    String? deviceId,
  }) async {
    return pending != null
        ? pending!.future
        : username == 'bob'
        ? _bob
        : _alice;
  }

  @override
  Future<List<LibraryNode>> fetchLibraries(JellyfinSession session) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'migrates existing shelves once and isolates subsequent accounts',
    () async {
      SharedPreferences.setMockInitialValues({
        'vhsfin.session': jsonEncode(_alice.toJson()),
        'vhsfin.shelf_sources.v3': jsonEncode([
          {'id': 'kids', 'name': 'Kids', 'breadcrumb': <String>[]},
        ]),
      });
      final container = ProviderContainer(
        overrides: [jellyfinClientProvider.overrideWithValue(_Client())],
      );
      addTearDown(container.dispose);
      await container.read(sessionProvider.future);
      container.read(shelfSourcesProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(shelfSourcesProvider).single.id, 'kids');
      await container
          .read(sessionProvider.notifier)
          .signIn(serverUrl: _bob.serverUrl, username: 'bob', password: '');
      expect(container.read(shelfSourcesProvider), isEmpty);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(shelfSourcesProvider), isEmpty);
      await container
          .read(shelfSourcesProvider.notifier)
          .add(const ShelfSource(id: 'shows', name: 'Shows'));
      await container
          .read(sessionProvider.notifier)
          .signIn(serverUrl: _alice.serverUrl, username: 'alice', password: '');
      container.read(shelfSourcesProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(shelfSourcesProvider).single.id, 'kids');
    },
  );

  testWidgets('first sign-in can finish shelf setup without a back stack', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/connect',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Living room')),
        ),
        GoRoute(path: '/connect', builder: (_, _) => const ConnectPage()),
        GoRoute(path: '/libraries', builder: (_, _) => const LibrariesPage()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [jellyfinClientProvider.overrideWithValue(_Client())],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'https://example.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'alice');
    await tester.ensureVisible(find.text('CONNECT & CHOOSE SHELVES'));
    await tester.tap(find.text('CONNECT & CHOOSE SHELVES'));
    await tester.pumpAndSettle();
    expect(find.text('SHELVES'), findsOneWidget);
    await tester.tap(find.text('DONE'));
    await tester.pumpAndSettle();
    expect(find.text('Living room'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'a failed login after leaving the page does not update disposed state',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final client = _Client()..pending = Completer<JellyfinSession>();
      final router = GoRouter(
        initialLocation: '/connect',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Living room')),
          ),
          GoRoute(path: '/connect', builder: (_, _) => const ConnectPage()),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [jellyfinClientProvider.overrideWithValue(client)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'https://example.test',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'alice');
      await tester.ensureVisible(find.text('CONNECT & CHOOSE SHELVES'));
      await tester.tap(find.text('CONNECT & CHOOSE SHELVES'));
      await tester.pump();
      router.go('/');
      await tester.pumpAndSettle();
      client.pending!.completeError(Exception('Connection failed'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
