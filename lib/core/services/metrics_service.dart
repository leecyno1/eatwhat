import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/metric_event.dart';

/// 指标统计服务
/// 核心指标：DAU、MAU、转化率、留存率
class MetricsService {
  static final MetricsService _instance = MetricsService._internal();
  factory MetricsService() => _instance;

  // 数据存储（使用 Hive）
  final Map<String, List<MetricEvent>> _events = {};

  // Hive box 名称
  static const String _boxName = 'metrics_events';

  // 内存中缓存的最大事件数
  static const int _maxEventsInMemory = 1000;

  bool _isInitialized = false;

  MetricsService._internal();

  /// 初始化服务
  Future<void> init() async {
    if (_isInitialized) return;
    await _loadFromStorage();
    _isInitialized = true;
    debugPrint('[MetricsService] 初始化完成');
  }

  /// 确保服务已初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  /// 记录事件
  Future<void> recordEvent(MetricEvent event) async {
    await _ensureInitialized();

    _events[event.type] ??= [];
    _events[event.type]!.add(event);

    // 限制内存中事件数量
    if (_events[event.type]!.length > _maxEventsInMemory) {
      _events[event.type] = _events[event.type]!.sublist(
        _events[event.type]!.length - _maxEventsInMemory,
      );
    }

    await _persistToStorage();
    debugPrint('[MetricsService] 记录事件: ${event.type}, userId: ${event.userId}');
  }

  /// 记录带便捷构造函数的事件
  Future<void> record(
    String type,
    String userId, {
    Map<String, dynamic>? properties,
  }) async {
    await recordEvent(MetricEvent(
      type: type,
      userId: userId,
      timestamp: DateTime.now(),
      properties: properties,
    ));
  }

  /// 获取 DAU（日活跃用户）
  int getDAU(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final sessions = _events[MetricTypes.sessionStart] ?? [];
    final daySessions = sessions.where((e) =>
        e.timestamp.isAfter(dayStart) && e.timestamp.isBefore(dayEnd));

    return daySessions.map((e) => e.userId).toSet().length;
  }

  /// 获取今日 DAU
  int get todayDAU => getDAU(DateTime.now());

  /// 获取 MAU（月活跃用户）
  int getMAU(int year, int month) {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 1);

    final sessions = _events[MetricTypes.sessionStart] ?? [];
    final monthSessions = sessions.where((e) =>
        e.timestamp.isAfter(monthStart) && e.timestamp.isBefore(monthEnd));

    return monthSessions.map((e) => e.userId).toSet().length;
  }

  /// 获取本月 MAU
  int get currentMonthMAU {
    final now = DateTime.now();
    return getMAU(now.year, now.month);
  }

  /// 获取指定日期范围的转化率
  double getConversionRate(
    String fromEvent,
    String toEvent, {
    int days = 7,
  }) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));

    final fromEvents = _events[fromEvent] ?? [];
    final toEvents = _events[toEvent] ?? [];

    final fromCount = fromEvents
        .where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(now))
        .length;

    final toCount = toEvents
        .where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(now))
        .length;

    if (fromCount == 0) return 0;
    return toCount / fromCount;
  }

  /// 获取留存率
  /// [day] D0 是注册日，D1 是次日留存，以此类推
  double getRetentionRate(int day, {int days = 30}) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));

    // 获取这段时间内注册的用户
    final registerEvents = _events[MetricTypes.userRegister] ?? [];
    final newUsers = registerEvents
        .where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(now))
        .map((e) => e.userId)
        .toSet();

    if (newUsers.isEmpty) return 0;

    // 计算在第 N 天活跃的用户数
    int retainedCount = 0;
    for (final userId in newUsers) {
      final userRegisterEvent = registerEvents.firstWhere(
        (e) => e.userId == userId,
        orElse: () => MetricEvent(
          type: MetricTypes.userRegister,
          userId: userId,
          timestamp: now,
        ),
      );

      final targetDate = DateTime(
        userRegisterEvent.timestamp.year,
        userRegisterEvent.timestamp.month,
        userRegisterEvent.timestamp.day,
      ).add(Duration(days: day));

      final sessions = _events[MetricTypes.sessionStart] ?? [];
      final hasActivity = sessions.any((e) =>
          e.userId == userId &&
          e.timestamp.isAfter(targetDate) &&
          e.timestamp.isBefore(targetDate.add(const Duration(days: 1))));

      if (hasActivity) retainedCount++;
    }

    return retainedCount / newUsers.length;
  }

  /// 获取多日留存率
  Map<int, double> getRetentionRates({List<int> days = const [1, 7, 30]}) {
    final rates = <int, double>{};
    for (final day in days) {
      rates[day] = getRetentionRate(day);
    }
    return rates;
  }

  /// 推荐转化率 = 加入购物车 / 推荐展示
  double getRecommendationConversionRate({int days = 7}) {
    return getConversionRate(
      MetricTypes.recommendationShown,
      MetricTypes.addToCart,
      days: days,
    );
  }

  /// 气泡互动完成率 = 完成偏好选择 / 进入气泡页
  double getBubbleInteractionRate({int days = 7}) {
    return getConversionRate(
      MetricTypes.bubbleViewed,
      MetricTypes.bubbleComplete,
      days: days,
    );
  }

  /// 订单完成率 = 订单提交 / 加入购物车
  double getOrderCompletionRate({int days = 7}) {
    return getConversionRate(
      MetricTypes.addToCart,
      MetricTypes.orderSubmitted,
      days: days,
    );
  }

  /// 获取指标汇总
  Future<MetricSummary> getSummary({int days = 7}) async {
    await _ensureInitialized();

    final retentionRates = <int, double>{};

    for (final day in [1, 7, 30]) {
      retentionRates[day] = getRetentionRate(day, days: 90);
    }

    return MetricSummary(
      dau: todayDAU,
      mau: currentMonthMAU,
      recommendationConversionRate: getRecommendationConversionRate(days: days),
      bubbleInteractionRate: getBubbleInteractionRate(days: days),
      orderCompletionRate: getOrderCompletionRate(days: days),
      retentionRates: retentionRates,
    );
  }

  /// 清除所有数据（用于测试）
  Future<void> clearAll() async {
    _events.clear();
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.clear();
    } catch (e) {
      debugPrint('[MetricsService] 清除数据失败: $e');
    }
  }

  /// 持久化到存储
  Future<void> _persistToStorage() async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      final allEvents = <String, List<Map<String, dynamic>>>{};

      for (final entry in _events.entries) {
        allEvents[entry.key] = entry.value.map((e) => e.toMap()).toList();
      }

      await box.put('all_events', json.encode(allEvents));
    } catch (e) {
      debugPrint('[MetricsService] 持久化失败: $e');
    }
  }

  /// 从存储加载数据
  Future<void> _loadFromStorage() async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      final data = box.get('all_events');

      if (data != null) {
        final allEvents = json.decode(data) as Map<String, dynamic>;
        for (final entry in allEvents.entries) {
          final events = (entry.value as List)
              .map((e) => MetricEvent.fromMap(e as Map<String, dynamic>))
              .toList();
          _events[entry.key] = events;
        }
        debugPrint('[MetricsService] 从存储加载了 ${_events.length} 种事件类型');
      }
    } catch (e) {
      debugPrint('[MetricsService] 从存储加载失败: $e');
    }
  }

  /// 获取事件统计摘要
  Map<String, int> getEventCounts({int days = 7}) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    final counts = <String, int>{};

    for (final entry in _events.entries) {
      counts[entry.key] = entry.value
          .where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(now))
          .length;
    }

    return counts;
  }
}
