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
  
  // 优化应用启动
  AppStartupOptimizer.optimizeAppLaunch();
  
  runApp(const EatWhatApp());
  StartupPerformanceMonitor.recordMilestone('app_launched');
}

class EatWhatApp extends StatelessWidget {
  const EatWhatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 记录应用构建完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StartupPerformanceMonitor.recordMilestone('first_frame_rendered');
      StartupPerformanceMonitor.stop();
    });
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => BubbleController(),
        ),
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
        home: const BubbleScreen(),
        debugShowCheckedModeBanner: false,
        // 启用性能覆盖层（仅在调试模式下）
        showPerformanceOverlay: PerformanceConfig.showPerformanceOverlay,
      ),
    );
  }
}
