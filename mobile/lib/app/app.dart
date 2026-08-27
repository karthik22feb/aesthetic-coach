import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/application/theme_mode_notifier.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root widget: wires go_router (via [routerProvider]) into a
/// [MaterialApp.router]. No feature/business logic lives here -- see
/// docs/08-mobile-architecture.md section 2 for where each layer belongs.
class AestheticCoachApp extends ConsumerWidget {
  const AestheticCoachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Aesthetic Coach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Dark is the primary-designed theme (UI/UX Design System section 5),
      // but the app follows the system setting by default unless the user
      // overrides it from Settings (Sprint 2, Task 3) -- both themes
      // above are fully specified, not one inverted from the other.
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
