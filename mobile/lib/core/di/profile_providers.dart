import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/data/profile_api.dart';
import '../../features/profile/data/profile_repository.dart';
import 'network_providers.dart';

/// DI wiring for the profile-data layer, per docs/08-mobile-
/// architecture.md section 8 -- same pattern as network_providers.dart's
/// Auth wiring, kept in a separate file since Profile needs none of that
/// file's interceptor-callback bridging (no dependency cycle to work
/// around here, so plain top-level `final` providers are fine).
final profileApiProvider = Provider<ProfileApiClient>(
  (ref) => ProfileApi(ref.watch(dioProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepositoryContract>(
  (ref) => ProfileRepository(ref.watch(profileApiProvider)),
);
