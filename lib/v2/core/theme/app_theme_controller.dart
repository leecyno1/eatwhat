import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_skins.dart';

/// App-wide appearance modes. The first two are the legacy binary stages
/// (black-gold night / cream paper); the rest are curated aesthetics backed
/// by [ThemeSkins]. Palette getters read [AppThemeController.skin] so every
/// surface flips with a single notify.
enum AppThemeMode {
  dark,
  cream,
  lacquer,
  celadon,
  neon,
  ceramic,
  dunhuang,
  diner,
  ukiyoe,
  rosegold,
  bamboo,
}

class AppThemeController {
  AppThemeController._();

  static const String _prefsKey = 'v2_app_theme_mode';
  static const String _autoKey = 'v2_theme_auto';
  static const String _dayKey = 'v2_theme_day';
  static const String _nightKey = 'v2_theme_night';

  /// Live theme selection; listeners rebuild the whole app on change.
  /// Always holds the *resolved* skin — in auto mode this is the preference
  /// for the current system brightness, so downstream code never branches
  /// on auto itself.
  static final ValueNotifier<AppThemeMode> mode =
      ValueNotifier(AppThemeMode.cream);

  /// Whether the theme follows the system day/night cycle using the
  /// remembered per-slot preferences below.
  static final ValueNotifier<bool> autoEnabled = ValueNotifier(false);

  /// Skin used while the system reports daylight (auto mode only).
  static final ValueNotifier<AppThemeMode> dayPreference =
      ValueNotifier(AppThemeMode.cream);

  /// Skin used while the system reports night (auto mode only).
  static final ValueNotifier<AppThemeMode> nightPreference =
      ValueNotifier(AppThemeMode.dark);

  static Brightness _brightness = Brightness.light;

  /// Last observed system brightness; the appearance sheet reads it to
  /// label the current slot.
  static Brightness get systemBrightness => _brightness;

  /// The active skin driving every semantic palette getter.
  static ThemeSkin get skin => ThemeSkins.of(mode.value);

  /// Skin backing the daylight Material theme: the active skin when it is
  /// light, otherwise the legacy cream stage.
  static ThemeSkin get lightSkin => skin.isLight ? skin : ThemeSkins.cream;

  /// Skin backing the night Material theme: the active skin when it is dark,
  /// otherwise the legacy night stage.
  static ThemeSkin get darkSkin => skin.isLight ? ThemeSkins.dark : skin;

  /// Legacy daylight flag: true for any light skin (cream + light aesthetics).
  static bool get isCream => skin.isLight;

  static Future<void> loadStored() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      dayPreference.value =
          _readMode(prefs.getString(_dayKey)) ?? AppThemeMode.cream;
      nightPreference.value =
          _readMode(prefs.getString(_nightKey)) ?? AppThemeMode.dark;

      final storedMode = _readMode(prefs.getString(_prefsKey));
      final storedAuto = prefs.getBool(_autoKey);
      // New installs (nothing stored) default to auto; users who already
      // picked a manual theme keep it until they opt in.
      autoEnabled.value = storedAuto ?? (storedMode == null);

      if (autoEnabled.value) {
        mode.value = _resolveAuto();
      } else if (storedMode != null) {
        mode.value = storedMode;
      }
    } catch (_) {
      // Default to the warm cream stage when persistence is unavailable.
    }
  }

  static Future<void> setMode(AppThemeMode next) async {
    if (autoEnabled.value) {
      // Habit memory: a manual pick while auto is on becomes the preference
      // for the current day/night slot and applies immediately.
      _rememberSlot(next);
      mode.value = next;
      await _persist();
      return;
    }
    if (mode.value == next) return;
    mode.value = next;
    await _persist();
  }

  /// Enables or disables day/night auto switching. Enabling seeds the current
  /// slot with the skin on screen; disabling keeps that skin as the manual
  /// selection so nothing visually jumps.
  static Future<void> setAuto(bool enabled) async {
    if (autoEnabled.value == enabled) return;
    autoEnabled.value = enabled;
    if (enabled) {
      _rememberSlot(mode.value);
      mode.value = _resolveAuto();
    }
    await _persist();
  }

  /// Feeds the system brightness signal (wired to PlatformDispatcher in
  /// main.dart). Re-resolves the active skin when auto is on.
  static void applyBrightness(Brightness next) {
    if (_brightness == next) return;
    _brightness = next;
    if (autoEnabled.value) {
      mode.value = _resolveAuto();
    }
  }

  static Future<void> toggle() async {
    if (autoEnabled.value) {
      await setAuto(false);
    }
    await setMode(isCream ? AppThemeMode.dark : AppThemeMode.cream);
  }

  static AppThemeMode _resolveAuto() => _brightness == Brightness.dark
      ? nightPreference.value
      : dayPreference.value;

  static void _rememberSlot(AppThemeMode value) {
    if (_brightness == Brightness.dark) {
      nightPreference.value = value;
    } else {
      dayPreference.value = value;
    }
  }

  static AppThemeMode? _readMode(String? name) {
    for (final value in AppThemeMode.values) {
      if (name == value.name) return value;
    }
    return null;
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.value.name);
      await prefs.setBool(_autoKey, autoEnabled.value);
      await prefs.setString(_dayKey, dayPreference.value.name);
      await prefs.setString(_nightKey, nightPreference.value.name);
    } catch (_) {
      // The in-memory switch still applies for this session.
    }
  }
}