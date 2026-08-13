import 'package:flutter/material.dart';

/// Placeholder for the Coach tab (persona switcher + chat, weekly review
/// card -- docs/06-ui-ux-design-system.md section 4). Intentionally empty
/// of feature logic -- see home_screen.dart's docblock.
class CoachScreen extends StatelessWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Coach', key: Key('coach_screen_content'))),
    );
  }
}
