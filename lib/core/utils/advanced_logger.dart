import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 日志级别枚举
enum LogLevel {
  debug(0, 'DEBUG', '🐛'),
  info(1, 'INFO', 'ℹ️'),
  warning(2, 'WARNING', '⚠️'),
  error(3, 'ERROR', '❌'),
  fatal(4, 'FATAL', '💀');

  const LogLevel(this.value, this.name, this.emoji);

  final int value;
  final String name;
  final String emoji;
}

/// 日志条目数据结构
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? tag;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? extra;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.stackTrace,
    this.extra,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'tag': tag,
      'stackTrace': stackTrace?.toString(),
      'extra': extra,
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      level: LogLevel.values.firstWhere((l) => l.name == json['level']),
      message: json['message'],
      tag: json['tag'],
      stackTrace: json['stackTrace'] != null ? StackTrace.fromString(json['stackTrace']) : null,
      extra: json['extra'],
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('${level.emoji} ${level.name}: ');
    if (tag != null) buffer.write('[$tag] ');
    buffer.write(message);
    if (stackTrace != null) {
      buffer.write('\n');
      buffer.write(stackTrace.toString());
    }
    return buffer.toString();
  }
}

/// 高级日志系统 - 支持结构化日志、本地存储、远程上报
class AdvancedLogger {
  static AdvancedLogger? _instance;
  static AdvancedLogger get instance => _instance ??= AdvancedLogger._internal();

  AdvancedLogger._internal();

  // 配置选项
  LogLevel _minLogLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  bool _enableFileLogging = true;
  bool _enableConsoleLogging = true;
  bool _enableRemoteLogging = false;
  int _maxFileSize = 10 * 1024 * 1024; // 10MB
  int _maxLogFiles = 5;

  // 内部状态
  File? _currentLogFile;
  final List<LogEntry> _memoryBuffer = [];
  final int _maxMemoryBufferSize = 1000;
  Timer? _flushTimer;

  // 事件监听
  final StreamController<LogEntry> _logStreamController = StreamController<LogEntry>.broadcast();
  Stream<LogEntry> get logStream => _logStreamController.stream;

  /// 初始化日志系统
  Future<void> initialize({
    LogLevel? minLogLevel,
    bool? enableFileLogging,
    bool? enableConsoleLogging,
    bool? enableRemoteLogging,
    int? maxFileSize,
    int? maxLogFiles,
  }) async {
    _minLogLevel = minLogLevel ?? _minLogLevel;
    _enableFileLogging = enableFileLogging ?? _enableFileLogging;
    _enableConsoleLogging = enableConsoleLogging ?? _enableConsoleLogging;
    _enableRemoteLogging = enableRemoteLogging ?? _enableRemoteLogging;
    _maxFileSize = maxFileSize ?? _maxFileSize;
    _maxLogFiles = maxLogFiles ?? _maxLogFiles;

    if (_enableFileLogging) {
      await _initializeFileLogging();
    }

    // 启动定时刷新
    _flushTimer = Timer.periodic(const Duration(seconds: 10), (_) => _flushLogs());

    info('Advanced Logger initialized', tag: 'Logger');
  }

