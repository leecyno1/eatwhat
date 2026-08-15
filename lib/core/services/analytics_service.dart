import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/analytics_event.dart';
import 'metrics_service.dart';

/// 埋点服务核心类
/// 支持多种埋点模式：本地日志、Firebase Analytics、Sentry、自建服务器
class AnalyticsService {
  factory AnalyticsService() => _instance;

  AnalyticsService._internal() {
    _sessionId = _generateSessionId();
    _startFlushTimer();
  }

  static final AnalyticsService _instance = AnalyticsService._internal();

  // 当前埋点模式
  AnalyticsMode _currentMode = AnalyticsMode.local;

  // 用户ID
  String? _userId;

  // 会话ID
  late String _sessionId;

  // 页面名称栈（用于追踪页面路径）
  final List<String> _pageStack = [];

  // 事件队列（批处理用）
  final List<AnalyticsEvent> _eventQueue = [];
  static const int _batchSize = 10;

  /// 生成会话ID
  String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 获取当前会话ID
  String get sessionId => _sessionId;

  /// 设置埋点模式
  void setMode(AnalyticsMode mode) {
    _currentMode = mode;
    _log('埋点模式已切换为: ${mode.name}');
  }

  /// 设置用户ID
  void setUserId(String userId) {
    _userId = userId;
    _log('用户ID已设置: $userId');
  }

  /// 获取当前页面名称
  String? get currentPage => _pageStack.isNotEmpty ? _pageStack.last : null;

  /// 追踪页面进入
  void trackPageEnter(String pageName) {
    _pageStack.add(pageName);
    trackPageView(pageName);
  }

  /// 追踪页面离开
  void trackPageExit(String pageName) {
    if (_pageStack.isNotEmpty && _pageStack.last == pageName) {
      _pageStack.removeLast();
    }
  }

