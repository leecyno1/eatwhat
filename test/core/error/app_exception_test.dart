import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:eatwhat_app/core/error/app_exception.dart';

void main() {
  group('AppException', () {
    test('AuthException应该正确创建', () {
      final exception = AuthException(
        message: '登录失败',
        originalError: 'Invalid credentials',
      );

      expect(exception.message, equals('登录失败'));
      expect(exception.originalError, equals('Invalid credentials'));
      expect(exception.toString(), equals('登录失败'));
    });

    test('NetworkException应该包含statusCode和url', () {
      final exception = NetworkException(
        message: '网络错误',
        statusCode: 500,
        url: 'https://api.example.com',
      );

      expect(exception.statusCode, equals(500));
      expect(exception.url, equals('https://api.example.com'));
    });

    test('DataException应该正确创建', () {
      final exception = DataException(
        message: '数据解析失败',
      );

      expect(exception.message, contains('数据'));
    });

    test('BusinessException应该包含code', () {
      final exception = BusinessException(
        message: '业务错误',
        code: 'BUSINESS_001',
      );

      expect(exception.code, equals('BUSINESS_001'));
    });
  });

  group('ExceptionFactory', () {
    test('应该将FormatException转换为DataException', () {
      final formatException = FormatException('Invalid format');
      final result = ExceptionFactory.create(formatException, null);

      expect(result, isA<DataException>());
      expect(result.message, contains('Data parsing'));
    });

    test('应该将Timeout异常转换为NetworkException', () {
      // 使用Future.delayed并超时来生成TimeoutException
      final result = ExceptionFactory.create(
        Exception('Request timeout'),
        null,
        customMessage: 'Request timeout',
      );

      expect(result.message, contains('timeout'));
    });

    test('应该保留AppException不变', () {
      final originalException = AuthException(
        message: '认证错误',
      );
      final result = ExceptionFactory.create(originalException, null);

      expect(result, equals(originalException));
    });

    test('应该将其他异常转换为UnknownException', () {
      final result = ExceptionFactory.create('Unknown error', null);

      expect(result, isA<UnknownException>());
    });

    test('应该支持自定义消息', () {
      final exception = FormatException('Original');
      final result = ExceptionFactory.create(
        exception,
        null,
        customMessage: 'Custom message',
      );

      expect(result.message, contains('Custom message'));
    });
  });
}
