import 'package:dio/dio.dart';

/// Raw calls against `POST /devices` (docs/05-api-specification.md
/// section 6.11; backend/app/Modules/Auth/Http/Controllers/
/// DeviceController.php, Sprint 2 Task 8). Interface kept separate from
/// the implementation for the same reason as [ProfileApiClient]/
/// [GoalsApiClient] -- callers depend on a contract, not a transport --
/// though unlike [GoalsApiClient] there is no mock implementation here:
/// this endpoint is real and already wired up (Task 8 shipped alongside
/// this client, not deferred), so [DevicesApi] is the only
/// implementation.
abstract interface class DevicesApiClient {
  /// Registers [pushToken] for the current session's device. No
  /// response body on success (the backend returns 204) -- see
  /// DeviceController::store's docblock.
  Future<void> registerDevice(String pushToken);
}

class DevicesApi implements DevicesApiClient {
  DevicesApi(this._dio);

  final Dio _dio;

  @override
  Future<void> registerDevice(String pushToken) async {
    await _dio.post<void>('devices', data: {'pushToken': pushToken});
  }
}
