import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

class AppRadii {
  const AppRadii._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double sheet = 40;
  static const double pill = 999;

  static BorderRadius get small => BorderRadius.circular(sm);
  static BorderRadius get card => BorderRadius.circular(md);
  static BorderRadius get panel => BorderRadius.circular(lg);
  static BorderRadius get hero => BorderRadius.circular(sheet);
  static BorderRadius get capsule => BorderRadius.circular(pill);
}

class AppType {
  const AppType._();

  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    height: 1.08,
    color: AppPalette.gardenInk,
  );

  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.12,
    color: AppPalette.gardenInk,
  );

  static const TextStyle section = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.2,
    color: AppPalette.gardenInk,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppPalette.inkSoft,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppPalette.inkSoft,
  );

  static const TextStyle microLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: 1.2,
    color: AppPalette.inkMuted,
  );
}

class AppPalette {
  const AppPalette._();

  static const Color garden = Color(0xFF2F9B4F);
  static const Color gardenDeep = Color(0xFF20783B);
  static const Color gardenInk = Color(0xFF123D2D);
  static const Color gardenSoft = Color(0xFFE7F5E8);
  static const Color gardenMist = Color(0xFFF4FAF3);
  static const Color gardenBorder = Color(0xFFD3E7D5);
  static const Color tomato = Color(0xFFE4513F);
  static const Color chili = Color(0xFFF45B33);
  static const Color chiliDeep = Color(0xFFD9431F);
  static const Color yolk = Color(0xFFFFB545);
  static const Color herb = garden;
  static const Color leaf = Color(0xFF7ABF88);
  static const Color broth = Color(0xFFFFF5E6);
  static const Color cream = Color(0xFFFFFBF6);
  static const Color rice = Color(0xFFFFFFFF);
  static const Color char = Color(0xFF241712);
  static const Color ink = Color(0xFF1D1D1F);
  static const Color inkSoft = Color(0xFF5E5652);
  static const Color inkMuted = Color(0xFF8D817A);
  static const Color night = Color(0xFF1C1C1E);
  static const Color nightSurface = Color(0xFF242426);
  static const Color nightElevated = Color(0xFF2C2C2E);
  static const Color nightDivider = Color(0xFF3A3A3C);
  static const Color moonlight = Color(0xFFEDEBE8);
  static const Color moonMuted = Color(0xFF9B9691);
  static const Color grape = Color(0xFF8A7CF7);
  static const Color ocean = Color(0xFF45A6D8);
  static const Color canvas = gardenMist;
  static const Color surface = Color(0xFFFFFEFA);
  static const Color surfaceMuted = Color(0xFFEEF7ED);
  static const Color divider = gardenBorder;
  static const Color positiveSurface = gardenSoft;
  static const Color negativeSurface = Color(0xFFFFE8E2);

  static const LinearGradient appetiteGradient = LinearGradient(
    colors: [chili, yolk],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmSurfaceGradient = LinearGradient(
    colors: [cream, Color(0xFFFFEEE8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gardenGradient = LinearGradient(
    colors: [Color(0xFF39A85A), gardenDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppSurfaces {
  const AppSurfaces._();

  static const Color glass = Color(0xCCFFFFFF);
  static const Color glassSoft = Color(0x8FFFFFFF);
  static const Color scrim = Color(0x12000000);

  static BorderSide get glassSide => BorderSide(
        color: AppPalette.rice.withValues(alpha: 0.72),
      );

  static BoxBorder get glassBorder => Border.all(
        color: AppPalette.rice.withValues(alpha: 0.72),
      );

  static List<BoxShadow> softShadow([Color color = const Color(0x331A120E)]) {
    return [
      BoxShadow(
        color: color,
        blurRadius: 28,
        offset: const Offset(0, 16),
      ),
    ];
  }
}

class AppMotion {
  const AppMotion._();

  static const Duration press = Duration(milliseconds: 140);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration page = Duration(milliseconds: 300);

  static const Curve enter = Cubic(0.23, 1, 0.32, 1);
  static const Curve move = Cubic(0.77, 0, 0.175, 1);
  static const Curve sheet = Cubic(0.32, 0.72, 0, 1);
}

class AppDecorations {
  const AppDecorations._();

  static BoxDecoration card({
    Color color = AppSurfaces.glass,
    Color borderColor = AppPalette.rice,
    double radius = AppRadii.md,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
    );
  }

  static BoxDecoration floating({
    Color color = AppSurfaces.glass,
    Color borderColor = AppPalette.rice,
    double radius = AppRadii.lg,
  }) {
    return card(
      color: color,
      borderColor: borderColor,
      radius: radius,
    ).copyWith(boxShadow: AppSurfaces.softShadow());
  }
}
