import 'package:eatwhat_app/core/models/analytics_event.dart';
import 'package:eatwhat_app/core/services/analytics_service.dart';

/// Mock 埋点服务用于测试
class MockAnalyticsService implements AnalyticsService {
  MockAnalyticsService() {
    _mockSessionId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  final List<AnalyticsEvent> recordedEvents = [];
  String? _mockUserId;
  late String _mockSessionId;
  final List<String> _mockPageStack = [];

  @override
  String get sessionId => _mockSessionId;

  @override
  String? get currentPage =>
      _mockPageStack.isNotEmpty ? _mockPageStack.last : null;

  @override
  void setMode(AnalyticsMode mode) {}

  @override
  void setUserId(String userId) {
    _mockUserId = userId;
  }

  @override
  void trackPageEnter(String pageName) {
    _mockPageStack.add(pageName);
  }

  @override
  void trackPageExit(String pageName) {
    if (_mockPageStack.isNotEmpty && _mockPageStack.last == pageName) {
      _mockPageStack.removeLast();
    }
  }

  @override
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? properties,
    bool recordMetrics = true,
    bool anonymous = false,
  }) async {
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
      properties: properties,
      userId: anonymous ? null : _mockUserId,
      sessionId: anonymous ? null : _mockSessionId,
      pageName: anonymous ? null : currentPage,
    );

    recordedEvents.add(event);
  }

  @override
  Future<void> track(
    AnalyticsEventType eventType, {
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(eventType.name, properties: properties);
  }

  @override
  Future<void> trackPageView(String pageName) async {
    await trackEvent(
      'page_view',
      properties: {
        'page_name': pageName,
      },
    );
  }

  @override
  Future<void> setUserProperty(String name, dynamic value) async {
    await trackEvent('user_property_set', properties: {
      'property_name': name,
      'property_value': value?.toString(),
    });
  }

  @override
  Future<void> identify(String userId, {Map<String, dynamic>? traits}) async {
    _mockUserId = userId;
    await trackEvent('user_identified', properties: {
      'user_id': userId,
      ...?traits,
    });
  }

  @override
  Future<void> logout() async {
    if (_mockUserId != null) {
      await trackEvent('user_logout', properties: {
        'user_id': _mockUserId,
      });
      _mockUserId = null;
    }
  }

  @override
  void resetSession() {
    _mockSessionId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  Future<void> flush() async {
    // No-op for mock
  }

  void clear() {
    recordedEvents.clear();
    _mockPageStack.clear();
    _mockUserId = null;
  }
}
