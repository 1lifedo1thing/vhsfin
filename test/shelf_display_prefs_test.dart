import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/features/library/state/shelf_display_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  test('ShelfDisplayPrefs constructor defaults vhsOnly ON', () {
    expect(const ShelfDisplayPrefs().vhsOnly, isTrue);
  });

  test('vhsOnly defaults ON when prefs unset', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(shelfDisplayPrefsProvider).vhsOnly, isTrue);

    await _waitUntil(
      () => container.read(shelfDisplayPrefsProvider).vhsOnly,
      true,
    );
  });

  test('vhsOnly restore respects stored false', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vhsfin.box_art_only', false);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _waitUntil(
      () => container.read(shelfDisplayPrefsProvider).vhsOnly,
      false,
    );
  });
}

Future<void> _waitUntil(bool Function() read, bool expected) async {
  for (var i = 0; i < 50; i++) {
    if (read() == expected) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(read(), expected);
}
