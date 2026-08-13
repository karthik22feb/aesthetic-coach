import 'package:flutter/material.dart';

/// Placeholder for the "Train" tab (workout history, start-workout flow,
/// exercise library -- docs/06-ui-ux-design-system.md section 4). Lives
/// under the `workouts` feature folder (docs/08-mobile-architecture.md
/// section 2); "Train" is only the user-facing tab label. Intentionally
/// empty of feature logic -- see home_screen.dart's docblock.
class TrainScreen extends StatelessWidget {
  const TrainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Train', key: Key('train_screen_content'))),
    );
  }
}
