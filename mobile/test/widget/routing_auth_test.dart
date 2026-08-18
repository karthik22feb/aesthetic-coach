import 'package:aesthetic_coach/app/app.dart';
import 'package:aesthetic_coach/app/router.dart';
import 'package:aesthetic_coach/core/di/network_providers.dart';
import 'package:aesthetic_coach/core/error/failure.dart';
import 'package:aesthetic_coach/features/auth/data/auth_repository.dart';
import 'package:aesthetic_coach/features/auth/data/models/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unlike the per-screen fakes in login_screen_test.dart /
/// signup_screen_test.dart (which always fail `refresh()`, since those
/// tests don't care about session restoration), this fake succeeds
/// `refresh()` by default -- the more relevant default for exercising
/// the Splash -> authenticated path end to end.
class _FakeAuthRepository implements AuthRepositoryContract {
  Object? refreshError;
  Object? loginError;
  Object? registerError;

  @override
  Future<void> refresh() async {
    if (refreshError != null) throw refreshError!;
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
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
  }) async {
    if (registerError != null) throw registerError!;
    return AuthUser(id: '1', name: name, email: email, emailVerified: false);
  }

  @override
  Future<void> logout() async {}
}

Widget _app(_FakeAuthRepository fakeRepository) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    child: const AestheticCoachApp(),
  );
}

void main() {
  group('Authentication routing', () {
    testWidgets(
      'boots on Splash, then redirects to Login when session restoration fails',
      (tester) async {
        final fake = _FakeAuthRepository()
          ..refreshError = const AuthFailure(message: 'No session to restore.');
        await tester.pumpWidget(_app(fake));

        // Very first frame: still initializing, Splash is shown.
        expect(find.byKey(const Key('splash_brand_mark')), findsOneWidget);

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      },
    );

    testWidgets(
      'boots on Splash, then redirects straight to the app shell when session restoration succeeds',
      (tester) async {
        await tester.pumpWidget(_app(_FakeAuthRepository()));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('home_screen_content')), findsOneWidget);
      },
    );

    testWidgets('a successful login navigates from Login into the app shell', (
      tester,
    ) async {
      final fake = _FakeAuthRepository()
        ..refreshError = const AuthFailure(message: 'No session to restore.');
      await tester.pumpWidget(_app(fake));
      await tester.pumpAndSettle(); // resolves to Login

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

      expect(find.byKey(const Key('home_screen_content')), findsOneWidget);
    });

    testWidgets(
      'a successful registration navigates from Signup into the app shell',
      (tester) async {
        final fake = _FakeAuthRepository()
          ..refreshError = const AuthFailure(message: 'No session to restore.');
        await tester.pumpWidget(_app(fake));
        await tester.pumpAndSettle(); // resolves to Login

        await tester.tap(find.byKey(const Key('login_signup_link')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('signup_name_field')), findsOneWidget);

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
          'correct-horse-battery1',
        );
        await tester.tap(find.byKey(const Key('signup_submit_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('home_screen_content')), findsOneWidget);
      },
    );

    testWidgets(
      'an authenticated user is redirected away from /login back to the app shell',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const AestheticCoachApp(),
          ),
        );
        await tester.pumpAndSettle(); // resolves to authenticated + Home (refresh succeeds by default)
        expect(find.byKey(const Key('home_screen_content')), findsOneWidget);

        container.read(routerProvider).go('/login');
        await tester.pumpAndSettle();

        // The redirect guard sends an already-authenticated user straight
        // back to the app shell -- Login must never be reachable here.
        expect(find.byKey(const Key('login_email_field')), findsNothing);
        expect(find.byKey(const Key('home_screen_content')), findsOneWidget);
      },
    );
  });
}
