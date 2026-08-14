import 'package:flutter/material.dart';

/// Placeholder for the Progress tab (body metrics, goals, habits, historical
/// DFS trend -- docs/06-ui-ux-design-system.md section 4). Intentionally
/// empty of feature logic -- see home_screen.dart's docblock.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Progress', key: Key('progress_screen_content')),
      ),
    );
  }
}
