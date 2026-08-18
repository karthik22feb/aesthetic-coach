import 'package:aesthetic_coach/core/di/network_providers.dart';
import 'package:aesthetic_coach/core/error/failure.dart';
import 'package:aesthetic_coach/features/auth/application/auth_notifier.dart';
import 'package:aesthetic_coach/features/auth/application/auth_state.dart';
import 'package:aesthetic_coach/features/auth/data/auth_repository.dart';
import 'package:aesthetic_coach/features/auth/data/models/auth_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = AuthUser(
  id: '1',
  name: 'Priya Shah',
  email: 'priya@example.com',
  emailVerified: false,
);

class _FakeAuthRepository implements AuthRepositoryContract {
  Object? loginError;
  Object? registerError;
  Object? refreshError;
  bool logoutCalled = false;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    if (loginError != null) throw loginError!;
    return _user;
  }

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (registerError != null) throw registerError!;
    return _user;
  }

  @override
  Future<void> refresh() async {
    if (refreshError != null) throw refreshError!;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

void main() {
  group('AuthNotifier', () {
    late _FakeAuthRepository fakeRepository;
    late ProviderContainer container;

    setUp(() {
      fakeRepository = _FakeAuthRepository();
      container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );
      addTearDown(container.dispose);
    });

    test('initial state is initializing', () {
      expect(
        container.read(authNotifierProvider).status,
        AuthStatus.initializing,
      );
    });

    test('restoreSession success transitions to authenticated', () async {
      await container.read(authNotifierProvider.notifier).restoreSession();

      expect(
        container.read(authNotifierProvider).status,
        AuthStatus.authenticated,
      );
    });

    test('restoreSession failure (expired/no session) transitions to unauthenticated, not error', () async {
      fakeRepository.refreshError = const AuthFailure(
        message: 'No session to restore.',
      );

      await container.read(authNotifierProvider.notifier).restoreSession();

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.unauthenticated);
      // Per docs/screens/splash.md: a failed restore is a routing
      // decision, never shown to the user as an error.
      expect(state.failure, isNull);
    });

    test(
      'login sets authenticating then authenticated with the returned user',
      () async {
        final notifier = container.read(authNotifierProvider.notifier);
        final future = notifier.login(
          email: 'priya@example.com',
          password: 'correct-horse-battery1',
        );

        expect(
          container.read(authNotifierProvider).status,
          AuthStatus.authenticating,
        );
        await future;

        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.authenticated);
        expect(state.user, _user);
      },
    );

    test('login failure returns to unauthenticated with the failure attached for the form to display', () async {
      fakeRepository.loginError = const AuthFailure(
        message: 'The provided credentials are incorrect.',
      );

      await container
          .read(authNotifierProvider.notifier)
          .login(email: 'x@example.com', password: 'wrong');

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.failure, isA<AuthFailure>());
    });

    test(
      'register success transitions to authenticated with the returned user',
      () async {
        await container
            .read(authNotifierProvider.notifier)
            .register(
              name: 'Priya Shah',
              email: 'priya@example.com',
              password: 'correct-horse-battery1',
            );

        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.authenticated);
        expect(state.user, _user);
      },
    );

    test(
      'logout transitions to unauthenticated and delegates to the repository',
      () async {
        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.login(
          email: 'priya@example.com',
          password: 'correct-horse-battery1',
        );

        await notifier.logout();

        expect(
          container.read(authNotifierProvider).status,
          AuthStatus.unauthenticated,
        );
        expect(fakeRepository.logoutCalled, isTrue);
      },
    );

    test('handleSessionRevoked forces unauthenticated with a session_revoked failure', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.login(
        email: 'priya@example.com',
        password: 'correct-horse-battery1',
      );

      notifier.handleSessionRevoked();

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(
        state.failure,
        isA<AuthFailure>().having(
          (f) => f.sessionRevoked,
          'sessionRevoked',
          isTrue,
        ),
      );
    });
  });
}
