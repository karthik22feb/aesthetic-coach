import 'package:aesthetic_coach/app/app.dart';
import 'package:aesthetic_coach/core/di/devices_providers.dart';
import 'package:aesthetic_coach/core/di/goals_providers.dart';
import 'package:aesthetic_coach/core/di/network_providers.dart';
import 'package:aesthetic_coach/core/di/profile_providers.dart';
import 'package:aesthetic_coach/core/error/failure.dart';
import 'package:aesthetic_coach/features/auth/application/auth_notifier.dart';
import 'package:aesthetic_coach/features/auth/data/auth_repository.dart';
import 'package:aesthetic_coach/features/auth/data/models/auth_user.dart';
import 'package:aesthetic_coach/features/onboarding/data/devices_repository.dart';
import 'package:aesthetic_coach/features/onboarding/data/goals_repository.dart';
import 'package:aesthetic_coach/features/onboarding/data/models/goal.dart';
import 'package:aesthetic_coach/features/onboarding/data/models/onboarding_enums.dart';
import 'package:aesthetic_coach/features/profile/data/models/profile_enums.dart';
import 'package:aesthetic_coach/features/profile/data/models/user_profile.dart';
import 'package:aesthetic_coach/features/profile/data/profile_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepositoryContract {
  @override
  Future<void> refresh() async =>
      throw const AuthFailure(message: 'No session to restore.');

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async => const AuthUser(
    id: '1',
    name: 'Priya Shah',
    email: 'priya@example.com',
    emailVerified: true,
  );

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async => AuthUser(id: '1', name: name, email: email, emailVerified: true);

  @override
  Future<void> logout() async {}
}

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
  @override
  Future<UserProfile> getProfile() async => _profile;

  @override
  Future<UserProfile> updateProfile(Map<String, dynamic> changes) async =>
      _profile;
}

class _FakeGoalsRepository implements GoalsRepositoryContract {
  @override
  Future<Goal> createGoal({
    required GoalType type,
    required String title,
  }) async => Goal(id: 'goal-1', type: type, title: title);
}

class _FakeDevicesRepository implements DevicesRepositoryContract {
  int registerDeviceCallCount = 0;
  String? lastRegisteredToken;

  @override
  Future<void> registerDevice(String pushToken) async {
    registerDeviceCallCount++;
    lastRegisteredToken = pushToken;
  }
}

/// Drives through steps 1-4 to land on the Notification Permission step
/// -- this file is only concerned with that step's own behavior.
Future<ProviderContainer> _reachNotificationPermissionStep(
  WidgetTester tester, {
  required _FakeDevicesRepository devicesRepository,
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
      goalsRepositoryProvider.overrideWithValue(_FakeGoalsRepository()),
      devicesRepositoryProvider.overrideWithValue(devicesRepository),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const AestheticCoachApp(),
    ),
  );
  await tester.pumpAndSettle(); // resolves to Login (refresh fails)

  await container
      .read(authNotifierProvider.notifier)
      .register(
        name: 'Priya Shah',
        email: 'priya@example.com',
        password: 'correct-horse-battery1',
      );
  await tester.pumpAndSettle();

  await tester.tap(
    find.byKey(const Key('onboarding_profile_basics_continue_button')),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const Key('onboarding_goal_selection_skip_button')),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const Key('onboarding_experience_option_beginner')),
  );
  await tester.pump();
  await tester.tap(
    find.byKey(const Key('onboarding_experience_level_continue_button')),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const Key('onboarding_meet_coach_continue_button')),
  );
  await tester.pumpAndSettle();

  return container;
}

void main() {
  group('NotificationPermissionStep', () {
    late _FakeDevicesRepository fakeDevicesRepository;

    setUp(() {
      fakeDevicesRepository = _FakeDevicesRepository();
    });

    testWidgets('shows the contextual welcome copy and both actions', (
      tester,
    ) async {
      final container = await _reachNotificationPermissionStep(
        tester,
        devicesRepository: fakeDevicesRepository,
      );
      addTearDown(container.dispose);

      expect(
        find.byKey(
          const Key('onboarding_notification_permission_welcome_text'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('onboarding_notification_permission_enable_button'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('onboarding_notification_permission_skip_button')),
        findsOneWidget,
      );
    });

    testWidgets(
      '"Not now" finishes onboarding without ever calling DevicesRepository',
      (tester) async {
        final container = await _reachNotificationPermissionStep(
          tester,
          devicesRepository: fakeDevicesRepository,
        );
        addTearDown(container.dispose);

        await tester.tap(
          find.byKey(
            const Key('onboarding_notification_permission_skip_button'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('home_screen_content')), findsOneWidget);
        expect(container.read(authNotifierProvider).justRegistered, isFalse);
        expect(fakeDevicesRepository.registerDeviceCallCount, 0);
      },
    );

    testWidgets(
      '"Enable notifications" also finishes onboarding without registering a '
      'device -- no permission plugin is wired up, so permission is never '
      'actually granted (see PushNotificationPermissionClient)',
      (tester) async {
        final container = await _reachNotificationPermissionStep(
          tester,
          devicesRepository: fakeDevicesRepository,
        );
        addTearDown(container.dispose);

        await tester.tap(
          find.byKey(
            const Key('onboarding_notification_permission_enable_button'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('home_screen_content')), findsOneWidget);
        expect(container.read(authNotifierProvider).justRegistered, isFalse);
        // The documented constraint this task was built against: register
        // only when permission is granted AND a real token is available.
        // Today, neither is ever true, so this must never be called.
        expect(fakeDevicesRepository.registerDeviceCallCount, 0);
        expect(fakeDevicesRepository.lastRegisteredToken, isNull);
      },
    );
  });
}
