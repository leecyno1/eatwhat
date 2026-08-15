import 'package:eatwhat_app/core/models/analytics_event.dart';
import 'analytics_service.dart';

/// 埋点助手 - 提供便捷的事件追踪接口
/// 封装 AnalyticsService，提供类型安全的事件追踪方法
class AnalyticsHelper {
  static AnalyticsService? _mockAnalytics;
  static final AnalyticsService _defaultAnalytics = AnalyticsService();

  /// 获取当前使用的分析服务
  static AnalyticsService get _analytics => _mockAnalytics ?? _defaultAnalytics;

  /// 注入模拟的分析服务（用于测试）
  static void setMockAnalytics(AnalyticsService? mock) {
    _mockAnalytics = mock;
  }

  /// 重置为默认服务（用于测试清理）
  static void resetAnalytics() {
    _mockAnalytics = null;
  }

  // ========== 应用生命周期事件 ==========

  /// 追踪应用启动
  static Future<void> trackAppLaunch() async {
    await _analytics.track(
      AnalyticsEventType.appLaunch,
      properties: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪应用进入后台
  static Future<void> trackAppBackground() async {
    await _analytics.track(
      AnalyticsEventType.appBackground,
      properties: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪应用进入前台
  static Future<void> trackAppForeground() async {
    await _analytics.track(
      AnalyticsEventType.appForeground,
      properties: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ========== 气泡交互事件 ==========

  /// 追踪气泡被浏览
  static Future<void> trackBubbleViewed({
    String? bubbleId,
    String? foodId,
  }) async {
    await _analytics.track(
      AnalyticsEventType.bubbleViewed,
      properties: {
        if (bubbleId != null) 'bubble_id': bubbleId,
        if (foodId != null) 'food_id': foodId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪气泡被点击
  static Future<void> trackBubbleTapped({
    String? bubbleId,
    String? foodId,
  }) async {
    await _analytics.track(
      AnalyticsEventType.bubbleTapped,
      properties: {
        if (bubbleId != null) 'bubble_id': bubbleId,
        if (foodId != null) 'food_id': foodId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪气泡被长按
  static Future<void> trackBubbleLongPressed({
    String? bubbleId,
    String? foodId,
  }) async {
    await _analytics.track(
      AnalyticsEventType.bubbleLongPressed,
      properties: {
        if (bubbleId != null) 'bubble_id': bubbleId,
        if (foodId != null) 'food_id': foodId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪气泡上滑（喜欢）
  static Future<void> trackBubbleSwipedUp({
    String? bubbleId,
    String? foodId,
  }) async {
    await _analytics.track(
      AnalyticsEventType.bubbleSwipedUp,
      properties: {
        if (bubbleId != null) 'bubble_id': bubbleId,
        if (foodId != null) 'food_id': foodId,
        'action': 'like',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪气泡下滑（不喜欢）
  static Future<void> trackBubbleSwipedDown({
    String? bubbleId,
    String? foodId,
  }) async {
    await _analytics.track(
      AnalyticsEventType.bubbleSwipedDown,
      properties: {
        if (bubbleId != null) 'bubble_id': bubbleId,
        if (foodId != null) 'food_id': foodId,
        'action': 'dislike',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪气泡左滑
  static Future<void> trackBubbleSwipedLeft({
    String? bubbleId,
    String? foodId,
  }) async {
    await _analytics.track(
      AnalyticsEventType.bubbleSwipedLeft,
      properties: {
        if (bubbleId != null) 'bubble_id': bubbleId,
        if (foodId != null) 'food_id': foodId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪气泡右滑
  static Future<void> trackBubbleSwipedRight({
    String? bubbleId,
    String? foodId,
  }) async {
    await _analytics.track(
      AnalyticsEventType.bubbleSwipedRight,
      properties: {
        if (bubbleId != null) 'bubble_id': bubbleId,
        if (foodId != null) 'food_id': foodId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ========== 推荐相关事件 ==========

  /// 追踪推荐结果展示
  static Future<void> trackRecommendationShown({
    String? recommendationId,
    List<String>? foodIds,
    String? algorithm,
  }) async {
    await _analytics.track(
      AnalyticsEventType.recommendationShown,
      properties: {
        if (recommendationId != null) 'recommendation_id': recommendationId,
        if (foodIds != null) 'food_count': foodIds.length,
        if (algorithm != null) 'algorithm': algorithm,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪推荐结果被点击
  static Future<void> trackRecommendationClicked({
    String? recommendationId,
    String? foodId,
    int? position,
  }) async {
    await _analytics.track(
      AnalyticsEventType.recommendationClicked,
      properties: {
        if (recommendationId != null) 'recommendation_id': recommendationId,
        if (foodId != null) 'food_id': foodId,
        if (position != null) 'position': position,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪口味反馈
  static Future<void> trackTasteFeedback({
    String? foodId,
    int? rating,
    String? feedback,
  }) async {
    await _analytics.track(
      AnalyticsEventType.tasteFeedbackGiven,
      properties: {
        if (foodId != null) 'food_id': foodId,
        if (rating != null) 'rating': rating,
        if (feedback != null) 'feedback': feedback,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ========== 食物详情事件 ==========

  /// 追踪食物详情页浏览
  static Future<void> trackFoodDetailViewed({
    String? foodId,
    String? source,
  }) async {
    await _analytics.track(
      AnalyticsEventType.foodDetailViewed,
      properties: {
        if (foodId != null) 'food_id': foodId,
        if (source != null) 'source': source,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪食物收藏/取消收藏
  static Future<void> trackFoodFavoriteToggled({
    String? foodId,
    bool? isFavorited,
  }) async {
    await _analytics.track(
      AnalyticsEventType.foodFavoriteToggled,
      properties: {
        if (foodId != null) 'food_id': foodId,
        if (isFavorited != null) 'is_favorited': isFavorited,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ========== 购物车事件 ==========

  /// 追踪加入购物车
  static Future<void> trackAddToCart({
    String? foodId,
    int? quantity,
    double? price,
  }) async {
    await _analytics.track(
      AnalyticsEventType.addToCart,
      properties: {
        if (foodId != null) 'food_id': foodId,
        if (quantity != null) 'quantity': quantity,
        if (price != null) 'price': price,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪从购物车移除
  static Future<void> trackRemoveFromCart({
    String? foodId,
    int? quantity,
  }) async {
    await _analytics.track(
      AnalyticsEventType.removeFromCart,
      properties: {
        if (foodId != null) 'food_id': foodId,
        if (quantity != null) 'quantity': quantity,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪查看购物车
  static Future<void> trackCartViewed({
    int? itemCount,
    double? totalPrice,
  }) async {
    await _analytics.track(
      AnalyticsEventType.cartViewed,
      properties: {
        if (itemCount != null) 'item_count': itemCount,
        if (totalPrice != null) 'total_price': totalPrice,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪开始结算
  static Future<void> trackCheckoutStarted({
    int? itemCount,
    double? totalPrice,
  }) async {
    await _analytics.track(
      AnalyticsEventType.checkoutStarted,
      properties: {
        if (itemCount != null) 'item_count': itemCount,
        if (totalPrice != null) 'total_price': totalPrice,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ========== 订单事件 ==========

  /// 追踪订单提交
  static Future<void> trackOrderSubmitted({
    String? orderId,
    double? totalPrice,
    String? platform,
  }) async {
    await _analytics.track(
      AnalyticsEventType.orderSubmitted,
      properties: {
        if (orderId != null) 'order_id': orderId,
        if (totalPrice != null) 'total_price': totalPrice,
        if (platform != null) 'platform': platform,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪支付成功
  static Future<void> trackPaymentSuccess({
    String? orderId,
    double? amount,
    String? paymentMethod,
  }) async {
    await _analytics.track(
      AnalyticsEventType.paymentSuccess,
      properties: {
        if (orderId != null) 'order_id': orderId,
        if (amount != null) 'amount': amount,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪支付失败
  static Future<void> trackPaymentFailed({
    String? orderId,
    String? reason,
  }) async {
    await _analytics.track(
      AnalyticsEventType.paymentFailed,
      properties: {
        if (orderId != null) 'order_id': orderId,
        if (reason != null) 'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ========== A/B 测试事件 ==========

  /// 追踪实验曝光
  static Future<void> trackExperimentViewed({
    String? experimentId,
    String? variant,
  }) async {
    await _analytics.track(
      AnalyticsEventType.experimentViewed,
      properties: {
        if (experimentId != null) 'experiment_id': experimentId,
        if (variant != null) 'variant': variant,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪实验转化
  static Future<void> trackExperimentConverted({
    String? experimentId,
    String? variant,
  }) async {
    await _analytics.track(
      AnalyticsEventType.experimentConverted,
      properties: {
        if (experimentId != null) 'experiment_id': experimentId,
        if (variant != null) 'variant': variant,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ========== 搜索事件 ==========

  /// 追踪搜索操作
  static Future<void> trackSearchPerformed({
    String? query,
    int? resultCount,
  }) async {
    await _analytics.track(
      AnalyticsEventType.searchPerformed,
      properties: {
        if (query != null) 'query': query,
        if (resultCount != null) 'result_count': resultCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪搜索结果点击
  static Future<void> trackSearchResultClicked({
    String? query,
    String? foodId,
    int? position,
  }) async {
    await _analytics.track(
      AnalyticsEventType.searchResultClicked,
      properties: {
        if (query != null) 'query': query,
        if (foodId != null) 'food_id': foodId,
        if (position != null) 'position': position,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ========== 用户事件 ==========

  /// 追踪用户登录
  static Future<void> trackUserLogin({
    String? userId,
    String? method,
  }) async {
    await _analytics.track(
      AnalyticsEventType.userLogin,
      properties: {
        if (userId != null) 'user_id': userId,
        if (method != null) 'method': method,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪用户注册
  static Future<void> trackUserRegister({
    String? userId,
    String? method,
  }) async {
    await _analytics.track(
      AnalyticsEventType.userRegister,
      properties: {
        if (userId != null) 'user_id': userId,
        if (method != null) 'method': method,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 追踪用户登出
  static Future<void> trackUserLogout() async {
    await _analytics.logout();
  }

  // ========== 错误事件 ==========

  /// 追踪错误发生
  static Future<void> trackErrorOccurred({
    String? errorType,
    String? errorMessage,
    String? stackTrace,
  }) async {
    await _analytics.track(
      AnalyticsEventType.errorOccurred,
      properties: {
        if (errorType != null) 'error_type': errorType,
        if (errorMessage != null) 'error_message': errorMessage,
        if (stackTrace != null) 'stack_trace': stackTrace,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ========== 页面相关事件 ==========

  /// 进入页面
  static void enterPage(String pageName) {
    _analytics.trackPageEnter(pageName);
  }

  /// 离开页面
  static void exitPage(String pageName) {
    _analytics.trackPageExit(pageName);
  }

  /// 获取当前页面
  static String? getCurrentPage() {
    return _analytics.currentPage;
  }

  /// 设置用户ID
  static void setUserId(String userId) {
    _analytics.setUserId(userId);
  }

  /// 设置用户属性
  static Future<void> setUserProperty(String name, dynamic value) async {
    await _analytics.setUserProperty(name, value);
  }

  /// 识别用户
  static Future<void> identify(String userId, {Map<String, dynamic>? traits}) async {
    await _analytics.identify(userId, traits: traits);
  }
}
