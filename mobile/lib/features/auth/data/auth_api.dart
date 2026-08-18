import 'package:dio/dio.dart';

import 'models/auth_session.dart';
import 'models/auth_tokens.dart';

/// Raw HTTP calls against the backend's auth endpoints
/// (backend/app/Modules/Auth/routes.php, mounted under `/api/v1` --
/// docs/05-api-specification.md section 3). Returns parsed models or lets
/// [DioException] propagate -- [AuthRepository] is responsible for
/// mapping exceptions into [Failure]s and coordinating token storage;
/// this class only knows how to talk to the server.
///
/// Email/password only, per this task's scope -- `POST
/// /auth/oauth/google` and `POST /auth/oauth/apple` are deliberately not
/// wrapped here.
///
/// Extracted as an interface ([AuthApiClient]) purely so
/// [AuthRepository] can be unit-tested against a fake implementation
/// without a real Dio/network round trip -- see auth_repository_test.dart.
abstract interface class AuthApiClient {
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String platform,
    String? deviceName,
  });

  Future<AuthSession> login({
    required String email,
    required String password,
    required String platform,
    String? deviceName,
  });

  Future<AuthTokens> refresh(String refreshToken);

  Future<void> logout(String refreshToken);
}

class AuthApi implements AuthApiClient {
  AuthApi(this._dio);

  final Dio _dio;

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String platform,
    String? deviceName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'platform': platform,
        'deviceName': ?deviceName,
      },
    );
    return AuthSession.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
    required String platform,
    String? deviceName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'auth/login',
      data: {
        'email': email,
        'password': password,
        'platform': platform,
        'deviceName': ?deviceName,
      },
    );
    return AuthSession.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'auth/refresh',
      data: {'refreshToken': refreshToken},
      // This call must never itself trigger AuthInterceptor's 401-refresh
      // handling (that path is already excluded via the interceptor's own
      // exempt-path list) -- no special options needed here beyond that.
    );
    return AuthTokens.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// The access token authenticates the caller (via the `Authorization`
  /// header, attached by [AuthInterceptor]); `refreshToken` in the body
  /// identifies which device session to revoke -- see
  /// backend/app/Modules/Auth/Http/Requests/LogoutRequest.php.
  @override
  Future<void> logout(String refreshToken) async {
    await _dio.post<void>('auth/logout', data: {'refreshToken': refreshToken});
  }
}
