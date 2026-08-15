import 'package:flutter_test/flutter_test.dart';
import '../../helpers/fake_repositories.dart';

void main() {
  group('FoodService', () {
    late FakeFoodRepository fakeFoodRepository;

    setUp(() {
      fakeFoodRepository = FakeFoodRepository();
    });

    test('应该能获取所有食物列表', () async {
      // Act
      final foods = await fakeFoodRepository.getFoods();

      // Assert
      expect(foods, isNotEmpty);
      expect(foods.length, equals(3));
    });

    test('应该能按ID获取食物', () async {
      // Arrange
      const foodId = '1';

      // Act
      final food = await fakeFoodRepository.getFoodById(foodId);

      // Assert
      expect(food, isNotNull);
      expect(food?['id'], equals(foodId));
      expect(food?['name'], equals('宫保鸡丁'));
      expect(food?['price'], equals(28.0));
    });

    test('获取不存在的食物应该返回空', () async {
      // Arrange
      const nonExistentId = '999';

      // Act
      final food = await fakeFoodRepository.getFoodById(nonExistentId);

      // Assert
      expect(food, isEmpty);
    });

    test('食物列表应该包含正确的字段', () async {
      // Act
      final foods = await fakeFoodRepository.getFoods();
      final firstFood = foods.first;

      // Assert
      expect(firstFood.containsKey('id'), true);
      expect(firstFood.containsKey('name'), true);
      expect(firstFood.containsKey('price'), true);
    });
  });
}
