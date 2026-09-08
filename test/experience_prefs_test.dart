import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';
import 'package:vhsfin/features/living_room/state/experience_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('crtSkin defaults to zenith and persists selection', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(experiencePrefsProvider).crtSkin, CrtTvSkin.zenith);

    await container
        .read(experiencePrefsProvider.notifier)
        .setCrtSkin(CrtTvSkin.portable);
    expect(container.read(experiencePrefsProvider).crtSkin, CrtTvSkin.portable);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('vhsfin.crt_tv_skin.v1'), 'portable');
  });

  test('crtSkin restore reads stored skin', () async {
    SharedPreferences.setMockInitialValues({
      'vhsfin.crt_tv_skin.v1': 'woodConsole',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(experiencePrefsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(
      container.read(experiencePrefsProvider).crtSkin,
      CrtTvSkin.woodConsole,
    );
  });
}
