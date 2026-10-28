import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/data/push_notification_permission_client.dart';

/// DI wiring for the onboarding notification-permission step's platform
/// capability. Binds [UnavailablePushNotificationPermissionClient] --
/// see that class's docblock for why no other implementation exists
/// yet.
final pushNotificationPermissionClientProvider =
    Provider<PushNotificationPermissionClient>(
      (ref) => UnavailablePushNotificationPermissionClient(),
    );
