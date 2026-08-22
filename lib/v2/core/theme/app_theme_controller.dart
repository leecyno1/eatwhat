import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two app-wide themes: the black-gold night stage (default) and the
/// cream paper menu (米色纸感). Palette getters read [AppThemeController.mode]
/// so every surface flips with a single notify.
enum AppThemeMode { dark, cream }

class AppThemeController {
  AppThemeController._();

  static const String _prefsKey = 'v2_app_theme_mode';

  /// Live theme selection; listeners rebuild the whole app on change.
  static final ValueNotifier<AppThemeMode> mode =
      ValueNotifier(AppThemeMode.dark);

  static bool get isCream => mode.value == AppThemeMode.cream;

  static Future<void> loadStored() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefsKey);
      if (stored == AppThemeMode.cream.name) {
        mode.value = AppThemeMode.cream;
      }
    } catch (_) {
      // Default to the dark stage when persistence is unavailable.
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
