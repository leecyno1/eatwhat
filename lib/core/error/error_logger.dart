import 'package:sentry_flutter/sentry_flutter.dart';
import '../utils/log_sanitizer.dart';
import 'app_exception.dart';

/// 错误日志记录器
class ErrorLogger {
  static const String _tag = '🔴 ErrorLogger';

  /// 记录错误并上报到Sentry
  static Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? extra,
  }) async {
    // 转换为AppException
    final appException = error is AppException
        ? error
        : ExceptionFactory.create(error, stackTrace);

    // 本地日志
    _logLocally(appException, context: context);

    // 上报到Sentry
    await _reportToSentry(appException, context: context, extra: extra);
  }

  /// 本地日志记录
  static void _logLocally(
    AppException exception, {
    String? context,
  }) {
    final errorMessage = '''$_tag 异常记录
类型: ${exception.runtimeType}
消息: ${exception.message}
${context != null ? '上下文: $context' : ''}
原始错误: ${exception.originalError}
''';

    SecureLogger.error(errorMessage);
  }

  /// 上报到Sentry
  static Future<void> _reportToSentry(
    AppException exception, {
    String? context,
    Map<String, dynamic>? extra,
  }) async {
    try {
      await Sentry.captureException(
        exception,
        stackTrace: exception.stackTrace,
        withScope: (scope) {
          scope.setContexts('exception_context', {
            'message': exception.message,
            'type': exception.runtimeType.toString(),
            if (context != null) 'context': context,
            if (extra != null) ...extra,
          });
        },
      );
    } catch (e) {
      SecureLogger.warning('Failed to report to Sentry: $e');
    }
  }

  /// 记录警告
  static void logWarning(
    String message, {
    String? context,
    dynamic error,
  }) {
    final warningMessage = '''⚠️  警告
消息: $message
${context != null ? '上下文: $context' : ''}
${error != null ? '错误: $error' : ''}
''';

    SecureLogger.warning(warningMessage);
  }

  /// 记录信息
  static void logInfo(
    String message, {
    String? context,
  }) {
    final infoMessage = '''ℹ️  信息
消息: $message
${context != null ? '上下文: $context' : ''}
''';

    SecureLogger.info(infoMessage);
  }
}
