import 'package:aesthetic_coach/app/app.dart';
import 'package:aesthetic_coach/core/di/feature_flags.dart';
import 'package:aesthetic_coach/core/di/goals_providers.dart';
import 'package:aesthetic_coach/core/di/network_providers.dart';
import 'package:aesthetic_coach/core/di/profile_providers.dart';
import 'package:aesthetic_coach/core/error/failure.dart';
import 'package:aesthetic_coach/features/auth/application/auth_notifier.dart';
import 'package:aesthetic_coach/features/auth/data/auth_repository.dart';
import 'package:aesthetic_coach/features/auth/data/models/auth_user.dart';
import 'package:aesthetic_coach/core/di/devices_providers.dart';
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

/// Always succeeds `register()` -- this file is only concerned with what
/// happens *after* registration (the onboarding flow itself), not the
/// signup form, which signup_screen_test.dart already covers.
class _FakeAuthRepository implements AuthRepositoryContract {
  /// Controls what `register()` returns -- the Meet Your Coach step's
  /// verification-required branch needs this settable per test.
  bool registerEmailVerified = true;

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
  }) async => AuthUser(
    id: '1',
    name: name,
    email: email,
    emailVerified: registerEmailVerified,
  );

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
  Object? updateProfileError;
  Map<String, dynamic>? lastUpdatePayload;

  @override
  Future<UserProfile> getProfile() async => _profile;

  @override
  Future<UserProfile> updateProfile(Map<String, dynamic> changes) async {
    lastUpdatePayload = changes;
    if (updateProfileError != null) throw updateProfileError!;
    return _profile;
  }
}

class _FakeGoalsRepository implements GoalsRepositoryContract {
  Object? createGoalError;
  ({GoalType type, String title})? lastCreatePayload;
  int createGoalCallCount = 0;

  @override
  Future<Goal> createGoal({
    required GoalType type,
    required String title,
  }) async {
    createGoalCallCount++;
    lastCreatePayload = (type: type, title: title);
    if (createGoalError != null) throw createGoalError!;
    return Goal(id: 'goal-$createGoalCallCount', type: type, title: title);
  }
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

ProviderContainer _buildContainer({
  required _FakeAuthRepository authRepository,
  required _FakeProfileRepository profileRepository,
  required _FakeGoalsRepository goalsRepository,
  _FakeDevicesRepository? devicesRepository,
  bool? aiOnboardingGenerationEnabled,
}) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepository),
      profileRepositoryProvider.overrideWithValue(profileRepository),
      goalsRepositoryProvider.overrideWithValue(goalsRepository),
      if (devicesRepository != null)
        devicesRepositoryProvider.overrideWithValue(devicesRepository),
      if (aiOnboardingGenerationEnabled != null)
        aiOnboardingGenerationEnabledProvider.overrideWithValue(
          aiOnboardingGenerationEnabled,
        ),
    ],
  );
  return container;
}

Future<void> _registerAndReachOnboarding(
  WidgetTester tester,
  ProviderContainer container,
) async {
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
}

/// Drives through steps 1-3 (profile basics, goal selection via Skip,
/// experience level) with their default/minimal inputs, landing on the
/// Meet Your Coach step -- used by tests that only care about that
/// step's own behavior.
Future<void> _advanceToMeetYourCoach(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await _registerAndReachOnboarding(tester, container);

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
}

