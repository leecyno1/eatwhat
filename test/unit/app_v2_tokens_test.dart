import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_theme_controller.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/core/theme/fluid_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App V2 design tokens', () {
    test('legacy AppColors follow the active theme mode', () {
      AppThemeController.mode.value = AppThemeMode.dark;
      expect(AppColors.sunsetOrange, GoldPalette.gold);
      expect(AppColors.goldenHour, GoldPalette.goldSoft);
      expect(AppColors.lightBackground, GoldPalette.nightDeep);
      expect(AppColors.darkBackground, GoldPalette.nightDeep);
      expect(AppColors.textPrimary, GoldPalette.creamText);
      expect(AppColors.textSecondary, GoldPalette.creamMuted);

      AppThemeController.mode.value = AppThemeMode.cream;
      expect(AppColors.sunsetOrange, const Color(0xFF2E2924));
      expect(AppColors.goldenHour, const Color(0xFF8C8172));
      expect(AppColors.lightBackground, const Color(0xFFF5EFE3));
      expect(AppColors.textPrimary, const Color(0xFF2E2924));
      expect(AppColors.textSecondary, const Color(0xFF8C8172));

      // 语义 token 按主题分发：夜场黑金 / 纸感米棕。
      AppThemeController.mode.value = AppThemeMode.dark;
      expect(AppPalette.canvas, GoldPalette.nightDeep);
      expect(AppPalette.garden, GoldPalette.gold);
      expect(AppPalette.gardenInk, GoldPalette.creamText);
      expect(AppPalette.broth, GoldPalette.nightDeep);
      expect(AppPalette.cream, GoldPalette.panel);
      expect(AppPalette.ink, GoldPalette.creamText);

      AppThemeController.mode.value = AppThemeMode.cream;
      expect(AppPalette.canvas, const Color(0xFFF5EFE3));
      expect(AppPalette.garden, const Color(0xFF2E2924));
      expect(AppPalette.gardenInk, const Color(0xFF2E2924));
      expect(AppPalette.broth, const Color(0xFFF5EFE3));
      expect(AppPalette.cream, const Color(0xFFFCF8EF));
      expect(AppPalette.ink, const Color(0xFF2E2924));
      AppThemeController.mode.value = AppThemeMode.dark;

      // 静态点缀色不随主题变化。
      expect(AppPalette.chili, const Color(0xFFF45B33));
      expect(AppSurfaces.glass.a, lessThan(1));
      expect(AppSurfaces.glassSoft.a, lessThan(1));
    });

    test('spacing and radius tokens keep stable layout primitives', () {
      expect(AppSpacing.xs, 8);
      expect(AppSpacing.md, 16);
      expect(AppSpacing.xl, 24);
      expect(AppRadii.md, 16);
      expect(AppRadii.sheet, 40);
      expect(AppRadii.pill, 999);
      expect(AppRadii.card, BorderRadius.circular(16));
      expect(AppRadii.hero, BorderRadius.circular(40));
    });

    test('FluidTheme dark stage uses gold tokens', () {
      AppThemeController.mode.value = AppThemeMode.dark;
      final theme = FluidTheme.darkTheme;
      final buttonStyle = theme.filledButtonTheme.style!;
      final states = <WidgetState>{};

      expect(theme.scaffoldBackgroundColor, GoldPalette.nightDeep);
      expect(theme.textTheme.displayLarge?.fontSize, AppType.display.fontSize);
      expect(theme.textTheme.displayLarge?.fontFamily, isNot('Songti SC'));
      expect(
        theme.textTheme.displayLarge?.fontWeight,
        AppType.display.fontWeight,
      );
      expect(theme.textTheme.headlineMedium?.fontSize, AppType.title.fontSize);
      expect(
          theme.textTheme.headlineMedium?.fontWeight, AppType.title.fontWeight);
      expect(theme.textTheme.bodyLarge?.height, AppType.body.height);
      expect(theme.textTheme.bodyLarge?.fontFamily, isNot('PingFang SC'));
      expect(
        buttonStyle.backgroundColor?.resolve(states),
        GoldPalette.gold,
      );
      expect(
        buttonStyle.foregroundColor?.resolve(states),
        GoldPalette.nightDeep,
      );
    });

    test('FluidTheme cream paper stage uses ink tokens', () {
      AppThemeController.mode.value = AppThemeMode.cream;
      final theme = FluidTheme.lightTheme;
      final buttonStyle = theme.filledButtonTheme.style!;
      final states = <WidgetState>{};

      expect(theme.scaffoldBackgroundColor, const Color(0xFFF5EFE3));
      expect(theme.colorScheme.primary, const Color(0xFF2E2924));
      expect(theme.colorScheme.surface, const Color(0xFFFCF8EF));
      expect(
        buttonStyle.backgroundColor?.resolve(states),
        const Color(0xFF2E2924),
      );
      expect(
        buttonStyle.foregroundColor?.resolve(states),
        const Color(0xFFFCF8EF),
      );

      AppThemeController.mode.value = AppThemeMode.dark;
    });
  });
}
