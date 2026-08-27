import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/theme_storage.dart';

/// DI wiring for the settings-storage layer, matching the pattern
/// established by network_providers.dart (auth) and profile_providers.dart.
final themeStorageProvider = Provider<ThemeStorageContract>(
  (ref) => ThemeStorage(),
);
