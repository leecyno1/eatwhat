import 'dart:math';
import '../models/food.dart';

/// 美食数据生成器 - 自动生成1000+道菜品数据
class FoodDataGenerator {
  static final Random _random = Random();

  // 基础食材库
  static const List<String> _proteins = [
    '鸡肉',
    '牛肉',
    '猪肉',
    '羊肉',
    '鱼肉',
    '虾',
    '蟹',
    '鸭肉',
    '鹅肉',
    '兔肉',
    '豆腐',
    '鸡蛋',
    '鹌鹑蛋',
    '扇贝',
    '蛤蜊',
    '鲍鱼',
    '海参',
    '墨鱼',
    '章鱼',
    '带鱼'
  ];

  static const List<String> _vegetables = [
    '白菜',
    '菠菜',
    '韭菜',
    '芹菜',
    '萝卜',
    '胡萝卜',
    '土豆',
    '番茄',
    '黄瓜',
    '茄子',
    '青椒',
    '红椒',
    '洋葱',
    '大蒜',
    '生姜',
    '大葱',
    '豆角',
    '冬瓜',
    '南瓜',
    '丝瓜',
    '苦瓜',
    '西兰花',
    '花菜',
    '卷心菜',
    '莴笋',
    '竹笋',
    '蘑菇',
    '木耳',
    '银耳',
    '海带'
  ];

  static const List<String> _seasonings = [
    '生抽',
    '老抽',
    '盐',
    '糖',
    '醋',
    '料酒',
    '胡椒粉',
    '花椒',
    '辣椒',
    '蒜蓉',
    '豆瓣酱',
    '甜面酱',
    '蚝油',
    '香油',
    '辣椒油',
    '花椒油',
    '芝麻',
    '花生',
    '葱花',
    '香菜'
  ];

  // 烹饪方法
  static const List<String> _cookingMethods = [
    '红烧',
    '清蒸',
    '爆炒',
    '干煸',
    '水煮',
    '油焖',
    '糖醋',
    '宫保',
    '鱼香',
    '麻婆',
    '白切',
    '卤制',
    '炖煮',
    '煎制',
    '烤制',
    '凉拌',
    '腌制',
    '炸制',
    '熏制',
    '蒸制'
  ];

  // 口味属性
  static const List<List<String>> _tasteProfiles = [
    ['麻', '辣', '鲜'],
    ['酸', '甜', '鲜'],
    ['香', '咸', '鲜'],
    ['清淡', '鲜', '嫩'],
    ['浓郁', '香', '醇'],
    ['爽脆', '清香'],
    ['软糯', '甜', '香'],
    ['鲜美', '滑嫩'],
    ['麻辣', '香'],
    ['酸辣', '开胃'],
    ['甜酸', '爽口'],
    ['咸鲜', '下饭'],
    ['清香', '淡雅'],
    ['浓香', '厚重'],
    ['鲜嫩', '多汁'],
    ['酥脆', '香甜']
  ];

  // 菜系特色词汇
  static const Map<String, List<String>> _cuisineCharacteristics = {
    '川菜': ['麻辣', '鲜香', '下饭', '开胃', '重口味'],
    '粤菜': ['清淡', '鲜美', '精致', '营养', '原汁原味'],
    '鲁菜': ['醇厚', '实在', '营养', '传统', '家常'],
    '苏菜': ['精美', '鲜甜', '清雅', '细腻', '江南风味'],
    '浙菜': ['清香', '鲜嫩', '爽口', '杭帮', '精致'],
    '闽菜': ['鲜美', '清汤', '海鲜', '营养', '滋补'],
    '湘菜': ['香辣', '下饭', '农家', '火辣', '重口味'],
    '徽菜': ['醇香', '原汁', '山珍', '野味', '传统'],
    '东北菜': ['实惠', '大盘', '下饭', '暖胃', '家常'],
    '西北菜': ['豪爽', '面食', '清真', '实在', '传统'],
    '云贵菜': ['酸辣', '开胃', '山珍', '野菜', '特色'],
    '西餐': ['精致', '营养', '时尚', '健康', '异国'],
    '日料': ['新鲜', '精美', '清淡', '营养', '原味'],
    '韩料': ['辣味', '开胃', '烧烤', '泡菜', '特色'],
    '东南亚菜': ['酸辣', '香料', '椰香', '热带', '异域']
  };

