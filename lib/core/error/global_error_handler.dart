import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/log_sanitizer.dart';

/// 错误回调函数类型定义
typedef ErrorCallback = void Function(dynamic error, StackTrace? stackTrace);

/// 全局错误处理器 - 统一处理应用中的所有错误
class GlobalErrorHandler {
  static GlobalErrorHandler? _instance;
  static GlobalErrorHandler get instance => _instance ??= GlobalErrorHandler._internal();

  GlobalErrorHandler._internal();

  /// 错误处理策略
  final List<ErrorCallback> _errorCallbacks = [];

  /// 初始化全局错误处理
  static void initialize() {
    final handler = GlobalErrorHandler.instance;

    // 1. Flutter框架错误处理
    FlutterError.onError = (FlutterErrorDetails details) {
      handler._handleFlutterError(details);
    };

    // 2. 异步错误处理
    PlatformDispatcher.instance.onError = (error, stack) {
      handler._handlePlatformError(error, stack);
      return true;
    };

    // 3. Zone错误处理
    runZonedGuarded(() {
      // 应用启动代码将在这个Zone中运行
    }, (error, stackTrace) {
      handler._handleZoneError(error, stackTrace);
    });

    SecureLogger.info('🛡️ 全局错误处理器已初始化');
  }

  /// 添加错误处理回调
  void addErrorCallback(ErrorCallback callback) {
    _errorCallbacks.add(callback);
  }

  /// 移除错误处理回调
  void removeErrorCallback(ErrorCallback callback) {
    _errorCallbacks.remove(callback);
  }

  /// 处理Flutter框架错误
  void _handleFlutterError(FlutterErrorDetails details) {
    SecureLogger.error('Flutter Error: ${details.exception}', stackTrace: details.stack);

    // 通知所有注册的回调
    for (final callback in _errorCallbacks) {
      try {
        callback(details.exception, details.stack);
      } catch (e) {
        developer.log('Error in error callback: $e');
      }
    }

    // 在debug模式下显示红屏
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      // 生产模式下记录错误但不显示红屏
      developer.log('Flutter error: ${details.exception}', error: details.exception);
    }
  }

  /// 处理平台错误
  bool _handlePlatformError(Object error, StackTrace stackTrace) {
    SecureLogger.error('Platform Error: $error', stackTrace: stackTrace);

    for (final callback in _errorCallbacks) {
      try {
        callback(error, stackTrace);
      } catch (e) {
        developer.log('Error in error callback: $e');
      }
    }

    return true;
  }

  /// 处理Zone错误
  void _handleZoneError(Object error, StackTrace stackTrace) {
    SecureLogger.error('Zone Error: $error', stackTrace: stackTrace);

    for (final callback in _errorCallbacks) {
      try {
        callback(error, stackTrace);
      } catch (e) {
        developer.log('Error in error callback: $e');
      }
    }
  }

  /// 手动报告错误
  static void reportError(
    dynamic exception, [
    StackTrace? stackTrace,
    String? context,
  ]) {
    final contextInfo = context != null ? ' Context: $context' : '';
    SecureLogger.error('Manual Error Report: $exception$contextInfo', stackTrace: stackTrace);

    // 触发错误处理回调
    for (final callback in instance._errorCallbacks) {
      try {
        callback(exception, stackTrace);
      } catch (e) {
        developer.log('Error in error callback: $e');
      }
    }
  }

  /// 创建错误恢复UI
  static Widget buildErrorWidget(FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Color(0xFFFF6B6B),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '😅 出了点小问题',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '我们已经记录了这个错误，\n开发团队会尽快修复。',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF7F8C8D),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
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
                  if (kDebugMode) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Debug Info:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            details.exception.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7F8C8D),
                              fontFamily: 'monospace',
                            ),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 错误边界包装器 - 用于包装可能出错的Widget
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final String? errorContext;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.errorContext,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (error, stackTrace) {
          // 报告错误
          GlobalErrorHandler.reportError(error, stackTrace, errorContext);

          // 返回fallback UI或默认错误UI
          return fallback ?? _buildDefaultErrorWidget(error);
        }
      },
    );
  }

  Widget _buildDefaultErrorWidget(dynamic error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFFF6B6B),
            size: 24,
          ),
          const SizedBox(height: 8),
          const Text(
            '加载失败',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 4),
            Text(
              error.toString(),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7F8C8D),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// 异步操作错误处理器
class AsyncErrorHandler {
  /// 安全执行异步操作
  static Future<T?> safeExecute<T>(
    Future<T> Function() operation, {
    String? context,
    T? fallbackValue,
    bool logError = true,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      if (logError) {
        GlobalErrorHandler.reportError(error, stackTrace, context);
      }
      return fallbackValue;
    }
  }

  /// 安全执行同步操作
  static T? safeExecuteSync<T>(
    T Function() operation, {
    String? context,
    T? fallbackValue,
    bool logError = true,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      if (logError) {
        GlobalErrorHandler.reportError(error, stackTrace, context);
      }
      return fallbackValue;
    }
  }
}
