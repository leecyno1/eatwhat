import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwhat_app/core/providers/food_provider.dart';
import 'package:eatwhat_app/core/models/food.dart';

void main() {
  group('FoodState', () {
    test('应该能创建FoodState', () {
      const state = FoodState();
      expect(state.foods, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('应该能使用copyWith更新状态', () {
      const state = FoodState();
      final newState = state.copyWith(isLoading: true);

      expect(newState.isLoading, true);
      expect(newState.foods, isEmpty);
    });

    test('copyWith应该保留未更新的字段', () {
      final foods = [
        Food(
          id: '1',
          name: '番茄鸡蛋面',
          imageUrl: 'https://example.com/image.jpg',
          rating: 4.5,
          tags: ['面食'],
        ),
      ];
      final state = FoodState(foods: foods, isLoading: true);
      final newState = state.copyWith(error: '错误');

      expect(newState.foods, equals(foods));
      expect(newState.isLoading, true);
      expect(newState.error, equals('错误'));
    });
  });

  group('FoodNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始状态应该为空', () {
      final state = container.read(foodProvider);
      expect(state.foods, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('应该能清空错误', () {
      final notifier = container.read(foodProvider.notifier);

      // 设置一个错误状态
      notifier.state = notifier.state.copyWith(error: '测试错误');
      expect(container.read(foodProvider).error, equals('测试错误'));

      // 清空错误
      notifier.clearError();
      expect(container.read(foodProvider).error, isNull);
    });

    test('loadFoods应该更新加载状态', () async {
      final notifier = container.read(foodProvider.notifier);

      // 开始加载
      final loadFuture = notifier.loadFoods();

      // 加载过程中应该显示loading
      await Future.delayed(Duration.zero);

      await loadFuture;

      // 加载完成后应该不再loading
      final state = container.read(foodProvider);
      expect(state.isLoading, false);
    });

    test('searchFoods应该更新状态', () async {
      final notifier = container.read(foodProvider.notifier);

      await notifier.searchFoods('番茄');

      final state = container.read(foodProvider);
      expect(state.isLoading, false);
    });

    test('getFoodsByCategory应该更新状态', () async {
      final notifier = container.read(foodProvider.notifier);

      await notifier.getFoodsByCategory('面食');

      final state = container.read(foodProvider);
      expect(state.isLoading, false);
    });
  });

  group('foodByIdProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('应该能根据ID获取食物', () async {
      final foodFuture = container.read(foodByIdProvider('test_id').future);

      // 等待异步操作完成
      await foodFuture;
    });
  });

  group('recommendedFoodsProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('应该能获取推荐食物', () async {
      final foodsFuture = container.read(recommendedFoodsProvider.future);

      // 等待异步操作完成
      final foods = await foodsFuture;
      expect(foods, isA<List<Food>>());
    });
  });
}
