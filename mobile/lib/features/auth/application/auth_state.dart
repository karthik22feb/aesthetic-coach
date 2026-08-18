import '../../../core/error/failure.dart';
import '../data/models/auth_user.dart';

enum AuthStatus {
  /// App just started; session restoration (via the persisted refresh
  /// token) is in flight. The router keeps the user on Splash during
  /// this state.
  initializing,

  /// No valid session. `failure` may be set if this follows a failed
  /// login/signup attempt (the user stays on that screen and sees an
  /// inline error) or null if this follows a silent, expected outcome
  /// (e.g. no stored session to restore on first launch).
  unauthenticated,

  /// A login or signup request is in flight.
  authenticating,

  /// A valid session exists. `user` is populated after a fresh
  /// login/signup (the API returns the user object); it is `null` after
  /// a pure session-restore-via-refresh at startup, since `POST
  /// /auth/refresh` does not return user data -- see
  /// AuthRepository.refresh() and this task's Known Gaps.
  authenticated,

  /// A logout request is in flight.
  signingOut,

  /// An unexpected, non-recoverable-inline failure -- distinct from a
  /// simple failed login/signup attempt (which stays `unauthenticated`
  /// with `failure` set so the user can retry on the same form).
  error,
}

class AuthState {
  const AuthState({required this.status, this.user, this.failure});

  static const initial = AuthState(status: AuthStatus.initializing);

  final AuthStatus status;
  final AuthUser? user;
  final Failure? failure;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AuthState &&
      other.status == status &&
      other.user == user &&
      other.failure == failure;

  @override
  int get hashCode => Object.hash(status, user, failure);

  /// Deliberately prints every field -- safe to do since neither
  /// [AuthUser] nor any [Failure] subtype ever carries a raw token (see
  /// test/unit/auth_security_test.dart's dedicated check for this).
  @override
  String toString() =>
      'AuthState(status: $status, user: $user, failure: $failure)';
}
