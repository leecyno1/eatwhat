import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food.dart';
import '../models/bubble.dart';
import '../models/user_preference.dart';
import '../services/unified_food_data_service.dart';

/// Food数据状态
class FoodState {
  final List<Food> foods;
  final bool isLoading;
  final String? error;

  const FoodState({
    this.foods = const [],
    this.isLoading = false,
    this.error,
  });

  FoodState copyWith({
    List<Food>? foods,
    bool? isLoading,
    String? error,
  }) {
    return FoodState(
      foods: foods ?? this.foods,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Food数据Provider
class FoodNotifier extends StateNotifier<FoodState> {
  final UnifiedFoodDataService _foodService;

  FoodNotifier(this._foodService) : super(const FoodState());

  /// 加载所有食物
  Future<void> loadFoods() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 使用空的气泡列表和默认用户偏好
      final foods = await _foodService.getRecommendations(
        [],
        UserPreference(userId: 'default'),
        limit: 50,
      );
      state = state.copyWith(
        foods: foods,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 根据ID获取食物
  Future<Food?> getFoodById(String id) async {
    try {
      // 从当前状态中查找
      return state.foods.firstWhere(
        (food) => food.id == id,
        orElse: () => throw Exception('Food not found'),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// 搜索食物
  Future<void> searchFoods(String query) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 使用推荐系统进行搜索
      final foods = await _foodService.getRecommendations(
        [],
        UserPreference(userId: 'default'),
        limit: 20,
      );
      // 简单的客户端过滤
      final filtered = foods.where((food) =>
        food.name.toLowerCase().contains(query.toLowerCase())
      ).toList();

      state = state.copyWith(
        foods: filtered,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 按分类获取食物
  Future<void> getFoodsByCategory(String category) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final foods = await _foodService.getRecommendations(
        [],
        UserPreference(userId: 'default'),
        limit: 30,
      );
      // 简单的客户端过滤
      final filtered = foods.where((food) =>
        food.tags.contains(category)
      ).toList();

      state = state.copyWith(
        foods: filtered,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 清空错误
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Food Provider定义
final foodProvider = StateNotifierProvider<FoodNotifier, FoodState>((ref) {
  final foodService = UnifiedFoodDataService();
  return FoodNotifier(foodService);
});

/// 单个Food Provider（根据ID）
final foodByIdProvider = FutureProvider.family<Food?, String>((ref, id) async {
  final foodState = ref.watch(foodProvider);
  try {
    return foodState.foods.firstWhere(
      (food) => food.id == id,
    );
  } catch (e) {
    return null;
  }
});

/// 推荐食物Provider
final recommendedFoodsProvider = FutureProvider<List<Food>>((ref) async {
  final foodService = UnifiedFoodDataService();
  return await foodService.getRecommendations(
    [],
    UserPreference(userId: 'default'),
    limit: 10,
  );
});
