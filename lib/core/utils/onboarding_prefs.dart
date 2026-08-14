// lib/core/utils/onboarding_prefs.dart

import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences for the onboarding seen flag.
/// shared_preferences is already a project dependency (used in main.dart
/// for theme persistence), so no pubspec change is needed.
class OnboardingPrefs {
  OnboardingPrefs._();

  static const _key = 'onboarding_seen';

  // In-memory cache so the router redirect never hits disk twice.
  // Set to true immediately when markOnboardingSeen() is called so the
  // redirect doesn't bounce the user back to /onboarding after they finish.
  static bool? _cache;

  /// Returns true when the user has already completed onboarding.
  static Future<bool> hasSeenOnboarding() async {
    if (_cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();
    _cache = prefs.getBool(_key) ?? false;
    return _cache!;
  }

  /// Call this after the user taps "Get Started" or "Skip".
  /// Updates the in-memory cache immediately so the router redirect
  /// sees the new value before the async write completes.
  static Future<void> markOnboardingSeen() async {
    _cache = true; // update cache first — redirect reads this
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  /// Development helper — resets the flag so onboarding shows again.
  static Future<void> reset() async {
    _cache = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
