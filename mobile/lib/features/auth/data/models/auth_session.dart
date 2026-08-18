import 'auth_tokens.dart';
import 'auth_user.dart';

/// The full response shape from register/login
/// (`{ user, accessToken, refreshToken, expiresIn }`) -- `POST
/// /auth/refresh` returns only the token triple (no `user`), so that path
/// uses [AuthTokens] directly rather than this type.
class AuthSession {
  const AuthSession({required this.user, required this.tokens});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      tokens: AuthTokens.fromJson(json),
    );
  }

  final AuthUser user;
  final AuthTokens tokens;
}
