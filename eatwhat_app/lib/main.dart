import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/bubble/controllers/bubble_controller.dart';
import 'features/recommendation/controllers/recommendation_controller.dart';
import 'features/bubble/screens/bubble_screen.dart';
import 'core/services/user_preference_service.dart';
import 'core/utils/memory_manager.dart';
import 'core/utils/performance_optimizer.dart';
import 'core/utils/app_startup_optimizer.dart';
import 'core/config/performance_config.dart';
import 'core/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart';

void main() async {
  // 开始启动性能监控
  StartupPerformanceMonitor.start();
  
  WidgetsFlutterBinding.ensureInitialized();
  StartupPerformanceMonitor.recordMilestone('flutter_binding_initialized');
  
  // 初始化应用启动优化器
  await AppStartupOptimizer.initialize();
  StartupPerformanceMonitor.recordMilestone('startup_optimizer_initialized');
  
  // 初始化Hive
  await Hive.initFlutter();
  StartupPerformanceMonitor.recordMilestone('hive_initialized');
  
  // 初始化用户偏好服务
  await UserPreferenceService.initialize();
  StartupPerformanceMonitor.recordMilestone('user_preferences_initialized');
  
  // 初始化认证服务
  await AuthService.initialize();
  
  // 优化应用启动
  AppStartupOptimizer.optimizeAppLaunch();
  
  runApp(const EatWhatApp());
  StartupPerformanceMonitor.recordMilestone('app_launched');
}

class EatWhatApp extends StatelessWidget {
  const EatWhatApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 记录应用构建完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StartupPerformanceMonitor.recordMilestone('first_frame_rendered');
      StartupPerformanceMonitor.stop();
    });
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BubbleController()),
        // 可以在这里添加更多的Provider
      ],
      child: MaterialApp(
        title: '吃什么',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'PingFang SC',
          // 应用性能优化主题设置
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const BubbleScreen(),
        },
        // 启用性能覆盖层（仅在调试模式下）
        showPerformanceOverlay: PerformanceConfig.showPerformanceOverlay,
      ),
    );
  }
}

/// 启动页面 - 检查登录状态并决定显示哪个页面
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // 等待一小段时间显示启动画面
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      // 检查用户是否已登录
      if (AuthService.isLoggedIn) {
        // 已登录，直接进入主页
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // 未登录，进入登录页面
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 应用名称
              Text(
                '吃什么',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 副标题
              Text(
                '发现美食，享受生活',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 20,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // 加载指示器
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                '正在启动...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