  // 图片URL模板
  static const List<String> _imageUrls = [
    'https://images.unsplash.com/photo-1504544750208-dc0358e63f7f?w=400',
    'https://images.unsplash.com/photo-1582878825481-ca86a10bbdb8?w=400',
    'https://images.unsplash.com/photo-1517244683847-7456b63c5969?w=400',
    'https://images.unsplash.com/photo-1547330874-e47bda1b3f40?w=400',
    'https://images.unsplash.com/photo-1565299585323-38174c4a6a27?w=400',
    'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400',
    'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=400',
    'https://images.unsplash.com/photo-1585032226651-759b368d7be1?w=400',
    'https://images.unsplash.com/photo-1496116218417-1a781b1c416c?w=400',
    'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400',
    'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400',
    'https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5?w=400'
  ];

  /// 生成指定数量的菜品
  static List<Food> generateFoods(String cuisine, int count) {
    final foods = <Food>[];
    final characteristics = _cuisineCharacteristics[cuisine] ?? ['美味', '经典'];

    for (int i = 0; i < count; i++) {
      foods.add(_generateSingleFood(cuisine, i + 1, characteristics));
    }

    return foods;
  }

  /// 生成单个菜品
  static Food _generateSingleFood(String cuisine, int index, List<String> characteristics) {
    final cookingMethod = _cookingMethods[_random.nextInt(_cookingMethods.length)];
    final protein = _proteins[_random.nextInt(_proteins.length)];
    final vegetable = _vegetables[_random.nextInt(_vegetables.length)];

    // 生成菜名
    String dishName;
    if (_random.nextBool()) {
      dishName = '$cookingMethod$protein';
    } else {
      dishName = '$protein炒$vegetable';
    }

    // 如果菜名重复，添加修饰词
    if (_random.nextDouble() < 0.3) {
      final adjectives = ['香辣', '蒜蓉', '豉汁', '秘制', '招牌', '特色', '精品', '家常'];
      final adjective = adjectives[_random.nextInt(adjectives.length)];
      dishName = '$adjective$dishName';
    }

    // 生成描述
    final characteristic = characteristics[_random.nextInt(characteristics.length)];
    final description = _generateDescription(dishName, characteristic, cuisine);

    // 生成食材列表
    final ingredients = _generateIngredients(protein, vegetable);

    // 生成口味属性
    final tasteProfile = _tasteProfiles[_random.nextInt(_tasteProfiles.length)];

    // 生成价格 (根据菜系和食材调整)
    double basePrice = 20.0;
    if (cuisine == '西餐') {
      basePrice = 60.0;
    } else if (cuisine == '日料') {
      basePrice = 50.0;
    } else if (cuisine.contains('海鲜') || protein.contains('鲍鱼') || protein.contains('海参')) {
      basePrice = 80.0;
    }

    final price = basePrice + _random.nextDouble() * 40.0;

    // 生成营养信息
    final nutrition = _generateNutrition(protein, vegetable);

    return Food(
      id: '${_getCuisineCode(cuisine)}_${index.toString().padLeft(3, '0')}',
      name: dishName,
      description: description,
      cuisineType: cuisine,
      rating: 3.5 + _random.nextDouble() * 1.4, // 3.5-4.9
      price: double.parse(price.toStringAsFixed(1)),
      tasteAttributes: List.from(tasteProfile),
      imageUrl: _imageUrls[_random.nextInt(_imageUrls.length)],
      ingredients: ingredients,
      preparationTime: 10 + _random.nextInt(50), // 10-60分钟
      difficulty: _getDifficulty(),
      nutritionFacts: nutrition,
    );
  }

  /// 生成菜品描述
  static String _generateDescription(String dishName, String characteristic, String cuisine) {
    final descriptions = [
      '$characteristic，色泽诱人，营养丰富',
      '$cuisine经典，$characteristic，老少皆宜',
      '传统做法，$characteristic，回味无穷',
      '精心制作，$characteristic，值得品尝',
      '招牌菜品，$characteristic，食客好评',
      '家常美味，$characteristic，简单易做',
      '特色料理，$characteristic，独具风味',
      '经典搭配，$characteristic，营养均衡'
    ];

    return descriptions[_random.nextInt(descriptions.length)];
  }

  /// 生成食材列表
  static List<String> _generateIngredients(String protein, String vegetable) {
    final ingredients = [protein, vegetable];

    // 添加调料
    final seasoningCount = 2 + _random.nextInt(4); // 2-5种调料
    final usedSeasonings = <String>{};

    while (usedSeasonings.length < seasoningCount) {
      final seasoning = _seasonings[_random.nextInt(_seasonings.length)];
      usedSeasonings.add(seasoning);
    }

    ingredients.addAll(usedSeasonings);

    // 随机添加额外蔬菜
    if (_random.nextDouble() < 0.4) {
      final extraVeg = _vegetables[_random.nextInt(_vegetables.length)];
      if (extraVeg != vegetable) {
        ingredients.add(extraVeg);
      }
    }

    return ingredients;
  }

