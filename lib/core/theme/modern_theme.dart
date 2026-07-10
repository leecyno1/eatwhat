import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 现代化iPhone风格主题
class ModernTheme {
  // 现代配色方案 - 灵感来自iOS设计
  static const Color primaryColor = Color(0xFF007AFF); // iOS蓝
  static const Color secondaryColor = Color(0xFFFF9500); // iOS橙
  static const Color backgroundColor = Color(0xFFF2F2F7); // iOS背景灰
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color accentColor = Color(0xFF34C759); // iOS绿
  static const Color warningColor = Color(0xFFFF3B30); // iOS红

  // 渐变色
  static const List<Color> primaryGradient = [
    Color(0xFF007AFF),
    Color(0xFF5856D6),
  ];

  static const List<Color> foodGradient = [
    Color(0xFFFF9500),
    Color(0xFFFF6B6B),
  ];

  static const List<Color> bubbleGradients = [
    Color(0xFFFF6B6B), // 红色系 - 辣味
    Color(0xFF4ECDC4), // 青色系 - 清淡
    Color(0xFF45B7D1), // 蓝色系 - 清爽
    Color(0xFF96CEB4), // 绿色系 - 健康
    Color(0xFFFECA57), // 黄色系 - 酸甜
    Color(0xFFFF9FF3), // 粉色系 - 甜腻
    Color(0xFF54A0FF), // 蓝色系 - 鲜美
    Color(0xFFEE5A24), // 橙色系 - 香辣
  ];

  /// iPhone适配的主题数据
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
      ),

      // 字体 - SF Pro风格
      fontFamily: '.SF Pro Text',
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 34.sp, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500),
      ),

      // AppBar主题 - iOS风格
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        iconTheme: const IconThemeData(color: primaryColor),
      ),

      // 卡片主题
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        color: surfaceColor,
        shadowColor: Colors.black.withValues(alpha: 0.1),
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          textStyle: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        hintStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 17.sp,
        ),
      ),
    );
  }

  /// 深色主题
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: const Color(0xFF1C1C1E),
      ),
      fontFamily: '.SF Pro Text',
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 34.sp, fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w400, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w400, color: Colors.white70),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: primaryColor),
      ),
    );
  }

  /// 获取气泡渐变色
  static LinearGradient getBubbleGradient(int index) {
    final colors = bubbleGradients[index % bubbleGradients.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colors,
        colors.withValues(alpha: 0.8),
      ],
    );
  }

  /// 毛玻璃效果
  static BoxDecoration get glassDecoration => BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
      );

  /// 阴影效果
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  /// iPhone安全区域适配
  static EdgeInsets safeAreaPadding(BuildContext context) => EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        bottom: MediaQuery.of(context).padding.bottom,
      );
}
