import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwhat_app/core/providers/app_providers.dart';

void main() {
  group('AppProviders - FavoritesProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始状态应该是空收藏列表', () {
      final state = container.read(favoritesProvider);
      expect(state.foodIds, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('应该能添加收藏', () {
      final notifier = container.read(favoritesProvider.notifier);

      notifier.addFavorite('food_001');

      final state = container.read(favoritesProvider);
      expect(state.foodIds, contains('food_001'));
      expect(state.foodIds.length, 1);
    });

    test('不应该重复添加相同的收藏', () {
      final notifier = container.read(favoritesProvider.notifier);

      notifier.addFavorite('food_001');
      notifier.addFavorite('food_001');

      final state = container.read(favoritesProvider);
      expect(state.foodIds.length, 1);
    });

    test('应该能移除收藏', () {
      final notifier = container.read(favoritesProvider.notifier);

      notifier.addFavorite('food_001');
      expect(container.read(favoritesProvider).foodIds, contains('food_001'));

      notifier.removeFavorite('food_001');

      final state = container.read(favoritesProvider);
      expect(state.foodIds, isNot(contains('food_001')));
    });

    test('应该能切换收藏状态', () {
      final notifier = container.read(favoritesProvider.notifier);

      // 添加
      notifier.toggleFavorite('food_001');
      expect(container.read(favoritesProvider).foodIds, contains('food_001'));

      // 移除
      notifier.toggleFavorite('food_001');
      expect(container.read(favoritesProvider).foodIds, isNot(contains('food_001')));
    });

    test('应该能检查是否已收藏', () {
      final notifier = container.read(favoritesProvider.notifier);

      expect(notifier.isFavorite('food_001'), false);

      notifier.addFavorite('food_001');

      expect(notifier.isFavorite('food_001'), true);
    });

    test('应该能清空所有收藏', () {
      final notifier = container.read(favoritesProvider.notifier);

      notifier.addFavorite('food_001');
      notifier.addFavorite('food_002');
      expect(container.read(favoritesProvider).foodIds.length, 2);

      notifier.clearAll();

      final state = container.read(favoritesProvider);
      expect(state.foodIds, isEmpty);
    });

    test('isFavoriteProvider应该返回正确的收藏状态', () {
      final notifier = container.read(favoritesProvider.notifier);

      expect(container.read(isFavoriteProvider('food_001')), false);

      notifier.addFavorite('food_001');

      expect(container.read(isFavoriteProvider('food_001')), true);
    });
  });

  group('AppProviders - CartProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始状态应该是空购物车', () {
      final state = container.read(cartProvider);
      expect(state.items, isEmpty);
      expect(state.totalPrice, 0.0);
      expect(state.totalQuantity, 0);
    });

    test('应该能添加商品到购物车', () {
      final notifier = container.read(cartProvider.notifier);

      const item = CartItem(
        foodId: 'food_001',
        name: '番茄鸡蛋面',
        quantity: 1,
        price: 15.0,
      );

      notifier.addItem(item);

      final state = container.read(cartProvider);
      expect(state.items.length, 1);
      expect(state.items.first.foodId, 'food_001');
    });

    test('添加相同商品应该增加数量', () {
      final notifier = container.read(cartProvider.notifier);

      const item = CartItem(
        foodId: 'food_001',
        name: '番茄鸡蛋面',
        quantity: 1,
        price: 15.0,
      );

      notifier.addItem(item);
      notifier.addItem(item);

      final state = container.read(cartProvider);
      expect(state.items.length, 1);
      expect(state.items.first.quantity, 2);
    });

    test('应该能移除商品', () {
      final notifier = container.read(cartProvider.notifier);

      const item = CartItem(
        foodId: 'food_001',
        name: '番茄鸡蛋面',
        quantity: 1,
        price: 15.0,
      );

      notifier.addItem(item);
      expect(container.read(cartProvider).items.length, 1);

      notifier.removeItem('food_001');

      final state = container.read(cartProvider);
      expect(state.items, isEmpty);
    });

    test('应该能更新商品数量', () {
      final notifier = container.read(cartProvider.notifier);

      const item = CartItem(
        foodId: 'food_001',
        name: '番茄鸡蛋面',
        quantity: 1,
        price: 15.0,
      );

      notifier.addItem(item);
      notifier.updateQuantity('food_001', 3);

      final state = container.read(cartProvider);
      expect(state.items.first.quantity, 3);
    });

    test('数量更新为0应该移除商品', () {
      final notifier = container.read(cartProvider.notifier);

      const item = CartItem(
        foodId: 'food_001',
        name: '番茄鸡蛋面',
        quantity: 1,
        price: 15.0,
      );

      notifier.addItem(item);
      notifier.updateQuantity('food_001', 0);

      final state = container.read(cartProvider);
      expect(state.items, isEmpty);
    });

    test('应该能清空购物车', () {
      final notifier = container.read(cartProvider.notifier);

      const item1 = CartItem(
        foodId: 'food_001',
        name: '番茄鸡蛋面',
        quantity: 1,
        price: 15.0,
      );

      const item2 = CartItem(
        foodId: 'food_002',
        name: '红烧肉',
        quantity: 2,
        price: 30.0,
      );

      notifier.addItem(item1);
      notifier.addItem(item2);
      expect(container.read(cartProvider).items.length, 2);

      notifier.clearCart();

      final state = container.read(cartProvider);
      expect(state.items, isEmpty);
    });

    test('应该正确计算总价', () {
      final notifier = container.read(cartProvider.notifier);

      const item1 = CartItem(
        foodId: 'food_001',
        name: '番茄鸡蛋面',
        quantity: 2,
        price: 15.0,
      );

      const item2 = CartItem(
        foodId: 'food_002',
        name: '红烧肉',
        quantity: 1,
        price: 30.0,
      );

      notifier.addItem(item1);
      notifier.addItem(item2);

      final state = container.read(cartProvider);
      expect(state.totalPrice, 60.0); // 2*15 + 1*30
    });

    test('应该正确计算总数量', () {
      final notifier = container.read(cartProvider.notifier);

      const item1 = CartItem(
        foodId: 'food_001',
        name: '番茄鸡蛋面',
        quantity: 2,
        price: 15.0,
      );

      const item2 = CartItem(
        foodId: 'food_002',
        name: '红烧肉',
        quantity: 3,
        price: 30.0,
      );

      notifier.addItem(item1);
      notifier.addItem(item2);

      final state = container.read(cartProvider);
      expect(state.totalQuantity, 5); // 2 + 3
    });

    test('cartTotalPriceProvider应该返回正确的总价', () {
      final notifier = container.read(cartProvider.notifier);

      const item = CartItem(
        foodId: 'food_001',
        name: '番茄鸡蛋面',
        quantity: 2,
        price: 15.0,
      );

      notifier.addItem(item);

      expect(container.read(cartTotalPriceProvider), 30.0);
    });

    test('cartTotalQuantityProvider应该返回正确的总数量', () {
      final notifier = container.read(cartProvider.notifier);

      const item = CartItem(
        foodId: 'food_001',
        name: '番茄鸡蛋面',
        quantity: 3,
        price: 15.0,
      );

      notifier.addItem(item);

      expect(container.read(cartTotalQuantityProvider), 3);
    });
  });

  group('AppProviders - AppInitProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始状态应该是未初始化', () {
      final state = container.read(appInitProvider);
      expect(state.isInitialized, false);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('应该能初始化应用', () async {
      final notifier = container.read(appInitProvider.notifier);

      await notifier.initialize();

      final state = container.read(appInitProvider);
      expect(state.isInitialized, true);
      expect(state.isLoading, false);
    });
  });

  group('AppProviders - StateProviders', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('themeModeStateProvider应该有默认值', () {
      final themeMode = container.read(themeModeStateProvider);
      expect(themeMode, ThemeMode.system);
    });

    test('languageStateProvider应该有默认值', () {
      final language = container.read(languageStateProvider);
      expect(language, 'zh');
    });

    test('bottomNavIndexProvider应该有默认值', () {
      final index = container.read(bottomNavIndexProvider);
      expect(index, 0);
    });

    test('searchQueryProvider应该有默认值', () {
      final query = container.read(searchQueryProvider);
      expect(query, '');
    });

    test('应该能更新bottomNavIndex', () {
      container.read(bottomNavIndexProvider.notifier).state = 2;
      expect(container.read(bottomNavIndexProvider), 2);
    });

    test('应该能更新searchQuery', () {
      container.read(searchQueryProvider.notifier).state = '番茄';
      expect(container.read(searchQueryProvider), '番茄');
    });
  });
}
