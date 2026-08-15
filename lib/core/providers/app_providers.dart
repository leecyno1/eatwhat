import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/unified_food_data_service.dart';
import '../services/recipe_database_service.dart';
import '../services/howtocook_database_service.dart';
import '../services/vectorized_recommendation_engine.dart';
import '../services/user_preference_manager.dart';
import '../services/analytics_service.dart';
import '../services/analytics_helper.dart';

/// ========== 服务层 Providers ==========

/// UnifiedFoodDataService Provider
final unifiedFoodDataServiceProvider = Provider<UnifiedFoodDataService>((ref) {
  return UnifiedFoodDataService();
});

/// RecipeDatabaseService Provider
final recipeDatabaseServiceProvider = Provider<RecipeDatabaseService>((ref) {
  return RecipeDatabaseService();
});

/// HowToCookDatabaseService Provider
final howToCookDatabaseServiceProvider = Provider<HowToCookDatabaseService>((ref) {
  return HowToCookDatabaseService();
});

/// VectorizedRecommendationEngine Provider
final recommendationEngineProvider = Provider<VectorizedRecommendationEngine>((ref) {
  return VectorizedRecommendationEngine();
});

/// UserPreferenceManager Provider
final userPreferenceManagerProvider = Provider<UserPreferenceManager>((ref) {
  return UserPreferenceManager();
});

/// AnalyticsService Provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// ========== 应用状态 Providers ==========

/// 应用初始化状态
class AppInitState {
  final bool isInitialized;
  final bool isLoading;
  final String? error;

  const AppInitState({
    this.isInitialized = false,
    this.isLoading = false,
    this.error,
  });

  AppInitState copyWith({
    bool? isInitialized,
    bool? isLoading,
    String? error,
  }) {
    return AppInitState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 应用初始化 Provider
class AppInitNotifier extends StateNotifier<AppInitState> {
  AppInitNotifier() : super(const AppInitState());

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 初始化各种服务
      await Future.delayed(const Duration(milliseconds: 500));

      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final appInitProvider = StateNotifierProvider<AppInitNotifier, AppInitState>((ref) {
  return AppInitNotifier();
});

/// ========== UI状态 Providers ==========

/// 主题模式状态
enum ThemeMode {
  light,
  dark,
  system,
}

/// 主题模式 Provider
final themeModeStateProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

/// 语言状态 Provider
final languageStateProvider = StateProvider<String>((ref) {
  return 'zh';
});

/// 底部导航栏索引 Provider
final bottomNavIndexProvider = StateProvider<int>((ref) {
  return 0;
});

/// 搜索查询 Provider
final searchQueryProvider = StateProvider<String>((ref) {
  return '';
});

/// ========== 功能特性 Providers ==========

/// 收藏列表状态
class FavoritesState {
  final List<String> foodIds;
  final bool isLoading;
  final String? error;

  const FavoritesState({
    this.foodIds = const [],
    this.isLoading = false,
    this.error,
  });

  FavoritesState copyWith({
    List<String>? foodIds,
    bool? isLoading,
    String? error,
  }) {
    return FavoritesState(
      foodIds: foodIds ?? this.foodIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 收藏列表 Notifier
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier() : super(const FavoritesState());

  /// 添加收藏
  void addFavorite(String foodId) {
    if (!state.foodIds.contains(foodId)) {
      state = state.copyWith(
        foodIds: [...state.foodIds, foodId],
      );
    }
  }

  /// 移除收藏
  void removeFavorite(String foodId) {
    state = state.copyWith(
      foodIds: state.foodIds.where((id) => id != foodId).toList(),
    );
  }

  /// 切换收藏状态
  void toggleFavorite(String foodId) {
    if (state.foodIds.contains(foodId)) {
      removeFavorite(foodId);
    } else {
      addFavorite(foodId);
    }
  }

  /// 检查是否已收藏
  bool isFavorite(String foodId) {
    return state.foodIds.contains(foodId);
  }

  /// 清空收藏
  void clearAll() {
    state = const FavoritesState();
  }
}

/// 收藏列表 Provider
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  return FavoritesNotifier();
});

/// 检查是否已收藏 Provider
final isFavoriteProvider = Provider.family<bool, String>((ref, foodId) {
  return ref.watch(favoritesProvider).foodIds.contains(foodId);
});

/// ========== 购物车 Providers ==========

/// 购物车项
class CartItem {
  final String foodId;
  final String name;
  final int quantity;
  final double price;

  const CartItem({
    required this.foodId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  CartItem copyWith({
    String? foodId,
    String? name,
    int? quantity,
    double? price,
  }) {
    return CartItem(
      foodId: foodId ?? this.foodId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }
}

/// 购物车状态
class CartState {
  final List<CartItem> items;
  final bool isLoading;
  final String? error;

  const CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// 计算总价
  double get totalPrice {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  /// 计算总数量
  int get totalQuantity {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }
}

/// 购物车 Notifier
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  /// 添加到购物车
  void addItem(CartItem item) {
    final existingIndex = state.items.indexWhere((i) => i.foodId == item.foodId);

    if (existingIndex >= 0) {
      // 更新数量
      final updatedItems = [...state.items];
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + item.quantity,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      // 添加新项
      state = state.copyWith(items: [...state.items, item]);
    }
  }

  /// 移除项
  void removeItem(String foodId) {
    state = state.copyWith(
      items: state.items.where((item) => item.foodId != foodId).toList(),
    );
  }

  /// 更新数量
  void updateQuantity(String foodId, int quantity) {
    if (quantity <= 0) {
      removeItem(foodId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.foodId == foodId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  /// 清空购物车
  void clearCart() {
    state = const CartState();
  }
}

/// 购物车 Provider
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

/// 购物车总价 Provider
final cartTotalPriceProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).totalPrice;
});

/// 购物车总数量 Provider
final cartTotalQuantityProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).totalQuantity;
});
