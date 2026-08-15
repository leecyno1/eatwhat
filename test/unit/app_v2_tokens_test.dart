import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/core/theme/fluid_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App V2 design tokens', () {
    test('legacy AppColors map to the V2 garden palette', () {
      expect(AppColors.sunsetOrange, AppPalette.garden);
      expect(AppColors.goldenHour, AppPalette.yolk);
      expect(AppColors.lightBackground, AppPalette.canvas);
      expect(AppColors.darkBackground, AppPalette.night);
      expect(AppColors.textPrimary, AppPalette.gardenInk);
      expect(AppColors.textSecondary, AppPalette.inkMuted);
      expect(AppPalette.canvas, const Color(0xFFF4FAF3));
      expect(AppPalette.garden, const Color(0xFF2F9B4F));
      expect(AppPalette.gardenInk, const Color(0xFF123D2D));
      expect(AppPalette.broth, const Color(0xFFFFF5E6));
      expect(AppPalette.cream, const Color(0xFFFFFBF6));
      expect(AppPalette.chili, const Color(0xFFF45B33));
      expect(AppPalette.ink, const Color(0xFF1D1D1F));
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

    test('FluidTheme uses V2 typography and button tokens', () {
      final theme = FluidTheme.lightTheme;
      final buttonStyle = theme.filledButtonTheme.style!;
      final states = <WidgetState>{};

      expect(theme.scaffoldBackgroundColor, AppPalette.canvas);
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
        AppPalette.garden,
      );
      expect(buttonStyle.foregroundColor?.resolve(states), AppPalette.rice);
    });
  });
}
