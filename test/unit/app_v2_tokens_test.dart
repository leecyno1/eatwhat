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
      expect(AppColors.sunsetOrange, AppPalette.accentDark);
      expect(AppColors.goldenHour, AppPalette.accentSoftDark);
      expect(AppColors.lightBackground, AppPalette.nightBase);
      expect(AppColors.darkBackground, AppPalette.nightBase);
      expect(AppColors.textPrimary, AppPalette.nightText);
      expect(AppColors.textSecondary, AppPalette.nightMuted);

      AppThemeController.mode.value = AppThemeMode.cream;
      expect(AppColors.sunsetOrange, AppPalette.accentCream);
      expect(AppColors.goldenHour, AppPalette.accentSoftCream);
      expect(AppColors.lightBackground, AppPalette.creamBase);
      expect(AppColors.textPrimary, AppPalette.creamInk);
      expect(AppColors.textSecondary, AppPalette.creamMutedInk);

      // 语义 token 按主题分发：夜场黑金 / 纸感米棕。
      AppThemeController.mode.value = AppThemeMode.dark;
      expect(AppPalette.canvas, AppPalette.nightBase);
      expect(AppPalette.garden, AppPalette.accentDark);
      expect(AppPalette.gardenInk, AppPalette.nightText);
      expect(AppPalette.broth, AppPalette.nightBase);
      expect(AppPalette.cream, AppPalette.nightPanel);
      expect(AppPalette.ink, AppPalette.nightText);

      AppThemeController.mode.value = AppThemeMode.cream;
      expect(AppPalette.canvas, AppPalette.creamBase);
      expect(AppPalette.garden, AppPalette.accentCream);
      expect(AppPalette.gardenInk, AppPalette.creamInk);
      expect(AppPalette.broth, AppPalette.creamBase);
      expect(AppPalette.cream, AppPalette.creamPanel);
      expect(AppPalette.ink, AppPalette.creamInk);
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

    test('FluidTheme dark stage uses coral tokens', () {
      AppThemeController.mode.value = AppThemeMode.dark;
      final theme = FluidTheme.darkTheme;
      final buttonStyle = theme.filledButtonTheme.style!;
      final states = <WidgetState>{};

      expect(theme.scaffoldBackgroundColor, AppPalette.nightBase);
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
        AppPalette.accentDark,
      );
      expect(
        buttonStyle.foregroundColor?.resolve(states),
        AppPalette.nightBase,
      );
    });

    test('FluidTheme cream stage uses terracotta tokens', () {
      AppThemeController.mode.value = AppThemeMode.cream;
      final theme = FluidTheme.lightTheme;
      final buttonStyle = theme.filledButtonTheme.style!;
      final states = <WidgetState>{};

      expect(theme.scaffoldBackgroundColor, AppPalette.creamBase);
      expect(theme.colorScheme.primary, AppPalette.accentCream);
      expect(theme.colorScheme.surface, AppPalette.creamPanel);
      expect(
        buttonStyle.backgroundColor?.resolve(states),
        AppPalette.accentCream,
      );
      expect(
        buttonStyle.foregroundColor?.resolve(states),
        AppPalette.creamPanel,
      );

      AppThemeController.mode.value = AppThemeMode.dark;
    });
  });
}
