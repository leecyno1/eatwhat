import 'package:flutter_test/flutter_test.dart';
import 'package:eatwhat_app/core/services/analytics_helper.dart';
import 'mock_analytics_service.dart';

void main() {
  late MockAnalyticsService mockAnalytics;

  setUp(() {
    mockAnalytics = MockAnalyticsService();
    AnalyticsHelper.setMockAnalytics(mockAnalytics);
  });

  tearDown(() {
    AnalyticsHelper.resetAnalytics();
  });

  group('AnalyticsHelper - 应用生命周期', () {
    test('应该能追踪应用启动', () async {
      await AnalyticsHelper.trackAppLaunch();
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.name, equals('appLaunch'));
    });

    test('应该能追踪应用后台', () async {
      await AnalyticsHelper.trackAppBackground();
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.name, equals('appBackground'));
    });

    test('应该能追踪应用前台', () async {
      await AnalyticsHelper.trackAppForeground();
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.name, equals('appForeground'));
    });
  });

  group('AnalyticsHelper - 气泡交互', () {
    test('应该能追踪气泡被浏览', () async {
      await AnalyticsHelper.trackBubbleViewed(
        bubbleId: 'bubble_001',
        foodId: 'food_001',
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['bubble_id'], equals('bubble_001'));
    });

    test('应该能追踪气泡被点击', () async {
      await AnalyticsHelper.trackBubbleTapped(
        bubbleId: 'bubble_001',
        foodId: 'food_001',
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.type.name, equals('bubbleTapped'));
    });

    test('应该能追踪气泡被长按', () async {
      await AnalyticsHelper.trackBubbleLongPressed(
        bubbleId: 'bubble_001',
        foodId: 'food_001',
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
    });

    test('应该能追踪气泡上滑（喜欢）', () async {
      await AnalyticsHelper.trackBubbleSwipedUp(
        bubbleId: 'bubble_001',
        foodId: 'food_001',
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['action'], equals('like'));
    });

    test('应该能追踪气泡下滑（不喜欢）', () async {
      await AnalyticsHelper.trackBubbleSwipedDown(
        bubbleId: 'bubble_001',
        foodId: 'food_001',
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['action'], equals('dislike'));
    });

    test('应该能追踪气泡左滑', () async {
      await AnalyticsHelper.trackBubbleSwipedLeft(
        bubbleId: 'bubble_001',
        foodId: 'food_001',
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
    });

    test('应该能追踪气泡右滑', () async {
      await AnalyticsHelper.trackBubbleSwipedRight(
        bubbleId: 'bubble_001',
        foodId: 'food_001',
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
    });
  });

  group('AnalyticsHelper - 推荐相关', () {
    test('应该能追踪推荐结果展示', () async {
      await AnalyticsHelper.trackRecommendationShown(
        recommendationId: 'rec_001',
        foodIds: ['food_001', 'food_002'],
        algorithm: 'vectorized',
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['food_count'], equals(2));
    });

    test('应该能追踪推荐结果点击', () async {
      await AnalyticsHelper.trackRecommendationClicked(
        recommendationId: 'rec_001',
        foodId: 'food_001',
        position: 0,
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['position'], equals(0));
    });

    test('应该能追踪口味反馈', () async {
      await AnalyticsHelper.trackTasteFeedback(
        foodId: 'food_001',
        rating: 5,
        feedback: '很喜欢',
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['rating'], equals(5));
    });
  });

  group('AnalyticsHelper - 食物详情', () {
    test('应该能追踪食物详情页浏览', () async {
      await AnalyticsHelper.trackFoodDetailViewed(
        foodId: 'food_001',
        source: 'recommendation',
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['source'], equals('recommendation'));
    });

    test('应该能追踪食物收藏', () async {
      await AnalyticsHelper.trackFoodFavoriteToggled(
        foodId: 'food_001',
        isFavorited: true,
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['is_favorited'], equals(true));
    });

    test('应该能追踪食物取消收藏', () async {
      await AnalyticsHelper.trackFoodFavoriteToggled(
        foodId: 'food_001',
        isFavorited: false,
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['is_favorited'], equals(false));
    });
  });

  group('AnalyticsHelper - 购物车', () {
    test('应该能追踪加入购物车', () async {
      await AnalyticsHelper.trackAddToCart(
        foodId: 'food_001',
        quantity: 2,
        price: 29.99,
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['quantity'], equals(2));
    });

    test('应该能追踪从购物车移除', () async {
      await AnalyticsHelper.trackRemoveFromCart(
        foodId: 'food_001',
        quantity: 1,
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
    });

    test('应该能追踪查看购物车', () async {
      await AnalyticsHelper.trackCartViewed(
        itemCount: 3,
        totalPrice: 89.97,
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['item_count'], equals(3));
    });

    test('应该能追踪开始结算', () async {
      await AnalyticsHelper.trackCheckoutStarted(
        itemCount: 3,
        totalPrice: 89.97,
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
    });
  });

  group('AnalyticsHelper - 订单', () {
    test('应该能追踪订单提交', () async {
      await AnalyticsHelper.trackOrderSubmitted(
        orderId: 'order_001',
        totalPrice: 89.97,
        platform: 'meituan',
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['platform'], equals('meituan'));
    });

    test('应该能追踪支付成功', () async {
      await AnalyticsHelper.trackPaymentSuccess(
        orderId: 'order_001',
        amount: 89.97,
        paymentMethod: 'wechat',
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['payment_method'], equals('wechat'));
    });

    test('应该能追踪支付失败', () async {
      await AnalyticsHelper.trackPaymentFailed(
        orderId: 'order_001',
        reason: 'insufficient_balance',
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['reason'], equals('insufficient_balance'));
    });
  });

  group('AnalyticsHelper - A/B测试', () {
    test('应该能追踪实验曝光', () async {
      await AnalyticsHelper.trackExperimentViewed(
        experimentId: 'exp_001',
        variant: 'variant_a',
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['variant'], equals('variant_a'));
    });

    test('应该能追踪实验转化', () async {
      await AnalyticsHelper.trackExperimentConverted(
        experimentId: 'exp_001',
        variant: 'variant_a',
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
    });
  });

  group('AnalyticsHelper - 搜索', () {
    test('应该能追踪搜索操作', () async {
      await AnalyticsHelper.trackSearchPerformed(
        query: '番茄鸡蛋面',
        resultCount: 5,
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['query'], equals('番茄鸡蛋面'));
    });

    test('应该能追踪搜索结果点击', () async {
      await AnalyticsHelper.trackSearchResultClicked(
        query: '番茄鸡蛋面',
        foodId: 'food_001',
        position: 0,
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
    });
  });

  group('AnalyticsHelper - 用户', () {
    test('应该能追踪用户登录', () async {
      await AnalyticsHelper.trackUserLogin(
        userId: 'user_001',
        method: 'wechat',
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['method'], equals('wechat'));
    });

    test('应该能追踪用户注册', () async {
      await AnalyticsHelper.trackUserRegister(
        userId: 'user_001',
        method: 'phone',
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
    });

    test('应该能追踪用户登出', () async {
      mockAnalytics.setUserId('user_123');
      await AnalyticsHelper.trackUserLogout();
      expect(mockAnalytics.recordedEvents.length, equals(1));
    });
  });

  group('AnalyticsHelper - 错误', () {
    test('应该能追踪错误发生', () async {
      await AnalyticsHelper.trackErrorOccurred(
        errorType: 'NetworkException',
        errorMessage: 'Connection timeout',
        stackTrace: 'stack_trace_here',
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['error_type'], equals('NetworkException'));
    });
  });

  group('AnalyticsHelper - 页面管理', () {
    test('应该能进入页面', () {
      AnalyticsHelper.enterPage('home_page');
      expect(AnalyticsHelper.getCurrentPage(), equals('home_page'));
    });

    test('应该能离开页面', () {
      AnalyticsHelper.enterPage('detail_page');
      AnalyticsHelper.exitPage('detail_page');
      expect(AnalyticsHelper.getCurrentPage(), isNull);
    });

    test('应该能获取当前页面', () {
      AnalyticsHelper.enterPage('search_page');
      expect(AnalyticsHelper.getCurrentPage(), equals('search_page'));
    });

    test('应该能追踪页面堆栈', () {
      AnalyticsHelper.enterPage('page1');
      AnalyticsHelper.enterPage('page2');
      expect(AnalyticsHelper.getCurrentPage(), equals('page2'));

      AnalyticsHelper.exitPage('page2');
      expect(AnalyticsHelper.getCurrentPage(), equals('page1'));
    });
  });

  group('AnalyticsHelper - 用户属性', () {
    test('应该能设置用户ID', () {
      AnalyticsHelper.setUserId('user_123');
      // 用户ID应该被设置
    });

    test('应该能设置用户属性', () async {
      await AnalyticsHelper.setUserProperty('dark_mode', true);
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['property_name'], equals('dark_mode'));
    });

    test('应该能识别用户', () async {
      await AnalyticsHelper.identify(
        'user_456',
        traits: {'plan': 'premium', 'language': 'zh'},
      );
      expect(mockAnalytics.recordedEvents.length, equals(1));
      expect(mockAnalytics.recordedEvents.first.properties?['plan'], equals('premium'));
    });
  });
}
