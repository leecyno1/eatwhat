import 'package:flutter/material.dart';
import '../models/food.dart';
import '../data/food_data_generator.dart';

/// 简化的美食数据库服务
/// 提供真实的美食推荐数据
class SimpleFoodDatabase {
  static final SimpleFoodDatabase _instance = SimpleFoodDatabase._internal();
  factory SimpleFoodDatabase() => _instance;
  SimpleFoodDatabase._internal();
  
  final List<Food> _cachedFoods = [];
  bool _isInitialized = false;
  
  /// 初始化数据库
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('开始初始化美食数据库...');
      
      // 加载美食数据
      await _loadFoodData();
      
      _isInitialized = true;
      debugPrint('美食数据库初始化完成，共加载 ${_cachedFoods.length} 个美食项目');
      
    } catch (e) {
      debugPrint('数据库初始化失败: $e');
      _isInitialized = true;
    }
  }
  
  /// 加载美食数据
  Future<void> _loadFoodData() async {
    // 使用食物数据生成器生成1000+道菜品
    debugPrint('正在生成完整美食数据库...');
    final foods = FoodDataGenerator.generateFullDatabase();
    debugPrint('生成了 ${foods.length} 道菜品');
    
    _cachedFoods.addAll(foods);
    
    // 添加一些手工精选的特色菜品
    _cachedFoods.addAll([
      Food(
        id: 'featured_001',
        name: '宫保鸡丁',
        description: '四川传统名菜，鸡肉嫩滑，花生香脆，口感丰富',
        cuisineType: '川菜',
        rating: 4.7,
        price: 28.0,
        tasteAttributes: ['辣', '咸', '鲜'],
        difficulty: '中等',
        preparationTime: '25分钟',
        calories: 320,
        ingredients: ['鸡胸肉', '花生米', '干辣椒', '花椒', '葱', '蒜'],
        nutritionFacts: {
          'protein': 28.0,
          'carbs': 12.0,
          'fat': 18.0,
          'fiber': 3.0
        },
      ),
      
      Food(
        id: 'sichuan_002',
        name: '麻婆豆腐',
        description: '四川传统豆腐菜，麻辣鲜香，口感嫩滑',
        cuisineType: '川菜',
        rating: 4.5,
        price: 18.0,
        tasteAttributes: ['麻', '辣', '鲜'],
        difficulty: 'easy',
        preparationTime: '20分钟',
        calories: 180,
        ingredients: ['嫩豆腐', '牛肉末', '豆瓣酱', '花椒粉'],
        nutritionFacts: {
          'protein': 15.0,
          'carbs': 8.0,
          'fat': 12.0,
          'fiber': 2.0
        },
      ),
      
      Food(
        id: 'sichuan_003',
        name: '回锅肉',
        description: '四川经典家常菜，肥瘦相间，香辣开胃',
        cuisineType: '川菜',
        rating: 4.6,
        price: 32.0,
        tasteAttributes: ['辣', '香', '咸'],
        difficulty: 'medium',
        preparationTime: '30分钟',
        calories: 420,
        ingredients: ['五花肉', '青椒', '豆瓣酱', '甜面酱'],
        nutritionFacts: {
          'protein': 20.0,
          'carbs': 8.0,
          'fat': 32.0,
          'fiber': 2.0
        },
      ),
      
      // 粤菜
      Food(
        id: 'cantonese_001',
        name: '白切鸡',
        description: '粤菜经典，鸡肉鲜嫩，配蘸料食用',
        cuisineType: '粤菜',
        rating: 4.4,
        price: 35.0,
        tasteAttributes: ['鲜', '清淡'],
        difficulty: 'easy',
        preparationTime: '45分钟',
        calories: 220,
        ingredients: ['土鸡', '姜片', '葱段', '料酒'],
        nutritionFacts: {
          'protein': 28.0,
          'carbs': 2.0,
          'fat': 12.0,
          'fiber': 0.0
        },
      ),
      
      Food(
        id: 'cantonese_002',
        name: '蒸蛋羹',
        description: '粤式经典，口感嫩滑，营养丰富',
        cuisineType: '粤菜',
        rating: 4.3,
        price: 15.0,
        tasteAttributes: ['鲜', '嫩', '清淡'],
        difficulty: 'easy',
        preparationTime: '15分钟',
        calories: 120,
        ingredients: ['鸡蛋', '温水', '盐', '香油'],
        nutritionFacts: {
          'protein': 8.0,
          'carbs': 2.0,
          'fat': 9.0,
          'fiber': 0.0
        },
      ),
      
      // 湘菜
      Food(
        id: 'hunan_001',
        name: '剁椒鱼头',
        description: '湘菜招牌菜，鱼肉鲜嫩，剁椒香辣',
        cuisineType: '湘菜',
        rating: 4.8,
        price: 48.0,
        tasteAttributes: ['辣', '鲜', '香'],
        difficulty: 'medium',
        preparationTime: '35分钟',
        calories: 280,
        ingredients: ['鱼头', '剁椒', '蒸鱼豉油', '葱丝'],
        nutritionFacts: {
          'protein': 25.0,
          'carbs': 5.0,
          'fat': 15.0,
          'fiber': 1.0
        },
      ),
      
      // 苏菜
      Food(
        id: 'jiangsu_001',
        name: '红烧肉',
        description: '江南传统名菜，肥瘦相间，入口即化',
        cuisineType: '苏菜',
        rating: 4.8,
        price: 38.0,
        tasteAttributes: ['甜', '咸', '鲜'],
        difficulty: 'medium',
        preparationTime: '90分钟',
        calories: 450,
        ingredients: ['五花肉', '冰糖', '生抽', '老抽', '八角'],
        nutritionFacts: {
          'protein': 22.0,
          'carbs': 15.0,
          'fat': 35.0,
          'fiber': 1.0
        },
      ),
      
      Food(
        id: 'jiangsu_002',
        name: '糖醋里脊',
        description: '酸甜可口的经典菜品，外酥内嫩',
        cuisineType: '鲁菜',
        rating: 4.6,
        price: 32.0,
        tasteAttributes: ['甜', '酸', '鲜'],
        difficulty: 'medium',
        preparationTime: '30分钟',
        calories: 380,
        ingredients: ['里脊肉', '鸡蛋', '淀粉', '番茄酱', '白醋'],
        nutritionFacts: {
          'protein': 25.0,
          'carbs': 28.0,
          'fat': 20.0,
          'fiber': 2.0
        },
      ),
      
      // 家常菜
      Food(
        id: 'home_001',
        name: '西红柿炒鸡蛋',
        description: '简单家常菜，酸甜可口，营养丰富',
        cuisineType: '家常菜',
        rating: 4.2,
        price: 12.0,
        tasteAttributes: ['酸', '甜', '鲜'],
        difficulty: 'easy',
        preparationTime: '10分钟',
        calories: 150,
        ingredients: ['西红柿', '鸡蛋', '糖', '盐'],
        nutritionFacts: {
          'protein': 8.0,
          'carbs': 10.0,
          'fat': 8.0,
          'fiber': 2.0
        },
      ),
      
      Food(
        id: 'home_002',
        name: '青椒土豆丝',
        description: '经典素菜，清脆爽口，简单易做',
        cuisineType: '家常菜',
        rating: 4.0,
        price: 8.0,
        tasteAttributes: ['清淡', '脆'],
        difficulty: 'easy',
        preparationTime: '15分钟',
        calories: 90,
        ingredients: ['土豆', '青椒', '醋', '盐'],
        nutritionFacts: {
          'protein': 2.0,
          'carbs': 18.0,
          'fat': 2.0,
          'fiber': 3.0
        },
      ),
      
      Food(
        id: 'home_003',
        name: '蛋炒饭',
        description: '快手美食，香滑可口，营养均衡',
        cuisineType: '家常菜',
        rating: 4.1,
        price: 15.0,
        tasteAttributes: ['香', '鲜'],
        difficulty: 'easy',
        preparationTime: '10分钟',
        calories: 320,
        ingredients: ['米饭', '鸡蛋', '葱花', '盐'],
        nutritionFacts: {
          'protein': 12.0,
          'carbs': 45.0,
          'fat': 8.0,
          'fiber': 1.0
        },
      ),
      
      // 西餐
      Food(
        id: 'western_001',
        name: '意大利面',
        description: '经典意式面条，配番茄肉酱，口感丰富',
        cuisineType: '意大利菜',
        rating: 4.3,
        price: 25.0,
        tasteAttributes: ['鲜', '酸'],
        difficulty: 'easy',
        preparationTime: '25分钟',
        calories: 350,
        ingredients: ['意大利面条', '牛肉末', '番茄酱', '洋葱'],
        nutritionFacts: {
          'protein': 18.0,
          'carbs': 45.0,
          'fat': 12.0,
          'fiber': 4.0
        },
      ),
      
      Food(
        id: 'western_002',
        name: '牛排',
        description: '嫩滑多汁的牛排，配土豆泥',
        cuisineType: '西餐',
        rating: 4.7,
        price: 88.0,
        tasteAttributes: ['鲜', '香'],
        difficulty: 'medium',
        preparationTime: '20分钟',
        calories: 520,
        ingredients: ['牛排', '土豆', '黄油', '黑胡椒'],
        nutritionFacts: {
          'protein': 35.0,
          'carbs': 20.0,
          'fat': 28.0,
          'fiber': 3.0
        },
      ),
      
      // 点心小食
      Food(
        id: 'snack_001',
        name: '小笼包',
        description: '皮薄馅多，汤汁丰富的经典点心',
        cuisineType: '点心',
        rating: 4.6,
        price: 15.0,
        tasteAttributes: ['鲜', '香'],
        difficulty: 'hard',
        preparationTime: '120分钟',
        calories: 180,
        ingredients: ['面粉', '猪肉末', '皮冻', '生抽'],
        nutritionFacts: {
          'protein': 12.0,
          'carbs': 25.0,
          'fat': 8.0,
          'fiber': 2.0
        },
      ),
      
      Food(
        id: 'snack_002',
        name: '煎饺',
        description: '外焦内嫩，香脆可口的经典点心',
        cuisineType: '点心',
        rating: 4.4,
        price: 18.0,
        tasteAttributes: ['香', '脆'],
        difficulty: 'medium',
        preparationTime: '30分钟',
        calories: 220,
        ingredients: ['饺子皮', '猪肉馅', '韭菜', '油'],
        nutritionFacts: {
          'protein': 15.0,
          'carbs': 20.0,
          'fat': 12.0,
          'fiber': 2.0
        },
      ),
    ]);
    
    debugPrint('数据库初始化完成，总计 ${_cachedFoods.length} 道菜品');
  }
  
  /// 根据偏好搜索美食
  Future<List<Food>> searchByPreferences(List<String> preferences) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    return _cachedFoods.where((food) {
      // 检查菜系匹配
      for (final pref in preferences) {
        if (food.cuisineType.contains(pref) || 
            food.tasteAttributes.any((taste) => taste.contains(pref)) ||
            food.name.contains(pref)) {
          return true;
        }
      }
      return false;
    }).toList();
  }
  
  /// 根据口味标签搜索
  Future<List<Food>> searchByTaste(List<String> tastes) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    return _cachedFoods.where((food) {
      return food.tasteAttributes.any((taste) => tastes.contains(taste));
    }).toList();
  }
  
  /// 根据菜系搜索
  Future<List<Food>> searchByCuisine(String cuisine) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    return _cachedFoods.where((food) => food.cuisineType.contains(cuisine)).toList();
  }
  
  /// 获取推荐美食
  Future<List<Food>> getRecommendations({
    List<String>? preferences,
    String? cuisine,
    List<String>? tastes,
    int limit = 10,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    var results = List<Food>.from(_cachedFoods);
    
    // 应用过滤条件
    if (preferences != null && preferences.isNotEmpty) {
      results = results.where((food) {
        return preferences.any((pref) => 
          food.cuisineType.contains(pref) || 
          food.tasteAttributes.any((taste) => taste.contains(pref)) ||
          food.name.contains(pref)
        );
      }).toList();
    }
    
    if (cuisine != null) {
      results = results.where((food) => food.cuisineType.contains(cuisine)).toList();
    }
    
    if (tastes != null && tastes.isNotEmpty) {
      results = results.where((food) => 
        food.tasteAttributes.any((taste) => tastes.contains(taste))
      ).toList();
    }
    
    // 按评分排序
    results.sort((a, b) => b.rating.compareTo(a.rating));
    
    return results.take(limit).toList();
  }
  
  /// 获取所有美食
  Future<List<Food>> getAllFoods() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    return List<Food>.from(_cachedFoods);
  }
  
  /// 根据难度获取菜谱
  Future<List<Food>> getRecipesByDifficulty(String difficulty) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    return _cachedFoods.where((food) => food.difficulty == difficulty).toList();
  }
}