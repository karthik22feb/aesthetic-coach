import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/data/goals_api.dart';
import '../../features/onboarding/data/goals_repository.dart';

/// DI wiring for the onboarding goal-creation data layer, per
/// docs/08-mobile-architecture.md section 8 -- same pattern as
/// profile_providers.dart.
///
/// **Deliberately binds [MockGoalsApi], not [GoalsApi]**: the real
/// `POST /goals` endpoint this calls against doesn't exist on the
/// backend yet (Sprint 4 scope -- see goals_api.dart's docblock and
/// ENGINEERING_DECISION_LOG.md). When that endpoint ships, flip this one
/// line to `GoalsApi(ref.watch(dioProvider))` -- nothing else in this
/// feature (repository, notifier, screens, tests against the
/// repository contract) needs to change, since both implementations
/// satisfy the same [GoalsApiClient] interface.
final goalsApiProvider = Provider<GoalsApiClient>((ref) => MockGoalsApi());

final goalsRepositoryProvider = Provider<GoalsRepositoryContract>(
  (ref) => GoalsRepository(ref.watch(goalsApiProvider)),
);
