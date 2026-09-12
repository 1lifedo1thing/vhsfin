import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';
import 'package:vhsfin/features/living_room/state/experience_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('crtSkin defaults to crt90s and persists selection', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(experiencePrefsProvider).crtSkin, CrtTvSkin.crt90s);

    await container
        .read(experiencePrefsProvider.notifier)
        .setCrtSkin(CrtTvSkin.ivory);
    expect(container.read(experiencePrefsProvider).crtSkin, CrtTvSkin.ivory);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('vhsfin.crt_tv_skin.v1'), 'ivory');
  });

  test('crtSkin restore reads stored skin and legacy names', () async {
    SharedPreferences.setMockInitialValues({
      'vhsfin.crt_tv_skin.v1': 'woodConsole',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(experiencePrefsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(experiencePrefsProvider).crtSkin, CrtTvSkin.knob);
  });

  test(
    'resume positions are available after persisted state is ready',
    () async {
      SharedPreferences.setMockInitialValues({
        'vhsfin.tape_resume_ms.v1': jsonEncode({'movie': 42000}),
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final positions = container.read(tapeResumePositionsProvider.notifier);
      await positions.ready;

      expect(positions.positionFor('movie'), const Duration(seconds: 42));
    },
  );

  test('save-on-eject preference persists', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(experiencePrefsProvider.notifier)
        .setSaveTimestampOnEject(true);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('vhsfin.save_timestamp_on_eject'), isTrue);
  });
}
