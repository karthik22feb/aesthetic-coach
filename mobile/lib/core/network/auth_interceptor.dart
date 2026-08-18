import 'package:dio/dio.dart';

/// Paths that must never trigger the 401-refresh flow: a 401 from any of
/// these means "your credentials/refresh-token are actually wrong", not
/// "your access token expired" -- retrying via refresh would be
/// meaningless (login/register) or would recurse into itself (refresh).
const _refreshExemptPaths = ['auth/login', 'auth/register', 'auth/refresh'];

/// Attaches the access token to outgoing requests and transparently
/// refreshes it on a 401, per docs/08-mobile-architecture.md section 9
/// ("AuthInterceptor ... attaches access token, triggers the refresh flow
/// ... transparently on 401, queues concurrent requests during a
/// refresh").
///
/// Deliberately takes callbacks instead of importing features/auth/
/// directly, so this class stays testable in isolation and the core
/// networking layer stays feature-agnostic -- the actual wiring to
/// [AuthNotifier] happens in lib/core/di/network_providers.dart.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.getAccessToken,
    required this.refreshTokens,
    required this.onSessionRevoked,
  });

  /// The same [Dio] instance this interceptor is attached to -- used to
  /// retry the original request after a successful refresh via
  /// `dio.fetch`, which re-runs the interceptor chain (so the retried
  /// request picks up the freshly-refreshed token via [getAccessToken]).
  final Dio dio;

  final Future<String?> Function() getAccessToken;

  /// Performs the actual `/auth/refresh` call and persists the result.
  /// Returns `true` if a new access token is now available via
  /// [getAccessToken], `false` if the refresh failed (session revoked).
  final Future<bool> Function() refreshTokens;

  final void Function() onSessionRevoked;

  /// Single-flight guard: concurrent 401s share this one in-flight
  /// refresh instead of each starting their own (docs/08-mobile-
  /// architecture.md section 9's "queues concurrent requests during a
  /// refresh").
  Future<bool>? _refreshInFlight;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final options = err.requestOptions;

    final isUnauthorized = response?.statusCode == 401;
    final alreadyRetried = options.extra['authRetried'] == true;
    final isExempt = _refreshExemptPaths.any(
      (path) => options.path.contains(path),
    );

    if (!isUnauthorized || alreadyRetried || isExempt) {
      handler.next(err);
      return;
    }

    final refreshed = await (_refreshInFlight ??= _runRefresh());

    if (!refreshed) {
      onSessionRevoked();
      handler.next(err);
      return;
    }

    try {
      options.extra['authRetried'] = true;
      final retryResponse = await dio.fetch<dynamic>(options);
      handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _runRefresh() async {
    try {
      return await refreshTokens();
    } finally {
      // Cleared unconditionally (success or failure) so the *next* 401
      // triggers a fresh refresh attempt rather than replaying a stale
      // completed future.
      _refreshInFlight = null;
    }
  }
}
