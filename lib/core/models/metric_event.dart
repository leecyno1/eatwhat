import 'dart:convert';

/// 指标事件数据类
/// 用于记录用户行为指标事件
class MetricEvent {
  /// 事件类型
  final String type;

  /// 用户ID
  final String userId;

  /// 时间戳
  final DateTime timestamp;

  /// 事件属性
  final Map<String, dynamic>? properties;

  MetricEvent({
    required this.type,
    required this.userId,
    required this.timestamp,
    this.properties,
  });

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'properties': properties ?? {},
    };
  }

  /// 从 Map 创建
  factory MetricEvent.fromMap(Map<String, dynamic> map) {
    return MetricEvent(
      type: map['type'] as String,
      userId: map['user_id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      properties: map['properties'] != null
          ? Map<String, dynamic>.from(map['properties'])
          : null,
    );
  }

  /// 转换为 JSON 字符串
  String toJson() => json.encode(toMap());

  /// 从 JSON 字符串创建
  factory MetricEvent.fromJson(String source) =>
      MetricEvent.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MetricEvent(type: $type, userId: $userId, timestamp: $timestamp, properties: $properties)';
  }
}

/// 指标汇总数据类
class MetricSummary {
  /// 日活跃用户数
  final int dau;

  /// 月活跃用户数
  final int mau;

  /// 推荐转化率
  final double recommendationConversionRate;

  /// 气泡互动率
  final double bubbleInteractionRate;

  /// 订单完成率
  final double orderCompletionRate;

  /// 留存率 Map，key=天数，value=留存率
  final Map<int, double> retentionRates;

  MetricSummary({
    required this.dau,
    required this.mau,
    required this.recommendationConversionRate,
    required this.bubbleInteractionRate,
    required this.orderCompletionRate,
    required this.retentionRates,
  });

  /// 创建空实例
  factory MetricSummary.empty() {
    return MetricSummary(
      dau: 0,
      mau: 0,
      recommendationConversionRate: 0,
      bubbleInteractionRate: 0,
      orderCompletionRate: 0,
      retentionRates: {},
    );
  }

  @override
  String toString() {
    return 'MetricSummary(dau: $dau, mau: $mau, recommendationConversionRate: $recommendationConversionRate, '
        'bubbleInteractionRate: $bubbleInteractionRate, orderCompletionRate: $orderCompletionRate, '
        'retentionRates: $retentionRates)';
  }
}

/// 指标类型常量
class MetricTypes {
  MetricTypes._();

  /// 会话开始
  static const String sessionStart = 'session_start';

  /// 推荐展示
  static const String recommendationShown = 'recommendation_shown';

  /// 加入购物车
  static const String addToCart = 'add_to_cart';

  /// 订单提交
  static const String orderSubmitted = 'order_submitted';

  /// 气泡页面浏览
  static const String bubbleViewed = 'bubble_viewed';

  /// 气泡完成
  static const String bubbleComplete = 'bubble_complete';

  /// 用户注册
  static const String userRegister = 'user_register';
}
