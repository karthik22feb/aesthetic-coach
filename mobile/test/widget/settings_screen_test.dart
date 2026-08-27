import 'package:aesthetic_coach/core/di/profile_providers.dart';
import 'package:aesthetic_coach/core/di/settings_providers.dart';
import 'package:aesthetic_coach/core/error/failure.dart';
import 'package:aesthetic_coach/core/storage/theme_storage.dart';
import 'package:aesthetic_coach/features/profile/data/models/profile_enums.dart';
import 'package:aesthetic_coach/features/profile/data/models/user_profile.dart';
import 'package:aesthetic_coach/features/profile/data/profile_repository.dart';
import 'package:aesthetic_coach/features/settings/application/theme_mode_notifier.dart';
import 'package:aesthetic_coach/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _profile = UserProfile(
  id: '1',
  name: 'Priya Shah',
  email: 'priya@example.com',
  emailVerified: true,
  timezone: 'UTC',
  unitPreference: UnitPreference.metric,
  dietaryRestrictions: [],
);

class _FakeProfileRepository implements ProfileRepositoryContract {
  Object? getProfileError;
  Object? updateProfileError;
  UserProfile getProfileResponse = _profile;
  UserProfile updateProfileResponse = _profile;
  Map<String, dynamic>? lastUpdatePayload;

  @override
  Future<UserProfile> getProfile() async {
    if (getProfileError != null) throw getProfileError!;
    return getProfileResponse;
  }

  @override
  Future<UserProfile> updateProfile(Map<String, dynamic> changes) async {
    lastUpdatePayload = changes;
    if (updateProfileError != null) throw updateProfileError!;
    return updateProfileResponse;
  }
}

class _FakeThemeStorage implements ThemeStorageContract {
  String? stored;

  @override
  Future<String?> readThemeMode() async => stored;

  @override
  Future<void> saveThemeMode(String value) async => stored = value;
}

Widget _hostedSettingsScreen({
  required _FakeProfileRepository fakeRepository,
  required _FakeThemeStorage fakeThemeStorage,
}) {
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(fakeRepository),
      themeStorageProvider.overrideWithValue(fakeThemeStorage),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  );
}

void main() {
  group('SettingsScreen', () {
    late _FakeProfileRepository fakeRepository;
    late _FakeThemeStorage fakeThemeStorage;

    setUp(() {
      fakeRepository = _FakeProfileRepository();
      fakeThemeStorage = _FakeThemeStorage();
    });

    testWidgets('renders theme and unit preference controls', (tester) async {
      await tester.pumpWidget(
        _hostedSettingsScreen(
          fakeRepository: fakeRepository,
          fakeThemeStorage: fakeThemeStorage,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_theme_field')), findsOneWidget);
      expect(
        find.byKey(const Key('settings_unit_preference_field')),
        findsOneWidget,
      );
    });

    testWidgets('selecting Dark updates and persists the theme choice', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWithValue(fakeRepository),
          themeStorageProvider.overrideWithValue(fakeThemeStorage),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(fakeThemeStorage.stored, 'dark');
    });

    testWidgets('shows the current server-backed unit preference once loaded', (
      tester,
    ) async {
      fakeRepository.getProfileResponse = const UserProfile(
        id: '1',
        name: 'Priya Shah',
        email: 'priya@example.com',
        emailVerified: true,
        timezone: 'UTC',
        unitPreference: UnitPreference.imperial,
        dietaryRestrictions: [],
      );

      await tester.pumpWidget(
        _hostedSettingsScreen(
          fakeRepository: fakeRepository,
          fakeThemeStorage: fakeThemeStorage,
        ),
      );
      await tester.pumpAndSettle();

      final control = tester.widget<SegmentedButton<UnitPreference>>(
        find.byKey(const Key('settings_unit_preference_field')),
      );
      expect(control.selected, {UnitPreference.imperial});
    });

    testWidgets(
      'selecting Imperial sends a partial PATCH with only unitPreference',
      (tester) async {
        await tester.pumpWidget(
          _hostedSettingsScreen(
            fakeRepository: fakeRepository,
            fakeThemeStorage: fakeThemeStorage,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Imperial'));
        await tester.pumpAndSettle();

        expect(fakeRepository.lastUpdatePayload, {
          'unitPreference': 'imperial',
        });
      },
    );

    testWidgets('a failed unit-preference update shows an inline error', (
      tester,
    ) async {
      fakeRepository.updateProfileError = const NetworkFailure();

      await tester.pumpWidget(
        _hostedSettingsScreen(
          fakeRepository: fakeRepository,
          fakeThemeStorage: fakeThemeStorage,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Imperial'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('settings_unit_preference_save_error')),
        findsOneWidget,
      );
    });

    testWidgets(
      'a profile load failure shows an error for the unit preference control without crashing the screen',
      (tester) async {
        fakeRepository.getProfileError = const NetworkFailure();

        await tester.pumpWidget(
          _hostedSettingsScreen(
            fakeRepository: fakeRepository,
            fakeThemeStorage: fakeThemeStorage,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('settings_unit_preference_error')),
          findsOneWidget,
        );
        // Theme control is unaffected by the profile load failure.
        expect(find.byKey(const Key('settings_theme_field')), findsOneWidget);
      },
    );
  });
}
