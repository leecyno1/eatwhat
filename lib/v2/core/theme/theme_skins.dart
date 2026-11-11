import 'package:flutter/material.dart';

import 'app_theme_controller.dart';

/// One complete visual skin: the semantic color ramp plus the optional
/// ImageGen accessory slug used by the home storefront.
///
/// Every [AppPalette] semantic getter resolves through the active skin, so
/// adding an aesthetic is a single registry entry — no widget changes.
@immutable
class ThemeSkin {
  const ThemeSkin({
    required this.mode,
    required this.label,
    required this.subtitle,
    required this.isLight,
    required this.base,
    required this.panel,
    required this.elevated,
    required this.line,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.accentDeep,
    required this.accentSoft,
    this.assetSlug,
    this.hasAssets = false,
  });

  /// The persisted theme mode this skin backs.
  final AppThemeMode mode;

  /// Short display name, e.g. 朱漆金缮.
  final String label;

  /// One-line mood description for the appearance sheet.
  final String subtitle;

  /// Light skins read as "daylight" for the legacy binary branches.
  final bool isLight;

  /// Page background / stage mist.
  final Color base;

  /// Card & panel surface.
  final Color panel;

  /// Recessed / elevated surface one step off [panel].
  final Color elevated;

  /// Hairline borders and dividers.
  final Color line;

  /// Primary ink.
  final Color ink;

  /// Secondary / muted ink.
  final Color muted;

  /// Brand accent (buttons, focus, active states).
  final Color accent;

  /// Deeper (light skins) or lighter (dark skins) accent for gradients.
  final Color accentDeep;

  /// Soft companion accent for secondary highlights.
  final Color accentSoft;

  /// ImageGen accessory folder slug, or null for painted-only legacy skins.
  final String? assetSlug;

  /// True once this skin's accessory webp files are bundled. Skins whose
  /// assets have not landed yet fall back to the painted storefront.
  final bool hasAssets;

  String get id => mode.name;

  /// Asset path for a given accessory kind, or null when painted-only.
  String? assetPath(String kind) => assetSlug == null || !hasAssets
      ? null
      : 'assets/themes/${assetSlug}_$kind.webp';
}

/// Registry of all selectable skins. The first two are the legacy binary
/// modes kept byte-identical for backwards compatibility; the remaining nine
/// are the curated aesthetics with image-based storefront accessories.
class ThemeSkins {
  const ThemeSkins._();

  static const ThemeSkin cream = ThemeSkin(
    mode: AppThemeMode.cream,
    label: '米白 · 日间',
    subtitle: '暖象牙底，陶土强调',
    isLight: true,
    base: Color(0xFFF7F3EA),
    panel: Color(0xFFFFFDF8),
    elevated: Color(0xFFF0E8DB),
    line: Color(0xFFE3D8C6),
    ink: Color(0xFF241F1A),
    muted: Color(0xFF7D7466),
    accent: Color(0xFFC25B3D),
    accentDeep: Color(0xFF9E4630),
    accentSoft: Color(0xFFE8B39E),
  );

  static const ThemeSkin dark = ThemeSkin(
    mode: AppThemeMode.dark,
    label: '墨夜 · 夜间',
    subtitle: '炭黑底，珊瑚强调',
    isLight: false,
    base: Color(0xFF121417),
    panel: Color(0xFF1B1E23),
    elevated: Color(0xFF252A30),
    line: Color(0xFF343A42),
    ink: Color(0xFFF4EFE6),
    muted: Color(0xFFA8A29A),
    accent: Color(0xFFFF9270),
    accentDeep: Color(0xFFFFB59A),
    accentSoft: Color(0xFFFFB59A),
  );

  static const ThemeSkin lacquer = ThemeSkin(
    mode: AppThemeMode.lacquer,
    label: '朱漆金缮',
    subtitle: '象牙漆面，朱砂描金',
    isLight: true,
    base: Color(0xFFF6EFE3),
    panel: Color(0xFFFFFBF2),
    elevated: Color(0xFFF0E4D2),
    line: Color(0xFFE2D3BC),
    ink: Color(0xFF2A1B14),
    muted: Color(0xFF8A7663),
    accent: Color(0xFFB0402A),
    accentDeep: Color(0xFF8C2C1B),
    accentSoft: Color(0xFFE5B79C),
    assetSlug: 'lacquer',
    hasAssets: true,
  );

  static const ThemeSkin celadon = ThemeSkin(
    mode: AppThemeMode.celadon,
    label: '青瓷宋韵',
    subtitle: '雨过天青，素瓷温润',
    isLight: true,
    base: Color(0xFFEFF3EE),
    panel: Color(0xFFFAFCF8),
    elevated: Color(0xFFE2EAE2),
    line: Color(0xFFCFDCD2),
    ink: Color(0xFF22302A),
    muted: Color(0xFF6E8078),
    accent: Color(0xFF6E9C8C),
    accentDeep: Color(0xFF4C7A6C),
    accentSoft: Color(0xFFB9D3C6),
    assetSlug: 'celadon',
    hasAssets: true,
  );

