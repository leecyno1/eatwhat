import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

class FluidTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      fontFamily: '.SF Pro Text',
      primaryColor: AppPalette.garden,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppPalette.garden,
      ).copyWith(
        primary: AppPalette.garden,
        secondary: AppPalette.tomato,
        surface: AppPalette.surface,
        onSurface: AppPalette.gardenInk,
        outline: AppPalette.divider,
        surfaceContainerHighest: AppPalette.surfaceMuted,
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
          backgroundColor: AppPalette.garden,
          foregroundColor: AppPalette.rice,
          elevation: 4,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: AppType.label.copyWith(
            color: AppPalette.rice,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.capsule),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.gardenDeep,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: const BorderSide(color: AppPalette.garden),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.capsule),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.gardenDeep,
          textStyle: AppType.label,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppSurfaces.glassSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.card,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.card,
          borderSide: const BorderSide(color: AppPalette.rice),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.card,
          borderSide: const BorderSide(color: AppPalette.garden, width: 1.4),
        ),
        labelStyle: AppType.label.copyWith(color: AppPalette.inkSoft),
        hintStyle: AppType.body.copyWith(color: AppPalette.inkMuted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppSurfaces.glassSoft,
        selectedColor: AppPalette.positiveSurface,
        side: const BorderSide(color: AppPalette.rice),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.capsule),
        labelStyle: AppType.label,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppPalette.gardenInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppType.section,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: '.SF Pro Text',
      primaryColor: AppPalette.garden,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppPalette.garden,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppPalette.garden,
        secondary: AppPalette.tomato,
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
