import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/recipe.dart';
import '../models/food_item.dart';
import '../models/restaurant.dart';
import '../models/food.dart';

/// 统一数据库服务
class DatabaseService {
  static const String _recipesBoxName = 'recipes';
  static const String _foodItemsBoxName = 'food_items';
  static const String _restaurantsBoxName = 'restaurants';
  static const String _foodsBoxName = 'foods';
  static const String _searchHistoryBoxName = 'search_history';
  static const String _categoryBoxName = 'categories';

  static late Box<Map> _recipesBox;
  static late Box<Map> _foodItemsBox;
  static late Box<Map> _restaurantsBox;
  static late Box<Map> _foodsBox;
  static late Box<List> _searchHistoryBox;
  static late Box<Map> _categoryBox;

  /// 初始化数据库
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // 打开所有数据库
    _recipesBox = await Hive.openBox<Map>(_recipesBoxName);
    _foodItemsBox = await Hive.openBox<Map>(_foodItemsBoxName);
    _restaurantsBox = await Hive.openBox<Map>(_restaurantsBoxName);
    _foodsBox = await Hive.openBox<Map>(_foodsBoxName);
    _searchHistoryBox = await Hive.openBox<List>(_searchHistoryBoxName);
    _categoryBox = await Hive.openBox<Map>(_categoryBoxName);

