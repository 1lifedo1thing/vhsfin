import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/features/library/state/shelf_display_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ShelfDisplayPrefs constructor defaults vhsOnly ON', () {
    expect(const ShelfDisplayPrefs().vhsOnly, isTrue);
  });

  test('vhsOnly defaults ON when prefs unset', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(shelfDisplayPrefsProvider).vhsOnly, isTrue);

    // Flush async restore — still true when key missing.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(shelfDisplayPrefsProvider).vhsOnly, isTrue);
  });

  test('vhsOnly restore respects stored false', () async {
    SharedPreferences.setMockInitialValues({
      'vhsfin.box_art_only': false,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Trigger build + restore, then wait for SharedPreferences.
    container.read(shelfDisplayPrefsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(shelfDisplayPrefsProvider).vhsOnly, isFalse);
  });
}
