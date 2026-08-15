import 'package:flutter/foundation.dart';
import '../../../core/models/cart_item.dart';
import '../../../core/models/food.dart';
import '../../../core/services/cart_service.dart';

/// 购物车控制器 - ChangeNotifier 模式
/// 负责购物车业务逻辑和UI状态管理
class CartController extends ChangeNotifier {
  final CartService _cartService = CartService();

  // ============ 状态 ============

  bool _isLoading = false;
  String? _errorMessage;

  // ============ Getters ============

  /// 购物车商品列表
  List<CartItem> get items => _cartService.items;

  /// 商品总数量（所有商品数量之和）
  int get itemCount => _cartService.itemCount;

  /// 商品种类数
  int get uniqueItemCount => _cartService.uniqueItemCount;

  /// 商品小计金额
  double get subtotal => _cartService.subtotal;

  /// 是否为空
  bool get isEmpty => _cartService.isEmpty;

  /// 加载状态
  bool get isLoading => _isLoading;

  /// 错误信息
  String? get errorMessage => _errorMessage;

  /// 估算配送费
  /// 满30元免配送费，否则5元基础配送费
  double get deliveryFee {
    if (subtotal >= 30) return 0;
    return 5.0;
  }

  /// 订单总金额
  double get total => subtotal + deliveryFee;

  /// 配送费减免提示
  String get deliveryFeeHint {
    if (subtotal >= 30) return '已免配送费';
    final remaining = (30 - subtotal).toStringAsFixed(1);
    return '再买$remaining元免配送费';
  }

  // ============ 购物车操作 ============

  /// 添加商品到购物车
  Future<void> addToCart(
    Food food, {
    int quantity = 1,
    Map<String, String>? specs,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 获取价格（优先使用food.price）
      final price = food.price ?? 0.0;

      // 创建购物车商品
      final cartItem = CartItem(
        id: '${food.id}_${DateTime.now().millisecondsSinceEpoch}',
        foodId: food.id,
        name: food.name,
        imageUrl: food.imageUrl,
        price: price,
        quantity: quantity,
        specs: specs ?? {},
        recipeId: null,
      );

      await _cartService.addItem(cartItem);
      debugPrint('CartController: Added "${food.name}" to cart');
    } catch (e) {
      _errorMessage = '添加失败: $e';
      debugPrint('CartController: Error adding to cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 添加商品到购物车（通过菜谱）
  Future<void> addRecipeToCart({
    required String recipeId,
    required String name,
    String? imageUrl,
    required double price,
    int quantity = 1,
    Map<String, String>? specs,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cartItem = CartItem(
        id: '${recipeId}_${DateTime.now().millisecondsSinceEpoch}',
        foodId: recipeId,
        name: name,
        imageUrl: imageUrl,
        price: price,
        quantity: quantity,
        specs: specs ?? {},
        recipeId: recipeId,
      );

      await _cartService.addItem(cartItem);
      debugPrint('CartController: Added recipe "$name" to cart');
    } catch (e) {
      _errorMessage = '添加失败: $e';
      debugPrint('CartController: Error adding recipe to cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 从购物车移除商品
  Future<void> removeFromCart(String itemId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cartService.removeItem(itemId);
      debugPrint('CartController: Removed item $itemId');
    } catch (e) {
      _errorMessage = '移除失败: $e';
      debugPrint('CartController: Error removing from cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 更新商品数量
  Future<void> updateQuantity(String itemId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(itemId);
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cartService.updateQuantity(itemId, quantity);
      debugPrint('CartController: Updated item $itemId quantity to $quantity');
    } catch (e) {
      _errorMessage = '更新失败: $e';
      debugPrint('CartController: Error updating quantity: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 增加商品数量
  Future<void> incrementQuantity(String itemId) async {
    final item = items.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw Exception('Item not found'),
    );
    await updateQuantity(itemId, item.quantity + 1);
  }

  /// 减少商品数量
  Future<void> decrementQuantity(String itemId) async {
    final item = items.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw Exception('Item not found'),
    );
    await updateQuantity(itemId, item.quantity - 1);
  }

  /// 清空购物车
  Future<void> clearCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cartService.clear();
      debugPrint('CartController: Cart cleared');
    } catch (e) {
      _errorMessage = '清空失败: $e';
      debugPrint('CartController: Error clearing cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 更新商品规格
  Future<void> updateSpecs(String itemId, Map<String, String> newSpecs) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cartService.updateSpecs(itemId, newSpecs);
      debugPrint('CartController: Updated specs for item $itemId');
    } catch (e) {
      _errorMessage = '更新规格失败: $e';
      debugPrint('CartController: Error updating specs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ 辅助方法 ============

  /// 检查商品是否在购物车中
  bool isInCart(String foodId) {
    return _cartService.containsFood(foodId);
  }

  /// 获取指定商品在购物车中的数量
  int getCartQuantity(String foodId) {
    return _cartService.getQuantity(foodId);
  }

  /// 清除错误消息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
