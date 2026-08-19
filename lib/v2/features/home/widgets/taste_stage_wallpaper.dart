import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background themes for the physical preference stage.
///
/// The entity pile renders on top of these wallpapers. The active wallpaper
/// is persisted per device and can later be matched to the user profile via
/// [TasteStageWallpaper.resolveForProfile].
enum TasteStageWallpaper {
  night(
    label: '深夜食堂',
    colors: [Color(0xFF161618), Color(0xFF1C1C1E), Color(0xFF202024)],
    border: Color(0x66FFFFFF),
    glow: Color(0x1F7ABF88),
  ),
  garden(
    label: '菜园清晨',
    colors: [
      Color(0xC2FFFFFF),
      Color(0xB4EAF5E7),
      Color(0x8CD9EED5),
    ],
    border: Color(0xB8FFFFFF),
    glow: Color(0x1F2F9B4F),
  ),
  broth(
    label: '暖汤厨房',
    colors: [Color(0xFF2A2118), Color(0xFF33291E), Color(0xFF2E2419)],
    border: Color(0x66FFB545),
    glow: Color(0x26FFB545),
  ),
  matcha(
    label: '抹茶林间',
    colors: [Color(0xFF16211A), Color(0xFF1C2A21), Color(0xFF182520)],
    border: Color(0x667ABF88),
    glow: Color(0x267ABF88),
  );

  const TasteStageWallpaper({
    required this.label,
    required this.colors,
    required this.border,
    required this.glow,
  });

  /// Human-readable name shown when switching.
  final String label;

  /// Vertical gradient colors of the stage container.
  final List<Color> colors;

  /// Container border color.
  final Color border;

  /// Soft outer glow of the container.
  final Color glow;

  bool get isDark => this != garden;

  static const _storageKey = 'taste_stage_wallpaper';

  static List<TasteStageWallpaper> get cycleOrder =>
      const [night, garden, broth, matcha];

  TasteStageWallpaper get next {
    final order = cycleOrder;
    return order[(order.indexOf(this) + 1) % order.length];
  }

  BoxDecoration buildStageDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: border, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: glow,
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  /// Loads the persisted wallpaper, falling back to [night].
  static Future<TasteStageWallpaper> loadStored() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt(_storageKey);
      if (index == null || index < 0 || index >= cycleOrder.length) {
        return night;
      }
      return cycleOrder[index];
    } catch (_) {
      return night;
    }
  }

  Future<void> persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_storageKey, cycleOrder.indexOf(this));
    } catch (_) {
      // Wallpaper persistence is best-effort; never block the UI.
    }
  }

  /// Resolves the wallpaper matching a user profile.
  ///
  /// Placeholder heuristics for the upcoming profile-driven theming: heavy
  /// spicy/hotpot fans get the late-night canteen, health-leaning users get
  /// the matcha grove, everyone else keeps their stored choice.
  static TasteStageWallpaper resolveForProfile({
    Map<String, int> tagScores = const {},
    TasteStageWallpaper fallback = night,
  }) {
    var spicy = 0;
    var healthy = 0;
    tagScores.forEach((tagId, score) {
      if (score <= 0) return;
      if (tagId.startsWith('f_spicy') ||
          tagId == 'c_hotpot' ||
          tagId == 'c_bbq' ||
          tagId == 'f_numbing') {
        spicy += score;
      } else if (tagId.startsWith('d_') ||
          tagId == 'f_light' ||
          tagId == 'i_vegetable') {
        healthy += score;
      }
    });
    if (spicy >= 8 && spicy > healthy) return night;
    if (healthy >= 8 && healthy > spicy) return matcha;
    return fallback;
  }
}
