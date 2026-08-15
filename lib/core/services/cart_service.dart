import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item.dart';

/// 购物车服务 - 单例模式
/// 负责购物车数据的增删改查和持久化存储
class CartService {
  static const String _cartBoxName = 'cart_box';
  static late Box<dynamic> _cartBox;

  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

  // ============ Getters ============

  /// 获取购物车商品列表（不可变副本）
  List<CartItem> get items => List.unmodifiable(_items);

  /// 商品总数量
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// 商品小计金额
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// 是否为空
  bool get isEmpty => _items.isEmpty;

  /// 商品种类数
  int get uniqueItemCount => _items.length;

  // ============ 初始化 ============

  /// 初始化购物车服务，加载本地存储数据
  static Future<void> initialize() async {
    try {
      _cartBox = await Hive.openBox<dynamic>(_cartBoxName);
      debugPrint('CartService: Hive box opened');
      await _instance._loadFromStorage();
    } catch (e) {
      debugPrint('CartService initialization failed: $e');
    }
  }

  // ============ 增删改查操作 ============

  /// 添加商品到购物车
  /// 如果商品已存在（相同foodId + 相同规格），则累加数量
  Future<void> addItem(CartItem item) async {
    // 查找是否有相同商品（foodId + specs相同）
    final existingIndex = _items.indexWhere(
      (existing) =>
          existing.foodId == item.foodId &&
          _specsEqual(existing.specs, item.specs),
    );

    if (existingIndex != -1) {
      // 累加数量
      _items[existingIndex].quantity += item.quantity;
      debugPrint('CartService: Updated quantity for "${item.name}", new quantity: ${_items[existingIndex].quantity}');
    } else {
      // 添加新商品
      _items.add(item);
      debugPrint('CartService: Added "${item.name}" to cart');
    }

    await _saveToStorage();
  }

  /// 移除商品
  Future<void> removeItem(String itemId) async {
    final existed = _items.any((item) => item.id == itemId);
    _items.removeWhere((item) => item.id == itemId);
    if (existed) {
      debugPrint('CartService: Removed item $itemId');
      await _saveToStorage();
    }
  }

  /// 更新商品数量
  Future<void> updateQuantity(String itemId, int quantity) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _items[index].quantity = quantity;
      debugPrint('CartService: Updated item $itemId quantity to $quantity');
      await _saveToStorage();
    }
  }

  /// 更新商品规格
  Future<void> updateSpecs(String itemId, Map<String, String> newSpecs) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(specs: newSpecs);
      debugPrint('CartService: Updated specs for item $itemId');
      await _saveToStorage();
    }
  }

  /// 清空购物车
  Future<void> clear() async {
    _items.clear();
    debugPrint('CartService: Cart cleared');
    await _saveToStorage();
  }

  // ============ 辅助方法 ============

  /// 检查规格是否相同
  bool _specsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  /// 检查商品是否在购物车中
  bool containsFood(String foodId) {
    return _items.any((item) => item.foodId == foodId);
  }

  /// 获取指定商品的数量
  int getQuantity(String foodId) {
    int total = 0;
    for (final item in _items) {
      if (item.foodId == foodId) {
        total += item.quantity;
      }
    }
    return total;
  }

  // ============ 持久化存储 ============

  /// 保存到本地存储
  Future<void> _saveToStorage() async {
    try {
      final data = _items.map((item) => item.toJson()).toList();
      await _cartBox.put('cart_items', data);
      debugPrint('CartService: Saved ${_items.length} items to storage');
    } catch (e) {
      debugPrint('CartService: Failed to save to storage: $e');
    }
  }

  /// 从本地存储加载数据
  Future<void> _loadFromStorage() async {
    try {
      final data = _cartBox.get('cart_items');
      if (data is List) {
        _items.clear();
        for (final item in data) {
          try {
            _items.add(CartItem.fromJson(Map<String, dynamic>.from(item as Map)));
          } catch (e) {
            debugPrint('CartService: Failed to parse cart item: $e');
          }
        }
        debugPrint('CartService: Loaded ${_items.length} items from storage');
      }
    } catch (e) {
      debugPrint('CartService: Failed to load from storage: $e');
    }
  }

  /// 销毁并清理
  static Future<void> dispose() async {
    try {
      await _cartBox.close();
      debugPrint('CartService: Box closed');
    } catch (e) {
      debugPrint('CartService: Failed to close box: $e');
    }
  }
}
