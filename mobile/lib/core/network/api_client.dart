import 'package:dio/dio.dart';

import 'api_config.dart';

/// Builds the shared [Dio] instance's base configuration. Interceptors
/// ([AuthInterceptor] and anything logging-related) are attached at DI
/// wiring time (lib/core/di/network_providers.dart), not here, since they
/// need callbacks into feature-layer state that this file must stay free
/// of, per docs/08-mobile-architecture.md section 9.
///
/// No request/response logging interceptor is added -- per this task's
/// security requirements (never log Authorization headers, tokens, or
/// passwords), and Dio's built-in LogInterceptor would print headers and
/// request bodies by default, which is exactly what must not happen for
/// this module.
class ApiClient {
  static Dio createDio() {
    return Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
        headers: {'Accept': 'application/json'},
      ),
    );
  }
}
