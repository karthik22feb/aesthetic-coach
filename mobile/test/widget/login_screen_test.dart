import 'package:aesthetic_coach/core/di/network_providers.dart';
import 'package:aesthetic_coach/core/error/failure.dart';
import 'package:aesthetic_coach/features/auth/application/auth_notifier.dart';
import 'package:aesthetic_coach/features/auth/application/auth_state.dart';
import 'package:aesthetic_coach/features/auth/data/auth_repository.dart';
import 'package:aesthetic_coach/features/auth/data/models/auth_user.dart';
import 'package:aesthetic_coach/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A controllable fake so tests can drive every branch of
/// [LoginScreen] (success, invalid credentials, network error, ...)
/// without a real network call. `completer` lets a test hold `login()`
/// pending to assert the loading state before resolving it.
class _FakeAuthRepository implements AuthRepositoryContract {
  Object? loginError;
  Duration? loginDelay;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    if (loginDelay != null) await Future<void>.delayed(loginDelay!);
    if (loginError != null) throw loginError!;
    return const AuthUser(
      id: '1',
      name: 'Priya Shah',
      email: 'priya@example.com',
      emailVerified: false,
    );
  }

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> refresh() async =>
      throw const AuthFailure(message: 'No session to restore.');

  @override
  Future<void> logout() async {}
}

Widget _hostedLoginScreen(_FakeAuthRepository fakeRepository) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    child: const MaterialApp(home: LoginScreen()),
  );
}

void main() {
  group('LoginScreen', () {
    late _FakeAuthRepository fakeRepository;

    setUp(() => fakeRepository = _FakeAuthRepository());

    testWidgets('renders email, password, submit button, and the signup link', (
      tester,
    ) async {
      await tester.pumpWidget(_hostedLoginScreen(fakeRepository));
      await tester.pump();

      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.byKey(const Key('login_signup_link')), findsOneWidget);
    });

    testWidgets(
      'shows a validation error and does not submit for an invalid email',
      (tester) async {
        await tester.pumpWidget(_hostedLoginScreen(fakeRepository));
        await tester.pump();

        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          'not-an-email',
        );
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          'correct-horse-battery1',
        );
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pump();

        expect(find.text('Enter a valid email address'), findsOneWidget);
      },
    );

    testWidgets(
      'shows a validation error and does not submit for an empty password',
      (tester) async {
        await tester.pumpWidget(_hostedLoginScreen(fakeRepository));
        await tester.pump();

        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          'priya@example.com',
        );
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pump();

        expect(find.text('Password is required'), findsOneWidget);
      },
    );

    testWidgets(
      'shows a loading spinner on the submit button while the request is in flight',
      (tester) async {
        fakeRepository.loginDelay = const Duration(milliseconds: 200);
        await tester.pumpWidget(_hostedLoginScreen(fakeRepository));
        await tester.pump();

        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          'priya@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          'correct-horse-battery1',
        );
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        final button = tester.widget<FilledButton>(
          find.byKey(const Key('login_submit_button')),
        );
        expect(
          button.onPressed,
          isNull,
        ); // fields/button disabled during submit

        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'shows an inline error for invalid credentials without navigating away',
      (tester) async {
        fakeRepository.loginError = const AuthFailure(
          message: 'The provided credentials are incorrect.',
        );
        await tester.pumpWidget(_hostedLoginScreen(fakeRepository));
        await tester.pump();

        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          'priya@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          'wrong-password',
        );
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('login_error_text')), findsOneWidget);
        expect(
          find.text('The provided credentials are incorrect.'),
          findsOneWidget,
        );
        // Still on the login form -- no navigation was attempted by the
        // screen itself (that's the router's job on real auth success).
        expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      },
    );

    testWidgets(
      'a successful login transitions AuthNotifier to authenticated',
      (tester) async {
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: LoginScreen()),
          ),
        );
        await tester.pump();

        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          'priya@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          'correct-horse-battery1',
        );
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pumpAndSettle();

        expect(
          container.read(authNotifierProvider).status,
          AuthStatus.authenticated,
        );
      },
    );
  });
}
