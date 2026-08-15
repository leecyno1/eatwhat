import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/bubble/screens/bubble_screen.dart';
import '../../features/bubble/screens/glassmorphism_bubble_screen.dart';
import '../../features/recommendation/screens/recommendation_screen.dart';
import '../../features/user/screens/user_profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/pastel_settings_screen.dart';
import '../../features/style_preview/style_preview_screen.dart';
import '../../features/preferences/screens/taste_preferences_screen.dart';
import '../../features/metrics/metrics_dashboard_screen.dart';

/// 应用路由配置
class AppRouter {
  static const String home = '/';
  static const String glassmorphismHome = '/glassmorphism';
  static const String recommendation = '/recommendation';
  static const String userProfile = '/profile';
  static const String settings = '/settings';
  static const String stylePreview = '/style-preview';
  static const String tastePreferences = '/taste-preferences';
  static const String metricsDashboard = '/metrics';

  /// 创建路由配置
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: tastePreferences, // 演示新“口味偏好选择”页面
      routes: [
        // 传统风格主界面
        GoRoute(
          path: home,
          name: 'home',
          builder: (context, state) => const BubbleScreen(),
        ),

        // Glassmorphism风格主界面
        GoRoute(
          path: glassmorphismHome,
          name: 'glassmorphism_home',
          builder: (context, state) => const GlassmorphismBubbleScreen(),
        ),

        // 推荐界面
        GoRoute(
          path: recommendation,
          name: 'recommendation',
          builder: (context, state) => const RecommendationScreen(),
        ),

        // 用户资料界面
        GoRoute(
          path: userProfile,
          name: 'user_profile',
          builder: (context, state) => const UserProfileScreen(),
        ),

        // 设置界面
        GoRoute(
          path: settings,
          name: 'settings',
          builder: (context, state) => const PastelSettingsScreen(),
        ),

        // 视觉风格预览（新UI样式）
        GoRoute(
          path: stylePreview,
          name: 'style_preview',
          builder: (context, state) => const StylePreviewScreen(),
        ),

        // 新的口味偏好选择页面（瀑布流气泡）
        GoRoute(
          path: tastePreferences,
          name: 'taste_preferences',
          builder: (context, state) => const TastePreferencesScreen(),
        ),

        // 运营数据看板
        GoRoute(
          path: metricsDashboard,
          name: 'metrics_dashboard',
          builder: (context, state) => const MetricsDashboardScreen(),
        ),
      ],

      // 错误页面处理
      errorBuilder: (context, state) => _buildErrorPage(context, state),
    );
  }

  /// 构建页面
  static Widget _buildPage(GoRouterState state) {
    switch (state.matchedLocation) {
      case home:
        return const BubbleScreen();
      case glassmorphismHome:
        return const GlassmorphismBubbleScreen();
      case recommendation:
        return const RecommendationScreen();
      case userProfile:
        return const UserProfileScreen();
      case settings:
        return const SettingsScreen();
      default:
        return _buildErrorPage(null, state);
    }
  }

  /// 构建错误页面
  static Widget _buildErrorPage(BuildContext? context, GoRouterState state) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              '页面未找到',
              style: Theme.of(context!).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '路径: ${state.matchedLocation}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(home),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 路由导航工具类
class AppNavigation {
  /// 导航到主界面
  static void goToHome(BuildContext context) {
    context.go(AppRouter.home);
  }

  /// 导航到Glassmorphism主界面
  static void goToGlassmorphismHome(BuildContext context) {
    context.go(AppRouter.glassmorphismHome);
  }

  /// 导航到推荐界面
  static void goToRecommendation(BuildContext context) {
    context.go(AppRouter.recommendation);
  }

  /// 导航到用户资料界面
  static void goToUserProfile(BuildContext context) {
    context.go(AppRouter.userProfile);
  }

  /// 导航到设置界面
  static void goToSettings(BuildContext context) {
    context.go(AppRouter.settings);
  }

  /// 推送推荐界面
  static void pushRecommendation(BuildContext context) {
    context.push(AppRouter.recommendation);
  }

  /// 推送用户资料界面
  static void pushUserProfile(BuildContext context) {
    context.push(AppRouter.userProfile);
  }

  /// 推送设置界面
  static void pushSettings(BuildContext context) {
    context.push(AppRouter.settings);
  }

  /// 推送运营数据看板
  static void pushMetricsDashboard(BuildContext context) {
    context.push(AppRouter.metricsDashboard);
  }
}
