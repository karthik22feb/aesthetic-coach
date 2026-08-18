import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_notifier.dart';
import '../../features/auth/data/auth_api.dart';
import '../../features/auth/data/auth_repository.dart';
import '../error/failure.dart';
import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../network/auth_token_store.dart';
import '../storage/secure_token_storage.dart';

/// Central DI wiring for the networking + auth-data layer, per
/// docs/08-mobile-architecture.md section 8 ("Riverpod **is** the DI
/// mechanism ... `Provider`/`Provider.family` definitions in `core/di/`
/// wire concrete implementations ... behind repository interfaces").
///
/// This is also where [AuthInterceptor] gets its callbacks -- the one
/// place allowed to bridge core/network (feature-agnostic) and
/// features/auth/ (see auth_interceptor.dart's docblock for why the
/// interceptor class itself doesn't import features/auth/ directly).
///
/// Each provider's builder is a standalone, explicitly-signed private
/// function (not an inline closure) -- `dioProvider`'s builder reads
/// `authRepositoryProvider`, which itself is built from `dioProvider`.
/// That runtime dependency cycle (broken in practice by callbacks only
/// being *invoked* well after both providers finish constructing, never
/// during construction itself) otherwise defeats Dart's top-level type
/// inference when written as inline closures assigned directly to
/// `final` variables ("top_level_cycle").
final secureTokenStorageProvider = Provider<SecureTokenStorage>(
  _buildSecureTokenStorage,
);
final dioProvider = Provider<Dio>(_buildDio);
final authApiProvider = Provider<AuthApi>(_buildAuthApi);
final authRepositoryProvider = Provider<AuthRepositoryContract>(
  _buildAuthRepository,
);

SecureTokenStorage _buildSecureTokenStorage(Ref ref) => SecureTokenStorage();

Dio _buildDio(Ref ref) {
  final dio = ApiClient.createDio();

  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      getAccessToken: () async => ref.read(authTokenStoreProvider),
      refreshTokens: () async {
        try {
          await ref.read(authRepositoryProvider).refresh();
          return true;
        } on Failure {
          return false;
        }
      },
      onSessionRevoked: () =>
          ref.read(authNotifierProvider.notifier).handleSessionRevoked(),
    ),
  );

  return dio;
}

AuthApi _buildAuthApi(Ref ref) => AuthApi(ref.watch(dioProvider));

AuthRepositoryContract _buildAuthRepository(Ref ref) {
  return AuthRepository(
    api: ref.watch(authApiProvider),
    tokenStorage: ref.watch(secureTokenStorageProvider),
    ref: ref,
  );
}
