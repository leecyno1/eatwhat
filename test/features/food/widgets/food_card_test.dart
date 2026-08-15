import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwhat_app/features/food/widgets/food_card.dart';
import 'package:eatwhat_app/core/models/food.dart';
import 'package:eatwhat_app/core/providers/food_provider.dart';
import 'package:eatwhat_app/core/services/unified_food_data_service.dart';

void main() {
  group('FoodCard', () {
    late Food testFood;

    setUp(() {
      testFood = Food(
        id: '1',
        name: '番茄鸡蛋面',
        imageUrl: 'https://example.com/image.jpg',
        rating: 4.5,
        tags: ['面食', '快手菜', '家常'],
      );
    });

    testWidgets('应该显示食物名称', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FoodCard(food: testFood),
            ),
          ),
        ),
      );

      expect(find.text('番茄鸡蛋面'), findsOneWidget);
    });

    testWidgets('应该显示评分', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FoodCard(food: testFood),
            ),
          ),
        ),
      );

      expect(find.text('4.5'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('应该显示标签', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FoodCard(food: testFood),
            ),
          ),
        ),
      );

      expect(find.text('面食'), findsOneWidget);
      expect(find.text('快手菜'), findsOneWidget);
      expect(find.text('家常'), findsOneWidget);
    });

    testWidgets('应该显示收藏按钮', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FoodCard(food: testFood),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('可以隐藏收藏按钮', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FoodCard(
                food: testFood,
                showFavoriteButton: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('应该响应点击事件', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FoodCard(
                food: testFood,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FoodCard));
      await tester.pump();
      expect(tapped, true);
    });

    testWidgets('没有图片时应该显示占位符', (tester) async {
      final foodWithoutImage = Food(
        id: '2',
        name: '测试食物',
        tags: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FoodCard(food: foodWithoutImage),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('没有评分时不应该显示评分', (tester) async {
      final foodWithoutRating = Food(
        id: '3',
        name: '测试食物',
        tags: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FoodCard(food: foodWithoutRating),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('标签超过3个时只显示前3个', (tester) async {
      final foodWithManyTags = Food(
        id: '4',
        name: '测试食物',
        tags: ['标签1', '标签2', '标签3', '标签4', '标签5'],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FoodCard(food: foodWithManyTags),
            ),
          ),
        ),
      );

      expect(find.text('标签1'), findsOneWidget);
      expect(find.text('标签2'), findsOneWidget);
      expect(find.text('标签3'), findsOneWidget);
      expect(find.text('标签4'), findsNothing);
      expect(find.text('标签5'), findsNothing);
    });
  });

  group('FoodList', () {
    testWidgets('加载中时应该显示进度指示器', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            foodProvider.overrideWith((ref) {
              return MockFoodNotifier(const FoodState(isLoading: true));
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FoodList(),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('有错误时应该显示错误信息', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            foodProvider.overrideWith((ref) {
              return MockFoodNotifier(const FoodState(error: '加载失败'));
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FoodList(),
            ),
          ),
        ),
      );

      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('没有数据时应该显示空状态', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            foodProvider.overrideWith((ref) {
              return MockFoodNotifier(const FoodState());
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FoodList(),
            ),
          ),
        ),
      );

      expect(find.text('暂无数据'), findsOneWidget);
    });

    testWidgets('应该显示食物列表', (tester) async {
      final foods = [
        Food(id: '1', name: '食物1', tags: []),
        Food(id: '2', name: '食物2', tags: []),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            foodProvider.overrideWith((ref) {
              return MockFoodNotifier(FoodState(foods: foods));
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FoodList(),
            ),
          ),
        ),
      );

      expect(find.byType(FoodCard), findsNWidgets(2));
    });
  });
}

// Mock notifier for testing
class MockFoodNotifier extends FoodNotifier {
  MockFoodNotifier(FoodState initialState) : super(UnifiedFoodDataService()) {
    state = initialState;
  }

  @override
  Future<void> loadFoods() async {
    // Do nothing in mock
  }
}
