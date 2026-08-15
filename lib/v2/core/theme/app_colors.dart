import 'package:flutter/material.dart';

import 'app_tokens.dart';

class AppColors {
  // Legacy names retained for existing callers; the V2 primary is now garden.
  static const Color sunsetOrange = AppPalette.garden;
  static const Color goldenHour = AppPalette.yolk;

  static const LinearGradient primaryGradient = AppPalette.gardenGradient;

  // Accents
  static const Color freshLime = AppPalette.garden;
  static const Color berryPop = Color(0xFFE94A6A);

  // Backgrounds
  static const Color lightBackground = AppPalette.canvas;
  static const Color darkBackground = AppPalette.night;

  // Text
  static const Color textPrimary = AppPalette.gardenInk;
  static const Color textSecondary = AppPalette.inkMuted;

  // Glass
  static const Color glassWhite = Color(0x4DFFFFFF);
  static const Color glassBlack = Color(0x4D000000);
}
