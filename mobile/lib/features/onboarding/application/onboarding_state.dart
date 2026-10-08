import '../../../core/error/failure.dart';
import '../data/models/onboarding_enums.dart';

/// The 3 steps Sprint 2, Task 5 ships, per
/// docs/features/onboarding.md's UI Flow and
/// docs/TASK_BREAKDOWN.md § Sprint 2 (Task 5). "Meet Your Coach" (Task 6)
/// and the notification-permission prompt (Task 7) are separate,
/// not-yet-built steps that would extend this enum, not this file's
/// concern to anticipate.
enum OnboardingStep { profileBasics, goalSelection, experienceLevel }

class OnboardingState {
  const OnboardingState({
    required this.step,
    this.isSubmitting = false,
    this.failure,
    this.selectedGoalType,
    this.selectedExperienceLevel,
    this.selectedEquipment = const [],
  });

  static const initial = OnboardingState(step: OnboardingStep.profileBasics);

  final OnboardingStep step;

  /// True while a step's API call (profile update or goal creation) is
  /// in flight. Local-only steps (experience level) never set this.
  final bool isSubmitting;

  /// Set on a failed step submission so that step can show an inline
  /// retry, per docs/features/onboarding.md's Error Handling ("any
  /// single step's API failure surfaces an inline retry, never a full-
  /// flow restart"). Cleared on the next attempt.
  final Failure? failure;

  /// Retained after the Goal Selection step completes purely for
  /// display (e.g. a future "review your choices" surface) -- not read
  /// by any later step in this task's scope.
  final GoalType? selectedGoalType;

  /// Collected by the Experience Level step but not sent anywhere yet --
  /// no backend field exists for it (see
  /// docs/features/onboarding.md's APIs list). Carried in-memory only,
  /// for the not-yet-built "Meet Your Coach" step (F-ONB-03) to read
  /// once it exists.
  final ExperienceLevel? selectedExperienceLevel;
  final List<String> selectedEquipment;

  OnboardingState copyWith({
    OnboardingStep? step,
    bool? isSubmitting,
    Failure? failure,
    bool clearFailure = false,
    GoalType? selectedGoalType,
    ExperienceLevel? selectedExperienceLevel,
    List<String>? selectedEquipment,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: clearFailure ? null : (failure ?? this.failure),
      selectedGoalType: selectedGoalType ?? this.selectedGoalType,
      selectedExperienceLevel:
          selectedExperienceLevel ?? this.selectedExperienceLevel,
      selectedEquipment: selectedEquipment ?? this.selectedEquipment,
    );
  }
}
