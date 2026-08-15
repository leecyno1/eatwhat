/// 应用统一异常类型定义

/// 应用异常基类
abstract class AppException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

/// 认证异常
class AuthException extends AppException {
  AuthException({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// 网络异常
class NetworkException extends AppException {
  final int? statusCode;
  final String? url;

  NetworkException({
    required String message,
    this.statusCode,
    this.url,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// 数据解析异常
class DataException extends AppException {
  DataException({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// 本地存储异常
class StorageException extends AppException {
  StorageException({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// 业务逻辑异常
class BusinessException extends AppException {
  final String? code;

  BusinessException({
    required String message,
    this.code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// 未知异常
class UnknownException extends AppException {
  UnknownException({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// 异常工厂 - 将原始异常转换为AppException
class ExceptionFactory {
  static AppException create(
    dynamic error,
    StackTrace? stackTrace, {
    String? customMessage,
  }) {
    if (error is AppException) {
      return error;
    }

    if (error is FormatException) {
      return DataException(
        message: customMessage ?? 'Data parsing failed: ${error.message}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 注：TimeoutException来自dart:async
    if (error.runtimeType.toString() == '_TimeoutException') {
      return NetworkException(
        message: customMessage ?? 'Request timeout',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is NoSuchMethodError) {
      return UnknownException(
        message: customMessage ?? 'NoSuchMethodError: ${error.toString()}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 默认转换为UnknownException
    return UnknownException(
      message: customMessage ?? error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}
