import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../models/food_item.dart';
import '../models/restaurant.dart';

/// 外卖API服务 - 对接TheMealDB + 模拟真实外卖数据
class DeliveryApiService {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1/';
  static const List<String> _chineseCuisines = ['川菜', '粤菜', '湘菜', '鲁菜', '苏菜', '浙菜', '闽菜', '徽菜'];
  static const List<String> _restaurantTypes = [
    '中餐厅',
    '快餐店',
    '火锅店',
    '烧烤店',
    '面馆',
    '米粉店',
    '饺子馆',
    '茶餐厅'
  ];

  /// 根据关键词搜索菜品
  Future<List<FoodItem>> searchFood(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final response = await http.get(Uri.parse('${_baseUrl}search.php?s=$query'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] == null) {
          return [];
        }

        final List meals = data['meals'];
        return meals.map((meal) => _mealToFoodItem(meal)).toList();
      } else {
        throw Exception('Failed to load meals from API');
      }
    } catch (e) {
      debugPrint('Error searching food: $e');
      throw Exception('Network error or API failure.');
    }
  }

  /// 将API返回的meal对象转换为应用内部的FoodItem模型
  FoodItem _mealToFoodItem(Map<String, dynamic> meal) {
    return FoodItem(
      id: meal['idMeal'] ?? '',
      name: meal['strMeal'] ?? '未知菜品',
      description: meal['strInstructions'] ?? '暂无描述',
      cuisineType: meal['strArea'] ?? '国际菜',
      price: 25.0 + Random().nextDouble() * 50.0, // 随机价格
      imageUrl: meal['strMealThumb'],
      restaurantId: 'themealdb_${meal['idMeal']}',
      originalPrice: 25.0 + Random().nextDouble() * 50.0,
      rating: 4.0 + Random().nextDouble(),
    );
  }

  /// 获取随机菜品，用于外卖页面的推荐
  Future<List<FoodItem>> getRecommendedFoods({int count = 5}) async {
    try {
      List<FoodItem> recommendedFoods = [];
      for (int i = 0; i < count; i++) {
        final response = await http.get(Uri.parse('${_baseUrl}random.php'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['meals'] != null) {
            recommendedFoods.add(_mealToFoodItem(data['meals'][0]));
          }
        }
      }
      return recommendedFoods;
    } catch (e) {
      debugPrint('Error getting recommended food: $e');
      throw Exception('Network error or API failure.');
    }
  }

  /// 搜索附近餐厅 - 模拟实现
  Future<List<Restaurant>> searchRestaurants({
    required String keyword,
    required double latitude,
    required double longitude,
    int pageSize = 10,
  }) async {
    debugPrint('正在搜索餐厅: $keyword, 位置: ($latitude, $longitude)');

    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));

    final random = Random();
    final restaurants = <Restaurant>[];

    // 生成模拟餐厅数据
    for (int i = 0; i < pageSize; i++) {
      final restaurantType = _restaurantTypes[random.nextInt(_restaurantTypes.length)];
      final cuisine = _chineseCuisines[random.nextInt(_chineseCuisines.length)];

      restaurants.add(Restaurant(
        id: 'restaurant_${random.nextInt(10000)}',
        name: '${_generateRestaurantName()}$restaurantType',
        description: '正宗$cuisine，新鲜食材，快速配送',
        address:
            '${_generateAddress()} (距离${(random.nextDouble() * 3 + 0.5).toStringAsFixed(1)}km)',
        latitude: latitude + (random.nextDouble() - 0.5) * 0.02,
        longitude: longitude + (random.nextDouble() - 0.5) * 0.02,
        rating: 4.0 + random.nextDouble(),
        deliveryFee: 3.0 + random.nextDouble() * 5.0,
        minOrderAmount: 15.0 + random.nextDouble() * 15.0,
        deliveryTime: 25 + random.nextInt(20),
        imageUrl: 'https://picsum.photos/300/200?random=${random.nextInt(1000)}',
        categories: [cuisine],
        isOpen: random.nextBool() || random.nextBool(), // 80%概率开业
        tags: _generateRestaurantTags(keyword),
      ));
    }

    // 根据关键词过滤
    if (keyword.isNotEmpty) {
      return restaurants
          .where((r) =>
              r.name.contains(keyword) ||
              r.categories.any((c) => c.contains(keyword)) ||
              r.tags.any((t) => t.contains(keyword)))
          .toList();
    }

    return restaurants;
  }

  /// 生成餐厅名称
  String _generateRestaurantName() {
    final prefixes = ['老', '新', '金', '银', '红', '绿', '大', '小', '正宗', '美味'];
    final names = ['川香', '湘味', '粤式', '家常', '特色', '经典', '传统', '创新'];
    final random = Random();

    return '${prefixes[random.nextInt(prefixes.length)]}${names[random.nextInt(names.length)]}';
  }

  /// 生成地址
  String _generateAddress() {
    final districts = ['朝阳区', '海淀区', '西城区', '东城区', '丰台区', '石景山区'];
    final streets = ['中关村大街', '王府井大街', '西单北大街', '建国门外大街', '复兴路', '长安街'];
    final random = Random();

    return '${districts[random.nextInt(districts.length)]}${streets[random.nextInt(streets.length)]}${random.nextInt(999) + 1}号';
  }

  /// 生成餐厅标签
  List<String> _generateRestaurantTags(String keyword) {
    final baseTags = ['快速配送', '新鲜食材', '口味正宗', '性价比高'];
    final keywordTags = <String>[];

    if (keyword.contains('辣') || keyword.contains('川') || keyword.contains('湘')) {
      keywordTags.addAll(['麻辣', '香辣', '特辣']);
    }
    if (keyword.contains('清淡') || keyword.contains('粤') || keyword.contains('苏')) {
      keywordTags.addAll(['清淡', '鲜美', '营养']);
    }
    if (keyword.contains('快餐') || keyword.contains('便当')) {
      keywordTags.addAll(['快餐', '便当', '简餐']);
    }

    final allTags = [...baseTags, ...keywordTags];
    final random = Random();
    allTags.shuffle(random);

    return allTags.take(3).toList();
  }

  /// 获取餐厅菜单 - 模拟实现
  Future<List<FoodItem>> getRestaurantMenu(String restaurantId) async {
    debugPrint('获取餐厅菜单: $restaurantId');

    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 300));

    final random = Random();
    final menuItems = <FoodItem>[];

    // 根据餐厅ID生成不同类型的菜单
    final menuCategories = _getMenuCategories(restaurantId);

    for (final category in menuCategories) {
      final itemsInCategory = 3 + random.nextInt(5); // 每个类别3-7个菜品

      for (int i = 0; i < itemsInCategory; i++) {
        menuItems.add(FoodItem(
          id: '${restaurantId}_${category}_$i',
          name: _generateDishName(category),
          description: _generateDishDescription(category),
          cuisineType: category,
          price: _generatePrice(category),
          originalPrice: _generateOriginalPrice(category),
          imageUrl: 'https://picsum.photos/400/300?random=${random.nextInt(1000)}',
          restaurantId: restaurantId,
          rating: 4.0 + random.nextDouble(),
          isRecommended: random.nextDouble() < 0.3, // 30%概率推荐
          calories: (200 + random.nextInt(600)).toDouble(),
          tasteAttributes: _generateDishTags(category),
          salesCount: random.nextInt(500) + 10, // 销量10-510
        ));
      }
    }

    // 随机打乱顺序，模拟真实菜单
    menuItems.shuffle(random);
    return menuItems;
  }

  /// 获取菜单类别
  List<String> _getMenuCategories(String restaurantId) {
    if (restaurantId.contains('川菜') || restaurantId.contains('湘菜')) {
      return ['川菜', '热菜', '凉菜', '汤类'];
    } else if (restaurantId.contains('粤菜')) {
      return ['粤菜', '点心', '汤类', '甜品'];
    } else if (restaurantId.contains('快餐')) {
      return ['套餐', '盖饭', '面条', '饮品'];
    } else if (restaurantId.contains('火锅')) {
      return ['锅底', '肉类', '蔬菜', '丸类'];
    } else {
      return ['热菜', '凉菜', '主食', '汤类'];
    }
  }

  /// 生成菜品名称
  String _generateDishName(String category) {
    final dishes = {
      '川菜': ['宫保鸡丁', '麻婆豆腐', '回锅肉', '鱼香肉丝', '水煮鱼', '辣子鸡'],
      '粤菜': ['白切鸡', '糖醋里脊', '蜜汁叉烧', '虾饺', '烧鹅', '煲仔饭'],
      '湘菜': ['剁椒鱼头', '口味虾', '毛血旺', '湘西腊肉', '农家小炒肉'],
      '热菜': ['红烧肉', '糖醋排骨', '清炒时蔬', '蒜蓉菠菜', '番茄炒蛋'],
      '凉菜': ['拍黄瓜', '凉拌海带', '口水鸡', '夫妻肺片', '凉拌木耳'],
      '汤类': ['冬瓜排骨汤', '番茄鸡蛋汤', '紫菜蛋花汤', '酸辣汤', '银耳莲子汤'],
      '套餐': ['经典套餐', '豪华套餐', '家庭套餐', '情侣套餐', '学生套餐'],
      '盖饭': ['红烧肉盖饭', '宫保鸡丁盖饭', '鱼香肉丝盖饭', '麻婆豆腐盖饭'],
      '面条': ['牛肉面', '西红柿鸡蛋面', '炸酱面', '担担面', '酸辣面'],
      '饮品': ['柠檬蜂蜜茶', '原味奶茶', '鲜橙汁', '绿豆汤', '银耳汤'],
    };

    final categoryDishes = dishes[category] ?? dishes['热菜']!;
    final random = Random();
    return categoryDishes[random.nextInt(categoryDishes.length)];
  }

  /// 生成菜品描述
  String _generateDishDescription(String category) {
    final descriptions = [
      '精选优质食材，传统工艺制作',
      '口感丰富，营养均衡',
      '经典家常味道，回味无穷',
      '新鲜现做，香气扑鼻',
      '招牌特色，不容错过',
      '健康美味，老少皆宜',
    ];

    final random = Random();
    return descriptions[random.nextInt(descriptions.length)];
  }

  /// 生成价格
  double _generatePrice(String category) {
    final priceRanges = {
      '川菜': [18.0, 45.0],
      '粤菜': [25.0, 60.0],
      '湘菜': [16.0, 40.0],
      '热菜': [12.0, 35.0],
      '凉菜': [8.0, 25.0],
      '汤类': [6.0, 20.0],
      '套餐': [20.0, 50.0],
      '盖饭': [15.0, 30.0],
      '面条': [12.0, 25.0],
      '饮品': [5.0, 15.0],
    };

    final range = priceRanges[category] ?? [10.0, 30.0];
    final random = Random();
    return range[0] + random.nextDouble() * (range[1] - range[0]);
  }

  /// 生成原价
  double _generateOriginalPrice(String category) {
    final currentPrice = _generatePrice(category);
    final random = Random();
    // 20%概率有优惠
    return random.nextDouble() < 0.2
        ? currentPrice * (1.1 + random.nextDouble() * 0.3)
        : currentPrice;
  }

  /// 生成菜品标签
  List<String> _generateDishTags(String category) {
    final tagsByCategory = {
      '川菜': ['麻辣', '下饭', '经典'],
      '粤菜': ['清淡', '鲜美', '营养'],
      '湘菜': ['香辣', '开胃', '下饭'],
      '热菜': ['家常', '营养', '美味'],
      '凉菜': ['爽口', '开胃', '清淡'],
      '汤类': ['滋补', '暖胃', '营养'],
      '套餐': ['实惠', '丰富', '超值'],
      '饮品': ['解腻', '清甜', '解渴'],
    };

    return tagsByCategory[category] ?? ['美味', '新鲜', '推荐'];
  }
}
