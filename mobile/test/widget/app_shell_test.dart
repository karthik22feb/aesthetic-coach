import 'package:aesthetic_coach/app/app.dart';
import 'package:aesthetic_coach/features/auth/application/auth_notifier.dart';
import 'package:aesthetic_coach/features/auth/application/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Overrides [authNotifierProvider] so the shell tests exercise the
/// 5-tab navigation shell directly, as an already-authenticated user,
/// without going through [AuthNotifier.build]'s real
/// `restoreSession()` call (which would otherwise hit the network in a
/// test environment -- see auth_notifier_test.dart for testing that
/// logic itself).
class _FakeAuthenticatedNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

Widget _authenticatedApp() {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(_FakeAuthenticatedNotifier.new),
    ],
    child: const AestheticCoachApp(),
  );
}

void main() {
  group('AestheticCoachApp shell (authenticated)', () {
    testWidgets(
      'boots inside a ProviderScope and shows the Home tab by default',
      (tester) async {
        await tester.pumpWidget(_authenticatedApp());
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('home_screen_content')), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
      },
    );

    testWidgets('all 5 tab destinations are present and navigate correctly', (
      tester,
    ) async {
      await tester.pumpWidget(_authenticatedApp());
      await tester.pumpAndSettle();

      const tabs = ['Home', 'Train', 'Coach', 'Nutrition', 'Progress'];

      for (final label in tabs) {
        expect(
          find.widgetWithText(NavigationDestination, label),
          findsOneWidget,
        );
      }

      const contentKeys = [
        'home_screen_content',
        'train_screen_content',
        'coach_screen_content',
        'nutrition_screen_content',
        'progress_screen_content',
      ];

      for (var i = 0; i < tabs.length; i++) {
        await tester.tap(find.widgetWithText(NavigationDestination, tabs[i]));
        await tester.pumpAndSettle();

        expect(find.byKey(Key(contentKeys[i])), findsOneWidget);
      }
    });

    testWidgets(
      'switching tabs and back preserves each tab\'s own navigation stack (StatefulShellRoute)',
      (tester) async {
        await tester.pumpWidget(_authenticatedApp());
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(NavigationDestination, 'Train'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('train_screen_content')), findsOneWidget);

        await tester.tap(find.widgetWithText(NavigationDestination, 'Home'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('home_screen_content')), findsOneWidget);

        await tester.tap(find.widgetWithText(NavigationDestination, 'Train'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('train_screen_content')), findsOneWidget);
      },
    );
  });
}
