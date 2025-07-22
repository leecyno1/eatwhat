import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/services/storage_service.dart';
import 'core/config/env_config.dart';
import 'core/theme/modern_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/utils/performance_optimizer.dart';
import 'core/utils/memory_manager.dart';
import 'core/utils/log_sanitizer.dart';
import 'core/ai/personality_ai_service.dart';
import 'core/services/monetization_service.dart';
import 'core/services/growth_engine.dart';
import 'features/bubble/controllers/bubble_controller.dart';
import 'features/bubble/controllers/physical_entity_controller.dart';
import 'features/recommendation/controllers/recommendation_controller.dart';
import 'features/bubble/screens/enhanced_physical_entity_screen.dart';
import 'features/debug/debug_bubble_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 优化后的初始化过程
  try {
    SecureLogger.info('🚀 开始初始化《吃什么》应用...');

    // ✅ 阶段一：性能基础设施初始化
    PerformanceOptimizer().initialize(
      onPerformanceIssue: () => SecureLogger.warning('⚠️ 检测到性能问题'),
    );
    MemoryManager().initialize();

    // ✅ 基础服务初始化
    await EnvConfig.init().catchError((e) {
      SecureLogger.warning('Env config warning: $e');
    });
    
    // ✅ 安全验证
    if (!EnvConfig.validateConfig()) {
      SecureLogger.error('🚨 Configuration validation failed!');
    }
    
    if (!EnvConfig.validateApiKeySecurity()) {
      SecureLogger.error('🚨 API key security validation failed!');
    }

    await StorageService.initialize().catchError((e) {
      SecureLogger.warning('Storage service warning: $e');
    });

    // ✅ 阶段二：AI和个性化服务初始化
    await PersonalityAiService().initialize().catchError((e) {
      SecureLogger.warning('AI service warning: $e');
    });

    // ✅ 阶段三：商业化服务初始化
    await MonetizationService().initialize().catchError((e) {
      SecureLogger.warning('Monetization service warning: $e');
    });

    await GrowthEngine().initialize().catchError((e) {
      SecureLogger.warning('Growth engine warning: $e');
    });

    // 应用性能优化
    PerformanceOptimizer().applyOptimizations();

    SecureLogger.info('🎉 《吃什么》应用初始化完成 - 爆款模式已启动！');
  } catch (e) {
    SecureLogger.warning('初始化警告: $e - 继续启动应用');
  }

  runApp(const EatWhatApp());
}

class EatWhatApp extends StatelessWidget {
  const EatWhatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BubbleController()),
        ChangeNotifierProvider(create: (context) => PhysicalEntityController()),
        ChangeNotifierProvider(create: (context) => RecommendationController()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812), // iPhone标准尺寸
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            title: 'EatWhat',
            theme: ModernTheme.lightTheme,
            darkTheme: ModernTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: kIsWeb ? const DebugBubbleScreen() : const HomeScreen(), // Web上使用调试模式
            debugShowCheckedModeBanner: false,
            
            // 国际化支持
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            
            // 性能优化
            builder: (context, widget) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
                  ),
                ),
                child: widget!,
              );
            },
          );
        },
      ),
    );
  }
}

/// 安全的物理实体界面包装器
class SafePhysicalEntityScreen extends StatelessWidget {
  const SafePhysicalEntityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: ErrorHandler(
        child: EnhancedPhysicalEntityScreen(),
      ),
    );
  }
}

/// 错误处理组件
class ErrorHandler extends StatelessWidget {
  final Widget child;

  const ErrorHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (e) {
          SecureLogger.error('UI Error caught: $e');
          return _buildErrorFallback(context);
        }
      },
    );
  }

  Widget _buildErrorFallback(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.restaurant,
                  size: 80,
                  color: Color(0xFF007AFF),
                ),
                const SizedBox(height: 24),
                const Text(
                  '🍽️ 吃什么',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007AFF),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '正在初始化您的专属美食推荐系统...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  color: Color(0xFF007AFF),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // 重启应用
                    SystemNavigator.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '重新启动',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
