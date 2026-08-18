import 'package:aesthetic_coach/core/error/failure.dart';
import 'package:aesthetic_coach/core/di/network_providers.dart';
import 'package:aesthetic_coach/core/network/auth_token_store.dart';
import 'package:aesthetic_coach/core/storage/secure_token_storage.dart';
import 'package:aesthetic_coach/features/auth/application/auth_notifier.dart';
import 'package:aesthetic_coach/features/auth/application/auth_state.dart';
import 'package:aesthetic_coach/features/auth/data/auth_api.dart';
import 'package:aesthetic_coach/features/auth/data/auth_repository.dart';
import 'package:aesthetic_coach/features/auth/data/models/auth_session.dart';
import 'package:aesthetic_coach/features/auth/data/models/auth_tokens.dart';
import 'package:aesthetic_coach/features/auth/data/models/auth_user.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Explicit security-property tests for the mobile auth module, per this
/// task's Security Gate requirements. Where a property is already an
/// incidental consequence of a functional test elsewhere
/// (auth_repository_test.dart, auth_interceptor_test.dart,
/// auth_notifier_test.dart), it's re-asserted here under its own name so
/// it's traceable as a deliberately-verified security property, not
/// just a side effect of some other test passing.

class _FakeStore implements TokenKeyValueStore {
  final Map<String, String> data = {};

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> delete(String key) async => data.remove(key);
}

class _FakeAuthApi implements AuthApiClient {
  Object? refreshError;
  int refreshCallCount = 0;

  final AuthSession sessionResponse = const AuthSession(
    user: AuthUser(
      id: '1',
      name: 'Priya Shah',
      email: 'priya@example.com',
      emailVerified: false,
    ),
    tokens: AuthTokens(
      accessToken: 'the-access-token',
      refreshToken: 'the-refresh-token',
      expiresIn: 900,
    ),
  );

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
    required String platform,
    String? deviceName,
  }) async => sessionResponse;

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String platform,
    String? deviceName,
  }) async => sessionResponse;

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    refreshCallCount++;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    if (refreshError != null) throw refreshError!;
    return const AuthTokens(
      accessToken: 'new-access',
      refreshToken: 'new-refresh',
      expiresIn: 900,
    );
  }

  @override
  Future<void> logout(String refreshToken) async {}
}

void main() {
  group('Security: token handling', () {
    late _FakeStore fakeStore;
    late _FakeAuthApi fakeApi;
    late ProviderContainer container;
    late AuthRepository repository;

    setUp(() {
      fakeStore = _FakeStore();
      fakeApi = _FakeAuthApi();
      container = ProviderContainer();
      final refProvider = Provider<Ref>((ref) => ref);
      final ref = container.read(refProvider);
      repository = AuthRepository(
        api: fakeApi,
        tokenStorage: SecureTokenStorage(store: fakeStore),
        ref: ref,
      );
    });

    tearDown(() => container.dispose());

    test('secure storage never contains the access token -- only the refresh token, under a single key', () async {
      await repository.login(
        email: 'priya@example.com',
        password: 'correct-horse-battery1',
      );

      expect(fakeStore.data, hasLength(1));
      expect(fakeStore.data.values, isNot(contains('the-access-token')));
      expect(fakeStore.data.values, contains('the-refresh-token'));
    });

    test('the access token lives only in the in-memory AuthTokenStore, never in secure storage', () async {
      await repository.login(
        email: 'priya@example.com',
        password: 'correct-horse-battery1',
      );

      expect(container.read(authTokenStoreProvider), 'the-access-token');
      expect(fakeStore.data.values, isNot(contains('the-access-token')));
    });

    test('AuthTokens.toString() redacts both tokens (defense against accidental logging)', () {
      const tokens = AuthTokens(
        accessToken: 'secret-access',
        refreshToken: 'secret-refresh',
        expiresIn: 900,
      );
      final printed = tokens.toString();

      expect(printed, isNot(contains('secret-access')));
      expect(printed, isNot(contains('secret-refresh')));
    });

    test(
      'AuthState never carries a raw token value in any of its fields',
      () async {
        final user = await repository.login(
          email: 'priya@example.com',
          password: 'correct-horse-battery1',
        );
        final state = AuthState(status: AuthStatus.authenticated, user: user);

        // AuthState only exposes status/user/failure -- user is name/email/
        // id/emailVerified only (mirrors the backend's UserResource), and
        // failure carries human-readable messages, never a token.
        expect(state.toString(), isNot(contains('the-access-token')));
        expect(state.toString(), isNot(contains('the-refresh-token')));
      },
    );

    test(
      'refresh failure (session_revoked) clears every local credential',
      () async {
        await repository.login(
          email: 'priya@example.com',
          password: 'correct-horse-battery1',
        );
        expect(fakeStore.data, isNotEmpty);
        expect(container.read(authTokenStoreProvider), isNotNull);

        final options = RequestOptions(path: 'auth/refresh');
        fakeApi.refreshError = DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: {
              'error': {'code': 'session_revoked', 'message': 'revoked'},
            },
          ),
          type: DioExceptionType.badResponse,
        );

        await expectLater(repository.refresh(), throwsA(isA<AuthFailure>()));

        expect(fakeStore.data, isEmpty);
        expect(container.read(authTokenStoreProvider), isNull);
      },
    );

    test(
      'handleSessionRevoked results in an unauthenticated AuthState',
      () async {
        final notifierContainer = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(notifierContainer.dispose);

        await notifierContainer
            .read(authNotifierProvider.notifier)
            .login(
              email: 'priya@example.com',
              password: 'correct-horse-battery1',
            );
        expect(
          notifierContainer.read(authNotifierProvider).isAuthenticated,
          isTrue,
        );

        notifierContainer
            .read(authNotifierProvider.notifier)
            .handleSessionRevoked();

        expect(
          notifierContainer.read(authNotifierProvider).isAuthenticated,
          isFalse,
        );
      },
    );

    test(
      'AuthRepository.refresh() itself is not single-flight -- concurrent 401 protection is '
      'AuthInterceptor\'s responsibility (see auth_interceptor_test.dart)',
      () async {
        await repository.login(
          email: 'priya@example.com',
          password: 'correct-horse-battery1',
        );
        fakeApi.refreshCallCount = 0;

        // Documents the actual division of responsibility: calling
        // refresh() directly and concurrently does hit the API twice
        // here, by design -- the single-flight guard lives one layer up,
        // in AuthInterceptor, which is what real concurrent-401 traffic
        // actually goes through.
        await Future.wait([repository.refresh(), repository.refresh()]);

        expect(fakeApi.refreshCallCount, 2);
      },
    );
  });
}