void main() {
  group('OnboardingFlowScreen', () {
    late _FakeAuthRepository fakeAuthRepository;
    late _FakeProfileRepository fakeProfileRepository;
    late _FakeGoalsRepository fakeGoalsRepository;
    late ProviderContainer container;

    setUp(() {
      fakeAuthRepository = _FakeAuthRepository();
      fakeProfileRepository = _FakeProfileRepository();
      fakeGoalsRepository = _FakeGoalsRepository();
      container = _buildContainer(
        authRepository: fakeAuthRepository,
        profileRepository: fakeProfileRepository,
        goalsRepository: fakeGoalsRepository,
      );
    });

    tearDown(() => container.dispose());

    testWidgets(
      'completing all 5 steps submits profile basics, creates the selected goal, and finishes to Home',
      (tester) async {
        await _registerAndReachOnboarding(tester, container);

        // Step 1: profile basics.
        expect(
          find.byKey(const Key('onboarding_timezone_field')),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const Key('onboarding_timezone_field')),
          'Asia/Kolkata',
        );
        await tester.tap(
          find.byKey(const Key('onboarding_profile_basics_continue_button')),
        );
        await tester.pumpAndSettle();

        expect(
          fakeProfileRepository.lastUpdatePayload?['timezone'],
          'Asia/Kolkata',
        );
        expect(
          fakeProfileRepository.lastUpdatePayload?['unitPreference'],
          'metric',
        );

        // Step 2: goal selection -- pick Strength explicitly.
        expect(
          find.byKey(const Key('onboarding_goal_option_strength')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const Key('onboarding_goal_option_strength')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('onboarding_goal_selection_continue_button')),
        );
        await tester.pumpAndSettle();

        expect(fakeGoalsRepository.lastCreatePayload?.type, GoalType.strength);
        expect(fakeGoalsRepository.createGoalCallCount, 1);

        // Step 3: experience level -- local only, then Continue.
        expect(
          find.byKey(const Key('onboarding_experience_option_beginner')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const Key('onboarding_experience_option_beginner')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('onboarding_experience_level_continue_button')),
        );
        await tester.pumpAndSettle();

        // Step 4: Meet Your Coach -- the fake user is email-verified and
        // the AI-generation flag defaults to off, so the deferred state
        // shows; Continue advances to Notification Permission.
        expect(
          find.byKey(const Key('onboarding_meet_coach_welcome_text')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('onboarding_meet_coach_deferred_text')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const Key('onboarding_meet_coach_continue_button')),
        );
        await tester.pumpAndSettle();

        // Step 5: Notification Permission -- "Not now" reaches Home.
        expect(
          find.byKey(
            const Key('onboarding_notification_permission_welcome_text'),
          ),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(
            const Key('onboarding_notification_permission_skip_button'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('home_screen_content')), findsOneWidget);
        // justRegistered is cleared so a later /login or /home navigation
        // doesn't bounce this session back into Onboarding.
        expect(container.read(authNotifierProvider).justRegistered, isFalse);
      },
    );

    testWidgets(
      'skipping goal selection seeds the documented default goal (habit / "Build a consistent routine")',
      (tester) async {
        await _registerAndReachOnboarding(tester, container);

        await tester.tap(
          find.byKey(const Key('onboarding_profile_basics_continue_button')),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('onboarding_goal_selection_skip_button')),
        );
        await tester.pumpAndSettle();

        expect(fakeGoalsRepository.lastCreatePayload?.type, GoalType.habit);
        expect(
          fakeGoalsRepository.lastCreatePayload?.title,
          'Build a consistent routine',
        );
        // Advanced to the Experience Level step, not stuck on Goal Selection.
        expect(
          find.byKey(const Key('onboarding_experience_option_beginner')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'a goal-creation failure is shown inline and does not advance the step',
      (tester) async {
        fakeGoalsRepository.createGoalError = const ServerFailure();
        await _registerAndReachOnboarding(tester, container);

        await tester.tap(
          find.byKey(const Key('onboarding_profile_basics_continue_button')),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('onboarding_goal_option_habit')));
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('onboarding_goal_selection_continue_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('onboarding_goal_selection_error_text')),
          findsOneWidget,
        );
        // Still on Goal Selection -- Experience Level was not reached.
        expect(
          find.byKey(const Key('onboarding_goal_option_habit')),
          findsOneWidget,
        );
      },
    );
  });

  group('MeetYourCoachStep', () {
    late _FakeAuthRepository fakeAuthRepository;
    late _FakeProfileRepository fakeProfileRepository;
    late _FakeGoalsRepository fakeGoalsRepository;

    setUp(() {
      fakeAuthRepository = _FakeAuthRepository();
      fakeProfileRepository = _FakeProfileRepository();
      fakeGoalsRepository = _FakeGoalsRepository();
    });

    testWidgets(
      'shows the verification-required state for an unverified user, and Continue still advances (BR-2: non-blocking)',
      (tester) async {
        fakeAuthRepository.registerEmailVerified = false;
        final container = _buildContainer(
          authRepository: fakeAuthRepository,
          profileRepository: fakeProfileRepository,
          goalsRepository: fakeGoalsRepository,
        );
        addTearDown(container.dispose);

        await _advanceToMeetYourCoach(tester, container);

        expect(
          find.byKey(const Key('onboarding_meet_coach_welcome_text')),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const Key('onboarding_meet_coach_verification_required_text'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('onboarding_meet_coach_deferred_text')),
          findsNothing,
        );

        // BR-2: non-blocking -- Continue still advances to the next step,
        // not stuck here waiting for verification.
        await tester.tap(
          find.byKey(const Key('onboarding_meet_coach_continue_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const Key('onboarding_notification_permission_welcome_text'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows the deferred state for a verified user when the AI-generation flag is off (the shipped default)',
      (tester) async {
        final container = _buildContainer(
          authRepository: fakeAuthRepository,
          profileRepository: fakeProfileRepository,
          goalsRepository: fakeGoalsRepository,
          aiOnboardingGenerationEnabled: false,
        );
        addTearDown(container.dispose);

        await _advanceToMeetYourCoach(tester, container);

        expect(
          find.byKey(const Key('onboarding_meet_coach_deferred_text')),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const Key('onboarding_meet_coach_verification_required_text'),
          ),
          findsNothing,
        );
        expect(
          find.byKey(const Key('onboarding_meet_coach_generating_text')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'shows the generating state for a verified user when the AI-generation flag is overridden on',
      (tester) async {
        final container = _buildContainer(
          authRepository: fakeAuthRepository,
          profileRepository: fakeProfileRepository,
          goalsRepository: fakeGoalsRepository,
          aiOnboardingGenerationEnabled: true,
        );
        addTearDown(container.dispose);

        await _advanceToMeetYourCoach(tester, container);

        expect(
          find.byKey(const Key('onboarding_meet_coach_generating_text')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('onboarding_meet_coach_deferred_text')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Continue does not clear justRegistered -- onboarding is not finished yet',
      (tester) async {
        final container = _buildContainer(
          authRepository: fakeAuthRepository,
          profileRepository: fakeProfileRepository,
          goalsRepository: fakeGoalsRepository,
        );
        addTearDown(container.dispose);

        await _advanceToMeetYourCoach(tester, container);
        await tester.tap(
          find.byKey(const Key('onboarding_meet_coach_continue_button')),
        );
        await tester.pumpAndSettle();

        expect(container.read(authNotifierProvider).justRegistered, isTrue);
      },
    );
  });
}
