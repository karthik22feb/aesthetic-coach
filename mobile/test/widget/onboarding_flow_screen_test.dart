import 'package:aesthetic_coach/app/app.dart';
import 'package:aesthetic_coach/core/di/goals_providers.dart';
import 'package:aesthetic_coach/core/di/network_providers.dart';
import 'package:aesthetic_coach/core/di/profile_providers.dart';
import 'package:aesthetic_coach/core/error/failure.dart';
import 'package:aesthetic_coach/features/auth/application/auth_notifier.dart';
import 'package:aesthetic_coach/features/auth/data/auth_repository.dart';
import 'package:aesthetic_coach/features/auth/data/models/auth_user.dart';
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

ProviderContainer _buildContainer({
  required _FakeProfileRepository profileRepository,
  required _FakeGoalsRepository goalsRepository,
}) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      profileRepositoryProvider.overrideWithValue(profileRepository),
      goalsRepositoryProvider.overrideWithValue(goalsRepository),
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

void main() {
  group('OnboardingFlowScreen', () {
    late _FakeProfileRepository fakeProfileRepository;
    late _FakeGoalsRepository fakeGoalsRepository;
    late ProviderContainer container;

    setUp(() {
      fakeProfileRepository = _FakeProfileRepository();
      fakeGoalsRepository = _FakeGoalsRepository();
      container = _buildContainer(
        profileRepository: fakeProfileRepository,
        goalsRepository: fakeGoalsRepository,
      );
    });

    tearDown(() => container.dispose());

    testWidgets(
      'completing all 3 steps submits profile basics, creates the selected goal, and finishes to Home',
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

        // Step 3: experience level -- local only, then Finish.
        expect(
          find.byKey(const Key('onboarding_experience_option_beginner')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const Key('onboarding_experience_option_beginner')),
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('onboarding_finish_button')));
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
}
