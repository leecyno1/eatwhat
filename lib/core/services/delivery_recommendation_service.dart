import 'package:flutter/foundation.dart';
import '../models/restaurant.dart';
import '../models/food_item.dart';
import '../models/user_preference.dart';
import 'delivery_api_service.dart';

/// 外卖推荐服务
class DeliveryRecommendationService {
  static final DeliveryRecommendationService _instance =
      DeliveryRecommendationService._internal();
  factory DeliveryRecommendationService() => _instance;
  DeliveryRecommendationService._internal();

  final DeliveryApiService _apiService = DeliveryApiService();

  /// 获取推荐餐厅
  Future<List<Restaurant>> getRecommendations({
    required UserPreference userPreference,
    required double latitude,
    required double longitude,
    int limit = 20,
  }) async {
    try {
      final searchKeywords = _generateSearchKeywords(userPreference);
      final allRestaurants = <Restaurant>[];

      for (final keyword in searchKeywords) {
        final restaurants = await _apiService.searchRestaurants(
          keyword: keyword,
          latitude: latitude,
          longitude: longitude,
          pageSize: 10,
        );
        allRestaurants.addAll(restaurants);
      }

      // 去重
      final uniqueRestaurants = _removeDuplicates(allRestaurants);

      // 评分排序
      final scoredRestaurants =
          _scoreRestaurants(uniqueRestaurants, userPreference);

      return scoredRestaurants.take(limit).toList();
    } catch (e) {
      debugPrint('获取推荐失败: $e');
      return [];
    }
  }

  /// 生成搜索关键词
  List<String> _generateSearchKeywords(UserPreference userPreference) {
    final keywords = <String>[];

    // 基于菜系偏好生成关键词
    userPreference.cuisinePreferences.forEach((cuisine, score) {
      if (score > 0) {
        keywords.add(cuisine);
      }
    });

    // 基于口味偏好生成关键词
    userPreference.tastePreferences.forEach((taste, score) {
      if (score > 0) {
        keywords.add(taste);
      }
    });

    // 如果没有偏好，使用默认关键词
    if (keywords.isEmpty) {
      keywords.addAll(['川菜', '粤菜', '湘菜', '快餐', '小吃']);
    }

    return keywords.take(5).toList();
  }

  /// 去重餐厅
  List<Restaurant> _removeDuplicates(List<Restaurant> restaurants) {
    final seen = <String>{};
    final unique = <Restaurant>[];

    for (final restaurant in restaurants) {
      if (!seen.contains(restaurant.id)) {
        seen.add(restaurant.id);
        unique.add(restaurant);
      }
    }

    return unique;
  }

  /// 餐厅评分算法
  List<Restaurant> _scoreRestaurants(
      List<Restaurant> restaurants, UserPreference userPreference) {
    final scored = restaurants.map((restaurant) {
      double score = 0.0;

      // 基础评分
      if (restaurant.rating != null) {
        score += restaurant.rating! * 2;
      }

      // 距离评分
      if (restaurant.distance != null) {
        final distanceScore =
            (5000 - restaurant.distance!.clamp(0, 5000)) / 1000;
        score += distanceScore;
      }

      // 配送费评分
      if (restaurant.deliveryFee != null) {
        final feeScore = (10 - restaurant.deliveryFee!.clamp(0, 10)) / 2;
        score += feeScore;
      }

      // 口味匹配评分
      final tasteScore = _calculateTasteMatch(restaurant, userPreference);
      score += tasteScore * 3;

      return MapEntry(restaurant, score);
    }).toList();

    // 按分数排序
    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.map((entry) => entry.key).toList();
  }