    // 初始化示例数据
    await _initializeSampleData();
  }

  /// 初始化示例数据
  static Future<void> _initializeSampleData() async {
    if (_recipesBox.isEmpty) {
      await _loadSampleRecipes();
    }
    if (_foodItemsBox.isEmpty) {
      await _loadSampleFoodItems();
    }
    if (_restaurantsBox.isEmpty) {
      await _loadSampleRestaurants();
    }
    if (_foodsBox.isEmpty) {
      await _loadSampleFoods();
    }
    if (_categoryBox.isEmpty) {
      await _loadCategories();
    }
  }

  // ============ 菜谱数据管理 ============

  /// 添加菜谱
  static Future<void> addRecipe(Recipe recipe) async {
    await _recipesBox.put(recipe.id, recipe.toJson());
  }

  /// 获取菜谱
  static Recipe? getRecipe(String id) {
    final data = _recipesBox.get(id);
    if (data != null) {
      return Recipe.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  /// 获取所有菜谱
  static List<Recipe> getAllRecipes() {
    final recipes = <Recipe>[];
    for (final data in _recipesBox.values) {
      try {
        recipes.add(Recipe.fromJson(Map<String, dynamic>.from(data)));
      } catch (e) {
        debugPrint('解析菜谱数据失败: $e');
      }
    }
    return recipes;
  }

  /// 搜索菜谱
  static List<Recipe> searchRecipes({
    String? keyword,
    String? cuisine,
    CookingMethod? cookingMethod,
    RecipeDifficulty? difficulty,
    int? maxTime,
    bool? isVegetarian,
    List<String>? tags,
  }) {
    final allRecipes = getAllRecipes();

    return allRecipes.where((recipe) {
      // 关键词搜索
      if (keyword != null && keyword.isNotEmpty) {
        final searchKeyword = keyword.toLowerCase();
        if (!recipe.name.toLowerCase().contains(searchKeyword) &&
            !recipe.description.toLowerCase().contains(searchKeyword) &&
            !recipe.tags
                .any((tag) => tag.toLowerCase().contains(searchKeyword))) {
          return false;
        }
      }

      // 菜系筛选
      if (cuisine != null && recipe.cuisine != cuisine) {
        return false;
      }

      // 烹饪方式筛选
      if (cookingMethod != null && recipe.cookingMethod != cookingMethod) {
        return false;
      }

      // 难度筛选
      if (difficulty != null && recipe.difficulty != difficulty) {
        return false;
      }

      // 时间筛选
      if (maxTime != null && recipe.totalTime > maxTime) {
        return false;
      }

      // 素食筛选
      if (isVegetarian != null && recipe.isVegetarian != isVegetarian) {
        return false;
      }

      // 标签筛选
      if (tags != null && tags.isNotEmpty) {
        if (!tags.any((tag) => recipe.tags.contains(tag))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// 更新菜谱
  static Future<void> updateRecipe(Recipe recipe) async {
    await _recipesBox.put(recipe.id, recipe.toJson());
  }

  /// 删除菜谱
  static Future<void> deleteRecipe(String id) async {
    await _recipesBox.delete(id);
  }

  // ============ 外卖食品管理 ============

  /// 添加外卖食品
  static Future<void> addFoodItem(FoodItem foodItem) async {
    await _foodItemsBox.put(foodItem.id, foodItem.toJson());
  }

  /// 获取外卖食品
  static FoodItem? getFoodItem(String id) {
    final data = _foodItemsBox.get(id);
    if (data != null) {
      return FoodItem.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  /// 获取所有外卖食品
  static List<FoodItem> getAllFoodItems() {
    final foodItems = <FoodItem>[];
    for (final data in _foodItemsBox.values) {
      try {
        foodItems.add(FoodItem.fromJson(Map<String, dynamic>.from(data)));
      } catch (e) {
        debugPrint('解析外卖食品数据失败: $e');
      }
    }
    return foodItems;
  }

  /// 根据餐厅ID获取菜品
  static List<FoodItem> getFoodItemsByRestaurant(String restaurantId) {
    return getAllFoodItems()
        .where((item) => item.restaurantId == restaurantId)
        .toList();
  }

  /// 搜索外卖食品
  static List<FoodItem> searchFoodItems({
    String? keyword,
    String? cuisine,
    String? restaurantId,
    double? maxPrice,
    double? minRating,
    bool? isAvailable,
  }) {
    final allFoodItems = getAllFoodItems();

    return allFoodItems.where((item) {
      // 关键词搜索
      if (keyword != null && keyword.isNotEmpty) {
        final searchKeyword = keyword.toLowerCase();
        if (!item.name.toLowerCase().contains(searchKeyword) &&
            !(item.description?.toLowerCase().contains(searchKeyword) ??
                false)) {
          return false;
        }
      }

      // 菜系筛选
      if (cuisine != null && item.cuisineType != cuisine) {
        return false;
      }

      // 餐厅筛选
      if (restaurantId != null && item.restaurantId != restaurantId) {
        return false;
      }

      // 价格筛选
      if (maxPrice != null && (item.price ?? 0.0) > maxPrice) {
        return false;
      }

      // 评分筛选
      if (minRating != null && item.rating < minRating) {
        return false;
      }

      // 可用性筛选
      if (isAvailable != null && item.isAvailable != isAvailable) {
        return false;
      }

      return true;
    }).toList();
  }

  // ============ 餐厅管理 ============

  /// 添加餐厅
  static Future<void> addRestaurant(Restaurant restaurant) async {
    await _restaurantsBox.put(restaurant.id, restaurant.toJson());
  }

  /// 获取餐厅
  static Restaurant? getRestaurant(String id) {
    final data = _restaurantsBox.get(id);
    if (data != null) {
      return Restaurant.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  /// 获取所有餐厅
  static List<Restaurant> getAllRestaurants() {
    final restaurants = <Restaurant>[];
    for (final data in _restaurantsBox.values) {
      try {
        restaurants.add(Restaurant.fromJson(Map<String, dynamic>.from(data)));
      } catch (e) {
        debugPrint('解析餐厅数据失败: $e');
      }
    }
    return restaurants;
  }

  /// 搜索餐厅
  static List<Restaurant> searchRestaurants({
    String? keyword,
    double? latitude,
    double? longitude,
    double? maxDistance,
    double? minRating,
    bool? isOpen,
    List<String>? tags,
  }) {
    final allRestaurants = getAllRestaurants();

    return allRestaurants.where((restaurant) {
      // 关键词搜索
      if (keyword != null && keyword.isNotEmpty) {
        final searchKeyword = keyword.toLowerCase();
        if (!restaurant.name.toLowerCase().contains(searchKeyword) &&
            !(restaurant.description?.toLowerCase().contains(searchKeyword) ??
                false)) {
          return false;
        }
      }

      // 距离筛选
      if (latitude != null && longitude != null && maxDistance != null) {
        if (restaurant.latitude != null && restaurant.longitude != null) {
          final distance = _calculateDistance(
            latitude,
            longitude,
            restaurant.latitude!,
            restaurant.longitude!,
          );
          if (distance > maxDistance) {
            return false;
          }
        }
      }

      // 评分筛选
      if (minRating != null && (restaurant.rating ?? 0.0) < minRating) {
        return false;
      }

      // 营业状态筛选
      if (isOpen != null && restaurant.isOpen != isOpen) {
        return false;
      }

      // 标签筛选
      if (tags != null && tags.isNotEmpty) {
        if (!tags.any((tag) => restaurant.tags.contains(tag))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ============ 通用菜品管理 ============

  /// 添加菜品
  static Future<void> addFood(Food food) async {
    await _foodsBox.put(food.id, food.toJson());
  }

  /// 获取菜品
  static Food? getFood(String id) {
    final data = _foodsBox.get(id);
    if (data != null) {
      return Food.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  /// 获取所有菜品
  static List<Food> getAllFoods() {
    final foods = <Food>[];
    for (final data in _foodsBox.values) {
      try {
        foods.add(Food.fromJson(Map<String, dynamic>.from(data)));
      } catch (e) {
        debugPrint('解析菜品数据失败: $e');
      }
    }
    return foods;
  }

  // ============ 搜索历史管理 ============

  /// 添加搜索历史
  static Future<void> addSearchHistory(String keyword) async {
    final history = getSearchHistory();
    history.remove(keyword); // 移除重复项
    history.insert(0, keyword); // 添加到开头

    // 限制历史记录数量
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }

    await _searchHistoryBox.put('search_keywords', history);
  }

  /// 获取搜索历史
  static List<String> getSearchHistory() {
    final data = _searchHistoryBox.get('search_keywords');
    if (data != null) {
      return List<String>.from(data);
    }
    return [];
  }

  /// 清除搜索历史
  static Future<void> clearSearchHistory() async {
    await _searchHistoryBox.delete('search_keywords');
  }

  // ============ 分类管理 ============

  /// 获取菜系分类
  static List<String> getCuisineCategories() {
    final data = _categoryBox.get('cuisines');
    if (data != null) {
      return List<String>.from(data['categories'] ?? []);
    }
    return [];
  }

  /// 获取标签分类
  static List<String> getTagCategories() {
    final data = _categoryBox.get('tags');
    if (data != null) {
      return List<String>.from(data['categories'] ?? []);
    }
    return [];
  }

  // ============ 工具方法 ============

  /// 计算两点间距离（简化版）
  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    // 简化的距离计算，实际应用中可以使用 geolocator 包
    final deltaLat = lat1 - lat2;
    final deltaLon = lon1 - lon2;
    return (deltaLat * deltaLat + deltaLon * deltaLon) * 111.0; // 粗略转换为公里
  }

  /// 清理数据库
  static Future<void> cleanup() async {
    try {
      await Hive.close();
    } catch (e) {
      debugPrint('关闭数据库失败: $e');
    }
  }

  // ============ 示例数据加载 ============

  /// 加载示例菜谱
  static Future<void> _loadSampleRecipes() async {
    final sampleRecipes = [
      Recipe(
        id: 'recipe_001',
        name: '宫保鸡丁',
        description: '经典川菜，麻辣鲜香，鸡肉嫩滑',
        cuisine: '川菜',
        cookingMethod: CookingMethod.stirFry,
        difficulty: RecipeDifficulty.medium,
        preparationTime: 20,
        cookingTime: 15,
        servings: 3,
        imageUrl: 'https://via.placeholder.com/300x200?text=宫保鸡丁',
        tags: ['川菜', '鸡肉', '辣', '下饭'],
        ingredients: [
          RecipeIngredient(name: '鸡胸肉', amount: '300', unit: 'g', isMain: true),
          RecipeIngredient(name: '花生米', amount: '100', unit: 'g'),
          RecipeIngredient(name: '干辣椒', amount: '10', unit: '个'),
          RecipeIngredient(name: '花椒', amount: '1', unit: '小勺'),
          RecipeIngredient(name: '蒜', amount: '3', unit: '瓣'),
        ],
        steps: [
          CookingStep(stepNumber: 1, description: '鸡胸肉切丁，用料酒、生抽、淀粉腌制15分钟'),
          CookingStep(stepNumber: 2, description: '热锅下油，下花生米炸至金黄捞起'),
          CookingStep(stepNumber: 3, description: '下鸡丁炒至变色，盛起'),
          CookingStep(stepNumber: 4, description: '爆炒干辣椒和花椒，下蒜爆香'),
          CookingStep(stepNumber: 5, description: '倒入鸡丁和花生米，调味炒匀即可'),
        ],
        nutrition:
            NutritionInfo(calories: 280, protein: 25, carbs: 12, fat: 15),
        rating: 4.5,
        reviewCount: 128,
        authorId: 'chef_001',
        authorName: '川菜大师',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        tips: '鸡肉要先腌制，炒制时间不宜过长以保持嫩滑',
        seasonalInfo: SeasonalInfo(),
        equipment: CookingEquipment(),
      ),
      Recipe(
        id: 'recipe_002',
        name: '番茄鸡蛋面',
        description: '家常面条，酸甜开胃，营养丰富',
        cuisine: '家常菜',
        cookingMethod: CookingMethod.boil,
        difficulty: RecipeDifficulty.easy,
        preparationTime: 10,
        cookingTime: 15,
        servings: 2,
        imageUrl: 'https://via.placeholder.com/300x200?text=番茄鸡蛋面',
        tags: ['家常菜', '面条', '番茄', '鸡蛋', '快手'],
        ingredients: [
          RecipeIngredient(name: '面条', amount: '200', unit: 'g', isMain: true),
          RecipeIngredient(name: '番茄', amount: '2', unit: '个', isMain: true),
          RecipeIngredient(name: '鸡蛋', amount: '2', unit: '个'),
          RecipeIngredient(name: '葱', amount: '2', unit: '根'),
          RecipeIngredient(name: '糖', amount: '1', unit: '小勺'),
        ],
        steps: [
          CookingStep(stepNumber: 1, description: '番茄划十字刀，开水烫一下去皮切块'),
          CookingStep(stepNumber: 2, description: '鸡蛋打散，热油炒熟盛起'),
          CookingStep(stepNumber: 3, description: '锅内放油，下番茄块炒出汁水'),
          CookingStep(stepNumber: 4, description: '加水煮开，下面条煮熟'),
          CookingStep(stepNumber: 5, description: '加入炒蛋，调味，撒葱花即可'),
        ],
        nutrition: NutritionInfo(calories: 320, protein: 18, carbs: 45, fat: 8),
        rating: 4.2,
        reviewCount: 256,
        authorId: 'chef_002',
        authorName: '家常美食',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        tips: '番茄要充分炒出汁水，面条不要煮过头',
        seasonalInfo: SeasonalInfo(),
        equipment: CookingEquipment(),
      ),
    ];

    for (final recipe in sampleRecipes) {
      await addRecipe(recipe);
    }
  }

  /// 加载示例外卖食品
  static Future<void> _loadSampleFoodItems() async {
    final sampleFoodItems = [
      FoodItem(
        id: 'food_item_001',
        name: '麻辣香锅',
        description: '多种食材搭配，麻辣鲜香',
        cuisineType: '川菜',
        price: 38.0,
        originalPrice: 38.0,
        imageUrl: 'https://via.placeholder.com/200x150?text=麻辣香锅',
        isAvailable: true,
        restaurantId: 'restaurant_001',
        rating: 4.6,
        salesCount: 520,
        preparationTime: 30,
        allergens: ['花生', '芝麻'],
        ingredients: ['土豆', '豆腐', '金针菇', '牛肉片'],
      ),
      FoodItem(
        id: 'food_item_002',
        name: '小笼包',
        description: '皮薄馅大，汤汁鲜美',
        cuisineType: '江浙菜',
        price: 22.0,
        originalPrice: 25.0,
        discountPrice: 22.0,
        imageUrl: 'https://via.placeholder.com/200x150?text=小笼包',
        isAvailable: true,
        restaurantId: 'restaurant_002',
        rating: 4.8,
        salesCount: 890,
        preparationTime: 20,
        allergens: [],
        ingredients: ['猪肉', '面粉', '高汤'],
      ),
    ];

    for (final foodItem in sampleFoodItems) {
      await addFoodItem(foodItem);
    }
  }

  /// 加载示例餐厅
  static Future<void> _loadSampleRestaurants() async {
    final sampleRestaurants = [
      Restaurant(
        id: 'restaurant_001',
        name: '川味小厨',
        address: '中关村大街1号',
        latitude: 39.9796,
        longitude: 116.3053,
        rating: 4.5,
        deliveryFee: 6.0,
        minOrderAmount: 30.0,
        deliveryTime: 35,
        isOpen: true,
        imageUrl: 'https://via.placeholder.com/300x200?text=川味小厨',
        description: '正宗川菜，麻辣鲜香',
        phone: '010-12345678',
        openTime: '09:00',
        closeTime: '22:00',
        tags: ['川菜', '麻辣', '快餐'],
        reviewCount: 1250,
      ),
      Restaurant(
        id: 'restaurant_002',
        name: '江南小馆',
        address: '五道口购物中心B1',
        latitude: 39.9926,
        longitude: 116.3359,
        rating: 4.7,
        deliveryFee: 8.0,
        minOrderAmount: 25.0,
        deliveryTime: 40,
        isOpen: true,
        imageUrl: 'https://via.placeholder.com/300x200?text=江南小馆',
        description: '精致江浙菜，口感清淡',
        phone: '010-87654321',
        openTime: '08:00',
        closeTime: '21:30',
        tags: ['江浙菜', '清淡', '精致'],
        reviewCount: 890,
      ),
    ];

    for (final restaurant in sampleRestaurants) {
      await addRestaurant(restaurant);
    }
  }

  /// 加载示例菜品
  static Future<void> _loadSampleFoods() async {
    final sampleFoods = [
      Food(
        id: 'food_001',
        name: '红烧肉',
        description: '肥而不腻，香甜可口',
        cuisineType: '江浙菜',
        rating: 4.6,
        price: 35.0,
        tasteAttributes: ['甜', '咸', '鲜'],
        isFavorite: false,
      ),
      Food(
        id: 'food_002',
        name: '麻婆豆腐',
        description: '麻辣鲜香，嫩滑爽口',
        cuisineType: '川菜',
        rating: 4.4,
        price: 18.0,
        tasteAttributes: ['麻', '辣', '鲜'],
        isFavorite: false,
      ),
    ];

    for (final food in sampleFoods) {
      await addFood(food);
    }
  }

  /// 加载分类数据
  static Future<void> _loadCategories() async {
    await _categoryBox.put('cuisines', {
      'categories': [
        '川菜',
        '粤菜',
        '鲁菜',
        '苏菜',
        '浙菜',
        '闽菜',
        '湘菜',
        '徽菜',
        '京菜',
        '东北菜',
        '西北菜',
        '江西菜',
        '云南菜',
        '贵州菜',
        '日式料理',
        '韩式料理',
        '西餐',
        '东南亚菜',
        '印度菜',
        '家常菜',
        '素食',
        '烧烤',
        '火锅',
        '快餐',
      ],
    });

    await _categoryBox.put('tags', {
      'categories': [
        '辣',
        '不辣',
        '甜',
        '酸',
        '麻',
        '咸',
        '鲜',
        '香',
        '下饭',
        '下酒',
        '汤品',
        '主食',
        '小食',
        '甜品',
        '素食',
        '荤菜',
        '海鲜',
        '肉类',
        '蔬菜',
        '快手',
        '简单',
        '复杂',
        '营养',
        '低脂',
        '高蛋白',
        '儿童',
        '老人',
        '孕妇',
        '减肥',
        '增肌',
      ],
    });
  }
}
