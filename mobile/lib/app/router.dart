import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_notifier.dart';
import '../features/auth/application/auth_state.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/coach/presentation/coach_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/nutrition/presentation/nutrition_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/workouts/presentation/train_screen.dart';
import 'app_shell.dart';
import 'router_refresh_notifier.dart';
import 'splash_screen.dart';

/// The 5 primary bottom-nav tabs, per
/// docs/06-ui-ux-design-system.md section 4 ("Bottom tab bar, 5
/// destinations"): Home, Train, Coach, Nutrition, Progress. "Train" is the
/// user-facing label for the `workouts` feature (matching the folder name
/// already established in docs/08-mobile-architecture.md section 2).
///
/// Each branch is its own [StatefulShellBranch] so switching tabs preserves
/// that tab's navigation stack (docs/08-mobile-architecture.md section 3).
/// Tab screens are still placeholders (Tasks 5-7 scope) -- this task
/// (17-19) adds the /splash, /login, /signup routes and the
/// authentication redirect guard around the shell.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final target = state.matchedLocation;
      final goingToSplash = target == '/splash';
      final goingToAuthScreen = target == '/login' || target == '/signup';

      // Session restoration hasn't resolved yet -- keep the user on
      // Splash regardless of what they were originally navigating to
      // (docs/screens/splash.md: never expose protected screens before
      // auth state is known).
      if (authState.status == AuthStatus.initializing) {
        return goingToSplash ? null : '/splash';
      }

      if (!authState.isAuthenticated) {
        return goingToAuthScreen ? null : '/login';
      }

      // Authenticated: Splash/Login/Signup are no longer valid
      // destinations -- everything else (the app shell and its tabs) is
      // allowed through unchanged.
      if (goingToSplash || goingToAuthScreen) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      // Top-level (not a shell branch) since Profile isn't one of the 5
      // bottom-nav tabs -- pushed from Home via context.push, so it gets
      // its own back-stack entry over whichever tab the user was on,
      // matching go_router's normal push semantics. Already covered by
      // the redirect guard above: unauthenticated access falls through
      // to the generic "not splash/not auth screen" branch, which
      // redirects to /login exactly like any other protected route.
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/train',
                builder: (context, state) => const TrainScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/coach',
                builder: (context, state) => const CoachScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/nutrition',
                builder: (context, state) => const NutritionScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
