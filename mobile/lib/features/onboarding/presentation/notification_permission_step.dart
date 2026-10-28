import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_notifier.dart';
import '../application/onboarding_notifier.dart';

/// Sprint 2, Task 7 -- docs/features/onboarding.md's F-ONB-05 ("Request
/// push notification permission with contextual copy before the OS
/// prompt") and its Edge Cases ("User denies notification permission ->
/// onboarding proceeds normally; re-prompt only via a later in-app
/// settings nudge, never a forced re-ask").
///
/// The final step of the onboarding flow -- both buttons below finish
/// onboarding (clear [AuthState.justRegistered], navigate to `/home`)
/// regardless of outcome, including a failed/unavailable permission
/// request. "Enable notifications" additionally calls
/// [OnboardingNotifier.requestNotificationPermission] first, which --
/// per [PushNotificationPermissionClient]'s docblock -- always resolves
/// to not-granted in a shipped build today (no permission_handler/
/// firebase_messaging plugin is wired up yet; see
/// ENGINEERING_DECISION_LOG.md), so no push token is ever actually
/// registered by this screen today. The copy below is written to still
/// read correctly once that becomes true, since nothing about the UI
/// itself needs to change when it does.
class NotificationPermissionStep extends ConsumerWidget {
  const NotificationPermissionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);
    final isSubmitting = state.isSubmitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            key: const Key('onboarding_notification_permission_welcome_text'),
            "We'll let you know when it's time to train, when a streak is "
            "on the line, and when your coach has something new for you. "
            "You can change this anytime in Settings.",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('onboarding_notification_permission_enable_button'),
            onPressed: isSubmitting ? null : () => _enable(context, ref),
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enable notifications'),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('onboarding_notification_permission_skip_button'),
            onPressed: isSubmitting ? null : () => _finish(context, ref),
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }

  Future<void> _enable(BuildContext context, WidgetRef ref) async {
    await ref
        .read(onboardingNotifierProvider.notifier)
        .requestNotificationPermission();
    if (!context.mounted) return;
    _finish(context, ref);
  }

  void _finish(BuildContext context, WidgetRef ref) {
    ref.read(authNotifierProvider.notifier).clearJustRegistered();
    context.go('/home');
  }
}
