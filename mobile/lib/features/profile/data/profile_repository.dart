import 'package:dio/dio.dart';

import '../../../core/error/failure.dart';
import 'models/user_profile.dart';
import 'profile_api.dart';

/// Coordinates [ProfileApi] and failure-mapping -- no local persistence
/// is involved (unlike [AuthRepository], profile data isn't cached to
/// secure storage; it's re-fetched from the server on each screen
/// visit, per docs/screens/profile.md's "cached-first rendering" being a
/// future concern, not this task's scope).
///
/// Every method either returns successfully or throws a [Failure];
/// callers catch `on Failure`, matching the pattern established by
/// [AuthRepository].
abstract interface class ProfileRepositoryContract {
  Future<UserProfile> getProfile();
  Future<UserProfile> updateProfile(Map<String, dynamic> changes);
}

class ProfileRepository implements ProfileRepositoryContract {
  ProfileRepository(this._api);

  final ProfileApiClient _api;

  @override
  Future<UserProfile> getProfile() async {
    try {
      return await _api.getProfile();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<UserProfile> updateProfile(Map<String, dynamic> changes) async {
    try {
      return await _api.updateProfile(changes);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Duplicated from `AuthRepository._mapDioException` rather than
  /// extracted into a shared helper -- this task's scope is the Profile
  /// screen only, and refactoring the existing, already-tested
  /// AuthRepository is deliberately out of scope (see this session's
  /// task boundary: "do not modify unrelated code"). Behavior is kept
  /// identical to that implementation.
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
