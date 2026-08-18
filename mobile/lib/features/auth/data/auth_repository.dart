import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/auth_token_store.dart';
import '../../../core/storage/secure_token_storage.dart';
import 'auth_api.dart';
import 'models/auth_session.dart';
import 'models/auth_tokens.dart';
import 'models/auth_user.dart';

/// Coordinates [AuthApi] (the server) and [SecureTokenStorage] +
/// [AuthTokenStore] (local persistence) -- per this task's requirement
/// that widgets never call Dio or token storage directly.
///
/// Every method either returns successfully or throws a [Failure]
/// (mapped from the raw [DioException] by [_mapDioException]); there is
/// no separate exception type -- callers catch `on Failure`.
///
/// Implements [AuthRepositoryContract] purely so [AuthNotifier] can be
/// unit-tested against a fake, network-free implementation -- see
/// auth_notifier_test.dart.
abstract interface class AuthRepositoryContract {
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  });
  Future<AuthUser> login({required String email, required String password});
  Future<void> refresh();
  Future<void> logout();
}

class AuthRepository implements AuthRepositoryContract {
  // Fields are private but the constructor's named parameters (api,
  // tokenStorage, ref) must stay public since this class is constructed
  // from other files (core/di/network_providers.dart, tests) -- an
  // initializing formal (this._api) would require a private-named
  // parameter, breaking cross-file construction. Deliberate, not an
  // oversight, hence the ignores below.
  AuthRepository({
    required AuthApiClient api,
    required SecureTokenStorage tokenStorage,
    required Ref ref,
  }) : _api = api, // ignore: prefer_initializing_formals
       _tokenStorage = tokenStorage, // ignore: prefer_initializing_formals
       _ref = ref; // ignore: prefer_initializing_formals

  final AuthApiClient _api;
  final SecureTokenStorage _tokenStorage;
  final Ref _ref;

  static String _currentPlatform() => Platform.isIOS ? 'ios' : 'android';

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final session = await _api.register(
        name: name,
        email: email,
        password: password,
        platform: _currentPlatform(),
      );
      await _persistSession(session);
      return session.user;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _api.login(
        email: email,
        password: password,
        platform: _currentPlatform(),
      );
      await _persistSession(session);
      return session.user;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Reads the persisted refresh token and attempts to rotate it. On
  /// success, the *new* refresh token replaces the old one in secure
  /// storage (BR-3 rotation -- the old token must never be reused) and
  /// the new access token replaces the in-memory one. On any failure
  /// (no stored token, network error, or `session_revoked`), local
  /// credentials are cleared and the failure is rethrown.
  ///
  /// Returns nothing meaningful beyond success/failure -- callers that
  /// need the user's identity after a startup refresh don't get one
  /// here, matching the actual `POST /auth/refresh` response shape
  /// (token triple only, no `user`).
  @override
  Future<void> refresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      throw const AuthFailure(message: 'No session to restore.');
    }

    try {
      final tokens = await _api.refresh(refreshToken);
      await _persistTokens(tokens);
    } on DioException catch (e) {
      await _clearLocalCredentials();
      throw _mapDioException(e);
    }
  }

  /// Always clears local credentials, even if the server call fails --
  /// per this task's requirement that the user must never remain
  /// locally authenticated because the logout API failed.
  @override
  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    try {
      if (refreshToken != null) {
        await _api.logout(refreshToken);
      }
    } on DioException {
      // Intentionally swallowed -- an already-invalid/expired session on
      // the server is not a reason to keep the user locally
      // authenticated. See class docblock.
    } finally {
      await _clearLocalCredentials();
    }
  }

  Future<void> _persistSession(AuthSession session) =>
      _persistTokens(session.tokens);

  Future<void> _persistTokens(AuthTokens tokens) async {
    await _tokenStorage.saveRefreshToken(tokens.refreshToken);
    _ref
        .read(authTokenStoreProvider.notifier)
        .setAccessToken(tokens.accessToken);
  }

  Future<void> _clearLocalCredentials() async {
    await _tokenStorage.clear();
    _ref.read(authTokenStoreProvider.notifier).setAccessToken(null);
  }

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
    final code = error?['code'] as String?;
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
          message: code == 'session_revoked'
              ? 'Your session has expired. Please log in again.'
              : (message ?? 'The provided credentials are incorrect.'),
          sessionRevoked: code == 'session_revoked',
        );
      case 429:
        return const RateLimitedFailure();
      default:
        return const ServerFailure();
    }
  }
}
