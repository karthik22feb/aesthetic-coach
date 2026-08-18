import 'package:aesthetic_coach/core/di/network_providers.dart';
import 'package:aesthetic_coach/core/error/failure.dart';
import 'package:aesthetic_coach/features/auth/application/auth_notifier.dart';
import 'package:aesthetic_coach/features/auth/application/auth_state.dart';
import 'package:aesthetic_coach/features/auth/data/auth_repository.dart';
import 'package:aesthetic_coach/features/auth/data/models/auth_user.dart';
import 'package:aesthetic_coach/features/auth/presentation/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepositoryContract {
  Object? registerError;
  Duration? registerDelay;

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (registerDelay != null) await Future<void>.delayed(registerDelay!);
    if (registerError != null) throw registerError!;
    return AuthUser(id: '1', name: name, email: email, emailVerified: false);
  }

  @override
  Future<AuthUser> login({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> refresh() async =>
      throw const AuthFailure(message: 'No session to restore.');

  @override
  Future<void> logout() async {}
}

Widget _hostedSignupScreen(_FakeAuthRepository fakeRepository) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    child: const MaterialApp(home: SignupScreen()),
  );
}

void main() {
  group('SignupScreen', () {
    late _FakeAuthRepository fakeRepository;

    setUp(() => fakeRepository = _FakeAuthRepository());

    Future<void> fillValidForm(
      WidgetTester tester, {
      String password = 'correct-horse-battery1',
    }) async {
      await tester.enterText(
        find.byKey(const Key('signup_name_field')),
        'Priya Shah',
      );
      await tester.enterText(
        find.byKey(const Key('signup_email_field')),
        'priya@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('signup_password_field')),
        password,
      );
      await tester.enterText(
        find.byKey(const Key('signup_confirm_password_field')),
        password,
      );
    }

    testWidgets(
      'renders name, email, password, confirm-password, submit button, and the login link',
      (tester) async {
        await tester.pumpWidget(_hostedSignupScreen(fakeRepository));
        await tester.pump();

        expect(find.byKey(const Key('signup_name_field')), findsOneWidget);
        expect(find.byKey(const Key('signup_email_field')), findsOneWidget);
        expect(find.byKey(const Key('signup_password_field')), findsOneWidget);
        expect(
          find.byKey(const Key('signup_confirm_password_field')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('signup_submit_button')), findsOneWidget);
        expect(find.byKey(const Key('signup_login_link')), findsOneWidget);
      },
    );

    testWidgets(
      'required-field validation blocks submission when name is empty',
      (tester) async {
        await tester.pumpWidget(_hostedSignupScreen(fakeRepository));
        await tester.pump();

        await tester.enterText(
          find.byKey(const Key('signup_email_field')),
          'priya@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('signup_password_field')),
          'correct-horse-battery1',
        );
        await tester.enterText(
          find.byKey(const Key('signup_confirm_password_field')),
          'correct-horse-battery1',
        );
        await tester.tap(find.byKey(const Key('signup_submit_button')));
        await tester.pump();

        expect(find.text('Name is required'), findsOneWidget);
      },
    );

    testWidgets('shows a validation error for an invalid email', (
      tester,
    ) async {
      await tester.pumpWidget(_hostedSignupScreen(fakeRepository));
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('signup_name_field')),
        'Priya Shah',
      );
      await tester.enterText(
        find.byKey(const Key('signup_email_field')),
        'not-an-email',
      );
      await tester.enterText(
        find.byKey(const Key('signup_password_field')),
        'correct-horse-battery1',
      );
      await tester.enterText(
        find.byKey(const Key('signup_confirm_password_field')),
        'correct-horse-battery1',
      );
      await tester.tap(find.byKey(const Key('signup_submit_button')));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets(
      'enforces the BR-1 password policy client-side (too short, no letter, no digit)',
      (tester) async {
        await tester.pumpWidget(_hostedSignupScreen(fakeRepository));
        await tester.pump();

        await tester.enterText(
          find.byKey(const Key('signup_name_field')),
          'Priya Shah',
        );
        await tester.enterText(
          find.byKey(const Key('signup_email_field')),
          'priya@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('signup_password_field')),
          'short1',
        );
        await tester.enterText(
          find.byKey(const Key('signup_confirm_password_field')),
          'short1',
        );
        await tester.tap(find.byKey(const Key('signup_submit_button')));
        await tester.pump();

        expect(
          find.text('Password must be at least 10 characters'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows a validation error when confirm-password does not match',
      (tester) async {
        await tester.pumpWidget(_hostedSignupScreen(fakeRepository));
        await tester.pump();

        await tester.enterText(
          find.byKey(const Key('signup_name_field')),
          'Priya Shah',
        );
        await tester.enterText(
          find.byKey(const Key('signup_email_field')),
          'priya@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('signup_password_field')),
          'correct-horse-battery1',
        );
        await tester.enterText(
          find.byKey(const Key('signup_confirm_password_field')),
          'different-password1',
        );
        await tester.tap(find.byKey(const Key('signup_submit_button')));
        await tester.pump();

        expect(find.text('Passwords do not match'), findsOneWidget);
      },
    );

    testWidgets(
      'shows a loading spinner on the submit button while the request is in flight',
      (tester) async {
        fakeRepository.registerDelay = const Duration(milliseconds: 200);
        await tester.pumpWidget(_hostedSignupScreen(fakeRepository));
        await tester.pump();

        await fillValidForm(tester);
        await tester.tap(find.byKey(const Key('signup_submit_button')));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'shows the server-side duplicate-email validation error under the email field',
      (tester) async {
        fakeRepository.registerError = const ValidationFailure({
          'email': ['The email has already been taken.'],
        });
        await tester.pumpWidget(_hostedSignupScreen(fakeRepository));
        await tester.pump();

        await fillValidForm(tester);
        await tester.tap(find.byKey(const Key('signup_submit_button')));
        await tester.pumpAndSettle();

        expect(find.text('The email has already been taken.'), findsOneWidget);
      },
    );

    testWidgets(
      'a successful registration transitions AuthNotifier to authenticated',
      (tester) async {
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: SignupScreen()),
          ),
        );
        await tester.pump();

        await fillValidForm(tester);
        await tester.tap(find.byKey(const Key('signup_submit_button')));
        await tester.pumpAndSettle();

        expect(
          container.read(authNotifierProvider).status,
          AuthStatus.authenticated,
        );
      },
    );
  });
}
