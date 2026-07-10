import 'package:flutter/material.dart';
import '../models/bubble.dart';
import '../../shared/themes/design_tokens.dart';

/// 现代化应用主题配置
class AppTheme {
  // --- 新的颜色定义 ---
  static const Color primaryColor = Color(0xFF00A99D); // 充满活力的青绿色
  static const Color primaryVariantColor = Color(0xFF007A70);
  static const Color secondaryColor = Color(0xFFFFB74D); // 温馨的橙色
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFD32F2F);

  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);

  // --- 字体颜色 ---
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textOnPrimaryColor = Colors.white;
  static const Color textOnSecondaryColor = Colors.black;

  static const Color darkTextPrimaryColor = Color(0xFFE0E0E0);
  static const Color darkTextSecondaryColor = Color(0xFFBDBDBD);

  /// 浅色主题
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'SF Pro Text',
      colorScheme: const ColorScheme(
        primary: primaryColor,
        primaryContainer: primaryVariantColor,
        secondary: secondaryColor,
        secondaryContainer: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: textOnPrimaryColor,
        onSecondary: textOnSecondaryColor,
        onSurface: textPrimaryColor,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        color: surfaceColor,
        elevation: 1,
        iconTheme: IconThemeData(color: textPrimaryColor),
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor.withValues(alpha: 0.8),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
        ),
      ),
      textTheme: _lightTextTheme,
    );
  }

  /// 深色主题
  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      fontFamily: 'SF Pro Text',
      colorScheme: const ColorScheme(
        primary: primaryColor,
        primaryContainer: primaryVariantColor,
        secondary: secondaryColor,
        secondaryContainer: secondaryColor,
        surface: darkSurfaceColor,
        error: errorColor,
        onPrimary: textOnPrimaryColor,
        onSecondary: textOnSecondaryColor,
        onSurface: darkTextPrimaryColor,
        onError: Colors.white,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        color: darkSurfaceColor,
        elevation: 1,
        iconTheme: IconThemeData(color: darkTextPrimaryColor),
        titleTextStyle: TextStyle(
          color: darkTextPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: darkTextSecondaryColor.withValues(alpha: 0.8),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: const CardThemeData(
        color: darkSurfaceColor,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
        ),
      ),
      textTheme: _darkTextTheme,
    );
  }

  // --- 文字主题 ---
  static const TextTheme _lightTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimaryColor),
    displayMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimaryColor),
    displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimaryColor),
    headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimaryColor),
    headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimaryColor),
    titleLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimaryColor),
    bodyLarge: TextStyle(fontSize: 16, color: textPrimaryColor),
    bodyMedium: TextStyle(fontSize: 14, color: textSecondaryColor),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textOnPrimaryColor),
  );

  static const TextTheme _darkTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkTextPrimaryColor),
    displayMedium:
        TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkTextPrimaryColor),
    displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkTextPrimaryColor),
    headlineMedium:
        TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPrimaryColor),
    headlineSmall:
        TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkTextPrimaryColor),
    titleLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkTextPrimaryColor),
    bodyLarge: TextStyle(fontSize: 16, color: darkTextPrimaryColor),
    bodyMedium: TextStyle(fontSize: 14, color: darkTextSecondaryColor),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textOnPrimaryColor),
  );

  /// New rounded pastel theme based on the target reference
  /// Does not replace existing themes; opt-in via `AppTheme.roundedPastel`.
  static ThemeData get roundedPastel {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: DesignTokens.cream,
      primaryColor: DesignTokens.mint,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: DesignTokens.mint,
        onPrimary: Colors.white,
        secondary: DesignTokens.orange,
        onSecondary: DesignTokens.ink,
        surface: DesignTokens.surface,
        onSurface: DesignTokens.ink,
        error: const Color(0xFFDA3C3C),
        onError: Colors.white,
        primaryContainer: DesignTokens.teal,
        secondaryContainer: DesignTokens.butter,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: DesignTokens.ink,
        titleTextStyle: DesignTokens.h3,
      ),
      textTheme: const TextTheme(
        displayLarge: DesignTokens.h1,
        displayMedium: DesignTokens.h2,
        headlineMedium: DesignTokens.h3,
        bodyMedium: DesignTokens.body,
        bodySmall: DesignTokens.caption,
      ),
      cardTheme: const CardThemeData(
        color: DesignTokens.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: DesignTokens.bigRadius),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.ink,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DesignTokens.mint,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.ink,
          side: const BorderSide(color: DesignTokens.ink),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.surface,
        hintStyle: DesignTokens.caption,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border:
            OutlineInputBorder(borderRadius: DesignTokens.bigRadius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: DesignTokens.bigRadius,
            borderSide: BorderSide(color: DesignTokens.mint, width: 2)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DesignTokens.surface,
        labelStyle: const TextStyle(color: DesignTokens.ink, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: const StadiumBorder(),
        selectedColor: DesignTokens.mint.withOpacity(0.15),
      ),
      useMaterial3: true,
    );
  }

  /// 气泡主题颜色
  static Color getBubbleColor(BubbleType type) {
    switch (type) {
      case BubbleType.taste:
        return const Color(0xFFFF6B6B);
      case BubbleType.cuisine:
        return const Color(0xFF4ECDC4);
      case BubbleType.ingredient:
        return const Color(0xFF96CEB4);
      case BubbleType.scenario:
        return const Color(0xFF45B7D1);
      case BubbleType.nutrition:
        return const Color(0xFFEECA7C);
      // 兼容新增的细分口味类型，统一归类为 taste 色系
      default:
        return const Color(0xFFFF6B6B);
    }
  }

  /// 气泡渐变色
  static LinearGradient getBubbleGradient(BubbleType type) {
    final baseColor = getBubbleColor(type);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor,
        baseColor.withValues(alpha: 0.7),
      ],
    );
  }

  /// 自定义阴影
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];

  /// 浮动动作按钮阴影
  static List<BoxShadow> get fabShadow => [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  /// 气泡发光阴影
  static List<BoxShadow> getBubbleGlowShadow(Color color, {double intensity = 1.0}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.3 * intensity),
          blurRadius: 8 + 12 * intensity,
          spreadRadius: 2 + 4 * intensity,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
}
