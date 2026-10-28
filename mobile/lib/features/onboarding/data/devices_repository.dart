import 'package:dio/dio.dart';

import '../../../core/error/failure.dart';
import 'devices_api.dart';

/// Coordinates [DevicesApiClient] and failure-mapping, same split as
/// [ProfileRepository]/[GoalsRepository].
abstract interface class DevicesRepositoryContract {
  Future<void> registerDevice(String pushToken);
}

class DevicesRepository implements DevicesRepositoryContract {
  DevicesRepository(this._api);

  final DevicesApiClient _api;

  @override
  Future<void> registerDevice(String pushToken) async {
    try {
      await _api.registerDevice(pushToken);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Duplicated from ProfileRepository/GoalsRepository rather than
  /// shared -- same reasoning as those classes' own docblocks.
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
      case 404:
        return ServerFailure(
          message ?? 'This device could not be registered for notifications.',
        );
      case 429:
        return const RateLimitedFailure();
      default:
        return const ServerFailure();
    }
  }
}
