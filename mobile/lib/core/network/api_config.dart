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
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
}
