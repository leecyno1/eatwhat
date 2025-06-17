import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../models/restaurant.dart';
import '../models/food_item.dart';
import '../models/food.dart';
import 'delivery_api_service.dart';
import 'user_preference_service.dart';
import 'recommendation_engine.dart';

/// 外卖推荐服务
/// 整合美团和饿了么数据，提供个性化外卖推荐
class DeliveryRecommendationService {
  final DeliveryApiService _apiService;
  final UserPreferenceService _preferenceService;
  final RecommendationEngine _recommendationEngine;
  
  DeliveryRecommendationService({
    required DeliveryApiService apiService,
    required UserPreferenceService preferenceService,
    required RecommendationEngine recommendationEngine,
  }) : _apiService = apiService,
       _preferenceService = preferenceService,
       _recommendationEngine = recommendationEngine;

  /// 获取附近推荐餐厅
  /// 
  /// [latitude] 纬度
  /// [longitude] 经度
  /// [limit] 返回数量限制
  /// [radius] 搜索半径（米）
  Future<List<Restaurant>> getNearbyRecommendedRestaurants({
    required double latitude,
    required double longitude,
    int limit = 20,
    int radius = 3000,
  }) async {
    try {
      // 获取用户偏好
      final preferences = await _preferenceService.getUserPreferences();
      
      // 搜索附近餐厅
      final restaurants = await _apiService.searchNearbyRestaurants(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
      
      if (restaurants.isEmpty) return [];
      
      // 根据用户偏好过滤和排序
      final filteredRestaurants = _filterRestaurantsByPreferences(
        restaurants, 
        preferences,
      );
      
      // 计算推荐分数并排序
      final scoredRestaurants = _scoreRestaurants(
        filteredRestaurants,
        preferences,
        latitude,
        longitude,
      );
      
      // 返回前N个推荐
      return scoredRestaurants.take(limit).toList();
    } catch (e) {
      print('获取推荐餐厅失败: $e');
      return [];
    }
  }

  /// 获取推荐菜品
  /// 
  /// [restaurantId] 餐厅ID
  /// [platform] 平台类型
  /// [limit] 返回数量限制
  Future<List<FoodItem>> getRecommendedFoodItems({
    required String restaurantId,
    required RestaurantPlatform platform,
    int limit = 10,
  }) async {
    try {
      // 获取菜单
      List<FoodItem> menuItems;
      if (platform == RestaurantPlatform.meituan) {
        menuItems = await _apiService.getMeiTuanMenu(restaurantId);
      } else if (platform == RestaurantPlatform.eleme) {
        menuItems = await _apiService.getElemeMenu(restaurantId);
      } else {
        return [];
      }
      
      if (menuItems.isEmpty) return [];
      
      // 获取用户偏好
      final preferences = await _preferenceService.getUserPreferences();
      
      // 转换为Food对象进行推荐计算
      final foods = menuItems.map((item) => item.toFood()).toList();
      
      // 使用推荐引擎计算推荐分数
      final recommendations = await _recommendationEngine.getRecommendations(
        availableFoods: foods,
        count: limit * 2, // 获取更多候选
      );
      
      // 将推荐结果映射回FoodItem
      final recommendedItems = <FoodItem>[];
      for (final food in recommendations) {
        final item = menuItems.firstWhere(
          (item) => item.id == food.id,
          orElse: () => menuItems.first,
        );
        recommendedItems.add(item);
      }
      
      // 根据外卖特有因素重新排序
      final finalRecommendations = _rankFoodItemsByDeliveryFactors(
        recommendedItems,
        preferences,
      );
      
      return finalRecommendations.take(limit).toList();
    } catch (e) {
      print('获取推荐菜品失败: $e');
      return [];
    }
  }

  /// 智能推荐今日外卖
  /// 
  /// [latitude] 纬度
  /// [longitude] 经度
  /// [mealType] 餐次类型（早餐、午餐、晚餐、夜宵）
  Future<DeliveryRecommendation> getTodayDeliveryRecommendation({
    required double latitude,
    required double longitude,
    MealType? mealType,
  }) async {
    try {
      // 确定餐次类型
      final currentMealType = mealType ?? _getCurrentMealType();
      
      // 获取推荐餐厅
      final restaurants = await getNearbyRecommendedRestaurants(
        latitude: latitude,
        longitude: longitude,
        limit: 10,
      );
      
      if (restaurants.isEmpty) {
        return DeliveryRecommendation.empty();
      }
      
      // 为每个餐厅获取推荐菜品
      final restaurantRecommendations = <RestaurantRecommendation>[];
      
      for (final restaurant in restaurants.take(5)) {
        final foodItems = await getRecommendedFoodItems(
          restaurantId: restaurant.id,
          platform: restaurant.platform,
          limit: 3,
        );
        
        if (foodItems.isNotEmpty) {
          restaurantRecommendations.add(RestaurantRecommendation(
            restaurant: restaurant,
            recommendedItems: foodItems,
            score: _calculateRestaurantScore(restaurant, foodItems),
          ));
        }
      }
      
      // 按分数排序
      restaurantRecommendations.sort((a, b) => b.score.compareTo(a.score));
      
      return DeliveryRecommendation(
        mealType: currentMealType,
        recommendations: restaurantRecommendations,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      print('获取今日外卖推荐失败: $e');
      return DeliveryRecommendation.empty();
    }
  }

  /// 搜索外卖
  /// 
  /// [keyword] 搜索关键词
  /// [latitude] 纬度
  /// [longitude] 经度
  /// [filters] 搜索过滤器
  Future<DeliverySearchResult> searchDelivery({
    required String keyword,
    required double latitude,
    required double longitude,
    DeliverySearchFilters? filters,
  }) async {
    try {
      final searchFilters = filters ?? DeliverySearchFilters();
      
      // 搜索餐厅
      final restaurants = await _apiService.searchNearbyRestaurants(
        latitude: latitude,
        longitude: longitude,
        keyword: keyword,
        radius: searchFilters.radius,
      );
      
      // 应用过滤器
      final filteredRestaurants = _applySearchFilters(restaurants, searchFilters);
      
      // 搜索菜品（从推荐餐厅中）
      final foodItems = <FoodItem>[];
      for (final restaurant in filteredRestaurants.take(10)) {
        final menu = restaurant.platform == RestaurantPlatform.meituan
            ? await _apiService.getMeiTuanMenu(restaurant.id)
            : await _apiService.getElemeMenu(restaurant.id);
        
        final matchingItems = menu.where((item) => 
          item.name.toLowerCase().contains(keyword.toLowerCase()) ||
          item.description?.toLowerCase().contains(keyword.toLowerCase()) == true
        ).toList();
        
        foodItems.addAll(matchingItems);
      }
      
      return DeliverySearchResult(
        keyword: keyword,
        restaurants: filteredRestaurants,
        foodItems: foodItems,
        totalCount: filteredRestaurants.length + foodItems.length,
      );
    } catch (e) {
      print('搜索外卖失败: $e');
      return DeliverySearchResult.empty(keyword);
    }
  }

  /// 根据用户偏好过滤餐厅
  List<Restaurant> _filterRestaurantsByPreferences(
    List<Restaurant> restaurants,
    Map<String, dynamic> preferences,
  ) {
    return restaurants.where((restaurant) {
      // 过滤营业状态
      if (!restaurant.isOpen) return false;
      
      // 过滤配送费
      final maxDeliveryFee = preferences['maxDeliveryFee'] as double?;
      if (maxDeliveryFee != null && 
          restaurant.deliveryFee != null && 
          restaurant.deliveryFee! > maxDeliveryFee) {
        return false;
      }
      
      // 过滤起送价
      final maxMinOrder = preferences['maxMinOrderAmount'] as double?;
      if (maxMinOrder != null && 
          restaurant.minOrderAmount != null && 
          restaurant.minOrderAmount! > maxMinOrder) {
        return false;
      }
      
      // 过滤评分
      final minRating = preferences['minRating'] as double?;
      if (minRating != null && 
          restaurant.rating != null && 
          restaurant.rating! < minRating) {
        return false;
      }
      
      return true;
    }).toList();
  }

  /// 为餐厅计算推荐分数
  List<Restaurant> _scoreRestaurants(
    List<Restaurant> restaurants,
    Map<String, dynamic> preferences,
    double userLat,
    double userLng,
  ) {
    final scoredRestaurants = restaurants.map((restaurant) {
      double score = 0.0;
      
      // 距离分数（距离越近分数越高）
      if (restaurant.distance != null) {
        score += (3000 - restaurant.distance!.clamp(0, 3000)) / 3000 * 30;
      }
      
      // 评分分数
      if (restaurant.rating != null) {
        score += restaurant.rating! * 20;
      }
      
      // 配送时间分数（时间越短分数越高）
      if (restaurant.deliveryTime != null) {
        score += (60 - restaurant.deliveryTime!.clamp(0, 60)) / 60 * 15;
      }
      
      // 配送费分数（费用越低分数越高）
      if (restaurant.deliveryFee != null) {
        score += (10 - restaurant.deliveryFee!.clamp(0, 10)) / 10 * 10;
      }
      
      // 优惠活动加分
      if (restaurant.isPromotional) {
        score += 15;
      }
      
      // 评价数量加分
      if (restaurant.reviewCount != null && restaurant.reviewCount! > 100) {
        score += 10;
      }
      
      return restaurant.copyWith();
    }).toList();
    
    // 按分数排序
    scoredRestaurants.sort((a, b) => b.rating!.compareTo(a.rating!));
    
    return scoredRestaurants;
  }

  /// 根据外卖特有因素排序菜品
  List<FoodItem> _rankFoodItemsByDeliveryFactors(
    List<FoodItem> items,
    Map<String, dynamic> preferences,
  ) {
    return items.map((item) {
      double score = 0.0;
      
      // 销量分数
      score += (item.salesCount / 1000).clamp(0, 10);
      
      // 评分分数
      score += item.rating * 2;
      
      // 价格分数（根据用户预算偏好）
      final budget = preferences['budget'] as double? ?? 50.0;
      if (item.currentPrice <= budget) {
        score += 5;
      }
      
      // 折扣加分
      if (item.hasDiscount) {
        score += 3;
      }
      
      // 推荐标签加分
      if (item.isRecommended) score += 2;
      if (item.isHot) score += 2;
      if (item.isNew) score += 1;
      
      return item;
    }).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
  }

  /// 应用搜索过滤器
  List<Restaurant> _applySearchFilters(
    List<Restaurant> restaurants,
    DeliverySearchFilters filters,
  ) {
    return restaurants.where((restaurant) {
      // 价格范围过滤
      if (filters.priceRange != null) {
        // 这里可以根据餐厅的平均价格进行过滤
        // 暂时跳过，因为Restaurant模型中没有平均价格字段
      }
      
      // 评分过滤
      if (filters.minRating != null && 
          restaurant.rating != null && 
          restaurant.rating! < filters.minRating!) {
        return false;
      }
      
      // 配送时间过滤
      if (filters.maxDeliveryTime != null && 
          restaurant.deliveryTime != null && 
          restaurant.deliveryTime! > filters.maxDeliveryTime!) {
        return false;
      }
      
      // 分类过滤
      if (filters.categories.isNotEmpty) {
        final hasMatchingCategory = restaurant.categories.any(
          (category) => filters.categories.contains(category)
        );
        if (!hasMatchingCategory) return false;
      }
      
      return true;
    }).toList();
  }

  /// 获取当前餐次类型
  MealType _getCurrentMealType() {
    final hour = DateTime.now().hour;
    
    if (hour >= 6 && hour < 10) {
      return MealType.breakfast;
    } else if (hour >= 10 && hour < 14) {
      return MealType.lunch;
    } else if (hour >= 17 && hour < 21) {
      return MealType.dinner;
    } else {
      return MealType.snack;
    }
  }

  /// 计算餐厅推荐分数
  double _calculateRestaurantScore(
    Restaurant restaurant,
    List<FoodItem> recommendedItems,
  ) {
    double score = 0.0;
    
    // 餐厅基础分数
    if (restaurant.rating != null) {
      score += restaurant.rating! * 20;
    }
    
    // 推荐菜品分数
    if (recommendedItems.isNotEmpty) {
      final avgItemRating = recommendedItems
          .map((item) => item.rating)
          .reduce((a, b) => a + b) / recommendedItems.length;
      score += avgItemRating * 15;
    }
    
    // 距离分数
    if (restaurant.distance != null) {
      score += (3000 - restaurant.distance!.clamp(0, 3000)) / 3000 * 10;
    }
    
    return score;
  }
}

/// 餐次类型
enum MealType {
  breakfast('早餐'),
  lunch('午餐'),
  dinner('晚餐'),
  snack('夜宵/零食');
  
  const MealType(this.displayName);
  final String displayName;
}

/// 外卖推荐结果
class DeliveryRecommendation {
  final MealType mealType;
  final List<RestaurantRecommendation> recommendations;
  final DateTime generatedAt;
  
  const DeliveryRecommendation({
    required this.mealType,
    required this.recommendations,
    required this.generatedAt,
  });
  
  factory DeliveryRecommendation.empty() {
    return DeliveryRecommendation(
      mealType: MealType.lunch,
      recommendations: [],
      generatedAt: DateTime.now(),
    );
  }
  
  bool get isEmpty => recommendations.isEmpty;
  bool get isNotEmpty => recommendations.isNotEmpty;
}

/// 餐厅推荐
class RestaurantRecommendation {
  final Restaurant restaurant;
  final List<FoodItem> recommendedItems;
  final double score;
  
  const RestaurantRecommendation({
    required this.restaurant,
    required this.recommendedItems,
    required this.score,
  });
}

/// 外卖搜索结果
class DeliverySearchResult {
  final String keyword;
  final List<Restaurant> restaurants;
  final List<FoodItem> foodItems;
  final int totalCount;
  
  const DeliverySearchResult({
    required this.keyword,
    required this.restaurants,
    required this.foodItems,
    required this.totalCount,
  });
  
  factory DeliverySearchResult.empty(String keyword) {
    return DeliverySearchResult(
      keyword: keyword,
      restaurants: [],
      foodItems: [],
      totalCount: 0,
    );
  }
  
  bool get isEmpty => totalCount == 0;
  bool get isNotEmpty => totalCount > 0;
}

/// 搜索过滤器
class DeliverySearchFilters {
  final List<String> categories;
  final double? minRating;
  final int? maxDeliveryTime;
  final PriceRange? priceRange;
  final int radius;
  
  const DeliverySearchFilters({
    this.categories = const [],
    this.minRating,
    this.maxDeliveryTime,
    this.priceRange,
    this.radius = 3000,
  });
}

/// 价格范围
enum PriceRange {
  low('经济实惠', 0, 20),
  medium('中等价位', 20, 50),
  high('高端消费', 50, 100);
  
  const PriceRange(this.displayName, this.min, this.max);
  final String displayName;
  final double min;
  final double max;
}