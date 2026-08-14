import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/coach/presentation/coach_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/nutrition/presentation/nutrition_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/workouts/presentation/train_screen.dart';
import 'app_shell.dart';

/// The 5 primary bottom-nav tabs, per
/// docs/06-ui-ux-design-system.md section 4 ("Bottom tab bar, 5
/// destinations"): Home, Train, Coach, Nutrition, Progress. "Train" is the
/// user-facing label for the `workouts` feature (matching the folder name
/// already established in docs/08-mobile-architecture.md section 2).
///
/// Each branch is its own [StatefulShellBranch] so switching tabs preserves
/// that tab's navigation stack (docs/08-mobile-architecture.md section 3).
/// Screens are placeholders only -- no feature logic, per this session's
/// scope (Tasks 5-7: mobile foundation, not feature implementation).
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
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