  /// 计算口味匹配度
  double _calculateTasteMatch(
      Restaurant restaurant, UserPreference userPreference) {
    double matchScore = 0.0;
    int totalChecks = 0;

    // 检查菜系匹配
    for (final category in restaurant.categories) {
      totalChecks++;
      final cuisineScore = userPreference.cuisinePreferences[category] ?? 0;
      if (cuisineScore > 0) {
        matchScore += cuisineScore.toDouble() / 10;
      }
    }

    // 检查标签匹配
    for (final tag in restaurant.tags) {
      totalChecks++;
      final tasteScore = userPreference.tastePreferences[tag] ?? 0;
      if (tasteScore > 0) {
        matchScore += tasteScore.toDouble() / 20;
      }
    }

    return totalChecks > 0 ? matchScore / totalChecks : 0.0;
  }

  /// 获取推荐菜品
  Future<List<FoodItem>> getRecommendedDishes({
    required String restaurantId,
    required UserPreference userPreference,
    int limit = 10,
  }) async {
    try {
      // 获取餐厅菜单
      final menuItems = await _apiService.getRestaurantMenu(restaurantId);

      if (menuItems.isEmpty) {
        // 如果菜单为空，返回空列表
        return [];
      }

      // 基于用户偏好评分
      final scoredItems = _scoreFoodItems(menuItems, userPreference);

      return scoredItems.take(limit).toList();
    } catch (e) {
      debugPrint('获取推荐菜品失败: $e');
      return [];
    }
  }

  /// 菜品评分算法
  List<FoodItem> _scoreFoodItems(
      List<FoodItem> items, UserPreference userPreference) {
    final scored = items.map((item) {
      double score = 0.0;

      // 基础评分
      score += item.rating * 2;
    
      // 价格评分
      if (item.price != null && item.price! > 0) {
        if (item.price! <= 50.0) {
          score += (50.0 - item.price!) / 50.0 * 2;
        }
      }

      // 收藏状态加分
      if (userPreference.favoriteFoods.contains(item.id)) {
        score += 5.0;
      }

      // 不喜欢的食物扣分
      if (userPreference.dislikedFoods.contains(item.id)) {
        score -= 10.0;
      }

      // 口味匹配评分
      final tasteScore = _calculateFoodTasteMatch(item, userPreference);
      score += tasteScore * 4;

      return MapEntry(item, score);
    }).toList();

    // 按分数排序
    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.map((entry) => entry.key).toList();
  }

  /// 计算菜品口味匹配度
  double _calculateFoodTasteMatch(
      FoodItem item, UserPreference userPreference) {
    double matchScore = 0.0;
    int totalChecks = 0;

    // 检查口味匹配
    for (final taste in item.tasteAttributes) {
      totalChecks++;
      final tasteScore = userPreference.tastePreferences[taste] ?? 0;
      if (tasteScore > 0) {
        matchScore += tasteScore.toDouble() / 10;
      }
    }

    // 检查菜系匹配
    totalChecks++;
    final cuisineScore =
        userPreference.cuisinePreferences[item.cuisineType] ?? 0;
    if (cuisineScore > 0) {
      matchScore += cuisineScore.toDouble() / 10;
    }

    return totalChecks > 0 ? matchScore / totalChecks : 0.0;
  }

  /// 获取热门推荐
  Future<List<Restaurant>> getPopularRecommendations({
    required double latitude,
    required double longitude,
    int limit = 10,
  }) async {
    try {
      final popularKeywords = ['热门', '好评', '快餐', '小吃', '火锅'];
      final allRestaurants = <Restaurant>[];

      for (final keyword in popularKeywords) {
        final restaurants = await _apiService.searchRestaurants(
          keyword: keyword,
          latitude: latitude,
          longitude: longitude,
          pageSize: 5,
        );
        allRestaurants.addAll(restaurants);
      }

      // 去重并按评分排序
      final uniqueRestaurants = _removeDuplicates(allRestaurants);
      uniqueRestaurants.sort((a, b) {
        final aRating = a.rating ?? 0.0;
        final bRating = b.rating ?? 0.0;
        return bRating.compareTo(aRating);
      });

      return uniqueRestaurants.take(limit).toList();
    } catch (e) {
      debugPrint('获取热门推荐失败: $e');
      return [];
    }
  }
}
