/// API base URL, per docs/08-mobile-architecture.md section 10
/// ("Flavor-based configuration ... via Dart-define"). Full flavor
/// tooling (flutter_flavorizr, per-platform build flavors) is not set up
/// yet -- this is the minimum clean mechanism: override at build/run time
/// with `--dart-define=API_BASE_URL=...`, never hardcoded to a real
/// deployed host (none is documented as this project's production URL).
///
/// The default points at the local dev backend's documented port
/// (docker-compose.yml: `app` service, `8000:8000`). Android emulators
/// cannot reach the host machine via `localhost` -- pass
/// `--dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1` when running
/// on an Android emulator against a locally-hosted backend.
abstract final class ApiConfig {
  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  /// Always ends with exactly one trailing slash.
  ///
  /// [Dio]'s own URL builder (`RequestOptions.uri`, in
  /// package:dio/src/options.dart) concatenates `baseUrl + path` verbatim
  /// whenever `path` isn't already an absolute URL -- it inserts no
  /// separator. Every relative path used by `AuthApi`/`ProfileApi` (e.g.
  /// `'auth/register'`, `'me'`) deliberately has no leading slash, so if
  /// this value lacked a trailing slash, the request would silently
  /// become `.../v1auth/register` instead of `.../v1/auth/register` --
  /// a real, previously-undetected bug, confirmed against a live
  /// Android emulator + Laravel backend (the malformed path 404s
  /// server-side, and the client-side timeout before that 404 arrives
  /// surfaces as a generic "Unable to reach the server" failure). No
  /// existing test caught it because every unit/widget test injects a
  /// fake API client that bypasses Dio's real URL construction.
  static String get baseUrl =>
      _rawBaseUrl.endsWith('/') ? _rawBaseUrl : '$_rawBaseUrl/';
}
