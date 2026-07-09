import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_tokens.dart';

class FluidTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.sunsetOrange,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.sunsetOrange,
      ),
      textTheme: const TextTheme(
        displayLarge: AppType.display,
        headlineMedium: AppType.title,
        titleMedium: AppType.section,
        bodyLarge: AppType.body,
        bodyMedium: AppType.body,
        labelLarge: AppType.label,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.chili,
          foregroundColor: AppPalette.rice,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.capsule),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.sunsetOrange,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.sunsetOrange,
        brightness: Brightness.dark,
      ),
      textTheme: TextTheme(
        displayLarge: AppType.display.copyWith(color: AppPalette.rice),
        headlineMedium: AppType.title.copyWith(color: AppPalette.rice),
        titleMedium: AppType.section.copyWith(color: AppPalette.rice),
        bodyLarge: AppType.body.copyWith(color: AppPalette.rice),
        bodyMedium: AppType.body.copyWith(color: AppPalette.rice),
        labelLarge: AppType.label.copyWith(color: AppPalette.rice),
      ),
    );
  }
}
