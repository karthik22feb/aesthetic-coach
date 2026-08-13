import 'package:flutter/material.dart';

/// Placeholder for the Nutrition tab (daily macro summary, meal log, food
/// search -- docs/06-ui-ux-design-system.md section 4). Intentionally empty
/// of feature logic -- see home_screen.dart's docblock.
class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Nutrition', key: Key('nutrition_screen_content')),
      ),
    );
  }
}
