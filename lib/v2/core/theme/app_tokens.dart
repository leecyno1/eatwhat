import 'package:eatwhat_app/v2/core/theme/app_theme_controller.dart';
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

  static TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    height: 1.08,
    color: AppPalette.gardenInk,
  );

  static TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.12,
    color: AppPalette.gardenInk,
  );

  static TextStyle section = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.2,
    color: AppPalette.gardenInk,
  );

  static TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppPalette.inkSoft,
  );

  static TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppPalette.inkSoft,
  );

  static TextStyle microLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: 1.2,
    color: AppPalette.inkMuted,
  );
}

class AppPalette {
  const AppPalette._();

  static bool get _isCream => AppThemeController.isCream;

  // ---- 点缀原色（两主题通用，不随主题分发） ----
  static const Color tomato = Color(0xFFE4513F);
  static const Color chili = Color(0xFFF45B33);
  static const Color chiliDeep = Color(0xFFD9431F);
  static const Color yolk = Color(0xFFFFB545);
  static const Color grape = Color(0xFF8A7CF7);
  static const Color ocean = Color(0xFF45A6D8);
  static const Color negativeSurface = Color(0xFFFFE8E2);

  // ---- 夜场原色 ----
  static const Color _night = Color(0xFF0B0B0D);
  static const Color _nightSurface = Color(0xFF242426);
  static const Color _nightElevated = Color(0xFF2C2C2E);
  static const Color _nightDivider = Color(0xFF3A3A3C);
  static const Color _moonlight = Color(0xFFEDEBE8);
  static const Color _moonMuted = Color(0xFF9B9691);
  static const Color _leafDark = Color(0xFF7ABF88);

  // ---- 米色纸感原色：warm rice canvas, cream cards, brown ink ----
  static const Color _creamCanvas = Color(0xFFF5EFE3);
  static const Color _creamSurface = Color(0xFFFCF8EF);
  static const Color _creamElevated = Color(0xFFF0E8D8);
  static const Color _creamDivider = Color(0xFFE2D8C4);
  static const Color _inkBrown = Color(0xFF2E2924);
  static const Color _mutedBrown = Color(0xFF8C8172);
  static const Color _leafCream = Color(0xFF4A5D4E);

  // ---- 主题分发的语义 token（夜场黑金 / 纸感米棕） ----

  /// 品牌主强调：夜场香槟金 / 纸感印刷棕。
  static Color get garden => _isCream ? _inkBrown : GoldPalette.gold;
  static Color get gardenDeep =>
      _isCream ? const Color(0xFF4A4238) : GoldPalette.goldSoft;
  static Color get gardenInk => _isCream ? _inkBrown : GoldPalette.creamText;
  static Color get gardenSoft => _isCream ? _creamSurface : GoldPalette.panel;
  static Color get gardenMist =>
      _isCream ? _creamCanvas : GoldPalette.nightDeep;
  static Color get gardenBorder =>
      _isCream ? _creamDivider : GoldPalette.goldHairline;
  static Color get herb => garden;

  /// Accent green — sage ink (墨绿) on the cream paper theme.
  static Color get leaf => _isCream ? _leafCream : _leafDark;

  /// 页面底与面板。
  static Color get broth => _isCream ? _creamCanvas : GoldPalette.nightDeep;
  static Color get cream => _isCream ? _creamSurface : GoldPalette.panel;
  static Color get rice => _isCream ? _creamSurface : GoldPalette.panel;
  static Color get canvas => gardenMist;
  static Color get surface => _isCream ? _creamSurface : GoldPalette.panel;
  static Color get surfaceMuted => _isCream ? _creamElevated : _nightElevated;
  static Color get divider => gardenBorder;
  static Color get positiveSurface =>
      _isCream ? _creamElevated : GoldPalette.panel;

  /// 深炭色：深色面板底 / 浅色底上的墨色文字。
  static Color get char => _isCream ? _inkBrown : GoldPalette.panel;
  static Color get ink => _isCream ? _inkBrown : GoldPalette.creamText;
  static Color get inkSoft => _isCream ? _mutedBrown : GoldPalette.creamMuted;
  static Color get inkMuted => _isCream ? _mutedBrown : GoldPalette.creamMuted;

