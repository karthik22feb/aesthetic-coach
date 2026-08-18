import 'package:flutter/material.dart';

/// docs/screens/splash.md: "full-bleed brand mark ... no navigation
/// chrome". This screen has no logic of its own -- session restoration
/// runs in [AuthNotifier.build] (via [AuthNotifier.restoreSession]), and
/// [GoRouter]'s redirect (lib/app/router.dart) is what actually navigates
/// away once [AuthStatus] resolves. Keeping navigation entirely in the
/// router (rather than also here) is what avoids the "expose protected
/// screens before auth state is known" and redirect-loop pitfalls this
/// task explicitly calls out.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Aesthetic Coach, loading',
          child: Text(
            key: const Key('splash_brand_mark'),
            'Aesthetic Coach',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }
}
