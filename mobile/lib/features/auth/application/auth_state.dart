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
  const AuthState({
    required this.status,
    this.user,
    this.failure,
    this.justRegistered = false,
  });

  static const initial = AuthState(status: AuthStatus.initializing);

  final AuthStatus status;
  final AuthUser? user;
  final Failure? failure;

  /// True only immediately after a successful [AuthNotifier.register]
  /// call in *this* app session -- never set by login or session
  /// restore. The router (router.dart) reads this to send a freshly
  /// registered user into Onboarding (Sprint 2, Task 5) instead of
  /// straight to the app shell, per signup_screen.dart's documented
  /// destination. Deliberately in-memory only, not persisted: there is
  /// no documented server-side signal for "has this user completed
  /// onboarding" (no `GET /goals`, no onboarding-completion flag on
  /// `/me`), so this cannot and does not survive an app restart -- see
  /// OnboardingFlowScreen's docblock for the follow-up this implies.
  final bool justRegistered;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    Failure? failure,
    bool clearFailure = false,
    bool? justRegistered,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      failure: clearFailure ? null : (failure ?? this.failure),
      justRegistered: justRegistered ?? this.justRegistered,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AuthState &&
      other.status == status &&
      other.user == user &&
      other.failure == failure &&
      other.justRegistered == justRegistered;

  @override
  int get hashCode => Object.hash(status, user, failure, justRegistered);

  /// Deliberately prints every field -- safe to do since neither
  /// [AuthUser] nor any [Failure] subtype ever carries a raw token (see
  /// test/unit/auth_security_test.dart's dedicated check for this).
  @override
  String toString() =>
      'AuthState(status: $status, user: $user, failure: $failure, '
      'justRegistered: $justRegistered)';
}
