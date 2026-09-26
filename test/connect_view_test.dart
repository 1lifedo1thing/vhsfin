import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/auth/model/server_address.dart';
import 'package:vhsfin/features/auth/views/connect_view.dart';

void main() {
  test('server validation preserves reverse proxy prefixes', () {
    expect(
      normalizeServerAddress(' https://media.example/jellyfin/// '),
      'https://media.example/jellyfin',
    );
    expect(normalizeServerAddress('http://[::1]:8096/'), 'http://[::1]:8096');
    for (final address in [
      '',
      'ftp://media.local',
      'https://user:password@media.local',
      'https://media.local/web/#/home',
      'https://media.local?api_key=secret',
      'http://my server',
    ]) {
      expect(
        () => normalizeServerAddress(address),
        throwsFormatException,
        reason: address,
      );
    }
  });

  test('addresses without a scheme try https, then http', () {
    expect(serverAddressCandidates(' jellyfin.local:8096/ '), [
      'https://jellyfin.local:8096',
      'http://jellyfin.local:8096',
    ]);
    expect(serverAddressCandidates('192.168.1.20:8096', httpsOnly: true), [
      'https://192.168.1.20:8096',
    ], reason: 'an https page cannot reach an http server');
    expect(serverAddressCandidates('http://media.local'), [
      'http://media.local',
    ]);
    expect(() => serverAddressCandidates('my server'), throwsFormatException);
  });

  testWidgets(
    'validates fields, permits blank password, and prevents busy submit',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final server = TextEditingController();
      final user = TextEditingController();
      final password = TextEditingController();
      addTearDown(server.dispose);
      addTearDown(user.dispose);
      addTearDown(password.dispose);
      var calls = 0;
      Widget view({bool busy = false}) => MaterialApp(
        home: ConnectView(
          serverController: server,
          userController: user,
          passwordController: password,
          busy: busy,
          onSubmit: () => calls++,
          onBack: () {},
        ),
      );
      await tester.pumpWidget(view());
      final submit = find.text('CONNECT & CHOOSE SHELVES');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      expect(calls, 0);
      expect(find.text('Enter your Jellyfin username.'), findsOneWidget);
      server.text = 'http://jellyfin.local:8096';
      user.text = 'kid';
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      expect(calls, 1);
      await tester.pumpWidget(view(busy: true));
      final passwordField = tester.widget<EditableText>(
        find.byType(EditableText).last,
      );
      passwordField.onSubmitted?.call('');
      expect(calls, 1);
      await tester.pumpWidget(view());
      await tester.ensureVisible(find.byTooltip('Show password'));
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(find.byTooltip('Hide password'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('small screen and large text remain scrollable', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controllers = List.generate(3, (_) => TextEditingController());
    for (final controller in controllers) {
      addTearDown(controller.dispose);
    }
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: ConnectView(
          serverController: controllers[0],
          userController: controllers[1],
          passwordController: controllers[2],
          busy: false,
          onSubmit: () {},
          onBack: () {},
        ),
      ),
    );
    await tester.ensureVisible(find.text('First time here?'));
    await tester.tap(find.text('First time here?'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
