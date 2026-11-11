import 'dart:io';

import 'package:eatwhat_app/v2/core/theme/app_theme_controller.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/core/theme/theme_skins.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppThemeController.mode.value = AppThemeMode.cream;
  });

  tearDown(() {
    AppThemeController.mode.value = AppThemeMode.cream;
  });

  test('registry covers every theme mode with unique ids', () {
    expect(ThemeSkins.all.length, AppThemeMode.values.length);
    final ids = ThemeSkins.all.map((s) => s.id).toSet();
    expect(ids.length, ThemeSkins.all.length);
    for (final mode in AppThemeMode.values) {
      expect(ThemeSkins.of(mode).mode, mode);
    }
  });

  test('new aesthetics carry image asset slugs; legacy modes do not', () {
    const aesthetic = [
      AppThemeMode.lacquer,
      AppThemeMode.celadon,
      AppThemeMode.neon,
      AppThemeMode.ceramic,
      AppThemeMode.dunhuang,
      AppThemeMode.diner,
      AppThemeMode.ukiyoe,
      AppThemeMode.rosegold,
      AppThemeMode.bamboo,
    ];
    for (final mode in aesthetic) {
      expect(ThemeSkins.of(mode).assetSlug, mode.name);
    }
    expect(ThemeSkins.of(AppThemeMode.cream).assetSlug, isNull);
    expect(ThemeSkins.of(AppThemeMode.dark).assetSlug, isNull);
  });

  test('neon and rosegold are dark stages, the rest are light', () {
    expect(ThemeSkins.of(AppThemeMode.neon).isLight, isFalse);
    expect(ThemeSkins.of(AppThemeMode.rosegold).isLight, isFalse);
    for (final mode in [
      AppThemeMode.lacquer,
      AppThemeMode.celadon,
      AppThemeMode.ceramic,
      AppThemeMode.dunhuang,
      AppThemeMode.diner,
      AppThemeMode.ukiyoe,
      AppThemeMode.bamboo,
    ]) {
      expect(ThemeSkins.of(mode).isLight, isTrue, reason: mode.name);
    }
  });

  test('switching to an aesthetic re-inks the semantic palette', () async {
    await AppThemeController.setMode(AppThemeMode.celadon);
    final skin = ThemeSkins.of(AppThemeMode.celadon);
    expect(AppThemeController.isCream, isTrue);
    expect(AppPalette.broth, skin.base);
    expect(AppPalette.surface, skin.panel);
    expect(AppPalette.leaf, skin.accent);
    expect(AppPalette.ink, skin.ink);
    expect(AppPalette.divider, skin.line);
  });

  test('a dark aesthetic flips isCream and night tokens', () async {
    await AppThemeController.setMode(AppThemeMode.neon);
    final skin = ThemeSkins.of(AppThemeMode.neon);
    expect(AppThemeController.isCream, isFalse);
    expect(AppPalette.night, skin.base);
    expect(AppPalette.moonlight, skin.ink);
    expect(AppPalette.char, skin.panel);
  });

  test('aesthetic selection persists and reloads by name', () async {
    await AppThemeController.setMode(AppThemeMode.dunhuang);
    AppThemeController.mode.value = AppThemeMode.cream; // simulate new process
    await AppThemeController.loadStored();
    expect(AppThemeController.mode.value, AppThemeMode.dunhuang);
  });

  test('only bundled accessories resolve to asset paths', () {
    // All nine aesthetics now ship their four-piece accessory webp set.
    const bundled = {
      'lacquer',
      'celadon',
      'neon',
      'ceramic',
      'dunhuang',
      'diner',
      'ukiyoe',
      'rosegold',
      'bamboo',
    };
    for (final skin in ThemeSkins.all) {
      final expected = bundled.contains(skin.assetSlug);
      expect(skin.hasAssets, expected, reason: skin.id);
      if (expected) {
        for (final kind in ['button', 'frame', 'well', 'seal']) {
          final path = skin.assetPath(kind);
          expect(path, 'assets/themes/${skin.assetSlug}_$kind.webp');
          expect(File(path!).existsSync(), isTrue, reason: path);
        }
      } else {
        expect(skin.assetPath('button'), isNull, reason: skin.id);
        expect(skin.assetPath('seal'), isNull, reason: skin.id);
      }
    }
  });
}