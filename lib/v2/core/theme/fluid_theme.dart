import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

/// V2 全局双主题，由 AppV2 按 [AppThemeController.mode] 接线：
///
/// - [lightTheme]：米色纸感（cream 模式）——暖米纸底、印刷深棕强调。
/// - [darkTheme]：黑金夜场（dark 模式）——纯黑底、香槟金强调。
///
/// 两套主题共用 [AppTypeNight] 文字体系：其色值经 AppPalette 动态
/// getter 跟随主题分发（夜场暖白 / 纸感深棕），无需分别维护。
class FluidTheme {
  /// 米色纸感主题（cream 模式）。
  static ThemeData get lightTheme {
    const ink = Color(0xFF2E2924);
    const muted = Color(0xFF8C8172);
    const canvas = Color(0xFFF5EFE3);
    const surface = Color(0xFFFCF8EF);
    const elevated = Color(0xFFF0E8D8);
    const divider = Color(0xFFE2D8C4);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: canvas,
      fontFamily: '.SF Pro Text',
      primaryColor: ink,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ink,
      ).copyWith(
        primary: ink,
        onPrimary: surface,
        secondary: muted,
        onSecondary: surface,
        surface: surface,
        onSurface: ink,
        onSurfaceVariant: muted,
        outline: divider,
        surfaceContainerHighest: elevated,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypeNight.display,
        headlineMedium: AppTypeNight.title,
        titleMedium: AppTypeNight.section,
        bodyLarge: AppTypeNight.body,
        bodyMedium: AppTypeNight.body,
        labelLarge: AppTypeNight.label,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: surface,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: AppTypeNight.label.copyWith(
            color: surface,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.capsule),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: const BorderSide(color: divider),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.capsule),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          textStyle: AppTypeNight.label,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
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
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.card,
          borderSide: const BorderSide(color: ink, width: 1.4),
        ),
        labelStyle: AppTypeNight.label,
        hintStyle: AppTypeNight.body,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: elevated,
        side: const BorderSide(color: divider),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.capsule),
        labelStyle: AppTypeNight.label,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypeNight.section,
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 0.6,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: AppTypeNight.body,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

  /// 黑金夜场主题（dark 模式）。
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: '.SF Pro Text',
      primaryColor: GoldPalette.gold,
      colorScheme: ColorScheme.fromSeed(
        seedColor: GoldPalette.gold,
        brightness: Brightness.dark,
      ).copyWith(
        primary: GoldPalette.gold,
        onPrimary: GoldPalette.nightDeep,
        secondary: GoldPalette.goldSoft,
        onSecondary: GoldPalette.nightDeep,
        surface: GoldPalette.panel,
        onSurface: GoldPalette.creamText,
        onSurfaceVariant: GoldPalette.creamMuted,
        outline: GoldPalette.goldHairline,
        surfaceContainerHighest: AppPalette.nightElevated,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypeNight.display,
        headlineMedium: AppTypeNight.title,
        titleMedium: AppTypeNight.section,
        bodyLarge: AppTypeNight.body,
        bodyMedium: AppTypeNight.body,
        labelLarge: AppTypeNight.label,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: GoldPalette.gold,
          foregroundColor: GoldPalette.nightDeep,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: AppTypeNight.label.copyWith(
            color: GoldPalette.nightDeep,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.capsule),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GoldPalette.goldSoft,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: const BorderSide(color: GoldPalette.goldHairline),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.capsule),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GoldPalette.goldSoft,
          textStyle: AppTypeNight.label,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GoldPalette.panel,
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
          borderSide: const BorderSide(color: GoldPalette.goldHairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.card,
          borderSide: const BorderSide(color: GoldPalette.gold, width: 1.4),
        ),
        labelStyle: AppTypeNight.label,
        hintStyle: AppTypeNight.body,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: GoldPalette.panel,
        selectedColor: AppPalette.nightElevated,
        side: const BorderSide(color: GoldPalette.goldHairline),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.capsule),
        labelStyle: AppTypeNight.label,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: GoldPalette.creamText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypeNight.section,
      ),
      dividerTheme: const DividerThemeData(
        color: GoldPalette.goldHairline,
        thickness: 0.6,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: GoldPalette.panel,
        contentTextStyle: AppTypeNight.body.copyWith(
          color: GoldPalette.creamText,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: GoldPalette.panel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
