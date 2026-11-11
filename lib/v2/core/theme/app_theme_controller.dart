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

  /// Live theme selection; listeners rebuild the whole app on change.
  static final ValueNotifier<AppThemeMode> mode =
      ValueNotifier(AppThemeMode.cream);

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
      final stored = prefs.getString(_prefsKey);
      for (final value in AppThemeMode.values) {
        if (stored == value.name) {
          mode.value = value;
          return;
        }
      }
    } catch (_) {
      // Default to the warm cream stage when persistence is unavailable.
    }
  }

  static Future<void> setMode(AppThemeMode next) async {
    if (mode.value == next) return;
    mode.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, next.name);
    } catch (_) {
      // The in-memory switch still applies for this session.
    }
  }

  static Future<void> toggle() =>
      setMode(isCream ? AppThemeMode.dark : AppThemeMode.cream);
}
