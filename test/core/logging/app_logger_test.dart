import 'package:flutter_test/flutter_test.dart';
import 'package:eatwhat_app/core/logging/app_logger.dart';

void main() {
  group('AppLogger', () {
    late AppLogger logger;

    setUp(() {
      logger = AppLogger();
      logger.setMinLevel(LogLevel.debug); // 重置为debug级别
      logger.clearMemoryLogs();
    });

    test('应该能记录debug日志', () {
      logger.debug('测试debug日志', tag: 'test');
      final logs = logger.getMemoryLogs();

      expect(logs, isNotEmpty);
      expect(logs.last, contains('DEBUG'));
      expect(logs.last, contains('测试debug日志'));
      expect(logs.last, contains('[test]'));
    });

    test('应该能记录info日志', () {
      logger.info('测试info日志');
      final logs = logger.getMemoryLogs();

      expect(logs, isNotEmpty);
      expect(logs.last, contains('INFO'));
      expect(logs.last, contains('测试info日志'));
    });

    test('应该能记录warning日志', () {
      logger.warning('测试warning日志');
      final logs = logger.getMemoryLogs();

      expect(logs, isNotEmpty);
      expect(logs.last, contains('WARNING'));
    });

    test('应该能记录error日志', () {
      logger.error('测试error日志', error: 'Some error');
      final logs = logger.getMemoryLogs();

      expect(logs, isNotEmpty);
      expect(logs.last, contains('ERROR'));
      expect(logs.last, contains('Some error'));
    });

    test('应该尊重最小日志级别', () {
      logger.setMinLevel(LogLevel.info);
      logger.debug('不应该显示');
      logger.info('应该显示');
      final logs = logger.getMemoryLogs();

      expect(logs.length, equals(1));
      expect(logs.first, contains('INFO'));
    });

    test('应该按级别筛选日志', () {
      logger.debug('debug');
      logger.info('info');
      logger.warning('warning');
      logger.error('error');

      final errorLogs = logger.getMemoryLogs(level: LogLevel.error);
      expect(errorLogs.length, equals(1));
      expect(errorLogs.first, contains('ERROR'));
    });

    test('应该能清空内存日志', () {
      logger.info('测试');
      expect(logger.getMemoryLogs(), isNotEmpty);

      logger.clearMemoryLogs();
      expect(logger.getMemoryLogs(), isEmpty);
    });

    test('内存日志应该有最大限制', () {
      // 记录超过100条日志
      for (int i = 0; i < 150; i++) {
        logger.info('日志 $i');
      }

      final logs = logger.getMemoryLogs();
      expect(logs.length, equals(100)); // 最多保存100条
    });

    test('应该能导出日志', () {
      logger.debug('debug日志');
      logger.info('info日志');
      logger.error('error日志');

      final exported = logger.exportLogs();
      expect(exported, contains('debug日志'));
      expect(exported, contains('info日志'));
      expect(exported, contains('error日志'));
    });
  });
}
