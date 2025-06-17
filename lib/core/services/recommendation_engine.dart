import 'dart:math';
import '../models/bubble.dart';
import '../models/food.dart';

/// 推荐引擎
class RecommendationEngine {
  static final Random _random = Random();

  /// 根据选中的气泡生成食物推荐
  static List<Food> generateRecommendations(List<Bubble> selectedBubbles) {
    if (selectedBubbles.isEmpty) {
      return _getRandomFoods();
    }

    final recommendations = <Food>[];
    final foodDatabase = _getFoodDatabase();

    // 根据气泡类型和名称匹配食物
    for (final food in foodDatabase) {
      double score = _calculateMatchScore(food, selectedBubbles);
      if (score > 0.3) {
        recommendations.add(food.copyWith(rating: score * 5));
      }
    }

    // 按评分排序
    recommendations.sort((a, b) => b.rating.compareTo(a.rating));

    // 返回前10个推荐
    return recommendations.take(10).toList();
  }

  /// 计算食物与选中气泡的匹配分数
  static double _calculateMatchScore(Food food, List<Bubble> selectedBubbles) {
    double totalScore = 0.0;
    int matchCount = 0;

    for (final bubble in selectedBubbles) {
      double bubbleScore = 0.0;

      switch (bubble.type) {
        case BubbleType.taste:
          if (food.tasteAttributes.contains(bubble.name)) {
            bubbleScore = 1.0;
          }
          break;
        case BubbleType.cuisine:
          if (food.cuisineType == bubble.name) {
            bubbleScore = 1.0;
          }
          break;
        case BubbleType.ingredient:
          if (food.ingredients.any((ingredient) => 
              ingredient.contains(bubble.name))) {
            bubbleScore = 0.8;
          }
          break;
        case BubbleType.scenario:
          if (food.scenarios?.contains(bubble.name) == true) {
            bubbleScore = 0.7;
          }
          break;
        case BubbleType.nutrition:
          if (food.nutritionFacts?.containsKey(bubble.name) == true) {
            bubbleScore = 0.6;
          }
          break;
        default:
          bubbleScore = 0.1;
      }

      if (bubbleScore > 0) {
        totalScore += bubbleScore * bubble.weight;
        matchCount++;
      }
    }

    return matchCount > 0 ? totalScore / selectedBubbles.length : 0.0;
  }

  /// 获取随机食物推荐
  static List<Food> _getRandomFoods() {
    final foods = _getFoodDatabase();
    foods.shuffle(_random);
    return foods.take(5).toList();
  }

