import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/feature_flags.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/onboarding_notifier.dart';

/// Sprint 2, Task 6 -- docs/features/onboarding.md's F-ONB-04 ("Run one
/// guided AI conversation turn that ends in a generated first
/// `workout_templates` row") and Release Phase note ("ships as a single
/// structured AI Workout Recommendation call + written welcome, not
/// open-ended chat"). The written welcome is this step; the real call
/// is gated behind [aiOnboardingGenerationEnabledProvider] and stays
/// unreachable in shipped builds until Sprint 5 (see that provider's
/// docblock and ENGINEERING_DECISION_LOG.md) -- Workout Engine (Sprint 3)
/// and AI Recommendations (Sprint 5), which the real call needs, don't
/// exist in the backend in any form yet, so there is no call to
/// actually make today, only this gate to leave correctly in place for
/// when there is.
///
/// Always reachable and always continuable (to the Notification
/// Permission step, Task 7) regardless of email verification or the
/// flag's value -- per docs/features/onboarding.md's Error Handling
/// ("non-blocking by design") and Business Rules (BR-2: "the user can
/// finish onboarding and verify later, with the first-workout
/// generation deferred").
class MeetYourCoachStep extends ConsumerWidget {
  const MeetYourCoachStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailVerified =
        ref.watch(authNotifierProvider).user?.emailVerified ?? false;
    final generationEnabled = ref.watch(aiOnboardingGenerationEnabledProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            key: const Key('onboarding_meet_coach_welcome_text'),
            "Welcome! I'm your AI coach, and I'll be putting together "
            "your first personalized plan based on what you've just told me.",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          if (!emailVerified)
            Text(
              key: const Key(
                'onboarding_meet_coach_verification_required_text',
              ),
              'Verify your email to meet your coach. Once you confirm your '
              "email, we'll generate your first personalized plan "
              'automatically -- you can finish setup now and verify anytime.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else if (generationEnabled)
            // Unreachable in shipped builds (the provider is hardcoded
            // false) -- only reachable in a test that overrides it, to
            // prove this gate actually branches.
            //
            // TODO(Sprint 5): replace this placeholder with the real
            // generation call (POST /templates/ai-generate / POST
            // /coach/conversations, per docs/features/onboarding.md's
            // APIs) once Workout Engine and AI Recommendations exist for
            // it to call -- use OnboardingState.selectedExperienceLevel/
            // selectedEquipment as its context.
            Text(
              key: const Key('onboarding_meet_coach_generating_text'),
              'Generating your first plan...',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Text(
              key: const Key('onboarding_meet_coach_deferred_text'),
              "Your first plan is on its way. We'll generate it "
              'automatically once AI coaching goes live -- you '
              "won't need to do anything.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('onboarding_meet_coach_continue_button'),
            onPressed: () => ref
                .read(onboardingNotifierProvider.notifier)
                .advanceToNotificationPermission(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
