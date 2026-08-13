import 'package:flutter/material.dart';

/// Minimal Material 3 light/dark themes as a placeholder foundation.
///
/// This is deliberately NOT the full design system from
/// docs/06-ui-ux-design-system.md -- extracting the actual design tokens
/// (color scale, type scale, spacing scale) is its own task, out of scope
/// for the Task 5/6/7 mobile-foundation work. Replace these with the real
/// token set when that task lands; nothing downstream should depend on
/// these exact values.
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
    ),
  );
}

// TEMPORARY deliberate formatting violation for CI negative-test verification.
final     badlyFormatted   =    1;
