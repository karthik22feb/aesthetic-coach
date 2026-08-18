import 'package:aesthetic_coach/core/error/failure.dart';
import 'package:aesthetic_coach/core/network/auth_token_store.dart';
import 'package:aesthetic_coach/core/storage/secure_token_storage.dart';
import 'package:aesthetic_coach/features/auth/data/auth_api.dart';
import 'package:aesthetic_coach/features/auth/data/auth_repository.dart';
import 'package:aesthetic_coach/features/auth/data/models/auth_session.dart';
import 'package:aesthetic_coach/features/auth/data/models/auth_tokens.dart';
import 'package:aesthetic_coach/features/auth/data/models/auth_user.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  Object? registerError;
  Object? loginError;
  Object? refreshError;
  Object? logoutError;

  AuthSession sessionResponse = const AuthSession(
    user: AuthUser(
      id: '1',
      name: 'Priya Shah',
      email: 'priya@example.com',
      emailVerified: false,
    ),
    tokens: AuthTokens(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      expiresIn: 900,
    ),
  );

  AuthTokens refreshResponse = const AuthTokens(
    accessToken: 'access-2',
    refreshToken: 'refresh-2',
    expiresIn: 900,
  );

  String? lastLogoutRefreshToken;

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String platform,
    String? deviceName,
  }) async {
    if (registerError != null) throw registerError!;
    return sessionResponse;
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
    required String platform,
    String? deviceName,
  }) async {
    if (loginError != null) throw loginError!;
    return sessionResponse;
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    if (refreshError != null) throw refreshError!;
    return refreshResponse;
  }

  @override
  Future<void> logout(String refreshToken) async {
    lastLogoutRefreshToken = refreshToken;
    if (logoutError != null) throw logoutError!;
  }
}

DioException _dioError({required int statusCode, Map<String, dynamic>? data}) {
  final options = RequestOptions(path: 'auth/x');
  return DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: statusCode,
      data: data,
    ),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  group('AuthRepository', () {
    late _FakeStore fakeStore;
    late _FakeAuthApi fakeApi;
    late SecureTokenStorage tokenStorage;
    late ProviderContainer container;
    late Ref ref;
    late AuthRepository repository;

    setUp(() {
      fakeStore = _FakeStore();
      fakeApi = _FakeAuthApi();
      tokenStorage = SecureTokenStorage(store: fakeStore);
      container = ProviderContainer();
      // Standard Riverpod-test trick to obtain a real `Ref`.
      final refProvider = Provider<Ref>((ref) => ref);
      ref = container.read(refProvider);
      repository = AuthRepository(
        api: fakeApi,
        tokenStorage: tokenStorage,
        ref: ref,
      );
    });

    tearDown(() => container.dispose());

    test(
      'login success persists refresh token and in-memory access token',
      () async {
        final user = await repository.login(
          email: 'priya@example.com',
          password: 'correct-horse-battery1',
        );

        expect(user.email, 'priya@example.com');
        expect(await tokenStorage.readRefreshToken(), 'refresh-1');
        expect(container.read(authTokenStoreProvider), 'access-1');
      },
    );

    test(
      'login with invalid credentials throws AuthFailure and persists nothing',
      () async {
        fakeApi.loginError = _dioError(
          statusCode: 401,
          data: {
            'error': {
              'code': 'unauthenticated',
              'message': 'The provided credentials are incorrect.',
            },
          },
        );

        await expectLater(
          repository.login(email: 'x@example.com', password: 'wrong'),
          throwsA(
            isA<AuthFailure>().having(
              (f) => f.sessionRevoked,
              'sessionRevoked',
              isFalse,
            ),
          ),
        );
        expect(await tokenStorage.readRefreshToken(), isNull);
        expect(container.read(authTokenStoreProvider), isNull);
      },
    );

    test('register success persists tokens', () async {
      final user = await repository.register(
        name: 'Priya Shah',
        email: 'priya@example.com',
        password: 'correct-horse-battery1',
      );

      expect(user.name, 'Priya Shah');
      expect(await tokenStorage.readRefreshToken(), 'refresh-1');
    });

    test('register with server validation failure throws ValidationFailure with field details', () async {
      fakeApi.registerError = _dioError(
        statusCode: 422,
        data: {
          'error': {
            'code': 'validation_failed',
            'message': 'The given data was invalid.',
            'details': {
              'email': ['The email has already been taken.'],
            },
          },
        },
      );

      await expectLater(
        repository.register(
          name: 'X',
          email: 'taken@example.com',
          password: 'correct-horse-battery1',
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.fieldErrors['email'],
            'fieldErrors[email]',
            ['The email has already been taken.'],
          ),
        ),
      );
    });

    test('refresh with no stored refresh token throws immediately without calling the API', () async {
      await expectLater(repository.refresh(), throwsA(isA<AuthFailure>()));
    });

    test('refresh success replaces the stored refresh token (rotation) and updates access token', () async {
      await tokenStorage.saveRefreshToken('refresh-1');
      container
          .read(authTokenStoreProvider.notifier)
          .setAccessToken('access-1');

      await repository.refresh();

      expect(await tokenStorage.readRefreshToken(), 'refresh-2');
      expect(container.read(authTokenStoreProvider), 'access-2');
    });

    test(
      'refresh returning session_revoked clears all local credentials',
      () async {
        await tokenStorage.saveRefreshToken('refresh-1');
        container
            .read(authTokenStoreProvider.notifier)
            .setAccessToken('access-1');
        fakeApi.refreshError = _dioError(
          statusCode: 401,
          data: {
            'error': {
              'code': 'session_revoked',
              'message': 'This session has been revoked.',
            },
          },
        );

        await expectLater(
          repository.refresh(),
          throwsA(
            isA<AuthFailure>().having(
              (f) => f.sessionRevoked,
              'sessionRevoked',
              isTrue,
            ),
          ),
        );
        expect(await tokenStorage.readRefreshToken(), isNull);
        expect(container.read(authTokenStoreProvider), isNull);
      },
    );

    test(
      'logout when session already invalid still clears local credentials',
      () async {
        await tokenStorage.saveRefreshToken('refresh-1');
        container
            .read(authTokenStoreProvider.notifier)
            .setAccessToken('access-1');
        fakeApi.logoutError = _dioError(
          statusCode: 401,
          data: {
            'error': {'code': 'unauthenticated', 'message': 'x'},
          },
        );

        // Must not throw -- the user must never remain locally
        // authenticated because the logout API call failed.
        await expectLater(repository.logout(), completes);

        expect(await tokenStorage.readRefreshToken(), isNull);
        expect(container.read(authTokenStoreProvider), isNull);
        expect(fakeApi.lastLogoutRefreshToken, 'refresh-1');
      },
    );

    test('logout success clears local credentials and calls the API with the stored refresh token', () async {
      await tokenStorage.saveRefreshToken('refresh-1');
      container
          .read(authTokenStoreProvider.notifier)
          .setAccessToken('access-1');

      await repository.logout();

      expect(fakeApi.lastLogoutRefreshToken, 'refresh-1');
      expect(await tokenStorage.readRefreshToken(), isNull);
      expect(container.read(authTokenStoreProvider), isNull);
    });
  });
}
