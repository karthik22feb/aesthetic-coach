import 'package:flutter/material.dart';

/// Placeholder for the Home tab (DFS ring, today's plan, coach's top
/// recommendation -- docs/06-ui-ux-design-system.md section 4). Intentionally
/// empty of feature logic; this session (Tasks 5-7) only establishes the
/// navigable route, not the feature itself.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Home', key: Key('home_screen_content'))),
    );
  }
}