  /// 生成营养信息
  static Map<String, double> _generateNutrition(String protein, String vegetable) {
    // 基础营养值
    double calories = 200 + _random.nextDouble() * 300; // 200-500卡路里
    double proteinValue = 15 + _random.nextDouble() * 25; // 15-40g蛋白质
    double carbs = 5 + _random.nextDouble() * 45; // 5-50g碳水
    double fat = 5 + _random.nextDouble() * 25; // 5-30g脂肪
    double fiber = 1 + _random.nextDouble() * 8; // 1-9g纤维

    // 根据主要食材调整
    if (protein.contains('肉') || protein.contains('鸡') || protein.contains('鸭')) {
      proteinValue += 10;
      fat += 5;
    }

    if (protein.contains('鱼') || protein.contains('虾') || protein.contains('蟹')) {
      proteinValue += 8;
      calories -= 50;
    }

    if (protein.contains('豆腐')) {
      proteinValue += 5;
      fat -= 5;
      fiber += 3;
    }

    if (vegetable.contains('菜') || vegetable.contains('瓜')) {
      fiber += 2;
      calories -= 30;
    }

    return {
      'calories': double.parse(calories.toStringAsFixed(0)),
      'protein': double.parse(proteinValue.toStringAsFixed(1)),
      'carbs': double.parse(carbs.toStringAsFixed(1)),
      'fat': double.parse(fat.toStringAsFixed(1)),
      'fiber': double.parse(fiber.toStringAsFixed(1)),
    };
  }

  /// 获取难度
  static String _getDifficulty() {
    final difficulties = ['简单', '中等', '困难'];
    final weights = [0.4, 0.5, 0.1]; // 40%简单，50%中等，10%困难

    final random = _random.nextDouble();
    double sum = 0;

    for (int i = 0; i < weights.length; i++) {
      sum += weights[i];
      if (random <= sum) {
        return difficulties[i];
      }
    }

    return '中等';
  }

  /// 获取菜系代码
  static String _getCuisineCode(String cuisine) {
    const codes = {
      '川菜': 'sc',
      '粤菜': 'gd',
      '鲁菜': 'sd',
      '苏菜': 'js',
      '浙菜': 'zj',
      '闽菜': 'fj',
      '湘菜': 'hn',
      '徽菜': 'ah',
      '东北菜': 'db',
      '西北菜': 'xb',
      '云贵菜': 'yg',
      '西餐': 'west',
      '日料': 'jp',
      '韩料': 'kr',
      '东南亚菜': 'sea',
    };

    return codes[cuisine] ?? 'misc';
  }

  /// 生成完整的1000+菜品数据库
  static List<Food> generateFullDatabase() {
    final allFoods = <Food>[];

    // 按菜系分配菜品数量
    const cuisineDistribution = {
      '川菜': 120,
      '粤菜': 110,
      '鲁菜': 90,
      '苏菜': 85,
      '浙菜': 80,
      '闽菜': 75,
      '湘菜': 95,
      '徽菜': 70,
      '东北菜': 65,
      '西北菜': 55,
      '云贵菜': 50,
      '西餐': 85,
      '日料': 70,
      '韩料': 45,
      '东南亚菜': 45,
    };

    // 生成各菜系菜品
    cuisineDistribution.forEach((cuisine, count) {
      allFoods.addAll(generateFoods(cuisine, count));
    });

    // 打乱顺序
    allFoods.shuffle(_random);

    return allFoods;
  }

  /// 生成特定口味的菜品
  static List<Food> generateByTaste(String taste, int count) {
    final allFoods = generateFullDatabase();
    final filteredFoods = allFoods
        .where((food) => (food.tasteAttributes ?? []).any((attr) => attr.contains(taste)))
        .toList();

    filteredFoods.shuffle(_random);
    return filteredFoods.take(count).toList();
  }

  /// 生成特定价格范围的菜品
  static List<Food> generateByPriceRange(double minPrice, double maxPrice, int count) {
    final allFoods = generateFullDatabase();
    final filteredFoods = allFoods
        .where((food) => food.price != null && food.price! >= minPrice && food.price! <= maxPrice)
        .toList();

    filteredFoods.shuffle(_random);
    return filteredFoods.take(count).toList();
  }
}
