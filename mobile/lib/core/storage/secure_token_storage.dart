import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal seam over the actual secure-storage backend, so
/// [SecureTokenStorage] can be unit-tested with a plain in-memory fake
/// instead of `flutter_secure_storage`'s platform channel (which isn't
/// available in `flutter test`) -- without adding a mocking package.
abstract interface class TokenKeyValueStore {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

class SecureTokenKeyValueStore implements TokenKeyValueStore {
  const SecureTokenKeyValueStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Persists the refresh token only, per docs/08-mobile-architecture.md
/// section 5 ("Secrets (refresh token) use flutter_secure_storage ...
/// never Drift") and docs/03-system-architecture.md section 3.1 ("Store
/// accessToken in memory, refreshToken in secure storage").
///
/// The access token is never written here -- it lives only in
/// [AuthTokenStore]'s in-memory Riverpod state
/// (lib/core/network/auth_token_store.dart).
class SecureTokenStorage {
  SecureTokenStorage({TokenKeyValueStore? store})
    : _store = store ?? const SecureTokenKeyValueStore();

  final TokenKeyValueStore _store;

  static const _refreshTokenKey = 'auth.refreshToken';

  Future<void> saveRefreshToken(String refreshToken) =>
      _store.write(_refreshTokenKey, refreshToken);

  Future<String?> readRefreshToken() => _store.read(_refreshTokenKey);

  Future<void> clear() => _store.delete(_refreshTokenKey);
}
