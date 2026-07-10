/// 埋点事件类型枚举
/// 用于定义应用中所有可追踪的事件
enum AnalyticsEventType {
  // ========== 应用生命周期 ==========
  /// 应用启动
  appLaunch,
  /// 应用进入后台
  appBackground,
  /// 应用进入前台
  appForeground,

  // ========== 气泡交互 ==========
  /// 气泡被浏览
  bubbleViewed,
  /// 气泡被点击
  bubbleTapped,
  /// 气泡被长按
  bubbleLongPressed,
  /// 气泡上滑（喜欢）
  bubbleSwipedUp,
  /// 气泡下滑（不喜欢）
  bubbleSwipedDown,
  /// 气泡左滑
  bubbleSwipedLeft,
  /// 气泡右滑
  bubbleSwipedRight,

  // ========== 推荐相关 ==========
  /// 推荐结果展示
  recommendationShown,
  /// 推荐结果被点击
  recommendationClicked,
  /// 口味反馈
  tasteFeedbackGiven,

  // ========== 食物详情 ==========
  /// 食物详情页浏览
  foodDetailViewed,
  /// 食物收藏/取消收藏
  foodFavoriteToggled,

  // ========== 购物车 ==========
  /// 加入购物车
  addToCart,
  /// 从购物车移除
  removeFromCart,
  /// 查看购物车
  cartViewed,
  /// 开始结算
  checkoutStarted,

  // ========== 订单 ==========
  /// 订单提交
  orderSubmitted,
  /// 支付成功
  paymentSuccess,
  /// 支付失败
  paymentFailed,

  // ========== A/B 测试 ==========
  /// 实验曝光
  experimentViewed,
  /// 实验转化
  experimentConverted,

  // ========== 搜索 ==========
  /// 搜索操作
  searchPerformed,
  /// 搜索结果点击
  searchResultClicked,

  // ========== 用户 ==========
  /// 用户登录
  userLogin,
  /// 用户注册
  userRegister,
  /// 用户登出
  userLogout,

  // ========== 错误 ==========
  /// 错误发生
  errorOccurred,
}

/// 埋点模式枚举
enum AnalyticsMode {
  /// 本地日志模式（开发调试用）
  local,
  /// Firebase Analytics
  firebase,
  /// Sentry
  sentry,
  /// 自建服务器
  customServer,
}

/// 埋点事件数据类
class AnalyticsEvent {
  /// 事件名称
  final String name;

  /// 事件类型
  final AnalyticsEventType type;

  /// 事件属性
  final Map<String, dynamic>? properties;

  /// 用户ID
  final String? userId;

  /// 时间戳
  final DateTime timestamp;

  /// 会话ID
  final String? sessionId;

  /// 页面名称
  final String? pageName;

  AnalyticsEvent({
    required this.name,
    required this.type,
    this.properties,
    this.userId,
    DateTime? timestamp,
    this.sessionId,
    this.pageName,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.name,
      'properties': properties ?? {},
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'session_id': sessionId,
      'page_name': pageName,
    };
  }

  /// 从 Map 创建
  factory AnalyticsEvent.fromMap(Map<String, dynamic> map) {
    return AnalyticsEvent(
      name: map['name'] as String,
      type: AnalyticsEventType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AnalyticsEventType.appLaunch,
      ),
      properties: Map<String, dynamic>.from(map['properties'] ?? {}),
      userId: map['user_id'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      sessionId: map['session_id'] as String?,
      pageName: map['page_name'] as String?,
    );
  }
}
