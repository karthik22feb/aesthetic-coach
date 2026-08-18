import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_notifier.dart';
import '../features/auth/application/auth_state.dart';

/// Bridges [authNotifierProvider]'s changes to go_router's
/// `refreshListenable`, so the router re-evaluates its `redirect`
/// callback whenever auth status changes, without rebuilding the
/// [GoRouter] instance itself (which owns navigation history and
/// shouldn't be recreated on every auth transition).
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    _subscription = ref.listen(
      authNotifierProvider,
      (previous, next) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
