import 'package:flutter/material.dart';
import '../../../core/models/bubble.dart';
import '../../../core/models/food.dart';
import '../../../core/models/user_preference.dart';
import '../../../core/services/recommendation_engine.dart';
import 'package:url_launcher/url_launcher.dart';

/// 推荐控制器
class RecommendationController extends ChangeNotifier {
  List<Food> _recommendations = [];
  bool _isLoading = false;
  String? _errorMessage;
  UserPreference? _userPreference;

  /// 获取推荐列表
  List<Food> get recommendations => _recommendations;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 错误信息
  String? get errorMessage => _errorMessage;

  /// 用户偏好
  UserPreference? get userPreference => _userPreference;

  /// 生成推荐
  Future<void> generateRecommendations(List<Bubble> selectedBubbles) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // 模拟网络延迟
      await Future.delayed(const Duration(milliseconds: 800));

      // 使用推荐引擎生成推荐
      _recommendations = RecommendationEngine.generateRecommendations(selectedBubbles);

      // 如果有用户偏好，调整推荐分数
      if (_userPreference != null) {
        _adjustRecommendationsWithPreferences();
      }

    } catch (e) {
      _errorMessage = '生成推荐失败: $e';
      debugPrint('推荐生成错误: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 根据用户偏好调整推荐分数
  void _adjustRecommendationsWithPreferences() {
    if (_userPreference == null) return;

    for (int i = 0; i < _recommendations.length; i++) {
      final food = _recommendations[i];
      double adjustedRating = food.rating;

      // 检查食物是否在用户的喜欢/不喜欢列表中
      if (_userPreference!.favoriteFood.contains(food.id)) {
        adjustedRating += 1.0;
      } else if (_userPreference!.dislikedFood.contains(food.id)) {
        adjustedRating -= 2.0;
      }

      // 根据食物属性与用户气泡偏好的匹配度调整
      final bubbleNames = [
        ...food.tasteAttributes,
        food.cuisineType,
        ...food.ingredients,
        ...food.scenarios ?? [],
      ];
      
      final bonus = _userPreference!.getRecommendationBonus(bubbleNames);
      adjustedRating += bonus * 2.0;

      // 确保评分在合理范围内
      adjustedRating = adjustedRating.clamp(0.0, 5.0);

      _recommendations[i] = food.copyWith(rating: adjustedRating);
    }

    // 重新排序
    _recommendations.sort((a, b) => b.rating.compareTo(a.rating));
  }

  /// 更新用户偏好
  void updateUserPreference(UserPreference preference) {
    _userPreference = preference;
    notifyListeners();
  }

  /// 标记食物为喜欢/不喜欢
  void updateFoodPreference(String foodId, bool isLiked) {
    if (_userPreference != null) {
      _userPreference = _userPreference!.updateFoodPreference(foodId, isLiked);
      
      // 重新调整推荐分数
      _adjustRecommendationsWithPreferences();
      notifyListeners();
    }
  }

  /// 重新生成推荐
  Future<void> refreshRecommendations(List<Bubble> selectedBubbles) async {
    await generateRecommendations(selectedBubbles);
  }

  /// 清空推荐
  void clearRecommendations() {
    _recommendations.clear();
    _errorMessage = null;
    notifyListeners();
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 获取推荐统计信息
  Map<String, dynamic> getRecommendationStats() {
    if (_recommendations.isEmpty) {
      return {
        'total': 0,
        'averageRating': 0.0,
        'topCuisine': '无',
        'averageCalories': 0,
      };
    }

    final total = _recommendations.length;
    final averageRating = _recommendations
        .map((f) => f.rating)
        .reduce((a, b) => a + b) / total;

    // 统计最常见的菜系
    final cuisineCount = <String, int>{};
    for (final food in _recommendations) {
      cuisineCount[food.cuisineType] = (cuisineCount[food.cuisineType] ?? 0) + 1;
    }
    final topCuisine = cuisineCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // 计算平均卡路里
    final validCalories = _recommendations
        .where((f) => f.calories != null)
        .map((f) => f.calories!)
        .toList();
    final averageCalories = validCalories.isNotEmpty
        ? validCalories.reduce((a, b) => a + b) / validCalories.length
        : 0;

    return {
      'total': total,
      'averageRating': averageRating,
      'topCuisine': topCuisine,
      'averageCalories': averageCalories.round(),
    };
  }

  // --- 新增方法用于处理按钮点击 ---

  /// 打开菜谱链接
  Future<void> openRecipe(String foodName) async {
    // TODO: 替换为真实的菜谱库链接，并根据foodName构建搜索URL
    final Uri recipeUri = Uri.parse('https://www.xiachufang.com/search/?keyword=$foodName');
    if (await canLaunchUrl(recipeUri)) {
      await launchUrl(recipeUri, mode: LaunchMode.externalApplication);
    } else {
      _errorMessage = '无法打开菜谱链接';
      notifyListeners();
      debugPrint('无法启动 $recipeUri');
    }
  }

  /// 打开外卖链接 (美团或饿了么)
  Future<void> openFoodDelivery(String foodName, {String platform = 'meituan'}) async {
    Uri? deliveryUri;
    if (platform == 'meituan') {
      deliveryUri = Uri.parse('meituanwaimai://waimai.meituan.com/search?query=$foodName');
      // 备用网页链接，如果App无法启动
      // deliveryUri = Uri.parse('https://waimai.meituan.com/search?query=$foodName');
    } else if (platform == 'eleme') {
      // 饿了么的URL Scheme可能需要通过支付宝启动，或者直接搜索其网页版
      // 尝试直接打开饿了么搜索页 (需要确认准确的Scheme)
      // deliveryUri = Uri.parse('eleme://search?keyword=$foodName'); 
      // 备用网页链接
      deliveryUri = Uri.parse('https://www.ele.me/search/shop?keyword=$foodName');
    }

    if (deliveryUri != null && await canLaunchUrl(deliveryUri)) {
      await launchUrl(deliveryUri, mode: LaunchMode.externalApplication);
    } else {
       // 尝试备用网页链接
      Uri? webFallbackUri;
      if (platform == 'meituan') {
        webFallbackUri = Uri.parse('https://waimai.meituan.com/search/keyword?keyword=$foodName');
      } else if (platform == 'eleme') {
        webFallbackUri = Uri.parse('https://www.ele.me/search/shop?keyword=$foodName');
      }
      if (webFallbackUri != null && await canLaunchUrl(webFallbackUri)) {
        await launchUrl(webFallbackUri, mode: LaunchMode.externalApplication);
      } else {
        _errorMessage = '无法打开外卖应用或网页';
        notifyListeners();
        debugPrint('无法启动外卖链接: $deliveryUri 或 $webFallbackUri');
      }
    }
  }

  /// 打开附近餐厅链接 (大众点评)
  Future<void> openNearbyRestaurants(String foodName) async {
    final Uri restaurantUri = Uri.parse('dianping://searchshoplist?keyword=$foodName');
    // 备用网页链接
    // final Uri restaurantUri = Uri.parse('https://m.dianping.com/search/keyword/1/0_$foodName');

    if (await canLaunchUrl(restaurantUri)) {
      await launchUrl(restaurantUri, mode: LaunchMode.externalApplication);
    } else {
      // 尝试备用网页链接
      final Uri webFallbackUri = Uri.parse('https://m.dianping.com/search/keyword/1/0_$foodName');
      if (await canLaunchUrl(webFallbackUri)) {
        await launchUrl(webFallbackUri, mode: LaunchMode.externalApplication);
      } else {
        _errorMessage = '无法打开大众点评或网页';
        notifyListeners();
        debugPrint('无法启动 $restaurantUri 或 $webFallbackUri');
      }
    }
  }
}