  /// 模拟食物数据库
  static List<Food> _getFoodDatabase() {
    return [
      Food(
        name: '宫保鸡丁',
        description: '经典川菜，酸甜微辣，鸡肉嫩滑',
        cuisineType: '川菜',
        tasteAttributes: ['辣', '甜', '咸'],
        ingredients: ['鸡肉', '花生', '辣椒'],
        scenarios: ['午餐', '晚餐', '聚餐'],
        calories: 280,
        rating: 4.5,
        ratingCount: 1250,
      ),
      Food(
        name: '麻婆豆腐',
        description: '四川传统名菜，麻辣鲜香',
        cuisineType: '川菜',
        tasteAttributes: ['辣', '麻', '鲜'],
        ingredients: ['豆腐', '牛肉末', '豆瓣酱'],
        scenarios: ['午餐', '晚餐', '家庭餐'],
        calories: 180,
        rating: 4.3,
        ratingCount: 980,
      ),
      Food(
        name: '白切鸡',
        description: '粤菜经典，清淡鲜美',
        cuisineType: '粤菜',
        tasteAttributes: ['鲜', '清淡'],
        ingredients: ['鸡肉', '姜', '葱'],
        scenarios: ['午餐', '晚餐', '家庭餐'],
        calories: 220,
        rating: 4.2,
        ratingCount: 750,
      ),
      Food(
        name: '糖醋里脊',
        description: '酸甜可口，老少皆宜',
        cuisineType: '鲁菜',
        tasteAttributes: ['甜', '酸'],
        ingredients: ['猪肉', '番茄酱', '醋'],
        scenarios: ['午餐', '晚餐', '家庭餐'],
        calories: 320,
        rating: 4.4,
        ratingCount: 1100,
      ),
      Food(
        name: '清蒸鲈鱼',
        description: '江南名菜，鱼肉鲜嫩',
        cuisineType: '苏菜',
        tasteAttributes: ['鲜', '清淡'],
        ingredients: ['鲈鱼', '蒸鱼豉油', '葱丝'],
        scenarios: ['午餐', '晚餐', '精致餐'],
        calories: 150,
        rating: 4.6,
        ratingCount: 890,
      ),
      Food(
        name: '日式拉面',
        description: '浓郁汤头，Q弹面条',
        cuisineType: '日料',
        tasteAttributes: ['鲜', '香'],
        ingredients: ['面条', '叉烧', '海苔', '鸡蛋'],
        scenarios: ['午餐', '晚餐', '夜宵'],
        calories: 450,
        rating: 4.3,
        ratingCount: 1350,
      ),
      Food(
        name: '韩式烤肉',
        description: '香嫩烤肉，配菜丰富',
        cuisineType: '韩料',
        tasteAttributes: ['香', '咸'],
        ingredients: ['牛肉', '猪肉', '蔬菜'],
        scenarios: ['晚餐', '聚餐', '约会'],
        calories: 380,
        rating: 4.5,
        ratingCount: 920,
      ),
      Food(
        name: '意大利面',
        description: '经典西餐，口感丰富',
        cuisineType: '西餐',
        tasteAttributes: ['香', '鲜'],
        ingredients: ['面条', '番茄', '芝士'],
        scenarios: ['午餐', '晚餐', '约会'],
        calories: 350,
        rating: 4.1,
        ratingCount: 680,
      ),
      Food(
        name: '泰式咖喱',
        description: '香辣浓郁，椰香四溢',
        cuisineType: '泰菜',
        tasteAttributes: ['辣', '香', '甜'],
        ingredients: ['咖喱', '椰浆', '鸡肉', '蔬菜'],
        scenarios: ['午餐', '晚餐'],
        calories: 290,
        rating: 4.2,
        ratingCount: 560,
      ),
      Food(
        name: '小笼包',
        description: '皮薄汁多，上海特色',
        cuisineType: '苏菜',
        tasteAttributes: ['鲜', '香'],
        ingredients: ['猪肉', '面粉', '高汤'],
        scenarios: ['早餐', '午餐', '快餐'],
        calories: 180,
        rating: 4.7,
        ratingCount: 1580,
      ),
      Food(
        name: '煎饼果子',
        description: '天津特色早餐，香脆可口',
        cuisineType: '津菜',
        tasteAttributes: ['香', '咸'],
        ingredients: ['面糊', '鸡蛋', '薄脆', '酱料'],
        scenarios: ['早餐', '快餐'],
        calories: 250,
        rating: 4.0,
        ratingCount: 890,
      ),
      Food(
        name: '蔬菜沙拉',
        description: '清爽健康，营养丰富',
        cuisineType: '西餐',
        tasteAttributes: ['清淡', '鲜'],
        ingredients: ['生菜', '番茄', '黄瓜', '沙拉酱'],
        scenarios: ['午餐', '晚餐', '工作餐'],
        calories: 120,
        rating: 3.8,
        ratingCount: 450,
        nutritionFacts: {'高纤维': 1.0, '维生素': 1.0, '低热量': 1.0},
      ),
      Food(
        name: '牛排',
        description: '嫩滑多汁，西餐经典',
        cuisineType: '西餐',
        tasteAttributes: ['香', '鲜'],
        ingredients: ['牛肉', '黑胡椒', '蒜'],
        scenarios: ['晚餐', '约会', '精致餐'],
        calories: 420,
        rating: 4.6,
        ratingCount: 1200,
        nutritionFacts: {'高蛋白': 1.0, '补铁': 1.0},
      ),
      Food(
        name: '鸡蛋羹',
        description: '嫩滑如丝，营养丰富',
        cuisineType: '家常菜',
        tasteAttributes: ['鲜', '清淡'],
        ingredients: ['鸡蛋', '温水', '盐'],
        scenarios: ['早餐', '午餐', '家庭餐'],
        calories: 90,
        rating: 4.1,
        ratingCount: 670,
        nutritionFacts: {'高蛋白': 1.0, '低热量': 1.0},
      ),
    ];
  }
} 