import 'dart:math';

import 'package:dio/dio.dart';

import 'models/goal.dart';
import 'models/onboarding_enums.dart';

/// Raw calls against `POST /goals` (docs/features/onboarding.md's APIs
/// section; docs/features/goals.md). Interface kept separate from the
/// implementation for the same reason as [ProfileApiClient]
/// (features/profile/data/profile_api.dart) -- so callers depend on a
/// contract, not a transport -- but here that split is also what makes
/// [MockGoalsApi] possible, see this file's bottom section.
abstract interface class GoalsApiClient {
  Future<Goal> createGoal({required GoalType type, required String title});
}

/// The real, documented implementation -- calls `POST /goals` exactly as
/// specified in docs/05-api-specification.md's endpoint reference. **Not
/// currently wired up anywhere** (see core/di/goals_providers.dart):
/// `POST /goals` does not exist on the backend yet (its full CRUD
/// endpoint is explicitly Sprint 4 scope, per
/// docs/TASK_BREAKDOWN.md § Sprint 2, Task 4's own note -- only the
/// migration/model landed in Sprint 2). This class exists now, written
/// against the documented contract, so wiring up the real backend later
/// is a one-line change in goals_providers.dart (swap [MockGoalsApi] for
/// this class) with no change needed anywhere else in this feature --
/// see ENGINEERING_DECISION_LOG.md for the decision this resolves.
class GoalsApi implements GoalsApiClient {
  GoalsApi(this._dio);

  final Dio _dio;

  @override
  Future<Goal> createGoal({
    required GoalType type,
    required String title,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'goals',
      data: {'type': type.wireValue, 'title': title},
    );
    return Goal.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}

/// Stands in for [GoalsApi] until the real `POST /goals` endpoint ships
/// (Sprint 4) -- the project's established pattern for a documented API
/// contract whose backend doesn't exist yet, mirroring
/// docs/10-testing-strategy.md section 5's `FakeClaudeProvider
/// implementing AiProviderInterface` (a recorded-response fake behind
/// the real interface, not a different code path). Makes no network
/// call and cannot fail with a [DioException] -- callers (via
/// [GoalsRepository]) still go through the same success/[Failure] path
/// as the real implementation, so swapping this out later changes
/// nothing above this file.
///
/// Generates a client-side-only id (never a real server-assigned one)
/// so the rest of the onboarding flow has *something* to reference for
/// this session -- that id is never sent anywhere and is not expected to
/// remain valid once a real backend-issued goal eventually exists for
/// this user.
class MockGoalsApi implements GoalsApiClient {
  final _random = Random();

  @override
  Future<Goal> createGoal({
    required GoalType type,
    required String title,
  }) async {
    // Mirrors a real request's async nature (so UI loading states are
    // genuinely exercised in tests/manual QA) without an actual network
    // round trip.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return Goal(
      id: 'mock-goal-${_random.nextInt(1 << 32)}',
      type: type,
      title: title,
    );
  }
}
