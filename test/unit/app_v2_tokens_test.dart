import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/core/theme/fluid_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App V2 design tokens', () {
    test('legacy AppColors map to the V2 food palette', () {
      expect(AppColors.sunsetOrange, AppPalette.yolk);
      expect(AppColors.goldenHour, AppPalette.chili);
      expect(AppColors.lightBackground, AppPalette.broth);
      expect(AppColors.darkBackground, AppPalette.night);
      expect(AppColors.textPrimary, AppPalette.ink);
      expect(AppColors.textSecondary, AppPalette.inkMuted);
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

      expect(theme.scaffoldBackgroundColor, AppPalette.broth);
      expect(theme.textTheme.displayLarge?.fontSize, AppType.display.fontSize);
      expect(
        theme.textTheme.displayLarge?.fontWeight,
        AppType.display.fontWeight,
      );
      expect(theme.textTheme.headlineMedium?.fontSize, AppType.title.fontSize);
      expect(
          theme.textTheme.headlineMedium?.fontWeight, AppType.title.fontWeight);
      expect(theme.textTheme.bodyLarge?.height, AppType.body.height);
      expect(
        buttonStyle.backgroundColor?.resolve(states),
        AppPalette.chili,
      );
      expect(buttonStyle.foregroundColor?.resolve(states), AppPalette.rice);
    });
  });
}
