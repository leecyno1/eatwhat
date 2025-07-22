import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../../features/bubble/screens/enhanced_physical_entity_screen.dart';
import '../../features/recommendation/screens/enhanced_recommendation_screen.dart';
import '../../features/favorites/screens/favorites_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/user/screens/user_profile_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../utils/route_animations.dart';

/// 现代化路由配置
class AppRouter {
  static const String home = '/';
  static const String bubble = '/bubble';
  static const String recommendation = '/recommendation';
  static const String favorites = '/favorites';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String login = '/login';
  static const String register = '/register';
  
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: home,
      routes: [
        // 主页
        GoRoute(
          path: home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const HomeScreen(),
            transitionsBuilder: RouteAnimations.fadeTransition,
          ),
        ),
        
        // 气泡选择页面
        GoRoute(
          path: bubble,
          name: 'bubble',
          builder: (context, state) => const EnhancedPhysicalEntityScreen(),
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const EnhancedPhysicalEntityScreen(),
            transitionsBuilder: RouteAnimations.slideFromRightTransition,
          ),
        ),
        
        // 推荐页面
        GoRoute(
          path: recommendation,
          name: 'recommendation',
          builder: (context, state) => const EnhancedRecommendationScreen(
            recommendedFoods: [],
            selectedPreferences: [],
          ),
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const EnhancedRecommendationScreen(
              recommendedFoods: [],
              selectedPreferences: [],
            ),
            transitionsBuilder: RouteAnimations.slideFromBottomTransition,
          ),
        ),
        
        // 收藏页面
        GoRoute(
          path: favorites,
          name: 'favorites',
          builder: (context, state) => const FavoritesScreen(),
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const FavoritesScreen(),
            transitionsBuilder: RouteAnimations.scaleTransition,
          ),
        ),
        
        // 历史页面
        GoRoute(
          path: history,
          name: 'history',
          builder: (context, state) => const HistoryScreen(),
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const HistoryScreen(),
            transitionsBuilder: RouteAnimations.fadeTransition,
          ),
        ),
        
        // 用户页面
        GoRoute(
          path: profile,
          name: 'profile',
          builder: (context, state) => const UserProfileScreen(),
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const UserProfileScreen(),
            transitionsBuilder: RouteAnimations.slideFromRightTransition,
          ),
        ),
        
        // 登录页面
        GoRoute(
          path: login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const LoginScreen(),
            transitionsBuilder: RouteAnimations.modalTransition,
          ),
        ),
        
        // 注册页面
        GoRoute(
          path: register,
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const RegisterScreen(),
            transitionsBuilder: RouteAnimations.modalTransition,
          ),
        ),
      ],
      
      // 错误页面
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('页面不存在'),
        ),
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
                '页面不存在: ${state.uri}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(home),
                child: const Text('返回主页'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}