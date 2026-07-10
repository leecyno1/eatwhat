import '../models/food.dart';

/// 食物数据库
class FoodDatabase {
  static final List<Food> _foods = [
    Food(
      id: '1',
      name: '麻辣香锅',
      description: '四川特色美食，麻辣鲜香，配菜丰富，可自由搭配各种蔬菜和肉类',
      cuisineType: '川菜',
      tasteAttributes: ['麻辣', '香辣', '重口味'],
      ingredients: ['土豆', '豆皮', '午餐肉', '豆芽', '白菜'],
      scenarios: ['聚餐', '下饭'],
      calories: 450,
      rating: 4.6,
      ratingCount: 1250,
      imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400',
      price: 38.0,
      restaurant: '川味小厨',
    ),
    Food(
      id: '2',
      name: '广东肠粉',
      description: '广东传统茶点，皮薄馅嫩，口感爽滑，配以特制酱汁',
      cuisineType: '粤菜',
      tasteAttributes: ['清淡', '爽滑', '鲜美'],
      ingredients: ['米浆', '猪肉', '虾仁', '韭黄'],
      scenarios: ['早餐', '茶点'],
      calories: 280,
      rating: 4.4,
      ratingCount: 890,
      imageUrl: 'https://images.unsplash.com/photo-1563379091319-5d6c8b3d5b5e?w=400',
      price: 15.0,
      restaurant: '粤味茶餐厅',
    ),
    Food(
      id: '3',
      name: '北京烤鸭',
      description: '北京传统名菜，皮脆肉嫩，肥而不腻，配以薄饼、甜面酱',
      cuisineType: '京菜',
      tasteAttributes: ['香甜', '酥脆', '醇厚'],
      ingredients: ['鸭肉', '薄饼', '甜面酱', '黄瓜丝', '葱丝'],
      scenarios: ['正餐', '宴请'],
      calories: 520,
      rating: 4.8,
      ratingCount: 2100,
      imageUrl: 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400',
      price: 128.0,
      restaurant: '京味楼',
    ),
    Food(
      id: '4',
      name: '日式拉面',
      description: '日本经典面食，汤头浓郁，面条Q弹，配以叉烧、溏心蛋',
      cuisineType: '日料',
      tasteAttributes: ['鲜美', '浓郁', '清香'],
      ingredients: ['拉面', '叉烧', '溏心蛋', '海苔', '笋干'],
      scenarios: ['正餐', '夜宵'],
      calories: 420,
      rating: 4.5,
      ratingCount: 1680,
      imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400',
      price: 45.0,
      restaurant: '拉面道',
    ),
    Food(
      id: '5',
      name: '意大利肉酱面',
      description: '意式经典，肉酱浓郁，面条al dente，撒以帕尔马干酪',
      cuisineType: '西餐',
      tasteAttributes: ['浓郁', '香甜', '奶香'],
      ingredients: ['意面', '牛肉酱', '番茄', '洋葱', '帕尔马干酪'],
      scenarios: ['正餐', '约会'],
      calories: 480,
      rating: 4.3,
      ratingCount: 756,
      imageUrl: 'https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=400',
      price: 52.0,
      restaurant: '意式餐厅',
    ),
  ];

  /// 获取所有食物
  static List<Food> getAllFoods() {
    return List.from(_foods);
  }

  /// 根据ID获取食物
  static Food? getFoodById(String id) {
    try {
      return _foods.firstWhere((food) => food.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 根据菜系获取食物
  static List<Food> getFoodsByCuisine(String cuisineType) {
    return _foods.where((food) => food.cuisineType == cuisineType).toList();
  }

  /// 根据口味获取食物
  static List<Food> getFoodsByTaste(List<String> tastes) {
    return _foods.where((food) {
      return (food.tasteAttributes ?? const []).any((taste) => tastes.contains(taste));
    }).toList();
  }

  /// 搜索食物
  static List<Food> searchFoods(String query) {
    final lowerQuery = query.toLowerCase();
    return _foods.where((food) {
      return food.name.toLowerCase().contains(lowerQuery) ||
          (food.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          (food.cuisineType ?? '').toLowerCase().contains(lowerQuery) ||
          (food.tasteAttributes ?? const [])
              .any((taste) => taste.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// 获取热门食物
  static List<Food> getPopularFoods({int limit = 10}) {
    final sorted = List<Food>.from(_foods);
    sorted.sort((a, b) {
      final aScore = a.rating * (a.ratingCount ?? 0);
      final bScore = b.rating * (b.ratingCount ?? 0);
      return bScore.compareTo(aScore);
    });
    return sorted.take(limit).toList();
  }

  /// 获取高评分食物
  static List<Food> getHighRatedFoods({double minRating = 4.0, int limit = 10}) {
    final filtered = _foods.where((food) => food.rating >= minRating).toList();
    filtered.sort((a, b) => b.rating.compareTo(a.rating));
    return filtered.take(limit).toList();
  }
}