  /// 记录事件
  /// [eventName] 事件名称
  /// [properties] 事件属性
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? properties,
    bool recordMetrics = true,
    bool anonymous = false,
  }) async {
    // 获取事件类型枚举
    AnalyticsEventType? eventType;
    try {
      eventType = AnalyticsEventType.values.firstWhere(
        (e) => e.name == eventName,
      );
    } catch (_) {
      eventType = null;
    }

    final event = AnalyticsEvent(
      name: eventName,
      type: eventType ?? AnalyticsEventType.appLaunch,
      properties: _sanitizeProperties(
        properties,
        includeSession: !anonymous,
      ),
      userId: anonymous ? null : _userId,
      sessionId: anonymous ? null : _sessionId,
      pageName: anonymous ? null : currentPage,
    );

    _eventQueue.add(event);

    // 达到批处理大小时刷新
    if (_eventQueue.length >= _batchSize) {
      await _flush();
    }

    _logEvent(event);

    // 同时记录到指标系统
    if (recordMetrics && !anonymous) {
      await _recordToMetrics(eventName);
    }
  }

  /// 记录到指标系统
  Future<void> _recordToMetrics(String eventName) async {
    try {
      final userId = _userId ?? 'anonymous';
      await MetricsService().record(eventName, userId);
    } catch (e) {
      debugPrint('[Analytics] 记录指标失败: $e');
    }
  }

  /// 使用事件类型追踪事件
  Future<void> track(
    AnalyticsEventType eventType, {
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(eventType.name, properties: properties);
  }

  /// 追踪页面浏览
  Future<void> trackPageView(String pageName) async {
    await trackEvent(
      'page_view',
      properties: {
        'page_name': pageName,
        'previous_page':
            _pageStack.length > 1 ? _pageStack[_pageStack.length - 2] : null,
        'page_stack_depth': _pageStack.length,
      },
    );
  }

  /// 设置用户属性
  Future<void> setUserProperty(String name, dynamic value) async {
    _log('设置用户属性: $name = $value');
    // 本地模式下只记录日志
    if (_currentMode == AnalyticsMode.local) {
      await trackEvent('user_property_set', properties: {
        'property_name': name,
        'property_value': value?.toString(),
      });
    }
  }

  /// 记录用户ID
  Future<void> identify(String userId, {Map<String, dynamic>? traits}) async {
    _userId = userId;
    _log('用户识别: $userId');

    await trackEvent('user_identified', properties: {
      'user_id': userId,
      ...?traits,
    });
  }

  /// 记录用户登出
  Future<void> logout() async {
    if (_userId != null) {
      await trackEvent('user_logout', properties: {
        'user_id': _userId,
      });
      _userId = null;
    }
  }

  /// 重置会话
  void resetSession() {
    _sessionId = _generateSessionId();
    _log('会话已重置: $_sessionId');
  }

  /// 刷新事件队列
  Future<void> _flush() async {
    if (_eventQueue.isEmpty) return;

    final eventsToFlush = List<AnalyticsEvent>.from(_eventQueue);
    _eventQueue.clear();

    switch (_currentMode) {
      case AnalyticsMode.local:
        // 本地模式：输出到控制台/日志
        eventsToFlush.forEach(_logEvent);
        break;
      case AnalyticsMode.firebase:
        // Firebase Analytics 集成占位
        // await _sendToFirebase(eventsToFlush);
        _log('Firebase 埋点 (暂未集成): ${eventsToFlush.length} 个事件');
        break;
      case AnalyticsMode.sentry:
        // Sentry 集成占位
        // await _sendToSentry(eventsToFlush);
        _log('Sentry 埋点 (暂未集成): ${eventsToFlush.length} 个事件');
        break;
      case AnalyticsMode.customServer:
        // 自建服务器集成占位
        // await _sendToCustomServer(eventsToFlush);
        _log('自建服务器埋点 (暂未集成): ${eventsToFlush.length} 个事件');
        break;
    }
  }

  /// 启动定时刷新
  void _startFlushTimer() {
    // 在实际实现中可以使用 Timer.periodic
    // 这里简化处理，在每次 trackEvent 时检查时间
  }

  /// 记录事件到日志
  void _logEvent(AnalyticsEvent event) {
    final map = event.toMap();
    final message =
        '[Analytics] ${event.name}: ${_formatProperties(map['properties'])}';
    _log(message);
  }

  /// 格式化属性
  String _formatProperties(Map<String, dynamic>? properties) {
    if (properties == null || properties.isEmpty) return '{}';
    return properties.entries.map((e) => '${e.key}=${e.value}').join(', ');
  }

  /// 清理敏感数据
  Map<String, dynamic>? _sanitizeProperties(
    Map<String, dynamic>? properties, {
    required bool includeSession,
  }) {
    if (properties == null) return null;

    const sensitiveKeys = [
      'password',
      'token',
      'access_token',
      'refresh_token',
      'secret',
      'api_key',
      'credit_card',
      'phone',
      'email',
    ];

    final sanitized = Map<String, dynamic>.from(properties);
    for (final key in sanitized.keys) {
      if (sensitiveKeys.any((s) => key.toLowerCase().contains(s))) {
        sanitized[key] = '***';
      }
    }

    // 添加通用属性
    sanitized['_timestamp'] = DateTime.now().toIso8601String();
    if (includeSession) sanitized['_session_id'] = _sessionId;

    return sanitized;
  }

  /// 输出日志
  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }

    // 本地模式可以写入文件
    if (_currentMode == AnalyticsMode.local) {
      _writeToLocalLog(message);
    }
  }

  /// 写入本地日志文件
  Future<void> _writeToLocalLog(String message) async {
    try {
      final logDir = Directory.systemTemp;
      final logFile = File('${logDir.path}/eatwhat_analytics.log');
      final timestamp = DateTime.now().toIso8601String();
      await logFile.writeAsString(
        '[$timestamp] $message\n',
        mode: FileMode.append,
      );
    } catch (_) {
      // 忽略写入错误
    }
  }

  /// 同步发送所有待发送事件
  Future<void> flush() async {
    await _flush();
  }
}
