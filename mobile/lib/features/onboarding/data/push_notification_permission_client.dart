/// Result of a push-notification permission request: whether the OS
/// granted it, and the device's push token if one is actually available.
/// [pushToken] is deliberately independent of [granted] in shape (not a
/// non-null guarantee when granted) -- a real implementation can grant
/// permission yet still have no token yet (e.g. the provider SDK hasn't
/// finished registering with the platform), and the caller
/// (OnboardingNotifier) must only register a token that genuinely
/// exists, per this task's own instruction ("register ... only when
/// permission is granted and a real token is available").
class PushPermissionResult {
  const PushPermissionResult({required this.granted, this.pushToken});

  final bool granted;
  final String? pushToken;
}

/// Requests OS-level push-notification permission and, if granted,
/// returns the device's push token -- the client-side half of
/// docs/features/onboarding.md's F-ONB-05 ("Request push notification
/// permission ... before the OS prompt").
///
/// **No implementation of this can request a real OS permission or
/// obtain a real push token in this project today.** Doing so needs a
/// plugin this project doesn't have: requesting the actual OS dialog
/// (iOS `UNUserNotificationCenter`, Android 13+ `POST_NOTIFICATIONS`)
/// and reading a push token both require either `permission_handler` +
/// `firebase_messaging` (or an equivalent), neither of which is a
/// dependency of this app (see mobile/pubspec.yaml), and a real token
/// additionally needs a configured Firebase project --
/// INFRASTRUCTURE_READINESS.md lists "Firebase Project" as unconfigured,
/// needed by Sprint 5. Adding that whole platform-integration surface is
/// explicitly out of this task's scope (Task 7 is the onboarding *step*,
/// Task 8 is the *backend* endpoint -- neither is "set up push
/// notification infrastructure project-wide").
///
/// [UnavailablePushNotificationPermissionClient] is therefore the only
/// implementation: it always resolves to not-granted/no-token, which is
/// the honest answer given what's actually wired up, not a mock
/// pretending success. core/di/push_notification_providers.dart binds
/// it; a future Sprint 5 session adds the real plugin-backed
/// implementation and swaps the binding there -- nothing above this
/// interface needs to change. See ENGINEERING_DECISION_LOG.md.
abstract interface class PushNotificationPermissionClient {
  Future<PushPermissionResult> requestPermission();
}

class UnavailablePushNotificationPermissionClient
    implements PushNotificationPermissionClient {
  @override
  Future<PushPermissionResult> requestPermission() async {
    return const PushPermissionResult(granted: false, pushToken: null);
  }
}
