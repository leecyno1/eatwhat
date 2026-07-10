/// 应用程序常量定义
class AppConstants {
  // 应用信息
  static const String appName = '吃什么';
  static const String appVersion = '1.0.0';

  // 动画时长
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);

  // 气泡相关常量
  static const double minBubbleSize = 60.0;
  static const double maxBubbleSize = 120.0;
  static const double defaultBubbleSize = 80.0;
  static const double bubbleAnimationDuration = 300.0;
  static const double bubblePhysicsRestitution = 0.8;
  static const double bubblePhysicsFriction = 0.95;

  // UI间距
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // 圆角大小
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // 阴影相关
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // 推荐相关
  static const int maxRecommendations = 10;
  static const int maxHistory = 100;
  static const double minMatchScore = 0.3;

  // 网络相关
  static const int networkTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

  // 存储键名
  static const String userPreferencesKey = 'user_preferences';
  static const String historyKey = 'user_history';
  static const String favoritesKey = 'user_favorites';
  static const String settingsKey = 'app_settings';

  // 错误消息
  static const String networkError = '网络连接失败，请检查网络设置';
  static const String unknownError = '发生未知错误，请稍后重试';
  static const String noDataError = '暂无数据';
  static const String loadingError = '加载失败，请重试';

  // 成功消息
  static const String saveSuccess = '保存成功';
  static const String deleteSuccess = '删除成功';
  static const String updateSuccess = '更新成功';

  // 按钮文本
  static const String confirmText = '确认';
  static const String cancelText = '取消';
  static const String retryText = '重试';
  static const String okText = '好的';
  static const String refreshText = '刷新';
}

/// 食物分类常量
class FoodCategoryConstants {
  static const String chinese = '中餐';
  static const String western = '西餐';
  static const String japanese = '日料';
  static const String korean = '韩餐';
  static const String fastFood = '快餐';
  static const String dessert = '甜品';
  static const String drinks = '饮品';
  static const String breakfast = '早餐';
  static const String lunch = '午餐';
  static const String dinner = '晚餐';
  static const String snack = '小食';
}

/// 用户偏好标签常量
class PreferenceTagConstants {
  static const String spicy = '辣';
  static const String sweet = '甜';
  static const String sour = '酸';
  static const String salty = '咸';
  static const String light = '清淡';
  static const String heavy = '重口味';
  static const String vegetarian = '素食';
  static const String meat = '肉食';
  static const String seafood = '海鲜';
  static const String healthy = '健康';
  static const String comfort = '治愈';
}

/// 价格区间常量
class PriceRangeConstants {
  static const String budget = '经济实惠';
  static const String moderate = '中等价位';
  static const String expensive = '高端消费';

  static const double budgetMax = 30.0;
  static const double moderateMax = 80.0;
  static const double expensiveMax = 200.0;
}
