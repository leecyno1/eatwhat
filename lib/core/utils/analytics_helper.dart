import '../services/analytics_service.dart';
import '../models/analytics_event.dart';

/// 埋点辅助类
/// 提供便捷方法包装常用埋点场景，自动补充公共属性
class AnalyticsHelper {
  static final AnalyticsService _analytics = AnalyticsService();

  // ========== 应用生命周期 ==========

  /// 记录 App 启动
  static void logAppLaunch({String? version, String? platform}) {
    _analytics.trackEvent(AnalyticsEventType.appLaunch.name, properties: {
      'version': version,
      'platform': platform,
    });
  }

  /// 记录 App 进入后台
  static void logAppBackground() {
    _analytics.trackEvent(AnalyticsEventType.appBackground.name);
  }

  /// 记录 App 进入前台
  static void logAppForeground() {
    _analytics.trackEvent(AnalyticsEventType.appForeground.name);
  }

  // ========== 气泡交互 ==========

  /// 记录气泡浏览
  static void logBubbleViewed(String bubbleId, String bubbleName, String bubbleType) {
    _analytics.trackEvent(AnalyticsEventType.bubbleViewed.name, properties: {
      'bubble_id': bubbleId,
      'bubble_name': bubbleName,
      'bubble_type': bubbleType,
    });
  }

  /// 记录气泡点击
  static void logBubbleTapped(String bubbleId, String bubbleName) {
    _analytics.trackEvent(AnalyticsEventType.bubbleTapped.name, properties: {
      'bubble_id': bubbleId,
      'bubble_name': bubbleName,
    });
  }

  /// 记录气泡长按
  static void logBubbleLongPressed(String bubbleId, String bubbleName) {
    _analytics.trackEvent(AnalyticsEventType.bubbleLongPressed.name, properties: {
      'bubble_id': bubbleId,
      'bubble_name': bubbleName,
    });
  }

  /// 记录气泡滑动
  static void logBubbleSwiped(String bubbleId, String bubbleName, String direction) {
    final eventType = switch (direction) {
      'up' => AnalyticsEventType.bubbleSwipedUp,
      'down' => AnalyticsEventType.bubbleSwipedDown,
      'left' => AnalyticsEventType.bubbleSwipedLeft,
      'right' => AnalyticsEventType.bubbleSwipedRight,
      _ => AnalyticsEventType.bubbleTapped,
    };

    _analytics.trackEvent(eventType.name, properties: {
      'bubble_id': bubbleId,
      'bubble_name': bubbleName,
      'direction': direction,
    });
  }

  /// 记录气泡喜欢（上滑）
  static void logBubbleLiked(String bubbleId, String bubbleName) {
    logBubbleSwiped(bubbleId, bubbleName, 'up');
  }

  /// 记录气泡不喜欢（下滑）
  static void logBubbleDisliked(String bubbleId, String bubbleName) {
    logBubbleSwiped(bubbleId, bubbleName, 'down');
  }

  // ========== 推荐相关 ==========

  /// 记录推荐结果展示
  static void logRecommendationShown(
    int count, {
    List<String>? foodIds,
    String? source,
  }) {
    _analytics.trackEvent(AnalyticsEventType.recommendationShown.name, properties: {
      'count': count,
      'food_ids': foodIds?.take(5).toList(), // 只记录前5个
      'source': source,
    });
  }

  /// 记录推荐结果点击
  static void logRecommendationClicked(String foodId, String foodName, int position) {
    _analytics.trackEvent(AnalyticsEventType.recommendationClicked.name, properties: {
      'food_id': foodId,
      'food_name': foodName,
      'position': position,
    });
  }

  /// 记录口味反馈
  static void logTasteFeedback(String foodId, bool isLiked) {
    _analytics.trackEvent(AnalyticsEventType.tasteFeedbackGiven.name, properties: {
      'food_id': foodId,
      'is_liked': isLiked,
    });
  }

  // ========== 食物详情 ==========

  /// 记录食物详情浏览
  static void logFoodDetailViewed(String foodId, String foodName) {
    _analytics.trackEvent(AnalyticsEventType.foodDetailViewed.name, properties: {
      'food_id': foodId,
      'food_name': foodName,
    });
  }

  /// 记录食物收藏状态切换
  static void logFoodFavoriteToggled(String foodId, String foodName, bool isFavorite) {
    _analytics.trackEvent(AnalyticsEventType.foodFavoriteToggled.name, properties: {
      'food_id': foodId,
      'food_name': foodName,
      'is_favorite': isFavorite,
    });
  }

