import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/data/devices_api.dart';
import '../../features/onboarding/data/devices_repository.dart';
import 'network_providers.dart';

/// DI wiring for the device push-token-registration data layer, per
/// docs/08-mobile-architecture.md section 8 -- same pattern as
/// profile_providers.dart/goals_providers.dart.
///
/// Unlike goals_providers.dart, this binds the **real** [DevicesApi]:
/// `POST /devices` is a real, shipped backend endpoint (Sprint 2 Task 8),
/// not a documented-but-unbuilt one -- there is nothing to mock here.
final devicesApiProvider = Provider<DevicesApiClient>(
  (ref) => DevicesApi(ref.watch(dioProvider)),
);

final devicesRepositoryProvider = Provider<DevicesRepositoryContract>(
  (ref) => DevicesRepository(ref.watch(devicesApiProvider)),
);
