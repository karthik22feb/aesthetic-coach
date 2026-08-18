/// Typed failures surfaced to the UI, per
/// docs/08-mobile-architecture.md section 7 ("Error Handling") --
/// repository/network layers map raw exceptions into one of these rather
/// than letting the UI handle Dio/HTTP details directly.
sealed class Failure {
  const Failure();
}

/// No connectivity, DNS failure, timeout, or any other transport-level
/// error that never reached the server.
class NetworkFailure extends Failure {
  const NetworkFailure([
    this.message = 'Unable to reach the server. Check your connection.',
  ]);

  final String message;
}

/// 422 validation_failed -- field-level errors from the backend's
/// standard error envelope (docs/05-api-specification.md section 4).
class ValidationFailure extends Failure {
  const ValidationFailure(
    this.fieldErrors, [
    this.message = 'Some fields need attention.',
  ]);

  final Map<String, List<String>> fieldErrors;
  final String message;
}

/// 401 unauthenticated (bad credentials) or 401 session_revoked.
/// [sessionRevoked] distinguishes the two: session_revoked means the
/// user's local session must be cleared and they must log in again.
class AuthFailure extends Failure {
  const AuthFailure({required this.message, this.sessionRevoked = false});

  final String message;
  final bool sessionRevoked;
}

/// 429 rate_limited.
class RateLimitedFailure extends Failure {
  const RateLimitedFailure([
    this.message = 'Too many attempts. Please wait and try again.',
  ]);

  final String message;
}

/// 500/other unexpected server error, or a response that doesn't match
/// the expected envelope shape.
class ServerFailure extends Failure {
  const ServerFailure([
    this.message = 'Something went wrong on our end. Please try again.',
  ]);

  final String message;
}
