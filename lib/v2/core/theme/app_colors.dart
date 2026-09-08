import 'package:flutter/material.dart';

import 'app_theme_controller.dart';
import 'app_tokens.dart';

/// V2 流程页语义色：跟随 [AppThemeController] 双主题。
///
/// - 黑金夜场（dark）：纯黑底 + 香槟金强调 + 暖白文字。
/// - 米色纸感（cream）：暖米纸底 + 印刷深棕强调 + 深棕文字。
///
/// legacy 命名保留给既有调用方，但取值按主题分发，保证结果页之后的
/// 所有流程页面（详情/执行/菜库/收藏/美团）与当前舞台视觉统一。
class AppColors {
  static bool get _isCream => AppThemeController.isCream;

  /// 主强调：夜场香槟金 / 纸感深棕。
  static Color get sunsetOrange =>
      _isCream ? const Color(0xFF2E2924) : GoldPalette.gold;

  /// 次强调：夜场柔金 / 纸感灰棕。
  static Color get goldenHour =>
      _isCream ? const Color(0xFF8C8172) : GoldPalette.goldSoft;

  static LinearGradient get primaryGradient => LinearGradient(
        colors: _isCream
            ? const [Color(0xFF2E2924), Color(0xFF4A4238)]
            : const [GoldPalette.gold, GoldPalette.goldSoft],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// 点缀：夜场柔金 / 纸感苔绿。
  static Color get freshLime =>
      _isCream ? const Color(0xFF4A5D4E) : GoldPalette.goldSoft;

  static const Color berryPop = Color(0xFFE94A6A);

  /// 页面底：夜场纯黑 / 纸感暖米。
  static Color get lightBackground =>
      _isCream ? const Color(0xFFF5EFE3) : GoldPalette.nightDeep;

  static Color get darkBackground => lightBackground;

  /// 主文字：夜场暖白 / 纸感深棕。
  static Color get textPrimary =>
      _isCream ? const Color(0xFF2E2924) : GoldPalette.creamText;

  /// 次文字：夜场暖灰 / 纸感灰棕。
  static Color get textSecondary =>
      _isCream ? const Color(0xFF8C8172) : GoldPalette.creamMuted;

  // Glass
  static const Color glassWhite = Color(0x4DFFFFFF);
  static const Color glassBlack = Color(0x4D000000);
}
