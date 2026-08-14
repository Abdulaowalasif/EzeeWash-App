// lib/core/utils/theme_prefs.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages theme-mode persistence across app launches.
///
/// Pattern mirrors [OnboardingPrefs]: an in-memory [notifier] for instant UI
/// updates, backed by [SharedPreferences] for persistence across restarts.
///
/// Usage:
///   • Read/react: `ValueListenableBuilder<ThemeMode>(valueListenable: ThemePrefs.notifier, ...)`
///   • Save:       `await ThemePrefs.save(ThemeMode.dark)`
///   • Load on startup (before runApp): `await ThemePrefs.load()`
class ThemePrefs {
  ThemePrefs._();

  static const _key = 'theme_mode';

  /// Reactive notifier — rebuild any [ValueListenableBuilder] subscribed to this.
  static final ValueNotifier<ThemeMode> notifier = ValueNotifier(
    ThemeMode.system,
  );

  /// Call once in [main] after [dotenv.load] to restore the saved theme.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      notifier.value = ThemeMode.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => ThemeMode.system,
      );
    }
  }

  /// Instantly updates the UI and persists the new mode to disk.
  static Future<void> save(ThemeMode mode) async {
    notifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}
