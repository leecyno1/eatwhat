import 'package:eatwhat_app/core/models/metric_event.dart';

/// 用于测试的虚假指标服务
class FakeMetricsService {
  final List<MetricEvent> recordedEvents = [];

  Future<void> recordEvent(MetricEvent event) async {
    recordedEvents.add(event);
  }

  Future<void> record(
    String type,
    String userId, {
    Map<String, dynamic>? properties,
  }) async {
    recordedEvents.add(MetricEvent(
      type: type,
      userId: userId,
      timestamp: DateTime.now(),
      properties: properties,
    ));
  }

  Future<void> init() async {
    // 无需初始化
  }

  void clear() {
    recordedEvents.clear();
  }
}
