import 'package:flutter/material.dart';

/// Design tokens for the new rounded, soft, pastel UI style.
/// Derived from the reference design: cream backgrounds, bold rounded corners,
/// soft shadows, friendly typography, and pill CTAs.
class DesignTokens {
  // Core palette
  static const Color cream = Color(0xFFFAF6E9); // soft background
  static const Color creamAlt = Color(0xFFF7F2E2);
  static const Color ink = Color(0xFF2B2A29); // main text (dark brown)
  static const Color inkMuted = Color(0xFF6E6B67);

  // Accents
  static const Color mint = Color(0xFF56C0A9);
  static const Color teal = Color(0xFF2E8B79);
  static const Color orange = Color(0xFFF2A344);
  static const Color pink = Color(0xFFF48FA7);
  static const Color butter = Color(0xFFF7D77E);

  // Surfaces
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF4F1E9);

  // Elevation (soft neumorphic-like)
  static List<BoxShadow> softShadows([Color color = const Color(0x33000000)]) => [
        BoxShadow(color: color.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
        BoxShadow(color: color.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
      ];

  static const BorderRadius bigRadius = BorderRadius.all(Radius.circular(28));
  static const BorderRadius hugeRadius = BorderRadius.all(Radius.circular(36));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(999));

  // Spacing scale
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  // Typography (use built-in fonts; sizes tuned for mobile)
  static const TextStyle h1 =
      TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.1, color: ink);
  static const TextStyle h2 =
      TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.15, color: ink);
  static const TextStyle h3 =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.2, color: ink);
  static const TextStyle body =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4, color: inkMuted);
  static const TextStyle caption =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.2, color: inkMuted);
}