  /// 初始化文件日志
  Future<void> _initializeFileLogging() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDocDir.path}/logs');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      _currentLogFile = File('${logDir.path}/app_$timestamp.log');

      // 清理旧日志文件
      await _cleanupOldLogFiles(logDir);
    } catch (e) {
      developer.log('Failed to initialize file logging: $e');
    }
  }

  /// 清理旧日志文件
  Future<void> _cleanupOldLogFiles(Directory logDir) async {
    try {
      final files = logDir
          .listSync()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();

      // 按修改时间排序
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // 删除超出数量限制的文件
      if (files.length > _maxLogFiles) {
        for (int i = _maxLogFiles; i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (e) {
      developer.log('Failed to cleanup old log files: $e');
    }
  }

  /// 记录调试信息
  void debug(String message, {String? tag, Map<String, dynamic>? extra}) {
    _log(LogLevel.debug, message, tag: tag, extra: extra);
  }

  /// 记录一般信息
  void info(String message, {String? tag, Map<String, dynamic>? extra}) {
    _log(LogLevel.info, message, tag: tag, extra: extra);
  }

  /// 记录警告信息
  void warning(String message, {String? tag, Map<String, dynamic>? extra}) {
    _log(LogLevel.warning, message, tag: tag, extra: extra);
  }

  /// 记录错误信息
  void error(String message, {StackTrace? stackTrace, String? tag, Map<String, dynamic>? extra}) {
    _log(LogLevel.error, message, stackTrace: stackTrace, tag: tag, extra: extra);
  }

  /// 记录致命错误
  void fatal(String message, {StackTrace? stackTrace, String? tag, Map<String, dynamic>? extra}) {
    _log(LogLevel.fatal, message, stackTrace: stackTrace, tag: tag, extra: extra);
  }

  /// 结构化日志记录
  void structured(
    LogLevel level,
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  }) {
    _log(level, message, tag: tag, extra: data, stackTrace: stackTrace);
  }

  /// 性能日志
  void performance(String operation, Duration duration, {Map<String, dynamic>? metrics}) {
    final extra = <String, dynamic>{
      'duration_ms': duration.inMilliseconds,
      'operation': operation,
      if (metrics != null) ...metrics,
    };
    _log(LogLevel.info, 'Performance: $operation took ${duration.inMilliseconds}ms',
        tag: 'Performance', extra: extra);
  }

  /// 用户行为日志
  void userAction(String action, {Map<String, dynamic>? context}) {
    final extra = <String, dynamic>{
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
      if (context != null) ...context,
    };
    _log(LogLevel.info, 'User Action: $action', tag: 'UserBehavior', extra: extra);
  }

  /// 内部日志记录方法
  void _log(
    LogLevel level,
    String message, {
    String? tag,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    // 检查日志级别
    if (level.value < _minLogLevel.value) {
      return;
    }

    // 创建日志条目
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: _sanitizeMessage(message),
      tag: tag,
      stackTrace: stackTrace,
      extra: extra,
    );

    // 添加到内存缓冲区
    _memoryBuffer.add(entry);
    if (_memoryBuffer.length > _maxMemoryBufferSize) {
      _memoryBuffer.removeAt(0);
    }

    // 发送到流
    _logStreamController.add(entry);

    // 控制台输出
    if (_enableConsoleLogging) {
      _logToConsole(entry);
    }

    // 文件输出
    if (_enableFileLogging && _currentLogFile != null) {
      _logToFile(entry);
    }

    // 远程上报（异步）
    if (_enableRemoteLogging && level.value >= LogLevel.error.value) {
      _logToRemote(entry);
    }
  }

  /// 控制台输出
  void _logToConsole(LogEntry entry) {
    final formattedMessage = '${entry.level.emoji} [${entry.tag ?? 'APP'}] ${entry.message}';

    switch (entry.level) {
      case LogLevel.debug:
        developer.log(formattedMessage, level: 500);
        break;
      case LogLevel.info:
        developer.log(formattedMessage, level: 800);
        break;
      case LogLevel.warning:
        developer.log(formattedMessage, level: 900);
        break;
      case LogLevel.error:
      case LogLevel.fatal:
        developer.log(
          formattedMessage,
          level: 1000,
          error: entry.message,
          stackTrace: entry.stackTrace,
        );
        break;
    }

    // 在debug模式下也打印到debugPrint
    if (kDebugMode) {
      debugPrint(formattedMessage);
    }
  }

  /// 文件输出
  void _logToFile(LogEntry entry) {
    try {
      final file = _currentLogFile;
      if (file == null) return;

      // 检查文件大小
      if (file.existsSync() && file.lengthSync() > _maxFileSize) {
        _rotateLogFile();
        return;
      }

      // 写入日志
      final logLine = '${entry.toString()}\n';
      file.writeAsStringSync(logLine, mode: FileMode.append, flush: false);
    } catch (e) {
      developer.log('Failed to write log to file: $e');
    }
  }

  /// 轮转日志文件
  void _rotateLogFile() {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final currentFile = _currentLogFile;
      if (currentFile != null) {
        final directory = currentFile.parent;
        _currentLogFile = File('${directory.path}/app_$timestamp.log');
      }
    } catch (e) {
      developer.log('Failed to rotate log file: $e');
    }
  }

  /// 远程上报
  void _logToRemote(LogEntry entry) {
    // TODO: 实现远程日志上报
    // 可以集成Sentry、Firebase Crashlytics等
  }

  /// 刷新日志缓冲区
  void _flushLogs() {
    try {
      final file = _currentLogFile;
      if (file != null && file.existsSync()) {
        // 强制刷新文件缓冲区
        final raf = file.openSync(mode: FileMode.append);
        raf.flushSync();
        raf.closeSync();
      }
    } catch (e) {
      developer.log('Failed to flush logs: $e');
    }
  }

  /// 获取日志历史
  List<LogEntry> getRecentLogs({int? limit}) {
    final logs = List<LogEntry>.from(_memoryBuffer);
    if (limit != null && logs.length > limit) {
      return logs.sublist(logs.length - limit);
    }
    return logs;
  }

  /// 导出日志文件
  Future<List<File>> exportLogFiles() async {
    final files = <File>[];
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDocDir.path}/logs');

      if (await logDir.exists()) {
        final logFiles = logDir
            .listSync()
            .where((entity) => entity is File && entity.path.endsWith('.log'))
            .cast<File>()
            .toList();

        files.addAll(logFiles);
      }
    } catch (e) {
      error('Failed to export log files: $e');
    }
    return files;
  }

  /// 清理所有日志
  Future<void> clearLogs() async {
    try {
      _memoryBuffer.clear();

      final appDocDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDocDir.path}/logs');

      if (await logDir.exists()) {
        await logDir.delete(recursive: true);
        await _initializeFileLogging();
      }

      info('All logs cleared', tag: 'Logger');
    } catch (e) {
      error('Failed to clear logs: $e');
    }
  }

  /// 消息清理（移除敏感信息）
  String _sanitizeMessage(String message) {
    // 移除常见的敏感信息模式
    return message
        .replaceAll(
            RegExp(r'password["\s]*[:=]["\s]*[^"\s,}]+', caseSensitive: false), 'password=***')
        .replaceAll(RegExp(r'token["\s]*[:=]["\s]*[^"\s,}]+', caseSensitive: false), 'token=***')
        .replaceAll(RegExp(r'key["\s]*[:=]["\s]*[^"\s,}]+', caseSensitive: false), 'key=***')
        .replaceAll(RegExp(r'secret["\s]*[:=]["\s]*[^"\s,}]+', caseSensitive: false), 'secret=***');
  }

  /// 释放资源
  void dispose() {
    _flushTimer?.cancel();
    _logStreamController.close();
    _flushLogs();
  }
}

/// 全局日志接口 - 向后兼容SecureLogger
class SecureLogger {
  static final AdvancedLogger _logger = AdvancedLogger.instance;

  static void debug(String message, {String? tag}) => _logger.debug(message, tag: tag);
  static void info(String message, {String? tag}) => _logger.info(message, tag: tag);
  static void warning(String message, {String? tag}) => _logger.warning(message, tag: tag);
  static void error(String message, [StackTrace? stackTrace]) =>
      _logger.error(message, stackTrace: stackTrace);
  static void fatal(String message, [StackTrace? stackTrace]) =>
      _logger.fatal(message, stackTrace: stackTrace);

  // 性能监控
  static void performance(String operation, Duration duration) =>
      _logger.performance(operation, duration);

  // 用户行为记录
  static void userAction(String action, {Map<String, dynamic>? context}) =>
      _logger.userAction(action, context: context);
}
