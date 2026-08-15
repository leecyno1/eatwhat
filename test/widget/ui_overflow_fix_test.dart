import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eatwhat_app/features/recipe/widgets/recipe_card.dart';
import 'package:eatwhat_app/core/models/recipe.dart';

void main() {
  group('UI溢出修复验证测试', () {
    testWidgets('RecipeCard应该没有溢出错误', (WidgetTester tester) async {
      // 创建测试数据
      final testRecipe = Recipe(
        id: 'test-1',
        name: '测试菜谱名称很长的情况下应该正确处理文本溢出问题',
        description: '这是一个很长的描述，用来测试UI组件是否能正确处理文本溢出的情况',
        cuisine: '川菜',
        cookingMethod: CookingMethod.stirFry,
        difficulty: RecipeDifficulty.medium,
        preparationTime: 15,
        cookingTime: 30,
        servings: 2,
        imageUrl: 'https://example.com/img.png',
        tags: ['测试', 'UI'],
        ingredients: [
          RecipeIngredient(name: '测试食材1', amount: '100', unit: 'g', isMain: true),
          RecipeIngredient(name: '测试食材2', amount: '1', unit: '个'),
        ],
        steps: [
          CookingStep(stepNumber: 1, description: '步骤1'),
          CookingStep(stepNumber: 2, description: '步骤2'),
        ],
        nutrition: NutritionInfo(calories: 100, protein: 5),
        rating: 4.5,
        reviewCount: 1234,
        authorId: 'u1',
        authorName: 'tester',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
        seasonalInfo: SeasonalInfo(),
        equipment: CookingEquipment(),
      );

      // 构建测试Widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150, // 限制宽度测试溢出情况
              child: RecipeCard(recipe: testRecipe),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证没有溢出错误
      expect(tester.takeException(), isNull);

      // 验证组件正常渲染
      expect(find.text('测试菜谱名称很长的情况下应该正确处理文本溢出问题'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
    });

    testWidgets('ModernRecipeRecommendationScreen应该处理小屏幕', (WidgetTester tester) async {
      // 设置小屏幕尺寸
      await tester.binding.setSurfaceSize(Size(300, 600));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 300,
              height: 600,
              child: Text('Modern Recipe Screen Test'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证没有溢出错误
      expect(tester.takeException(), isNull);
    });

    testWidgets('Flexible布局应该正确工作', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100, // 非常小的宽度
              child: Row(
                children: [
                  Flexible(
                    flex: 2,
                    child: Container(
                      color: Colors.red,
                      child: Text('测试文本1'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    flex: 1,
                    child: Container(
                      color: Colors.blue,
                      child: Text('测试文本2'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证Flexible布局没有造成溢出
      expect(tester.takeException(), isNull);
      expect(find.text('测试文本1'), findsOneWidget);
      expect(find.text('测试文本2'), findsOneWidget);
    });
  });
}
