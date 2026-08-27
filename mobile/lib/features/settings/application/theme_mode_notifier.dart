import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/settings_providers.dart';

/// Owns the app's theme-mode selection (light/dark/system), persisted
/// on-device via [ThemeStorage]. Hand-written `Notifier` (no codegen),
/// matching AuthNotifier/ProfileNotifier's established convention.
///
/// Read by [AestheticCoachApp] (lib/app/app.dart) to drive
/// `MaterialApp.router`'s `themeMode` parameter, which previously was
/// hardcoded to `ThemeMode.system`.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Fire-and-forget restore, mirroring AuthNotifier.build()'s
    // restoreSession pattern -- Notifier.build() must be synchronous, so
    // the persisted choice (if any) is applied a moment after the
    // default (`system`) first renders.
    Future.microtask(_restore);
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    final stored = await ref.read(themeStorageProvider).readThemeMode();
    if (stored != null) {
      state = _fromStorageValue(stored);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref.read(themeStorageProvider).saveThemeMode(_toStorageValue(mode));
  }

  static ThemeMode _fromStorageValue(String value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static String _toStorageValue(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
