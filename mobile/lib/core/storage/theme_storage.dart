import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's theme choice on-device only. Unlike unit
/// preference (see [SettingsScreen]'s docblock), theme has no
/// server-side counterpart at all -- there is no `theme` column on
/// `users`, and no feature doc describes cross-device sync for it -- so
/// this is genuinely local-only, not a client-side cache of server
/// state. `SharedPreferences`, not `flutter_secure_storage`: this value
/// is not sensitive and doesn't belong in the secure-storage channel
/// reserved for the refresh token (see
/// core/storage/secure_token_storage.dart).
abstract interface class ThemeStorageContract {
  Future<String?> readThemeMode();
  Future<void> saveThemeMode(String value);
}

class ThemeStorage implements ThemeStorageContract {
  static const _key = 'theme_mode';

  @override
  Future<String?> readThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  @override
  Future<void> saveThemeMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }
}
