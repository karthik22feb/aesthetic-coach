/// The `{ accessToken, refreshToken, expiresIn }` triple returned by
/// register/login/refresh (backend/app/Modules/Auth/Http/Controllers/
/// AuthController.php `sessionResponse()` / `refresh()`).
///
/// Deliberately does not have a `toJson` -- these values are only ever
/// read from a server response, never sent as request bodies.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
    );
  }

  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  @override
  bool operator ==(Object other) =>
      other is AuthTokens &&
      other.accessToken == accessToken &&
      other.refreshToken == refreshToken &&
      other.expiresIn == expiresIn;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken, expiresIn);

  @override
  String toString() =>
      'AuthTokens(accessToken: <redacted>, refreshToken: <redacted>, expiresIn: $expiresIn)';
}
