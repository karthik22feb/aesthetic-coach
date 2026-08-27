import 'package:aesthetic_coach/core/di/settings_providers.dart';
import 'package:aesthetic_coach/core/storage/theme_storage.dart';
import 'package:aesthetic_coach/features/settings/application/theme_mode_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeThemeStorage implements ThemeStorageContract {
  String? stored;

  @override
  Future<String?> readThemeMode() async => stored;

  @override
  Future<void> saveThemeMode(String value) async => stored = value;
}

void main() {
  group('ThemeModeNotifier', () {
    late _FakeThemeStorage fakeStorage;
    late ProviderContainer container;

    setUp(() {
      fakeStorage = _FakeThemeStorage();
      container = ProviderContainer(
        overrides: [themeStorageProvider.overrideWithValue(fakeStorage)],
      );
      addTearDown(container.dispose);
    });

    test('initial state is system before restore resolves', () {
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('with nothing persisted, stays system after restore', () async {
      container.read(themeModeProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('restores a previously persisted choice on build', () async {
      fakeStorage.stored = 'dark';
      container.read(themeModeProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('setThemeMode updates state immediately', () async {
      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.light);

      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('setThemeMode persists the choice via storage', () async {
      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      expect(fakeStorage.stored, 'dark');
    });

    test('setThemeMode(system) persists as "system"', () async {
      // Let build()'s fire-and-forget restore settle first, so it can't
      // interleave with (and overwrite the result of) the two explicit
      // setThemeMode calls below -- mirrors how a real UI never calls
      // setThemeMode before the first frame renders.
      container.read(themeModeProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.light);
      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.system);

      expect(fakeStorage.stored, 'system');
      expect(container.read(themeModeProvider), ThemeMode.system);
    });
  });
}