  /// 夜场语义（米色模式下映射为纸感对应位）。
  static Color get night => _isCream ? _creamCanvas : _night;
  static Color get nightSurface => _isCream ? _creamSurface : _nightSurface;
  static Color get nightElevated => _isCream ? _creamElevated : _nightElevated;
  static Color get nightDivider => _isCream ? _creamDivider : _nightDivider;
  static Color get moonlight => _isCream ? _inkBrown : _moonlight;
  static Color get moonMuted => _isCream ? _mutedBrown : _moonMuted;

  // ---- 渐变 ----
  static const LinearGradient appetiteGradient = LinearGradient(
    colors: [chili, yolk],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get warmSurfaceGradient => LinearGradient(
        colors: _isCream
            ? const [_creamSurface, _creamElevated]
            : const [GoldPalette.panel, GoldPalette.nightDeep],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get gardenGradient => LinearGradient(
        colors: _isCream
            ? const [_inkBrown, Color(0xFF4A4238)]
            : const [GoldPalette.gold, GoldPalette.goldSoft],
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

/// Night-mode text styles for the V2 dark pages. Same metrics as the
/// daylight [AppType] styles, re-inked for the night palette so titles stay
/// moonlit and secondary text fades to moonMuted.
class AppTypeNight {
  const AppTypeNight._();

  static TextStyle get display => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        height: 1.08,
        color: AppPalette.moonlight,
      );

  static TextStyle get title => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.12,
        color: AppPalette.moonlight,
      );

  static TextStyle get section => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: AppPalette.moonlight,
      );

  static TextStyle get body => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: AppPalette.moonMuted,
      );

  static TextStyle get label => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppPalette.moonMuted,
      );

  static TextStyle get microLabel => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: 1.2,
        color: AppPalette.moonMuted,
      );
}

class AppDecorations {
  const AppDecorations._();

  static BoxDecoration card({
    Color color = AppSurfaces.glass,
    Color? borderColor,
    double radius = AppRadii.md,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? AppPalette.rice),
    );
  }

  static BoxDecoration floating({
    Color color = AppSurfaces.glass,
    Color? borderColor,
    double radius = AppRadii.lg,
  }) {
    return card(
      color: color,
      borderColor: borderColor,
      radius: radius,
    ).copyWith(boxShadow: AppSurfaces.softShadow());
  }

  /// Night-mode surface for the V2 dark pages: an elevated night panel
  /// with a subtle divider rim instead of the daylight glass card.
  static BoxDecoration nightCard({
    Color? color,
    Color? borderColor,
    double radius = AppRadii.md,
  }) {
    return BoxDecoration(
      color: color ?? AppPalette.nightSurface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? AppPalette.nightDivider),
    );
  }
}

/// Gold-luxury palette for the V2 result stage — 黑金奢华：纯黑底、香槟金
/// 强调、暖白文字、金色发丝线。serif 字体配大图，做高级餐厅菜单卡的观感。
class GoldPalette {
  const GoldPalette._();

  /// Stage background: near-black with a whisper of warmth.
  static const Color nightDeep = Color(0xFF0B0B0D);

  /// Panel color one step above the stage background.
  static const Color panel = Color(0xFF141416);

  /// Primary champagne gold — accents, active states, key actions.
  static const Color gold = Color(0xFFE8C97D);

  /// Softer antique gold for secondary accents.
  static const Color goldSoft = Color(0xFFC9A96E);

  /// Dim gold for hairlines and disabled states.
  static const Color goldDim = Color(0xFF8A6D2F);

  /// 20% gold hairline for borders and dividers.
  static const Color goldHairline = Color(0x33E8C97D);

  /// Warm candlelight white for primary text.
  static const Color creamText = Color(0xFFF5EEDC);

  /// Muted warm gray for secondary text.
  static const Color creamMuted = Color(0xFF9C948A);
}
