import '../../../core/error/failure.dart';
import '../data/models/onboarding_enums.dart';

/// The 5 steps Sprint 2, Tasks 5-7 ship, per
/// docs/features/onboarding.md's UI Flow and
/// docs/TASK_BREAKDOWN.md § Sprint 2 (Tasks 5-7). This is the full
/// documented flow -- nothing further to anticipate here.
enum OnboardingStep {
  profileBasics,
  goalSelection,
  experienceLevel,
  meetYourCoach,
  notificationPermission,
}

class OnboardingState {
  const OnboardingState({
    required this.step,
    this.isSubmitting = false,
    this.failure,
    this.selectedGoalType,
    this.selectedExperienceLevel,
    this.selectedEquipment = const [],
    this.notificationPermissionGranted,
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
  /// docs/features/onboarding.md's APIs list). Carried in-memory only;
  /// the "Meet Your Coach" step (F-ONB-03) will read this once the real
  /// AI-generation call it would feed into actually exists (Sprint 5 --
  /// see core/di/feature_flags.dart).
  final ExperienceLevel? selectedExperienceLevel;
  final List<String> selectedEquipment;

  /// Null until the Notification Permission step's "Enable
  /// notifications" action resolves; then the permission outcome
  /// ([PushPermissionResult.granted]). Not read by the step's own UI --
  /// per [UnavailablePushNotificationPermissionClient], the result is
  /// always `false` today, and the step finishes onboarding (navigates
  /// away) immediately after this resolves, so there is no frame in
  /// which showing a distinct "denied" message would ever actually be
  /// seen. Kept so tests can assert on the outcome directly rather than
  /// only on whether a repository call happened -- see
  /// OnboardingNotifier.requestNotificationPermission's tests.
  final bool? notificationPermissionGranted;

  OnboardingState copyWith({
    OnboardingStep? step,
    bool? isSubmitting,
    Failure? failure,
    bool clearFailure = false,
    GoalType? selectedGoalType,
    ExperienceLevel? selectedExperienceLevel,
    List<String>? selectedEquipment,
    bool? notificationPermissionGranted,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: clearFailure ? null : (failure ?? this.failure),
      selectedGoalType: selectedGoalType ?? this.selectedGoalType,
      selectedExperienceLevel:
          selectedExperienceLevel ?? this.selectedExperienceLevel,
      selectedEquipment: selectedEquipment ?? this.selectedEquipment,
      notificationPermissionGranted:
          notificationPermissionGranted ?? this.notificationPermissionGranted,
    );
  }
}
