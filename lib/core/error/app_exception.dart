/// 应用统一异常类型定义
library;

/// 应用异常基类
abstract class AppException implements Exception {

  AppException({
    required this.message,
    this.originalError,
    this.stackTrace,
  });
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  @override
  String toString() => message;
}

/// 认证异常
class AuthException extends AppException {
  AuthException({
    required super.message,
    super.originalError,
    super.stackTrace,
  });
}

/// 网络异常
class NetworkException extends AppException {

  NetworkException({
    required super.message,
    this.statusCode,
    this.url,
    super.originalError,
    super.stackTrace,
  });
  final int? statusCode;
  final String? url;
}

/// 数据解析异常
class DataException extends AppException {
  DataException({
    required super.message,
    super.originalError,
    super.stackTrace,
  });
}

/// 本地存储异常
class StorageException extends AppException {
  StorageException({
    required super.message,
    super.originalError,
    super.stackTrace,
  });
}

/// 业务逻辑异常
class BusinessException extends AppException {

  BusinessException({
    required super.message,
    this.code,
    super.originalError,
    super.stackTrace,
  });
  final String? code;
}

/// 未知异常
class UnknownException extends AppException {
  UnknownException({
    required super.message,
    super.originalError,
    super.stackTrace,
  });
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
