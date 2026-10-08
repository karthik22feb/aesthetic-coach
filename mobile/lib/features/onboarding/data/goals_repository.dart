import 'package:dio/dio.dart';

import '../../../core/error/failure.dart';
import 'goals_api.dart';
import 'models/goal.dart';
import 'models/onboarding_enums.dart';

/// Coordinates [GoalsApiClient] and failure-mapping, same split as
/// [ProfileRepository] (features/profile/data/profile_repository.dart).
/// Written against the interface, not [GoalsApi]/[MockGoalsApi]
/// specifically, so which one is actually wired up
/// (core/di/goals_providers.dart) is invisible here.
abstract interface class GoalsRepositoryContract {
  Future<Goal> createGoal({required GoalType type, required String title});
}

class GoalsRepository implements GoalsRepositoryContract {
  GoalsRepository(this._api);

  final GoalsApiClient _api;

  @override
  Future<Goal> createGoal({
    required GoalType type,
    required String title,
  }) async {
    try {
      return await _api.createGoal(type: type, title: title);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Duplicated from ProfileRepository._mapDioException rather than
  /// shared -- same reasoning as that class's own docblock: refactoring
  /// existing, already-tested code into a shared helper is out of this
  /// task's scope. [MockGoalsApi] never throws [DioException], so this
  /// path is only reachable once the real [GoalsApi] is wired up.
  Failure _mapDioException(DioException e) {
    final response = e.response;
    if (response == null) {
      return const NetworkFailure();
    }

    final body = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : null;
    final error = body?['error'] is Map<String, dynamic>
        ? body!['error'] as Map<String, dynamic>
        : null;
    final message = error?['message'] as String?;

    switch (response.statusCode) {
      case 422:
        final rawDetails = error?['details'];
        final details = <String, List<String>>{};
        if (rawDetails is Map<String, dynamic>) {
          for (final entry in rawDetails.entries) {
            details[entry.key] = (entry.value as List).cast<String>();
          }
        }
        return ValidationFailure(
          details,
          message ?? 'Some fields need attention.',
        );
      case 401:
        return AuthFailure(
          message: message ?? 'Your session has expired. Please log in again.',
          sessionRevoked: true,
        );
      case 429:
        return const RateLimitedFailure();
      default:
        return const ServerFailure();
    }
  }
}
