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
  /// 主强调：夜场珊瑚 / 纸感陶土。
  static Color get sunsetOrange => AppPalette.leaf;

  /// 次强调：同色系浅一档。
  static Color get goldenHour => AppThemeController.skin.accentSoft;

  static LinearGradient get primaryGradient => AppPalette.gardenGradient;

  /// 点缀：与主强调同源，避免再引入苔绿。
  static Color get freshLime => AppPalette.leaf;

  static const Color berryPop = Color(0xFFE94A6A);

  /// 页面底：跟随当前舞台（夜场炭黑 / 纸感暖白 / 各美学底色）。
  static Color get lightBackground => AppPalette.night;

  /// 夜场底：始终取夜间主题所用皮肤的底色，与当前模式无关。
  static Color get darkBackground => AppThemeController.darkSkin.base;

  /// 主文字：夜场暖白 / 纸感墨黑。
  static Color get textPrimary => AppPalette.ink;

  /// 次文字：夜场暖灰 / 纸感灰棕。
  static Color get textSecondary => AppPalette.inkSoft;

  // Glass
  static const Color glassWhite = Color(0x4DFFFFFF);
  static const Color glassBlack = Color(0x4D000000);
}
