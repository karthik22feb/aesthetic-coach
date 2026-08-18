import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/network_providers.dart';
import '../../../core/error/failure.dart';
import 'auth_state.dart';

/// Owns the app's authentication state. Hand-written `Notifier` (no
/// `riverpod_generator`/`@riverpod` codegen) -- see
/// ENGINEERING_DECISION_LOG.md for why this session continues deferring
/// codegen despite ADR-0004 naming it.
///
/// Every public method is a UI-facing action (login/register/logout) or
/// the app-startup session restore; none of them touch Dio or secure
/// storage directly -- that's [AuthRepository]'s job.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Fire-and-forget: runs after build() returns (Notifier.build must
    // be synchronous), updating state once session restoration
    // resolves. The router keeps the user on Splash while
    // status == initializing.
    Future.microtask(restoreSession);
    return AuthState.initial;
  }

  /// Maximum time Splash waits for session restoration before proceeding
  /// to Login as a safe default, per docs/screens/splash.md ("has a
  /// maximum display duration ... after which it proceeds to Login ...
  /// even if the session check hasn't resolved, to avoid an indefinitely
  /// stuck screen").
  static const restoreTimeout = Duration(seconds: 2);

  /// Attempts to restore a session from the persisted refresh token
  /// (docs/screens/splash.md). Never surfaces an error to the caller --
  /// per that screen's spec, a failed restore is "never shown to the
  /// user as an error, only as a routing decision" (falls through to
  /// Login).
  ///
  /// Guards every write with `state.status == AuthStatus.initializing`:
  /// this runs as a background fire-and-forget from [build], so if the
  /// user has already taken an explicit action (logged in, hit the
  /// Splash timeout and landed on Login, etc.) by the time this
  /// resolves, that more-recent, more-authoritative state must not be
  /// clobbered by a stale background result.
  Future<void> restoreSession() async {
    try {
      await ref.read(authRepositoryProvider).refresh().timeout(restoreTimeout);
      // No `user` available from a pure token refresh -- see AuthState's
      // docblock on the `authenticated` status.
      if (state.status == AuthStatus.initializing) {
        state = const AuthState(status: AuthStatus.authenticated);
      }
    } on Failure {
      if (state.status == AuthStatus.initializing) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } on TimeoutException {
      if (state.status == AuthStatus.initializing) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      clearFailure: true,
    );
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on Failure catch (failure) {
      state = AuthState(status: AuthStatus.unauthenticated, failure: failure);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      clearFailure: true,
    );
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .register(name: name, email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on Failure catch (failure) {
      state = AuthState(status: AuthStatus.unauthenticated, failure: failure);
    }
  }

  /// Always ends in `unauthenticated`, even if the server call inside
  /// the repository fails -- [AuthRepository.logout] already guarantees
  /// local credentials are cleared regardless, per this task's logout
  /// requirements.
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.signingOut, clearFailure: true);
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Invoked by [AuthInterceptor]'s `onSessionRevoked` callback (wired in
  /// core/di/network_providers.dart) when a background token refresh
  /// during a normal API call comes back `session_revoked`. Local
  /// credentials are already cleared by that point (inside
  /// [AuthRepository.refresh]'s failure path) -- this only updates the
  /// UI-facing state so the router redirects to Login with an
  /// explanatory message.
  void handleSessionRevoked() {
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      failure: AuthFailure(
        message: 'Your session has expired. Please log in again.',
        sessionRevoked: true,
      ),
    );
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
