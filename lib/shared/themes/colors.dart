import 'package:flutter/material.dart';

/// 应用颜色定义
class AppColors {
  // 主色调
  static const Color primary = Color(0xFFFF6B6B);
  static const Color primaryLight = Color(0xFFFF9A9A);
  static const Color primaryDark = Color(0xFFE55555);

  // 次要色
  static const Color secondary = Color(0xFF4ECDC4);
  static const Color secondaryLight = Color(0xFF7EEEE7);
  static const Color secondaryDark = Color(0xFF3BA8A0);

  // 背景色
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // 深色主题背景
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2D2D2D);

  // 文本色
  static const Color onBackground = Color(0xFF1A1A1A);
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // 深色主题文本色
  static const Color onBackgroundDark = Color(0xFFE5E5E5);
  static const Color onSurfaceDark = Color(0xFFE5E5E5);

  // 功能色
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // 灰色系
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // 气泡相关颜色
  static const Color bubblePrimary = Color(0xFFFF6B6B);
  static const Color bubbleSecondary = Color(0xFF4ECDC4);
  static const Color bubbleAccent = Color(0xFFFFE66D);
  static const Color bubbleNeutral = Color(0xFFA8E6CF);

  // 液态玻璃效果
  static const Color glassBackground = Color(0x26FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassShadow = Color(0x1A000000);

  // 食物分类颜色
  static const Color categoryRed = Color(0xFFFF6B6B);
  static const Color categoryOrange = Color(0xFFFFBE0B);
  static const Color categoryYellow = Color(0xFFFFE66D);
  static const Color categoryGreen = Color(0xFFA8E6CF);
  static const Color categoryBlue = Color(0xFF88D8FF);
  static const Color categoryPurple = Color(0xFFD4A5FF);
  static const Color categoryPink = Color(0xFFFFB3BA);

  // 价格等级颜色
  static const Color priceBudget = Color(0xFF4CAF50);
  static const Color priceModerate = Color(0xFFFF9800);
  static const Color priceExpensive = Color(0xFFF44336);

  // 评分颜色
  static const Color ratingGold = Color(0xFFFFD700);
  static const Color ratingSilver = Color(0xFFC0C0C0);
  static const Color ratingBronze = Color(0xFFCD7F32);
}

/// 渐变色定义
class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryDark],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondary, AppColors.secondaryDark],
  );

  static const LinearGradient bubbleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.bubblePrimary,
      AppColors.bubbleSecondary,
    ],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: [
      Color(0xFFF4F4F4),
      Color(0xFFE8E8E8),
      Color(0xFFF4F4F4),
    ],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x40FFFFFF),
      Color(0x10FFFFFF),
    ],
  );
}

/// 阴影定义
class AppShadows {
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x15000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x20000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> bubbleShadow = [
    BoxShadow(
      color: Color(0x20000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x10000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}