  // ========== 购物车 ==========

  /// 记录加入购物车
  static void logAddToCart(String foodId, String foodName, double price, int quantity) {
    _analytics.trackEvent(AnalyticsEventType.addToCart.name, properties: {
      'food_id': foodId,
      'food_name': foodName,
      'price': price,
      'quantity': quantity,
    });
  }

  /// 记录从购物车移除
  static void logRemoveFromCart(String foodId, String foodName) {
    _analytics.trackEvent(AnalyticsEventType.removeFromCart.name, properties: {
      'food_id': foodId,
      'food_name': foodName,
    });
  }

  /// 记录查看购物车
  static void logCartViewed(int itemCount, double totalPrice) {
    _analytics.trackEvent(AnalyticsEventType.cartViewed.name, properties: {
      'item_count': itemCount,
      'total_price': totalPrice,
    });
  }

  /// 记录开始结算
  static void logCheckoutStarted(int itemCount, double totalPrice) {
    _analytics.trackEvent(AnalyticsEventType.checkoutStarted.name, properties: {
      'item_count': itemCount,
      'total_price': totalPrice,
    });
  }

  // ========== 订单 ==========

  /// 记录订单提交
  static void logOrderSubmitted(String orderId, double amount, int itemCount) {
    _analytics.trackEvent(AnalyticsEventType.orderSubmitted.name, properties: {
      'order_id': orderId,
      'amount': amount,
      'item_count': itemCount,
    });
  }

  /// 记录支付成功
  static void logPaymentSuccess(String orderId, double amount) {
    _analytics.trackEvent(AnalyticsEventType.paymentSuccess.name, properties: {
      'order_id': orderId,
      'amount': amount,
    });
  }

  /// 记录支付失败
  static void logPaymentFailed(String orderId, String reason) {
    _analytics.trackEvent(AnalyticsEventType.paymentFailed.name, properties: {
      'order_id': orderId,
      'reason': reason,
    });
  }

  // ========== 搜索 ==========

  /// 记录搜索
  static void logSearch(String keyword, int resultCount) {
    _analytics.trackEvent(AnalyticsEventType.searchPerformed.name, properties: {
      'keyword': keyword,
      'result_count': resultCount,
    });
  }

  /// 记录搜索结果点击
  static void logSearchResultClicked(String foodId, String foodName, int position) {
    _analytics.trackEvent(AnalyticsEventType.searchResultClicked.name, properties: {
      'food_id': foodId,
      'food_name': foodName,
      'position': position,
    });
  }

  // ========== 用户 ==========

  /// 记录用户登录
  static void logUserLogin(String userId, String method) {
    _analytics.trackEvent(AnalyticsEventType.userLogin.name, properties: {
      'user_id': userId,
      'method': method,
    });
  }

  /// 记录用户注册
  static void logUserRegister(String userId, String method) {
    _analytics.trackEvent(AnalyticsEventType.userRegister.name, properties: {
      'user_id': userId,
      'method': method,
    });
  }

  /// 记录用户登出
  static void logUserLogout() {
    _analytics.logout();
  }

  // ========== A/B 测试 ==========

  /// 记录实验曝光
  static void logExperimentViewed(String experimentId, String variantId) {
    _analytics.trackEvent(AnalyticsEventType.experimentViewed.name, properties: {
      'experiment_id': experimentId,
      'variant_id': variantId,
    });
  }

  /// 记录实验转化
  static void logExperimentConverted(String experimentId, String variantId, String goalId) {
    _analytics.trackEvent(AnalyticsEventType.experimentConverted.name, properties: {
      'experiment_id': experimentId,
      'variant_id': variantId,
      'goal_id': goalId,
    });
  }

  // ========== 错误 ==========

  /// 记录错误
  static void logError(String errorType, String message, {String? stackTrace}) {
    _analytics.trackEvent(AnalyticsEventType.errorOccurred.name, properties: {
      'error_type': errorType,
      'message': message,
      'stack_trace': stackTrace,
    });
  }

  // ========== 页面追踪 ==========

  /// 记录页面进入
  static void logPageEnter(String pageName) {
    _analytics.trackPageEnter(pageName);
  }

  /// 记录页面离开
  static void logPageExit(String pageName) {
    _analytics.trackPageExit(pageName);
  }
}
