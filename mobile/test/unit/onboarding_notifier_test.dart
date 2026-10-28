import 'package:aesthetic_coach/core/di/devices_providers.dart';
import 'package:aesthetic_coach/core/di/goals_providers.dart';
import 'package:aesthetic_coach/core/di/profile_providers.dart';
import 'package:aesthetic_coach/core/di/push_notification_providers.dart';
import 'package:aesthetic_coach/core/error/failure.dart';
import 'package:aesthetic_coach/features/onboarding/application/onboarding_notifier.dart';
import 'package:aesthetic_coach/features/onboarding/data/devices_repository.dart';
import 'package:aesthetic_coach/features/onboarding/data/goals_repository.dart';
import 'package:aesthetic_coach/features/onboarding/data/models/goal.dart';
import 'package:aesthetic_coach/features/onboarding/data/models/onboarding_enums.dart';
import 'package:aesthetic_coach/features/onboarding/data/push_notification_permission_client.dart';
import 'package:aesthetic_coach/features/profile/data/models/user_profile.dart';
import 'package:aesthetic_coach/features/profile/data/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProfileRepository implements ProfileRepositoryContract {
  @override
  Future<UserProfile> getProfile() => throw UnimplementedError();

  @override
  Future<UserProfile> updateProfile(Map<String, dynamic> changes) =>
      throw UnimplementedError();
}

class _FakeGoalsRepository implements GoalsRepositoryContract {
  @override
  Future<Goal> createGoal({required GoalType type, required String title}) =>
      throw UnimplementedError();
}

class _FakeDevicesRepository implements DevicesRepositoryContract {
  Object? registerDeviceError;
  String? lastRegisteredToken;
  int registerDeviceCallCount = 0;

  @override
  Future<void> registerDevice(String pushToken) async {
    registerDeviceCallCount++;
    lastRegisteredToken = pushToken;
    if (registerDeviceError != null) throw registerDeviceError!;
  }
}

class _FakePushNotificationPermissionClient
    implements PushNotificationPermissionClient {
  PushPermissionResult result = const PushPermissionResult(granted: false);

  @override
  Future<PushPermissionResult> requestPermission() async => result;
}

ProviderContainer _buildContainer({
  required _FakeDevicesRepository devicesRepository,
  required _FakePushNotificationPermissionClient permissionClient,
}) {
  return ProviderContainer(
    overrides: [
      profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
      goalsRepositoryProvider.overrideWithValue(_FakeGoalsRepository()),
      devicesRepositoryProvider.overrideWithValue(devicesRepository),
      pushNotificationPermissionClientProvider.overrideWithValue(
        permissionClient,
      ),
    ],
  );
}

void main() {
  group('OnboardingNotifier.requestNotificationPermission', () {
    late _FakeDevicesRepository fakeDevicesRepository;
    late _FakePushNotificationPermissionClient fakePermissionClient;
    late ProviderContainer container;

    setUp(() {
      fakeDevicesRepository = _FakeDevicesRepository();
      fakePermissionClient = _FakePushNotificationPermissionClient();
      container = _buildContainer(
        devicesRepository: fakeDevicesRepository,
        permissionClient: fakePermissionClient,
      );
    });

    tearDown(() => container.dispose());

    test('when permission is not granted, does not register a device and records the outcome', () async {
      fakePermissionClient.result = const PushPermissionResult(granted: false);

      await container
          .read(onboardingNotifierProvider.notifier)
          .requestNotificationPermission();

      expect(fakeDevicesRepository.registerDeviceCallCount, 0);
      expect(
        container
            .read(onboardingNotifierProvider)
            .notificationPermissionGranted,
        isFalse,
      );
      expect(container.read(onboardingNotifierProvider).isSubmitting, isFalse);
    });

    test('when granted but no token is available, still does not register a device', () async {
      // A real implementation can plausibly grant permission before its
      // token is ready -- this is the scenario this task's own
      // instruction ("register ... only when ... a real token is
      // available") specifically guards against.
      fakePermissionClient.result = const PushPermissionResult(
        granted: true,
        pushToken: null,
      );

      await container
          .read(onboardingNotifierProvider.notifier)
          .requestNotificationPermission();

      expect(fakeDevicesRepository.registerDeviceCallCount, 0);
    });

    test('when granted and a real token is available, registers it via DevicesRepository', () async {
      fakePermissionClient.result = const PushPermissionResult(
        granted: true,
        pushToken: 'real-fcm-token',
      );

      await container
          .read(onboardingNotifierProvider.notifier)
          .requestNotificationPermission();

      expect(fakeDevicesRepository.registerDeviceCallCount, 1);
      expect(fakeDevicesRepository.lastRegisteredToken, 'real-fcm-token');
      expect(
        container
            .read(onboardingNotifierProvider)
            .notificationPermissionGranted,
        isTrue,
      );
    });

    test(
      'a DevicesRepository failure is swallowed -- never thrown, never blocks',
      () async {
        fakePermissionClient.result = const PushPermissionResult(
          granted: true,
          pushToken: 'real-fcm-token',
        );
        fakeDevicesRepository.registerDeviceError = const ServerFailure();

        await expectLater(
          container
              .read(onboardingNotifierProvider.notifier)
              .requestNotificationPermission(),
          completes,
        );

        expect(
          container.read(onboardingNotifierProvider).isSubmitting,
          isFalse,
        );
      },
    );
  });
}
