import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Placeholder for the Home tab (DFS ring, today's plan, coach's top
/// recommendation -- docs/06-ui-ux-design-system.md section 4). Intentionally
/// empty of feature logic; this session (Tasks 5-7) only establishes the
/// navigable route, not the feature itself.
///
/// The profile-icon AppBar action (Task 2, Sprint 2) is the one addition
/// on top of that placeholder -- Profile isn't one of the 5 bottom-nav
/// tabs (docs/06-ui-ux-design-system.md section 4 fixes those at Home/
/// Train/Coach/Nutrition/Progress), so it needs an explicit entry point
/// somewhere; Home is the natural landing surface for it until Settings
/// (Sprint 2, Task 3) exists with its own documented gear-icon link.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            key: const Key('home_profile_button'),
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: const Center(child: Text('Home', key: Key('home_screen_content'))),
    );
  }
}
