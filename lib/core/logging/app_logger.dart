import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 日志级别
enum LogLevel {
  debug("DEBUG"),
  info("INFO"),
  warning("WARNING"),
  error("ERROR");

  final String label;
  const LogLevel(this.label);
}

/// 应用日志系统
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  static const String _boxName = 'app_logs';
  late Box<String> _logBox;
  LogLevel _minLevel = LogLevel.debug;
  final List<String> _memoryLogs = [];
  static const int _maxMemoryLogs = 100;

  /// 初始化日志系统
  Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      _logBox = await Hive.openBox<String>(_boxName);
      debugPrint('📝 日志系统已初始化');
    } catch (e) {
      debugPrint('Failed to initialize AppLogger: $e');
    }
  }

  /// 设置最小日志级别
  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// 调试级别日志
  void debug(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  /// 信息级别日志
  void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  /// 警告级别日志
  void warning(String message, {String? tag}) {
    _log(LogLevel.warning, message, tag: tag);
  }

  /// 错误级别日志
  void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    final errorInfo = error != null ? '\nError: $error' : '';
    final stackInfo = stackTrace != null ? '\nStackTrace: $stackTrace' : '';
    _log(LogLevel.error, message + errorInfo + stackInfo, tag: tag);
  }

  /// 内部日志处理
  void _log(
    LogLevel level,
    String message, {
    String? tag,
  }) {
    if (level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final prefix = tag != null ? '[$tag]' : '';
    final logMessage = '[${level.label}] $timestamp $prefix $message';

    // 打印到控制台
    debugPrint(logMessage);

    // 保存到内存
    _memoryLogs.add(logMessage);
    if (_memoryLogs.length > _maxMemoryLogs) {
      _memoryLogs.removeAt(0);
    }

    // 保存到本地存储（仅保存错误和警告）
    if (level == LogLevel.error || level == LogLevel.warning) {
      _saveToBox(logMessage);
    }
  }

  /// 保存到Hive
  void _saveToBox(String logMessage) {
    try {
      final key = DateTime.now().millisecondsSinceEpoch.toString();
      _logBox.put(key, logMessage);
    } catch (e) {
      debugPrint('Failed to save log: $e');
    }
  }

  /// 获取内存中的日志
  List<String> getMemoryLogs({LogLevel? level}) {
    if (level == null) return List.from(_memoryLogs);
    return _memoryLogs
        .where((log) => log.contains('[${level.label}]'))
        .toList();
  }

  /// 获取本地存储的日志
  List<String> getStoredLogs({int limit = 100}) {
    try {
      final logs = _logBox.values.toList();
      return logs.length > limit ? logs.sublist(logs.length - limit) : logs;
    } catch (e) {
      debugPrint('Failed to read logs: $e');
      return [];
    }
  }

  /// 清空内存日志
  void clearMemoryLogs() {
    _memoryLogs.clear();
  }

  /// 清空本地日志
  Future<void> clearStoredLogs() async {
    try {
      await _logBox.clear();
      info('本地日志已清空');
    } catch (e) {
      error('Failed to clear logs', error: e);
    }
  }

  /// 导出日志为文本
  String exportLogs() {
    final allLogs = <String>[];
    allLogs.addAll(_memoryLogs);
    allLogs.addAll(getStoredLogs());
    return allLogs.join('\n');
  }

  /// 关闭日志系统
  Future<void> close() async {
    try {
      await _logBox.close();
    } catch (e) {
      debugPrint('Failed to close AppLogger: $e');
    }
  }
}

/// 全局日志实例
final appLogger = AppLogger();
