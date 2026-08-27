import 'package:aesthetic_coach/core/di/profile_providers.dart';
import 'package:aesthetic_coach/core/error/failure.dart';
import 'package:aesthetic_coach/features/profile/application/profile_notifier.dart';
import 'package:aesthetic_coach/features/profile/application/profile_state.dart';
import 'package:aesthetic_coach/features/profile/data/models/profile_enums.dart';
import 'package:aesthetic_coach/features/profile/data/models/user_profile.dart';
import 'package:aesthetic_coach/features/profile/data/profile_repository.dart';
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

  @override
  Future<UserProfile> getProfile() async {
    if (getProfileError != null) throw getProfileError!;
    return getProfileResponse;
  }

  @override
  Future<UserProfile> updateProfile(Map<String, dynamic> changes) async {
    if (updateProfileError != null) throw updateProfileError!;
    return updateProfileResponse;
  }
}

void main() {
  group('ProfileNotifier', () {
    late _FakeProfileRepository fakeRepository;
    late ProviderContainer container;

    setUp(() {
      fakeRepository = _FakeProfileRepository();
      container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);
    });

    test('initial state is loading', () {
      expect(
        container.read(profileNotifierProvider).status,
        ProfileStatus.loading,
      );
    });

    test(
      'build() triggers an automatic load that resolves to loaded',
      () async {
        // Reading the provider is what triggers build() (Riverpod
        // providers are lazy) -- only after that does the fire-and-forget
        // Future.microtask(loadProfile) get scheduled, matching
        // AuthNotifier's own build()-triggers-restoreSession pattern.
        container.read(profileNotifierProvider);
        await Future<void>.delayed(Duration.zero);

        final state = container.read(profileNotifierProvider);
        expect(state.status, ProfileStatus.loaded);
        expect(state.profile, _profile);
      },
    );

    test(
      'loadProfile failure transitions to error with the failure attached',
      () async {
        fakeRepository.getProfileError = const NetworkFailure();

        await container.read(profileNotifierProvider.notifier).loadProfile();

        final state = container.read(profileNotifierProvider);
        expect(state.status, ProfileStatus.error);
        expect(state.failure, isA<NetworkFailure>());
      },
    );

    test(
      'loadProfile can retry after a failure and recover to loaded',
      () async {
        fakeRepository.getProfileError = const NetworkFailure();
        await container.read(profileNotifierProvider.notifier).loadProfile();
        expect(
          container.read(profileNotifierProvider).status,
          ProfileStatus.error,
        );

        fakeRepository.getProfileError = null;
        await container.read(profileNotifierProvider.notifier).loadProfile();

        final state = container.read(profileNotifierProvider);
        expect(state.status, ProfileStatus.loaded);
        expect(state.profile, _profile);
      },
    );

    test(
      'updateProfile success updates state with the returned profile',
      () async {
        await container.read(profileNotifierProvider.notifier).loadProfile();
        fakeRepository.updateProfileResponse = const UserProfile(
          id: '1',
          name: 'New Name',
          email: 'priya@example.com',
          emailVerified: true,
          timezone: 'UTC',
          unitPreference: UnitPreference.metric,
          dietaryRestrictions: [],
        );

        final result = await container
            .read(profileNotifierProvider.notifier)
            .updateProfile({'name': 'New Name'});

        expect(result.name, 'New Name');
        expect(
          container.read(profileNotifierProvider).profile?.name,
          'New Name',
        );
      },
    );

    test('updateProfile failure rethrows the Failure and leaves state untouched, per docs/screens/profile.md (errors shown inline in the sheet, not the screen)', () async {
      await container.read(profileNotifierProvider.notifier).loadProfile();
      final stateBefore = container.read(profileNotifierProvider);
      fakeRepository.updateProfileError = const ValidationFailure({
        'heightCm': ['The height cm must be between 50 and 250.'],
      });

      await expectLater(
        container.read(profileNotifierProvider.notifier).updateProfile({
          'heightCm': 999,
        }),
        throwsA(isA<ValidationFailure>()),
      );

      // The screen's own state is unchanged -- still the pre-edit
      // profile, still `loaded`, no failure attached to the screen.
      expect(container.read(profileNotifierProvider), stateBefore);
    });
  });
}