  static const ThemeSkin neon = ThemeSkin(
    mode: AppThemeMode.neon,
    label: '霓虹夜市',
    subtitle: '深夜街市，粉蓝霓虹',
    isLight: false,
    base: Color(0xFF0D0B14),
    panel: Color(0xFF171426),
    elevated: Color(0xFF221D36),
    line: Color(0xFF332C4C),
    ink: Color(0xFFF2EEFF),
    muted: Color(0xFF9C93B8),
    accent: Color(0xFFFF4D8D),
    accentDeep: Color(0xFFFF7FB0),
    accentSoft: Color(0xFF63E6FF),
    assetSlug: 'neon',
    hasAssets: true,
  );

  static const ThemeSkin ceramic = ThemeSkin(
    mode: AppThemeMode.ceramic,
    label: '极简陶瓷白',
    subtitle: '哑光白瓷，一线墨色',
    isLight: true,
    base: Color(0xFFF4F4F2),
    panel: Color(0xFFFFFFFF),
    elevated: Color(0xFFE9E9E6),
    line: Color(0xFFDCDCD8),
    ink: Color(0xFF1C1C1A),
    muted: Color(0xFF777772),
    accent: Color(0xFF33332F),
    accentDeep: Color(0xFF141412),
    accentSoft: Color(0xFFB9B9B4),
    assetSlug: 'ceramic',
    hasAssets: true,
  );

  static const ThemeSkin dunhuang = ThemeSkin(
    mode: AppThemeMode.dunhuang,
    label: '敦煌壁画',
    subtitle: '沙底矿彩，石绿赭红',
    isLight: true,
    base: Color(0xFFF3E7D3),
    panel: Color(0xFFFBF3E4),
    elevated: Color(0xFFE8D8BE),
    line: Color(0xFFD8C4A4),
    ink: Color(0xFF3A2A1C),
    muted: Color(0xFF8C7458),
    accent: Color(0xFF2E7F74),
    accentDeep: Color(0xFF1D5F57),
    accentSoft: Color(0xFFC96F4A),
    assetSlug: 'dunhuang',
    hasAssets: true,
  );

  static const ThemeSkin diner = ThemeSkin(
    mode: AppThemeMode.diner,
    label: '复古美式',
    subtitle: '奶油餐车，樱桃红蓝',
    isLight: true,
    base: Color(0xFFF6E8D8),
    panel: Color(0xFFFFF6EA),
    elevated: Color(0xFFEDD9C2),
    line: Color(0xFFDFC5A8),
    ink: Color(0xFF33201A),
    muted: Color(0xFF8A6E5C),
    accent: Color(0xFFD0342C),
    accentDeep: Color(0xFF9E241E),
    accentSoft: Color(0xFF3E8E8C),
    assetSlug: 'diner',
    hasAssets: true,
  );

  static const ThemeSkin ukiyoe = ThemeSkin(
    mode: AppThemeMode.ukiyoe,
    label: '浮世绘',
    subtitle: '和纸普蓝，朱印点睛',
    isLight: true,
    base: Color(0xFFF2EDE2),
    panel: Color(0xFFFBF7EE),
    elevated: Color(0xFFE5DDCB),
    line: Color(0xFFD3C8B0),
    ink: Color(0xFF20242E),
    muted: Color(0xFF6F7684),
    accent: Color(0xFF274E79),
    accentDeep: Color(0xFF16345A),
    accentSoft: Color(0xFFC34A36),
    assetSlug: 'ukiyoe',
    hasAssets: true,
  );

  static const ThemeSkin rosegold = ThemeSkin(
    mode: AppThemeMode.rosegold,
    label: '玫瑰金奢华',
    subtitle: '暗夜幕布，玫瑰金线',
    isLight: false,
    base: Color(0xFF141014),
    panel: Color(0xFF1E181C),
    elevated: Color(0xFF2A2228),
    line: Color(0xFF3C3138),
    ink: Color(0xFFF6EDE9),
    muted: Color(0xFFA99698),
    accent: Color(0xFFE0A189),
    accentDeep: Color(0xFFF0C4AE),
    accentSoft: Color(0xFFC98D76),
    assetSlug: 'rosegold',
    hasAssets: true,
  );

  static const ThemeSkin bamboo = ThemeSkin(
    mode: AppThemeMode.bamboo,
    label: '竹编自然',
    subtitle: '竹青米黄，山野清气',
    isLight: true,
    base: Color(0xFFF1F2E8),
    panel: Color(0xFFFAFBF2),
    elevated: Color(0xFFE4E7D4),
    line: Color(0xFFD2D8BC),
    ink: Color(0xFF26301F),
    muted: Color(0xFF71805F),
    accent: Color(0xFF6D8F4E),
    accentDeep: Color(0xFF4C6B33),
    accentSoft: Color(0xFFD9B98A),
    assetSlug: 'bamboo',
    hasAssets: true,
  );

  static const List<ThemeSkin> all = [
    cream,
    dark,
    lacquer,
    celadon,
    neon,
    ceramic,
    dunhuang,
    diner,
    ukiyoe,
    rosegold,
    bamboo,
  ];

  /// The nine image-backed aesthetics, in gallery order.
  static const List<ThemeSkin> aesthetics = [
    lacquer,
    celadon,
    neon,
    ceramic,
    dunhuang,
    diner,
    ukiyoe,
    rosegold,
    bamboo,
  ];

  static ThemeSkin of(AppThemeMode mode) {
    return all.firstWhere((s) => s.mode == mode);
  }
}