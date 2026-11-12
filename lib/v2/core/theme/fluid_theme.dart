import 'package:flutter/material.dart';

import 'app_theme_controller.dart';
import 'app_tokens.dart';

/// V2 global theme, wired by AppV2 from [AppThemeController.mode].
///
/// [lightTheme] builds from [AppThemeController.lightSkin] and [darkTheme]
/// from [AppThemeController.darkSkin], so each brightness always reads a
/// matching skin: the active aesthetic when its brightness fits, otherwise
/// the legacy cream/night stage. Every curated aesthetic therefore flows
/// into Material widgets without widget changes.
///
/// Text uses the [AppTypeNight] family whose ink resolves through AppPalette,
/// so titles stay legible on any skin without separate maintenance.
class FluidTheme {
  /// Daylight build (any light skin).
  static ThemeData get lightTheme => _build(light: true);

  /// Night build (any dark skin).
  static ThemeData get darkTheme => _build(light: false);

  static ThemeData _build({required bool light}) {
    final skin =
        light ? AppThemeController.lightSkin : AppThemeController.darkSkin;
    final ink = skin.ink;
    final muted = skin.muted;
    final canvas = skin.base;
    final surface = skin.panel;
    final elevated = skin.elevated;
    final divider = skin.line;
    final accent = skin.accent;
    final accentSoft = skin.accentSoft;
    final onPrimary = light ? surface : canvas;
    final brightness = light ? Brightness.light : Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: canvas,
      fontFamily: '.SF Pro Text',
      primaryColor: accent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: brightness,
      ).copyWith(
        primary: accent,
        onPrimary: onPrimary,
        secondary: accentSoft,
        onSecondary: onPrimary,
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
          backgroundColor: accent,
          foregroundColor: onPrimary,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: AppTypeNight.label.copyWith(
            color: onPrimary,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.capsule),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: light ? accent : accentSoft,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: BorderSide(color: divider),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.capsule),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: light ? accent : accentSoft,
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
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.card,
          borderSide: BorderSide(color: accent, width: 1.4),
        ),
        labelStyle: AppTypeNight.label,
        hintStyle: AppTypeNight.body,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: light ? accentSoft.withValues(alpha: .38) : elevated,
        side: BorderSide(color: divider),
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
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 0.6,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: light
            ? AppTypeNight.body
            : AppTypeNight.body.copyWith(color: ink),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
