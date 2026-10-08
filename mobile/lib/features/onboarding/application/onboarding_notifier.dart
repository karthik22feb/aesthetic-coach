import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/goals_providers.dart';
import '../../../core/di/profile_providers.dart';
import '../../../core/error/failure.dart';
import '../data/models/onboarding_enums.dart';
import 'onboarding_state.dart';

/// Default goal seeded when the user skips goal selection entirely,
/// per docs/features/onboarding.md's Edge Cases ("defaults to a
/// `habit`-type goal ('build a consistent routine') so downstream AI
/// context always has at least one goal to reference").
const defaultSkippedGoalType = GoalType.habit;
const defaultSkippedGoalTitle = 'Build a consistent routine';

/// Owns the 3-step onboarding flow's submission state. Hand-written
/// `Notifier`, matching [AuthNotifier]/[ProfileNotifier]'s convention.
///
/// Each step's submission reuses an existing, real, already-tested
/// repository where one exists ([profileRepositoryProvider] for
/// `PATCH /me`) and the mock-backed [goalsRepositoryProvider] where the
/// real endpoint doesn't exist yet (see goals_api.dart) -- this class
/// does not know or care which [GoalsApiClient] implementation is
/// actually wired up.
class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => OnboardingState.initial;

  /// Step 1: profile basics, via the real `PATCH /me`. [changes] follows
  /// the same camelCase, backend-column-allowlist shape as
  /// EditProfileSheet's submit -- see ProfileApiClient.updateProfile's
  /// docblock for which keys the backend actually accepts.
  Future<void> submitProfileBasics(Map<String, dynamic> changes) async {
    state = state.copyWith(isSubmitting: true, clearFailure: true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(changes);
      state = state.copyWith(
        step: OnboardingStep.goalSelection,
        isSubmitting: false,
      );
    } on Failure catch (failure) {
      state = state.copyWith(isSubmitting: false, failure: failure);
    }
  }

  /// Step 2: goal selection, via [GoalsRepositoryContract.createGoal]
  /// (mock-backed for now -- see core/di/goals_providers.dart).
  Future<void> selectGoal({required GoalType type, required String title}) =>
      _createGoalAndAdvance(type: type, title: title);

  /// Step 2's skip affordance -- seeds the documented default goal
  /// rather than leaving the user with none (F-ONB-02 requires every
  /// user to end onboarding with at least one `goals` row).
  Future<void> skipGoal() => _createGoalAndAdvance(
    type: defaultSkippedGoalType,
    title: defaultSkippedGoalTitle,
  );

  Future<void> _createGoalAndAdvance({
    required GoalType type,
    required String title,
  }) async {
    state = state.copyWith(isSubmitting: true, clearFailure: true);
    try {
      await ref
          .read(goalsRepositoryProvider)
          .createGoal(type: type, title: title);
      state = state.copyWith(
        step: OnboardingStep.experienceLevel,
        isSubmitting: false,
        selectedGoalType: type,
      );
    } on Failure catch (failure) {
      state = state.copyWith(isSubmitting: false, failure: failure);
    }
  }

  /// Step 3: experience level + equipment. Purely local (no backend
  /// field exists yet -- see [OnboardingState.selectedExperienceLevel]'s
  /// docblock), so this never fails and never sets [isSubmitting].
  /// Advancing past this step (calling `AuthNotifier.clearJustRegistered`
  /// and navigating to `/home`) is the screen's own responsibility, not
  /// this notifier's -- there is no further step state to transition to.
  void setExperienceLevel({
    required ExperienceLevel level,
    required List<String> equipment,
  }) {
    state = state.copyWith(
      selectedExperienceLevel: level,
      selectedEquipment: equipment,
    );
  }
}

final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );
