import 'package:flutter_test/flutter_test.dart';
import 'package:eatwhat_app/core/models/analytics_event.dart';
import 'mock_analytics_service.dart';

void main() {
  group('MockAnalyticsService', () {
    late MockAnalyticsService analyticsService;

    setUp(() {
      analyticsService = MockAnalyticsService();
      analyticsService.setMode(AnalyticsMode.local);
    });

    tearDown(() {
      analyticsService.clear();
    });

    test('应该生成唯一的会话ID', () {
      final sessionId1 = analyticsService.sessionId;
      expect(sessionId1, isNotEmpty);
    });

    test('应该能设置用户ID', () async {
      analyticsService.setUserId('user123');
      expect(analyticsService.sessionId, isNotEmpty);
    });

    test('应该能记录事件', () async {
      await analyticsService.trackEvent(
        'test_event',
        properties: {'key': 'value'},
      );
      expect(analyticsService.recordedEvents.length, equals(1));
      expect(analyticsService.recordedEvents.first.name, equals('test_event'));
    });

    test('应该能追踪页面进入和离开', () async {
      analyticsService.trackPageEnter('home_page');
      expect(analyticsService.currentPage, equals('home_page'));

      analyticsService.trackPageExit('home_page');
      expect(analyticsService.currentPage, isNull);
    });

    test('应该能追踪页面堆栈', () async {
      analyticsService.trackPageEnter('page1');
      analyticsService.trackPageEnter('page2');
      expect(analyticsService.currentPage, equals('page2'));

      analyticsService.trackPageExit('page2');
      expect(analyticsService.currentPage, equals('page1'));
    });

    test('应该能设置埋点模式', () async {
      analyticsService.setMode(AnalyticsMode.firebase);
      expect(analyticsService.sessionId, isNotEmpty);

      analyticsService.setMode(AnalyticsMode.local);
      expect(analyticsService.sessionId, isNotEmpty);
    });

    test('应该能记录用户属性', () async {
      await analyticsService.setUserProperty('dark_mode', true);
      expect(analyticsService.recordedEvents.length, greaterThan(0));
    });

    test('应该能识别用户', () async {
      await analyticsService.identify(
        'user_abc',
        traits: {'plan': 'premium'},
      );
      expect(analyticsService.recordedEvents.length, greaterThan(0));
    });

    test('应该能记录用户登出', () async {
      analyticsService.setUserId('user123');
      await analyticsService.logout();
      expect(analyticsService.recordedEvents.length, equals(1));
      expect(analyticsService.recordedEvents.first.name, equals('user_logout'));
    });

    test('应该能重置会话', () async {
      final oldSessionId = analyticsService.sessionId;
      await Future.delayed(Duration(milliseconds: 10));
      analyticsService.resetSession();
      final newSessionId = analyticsService.sessionId;

      // 会话ID应该被更新（时间戳不同）
      expect(newSessionId, isNotEmpty);
    });

    test('应该能追踪特定事件类型', () async {
      await analyticsService.track(
        AnalyticsEventType.bubbleTapped,
        properties: {'bubble_id': 'bubble_001'},
      );
      expect(analyticsService.recordedEvents.length, equals(1));
      expect(analyticsService.recordedEvents.first.type, equals(AnalyticsEventType.bubbleTapped));
    });

    test('应该能追踪页面视图', () async {
      analyticsService.trackPageEnter('detail_page');
      await analyticsService.trackPageView('detail_page');
      expect(analyticsService.currentPage, equals('detail_page'));
      expect(analyticsService.recordedEvents.length, equals(1));
    });

    test('应该记录多个事件', () async {
      await analyticsService.trackEvent('event1');
      await analyticsService.trackEvent('event2');
      await analyticsService.trackEvent('event3');
      expect(analyticsService.recordedEvents.length, equals(3));
    });

    test('应该能刷新事件队列', () async {
      await analyticsService.trackEvent('event1');
      await analyticsService.trackEvent('event2');
      await analyticsService.flush();
      expect(analyticsService.recordedEvents.length, equals(2));
    });

    test('应该能清空事件', () async {
      await analyticsService.trackEvent('event1');
      expect(analyticsService.recordedEvents.length, equals(1));

      analyticsService.clear();
      expect(analyticsService.recordedEvents.length, equals(0));
    });
  });

  group('AnalyticsEvent', () {
    test('应该能创建AnalyticsEvent', () {
      final event = AnalyticsEvent(
        name: 'test_event',
        type: AnalyticsEventType.appLaunch,
        properties: {'key': 'value'},
        userId: 'user123',
        sessionId: 'session123',
        pageName: 'home',
      );

      expect(event.name, equals('test_event'));
      expect(event.type, equals(AnalyticsEventType.appLaunch));
      expect(event.userId, equals('user123'));
      expect(event.sessionId, equals('session123'));
      expect(event.pageName, equals('home'));
    });

    test('应该能转换为Map', () {
      final event = AnalyticsEvent(
        name: 'test_event',
        type: AnalyticsEventType.bubbleTapped,
        properties: {'bubble_id': '001'},
      );

      final map = event.toMap();
      expect(map['name'], equals('test_event'));
      expect(map['type'], equals('bubbleTapped'));
      expect(map['properties']['bubble_id'], equals('001'));
    });

    test('应该能从Map创建', () {
      final map = {
        'name': 'test_event',
        'type': 'bubbleTapped',
        'properties': {'key': 'value'},
        'user_id': 'user123',
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': 'session123',
        'page_name': 'home',
      };

      final event = AnalyticsEvent.fromMap(map);
      expect(event.name, equals('test_event'));
      expect(event.type, equals(AnalyticsEventType.bubbleTapped));
      expect(event.userId, equals('user123'));
    });

    test('应该为timestamp使用当前时间（如果未提供）', () {
      final before = DateTime.now();
      final event = AnalyticsEvent(
        name: 'test',
        type: AnalyticsEventType.appLaunch,
      );
      final after = DateTime.now();

      expect(event.timestamp.isAfter(before) || event.timestamp.isAtSameMomentAs(before), true);
      expect(event.timestamp.isBefore(after) || event.timestamp.isAtSameMomentAs(after), true);
    });
  });

  group('AnalyticsEventType', () {
    test('应该包含所有必要的事件类型', () {
      expect(AnalyticsEventType.values.length, greaterThan(20));
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.appLaunch));
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.bubbleTapped));
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.orderSubmitted));
    });
  });

  group('AnalyticsMode', () {
    test('应该包含所有支持的模式', () {
      expect(AnalyticsMode.values.length, equals(4));
      expect(AnalyticsMode.values, contains(AnalyticsMode.local));
      expect(AnalyticsMode.values, contains(AnalyticsMode.firebase));
      expect(AnalyticsMode.values, contains(AnalyticsMode.sentry));
      expect(AnalyticsMode.values, contains(AnalyticsMode.customServer));
    });
  });
}
