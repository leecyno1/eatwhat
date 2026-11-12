import 'package:eatwhat_app/v2/core/data/models/howtocook_recipe_detail.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/services/recipe_eligibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> completeRow() => {
        'dish_id': 101,
        'dish_name': '完整菜谱',
        'ingredients': [
          for (var i = 0; i < 12; i++) {'name': '蔬菜$i'},
          {'name': '花生油'},
        ],
        'steps': [
          for (var i = 0; i < 14; i++) {'description': '第${i + 1}步'},
          {'description': '确认全部食材熟透后出锅'},
        ],
        'tags': [for (var i = 0; i < 15; i++) '标签$i'],
      };

  test('完整食材不能因预览长度而在领域模型中丢失', () {
    final recipe = RecipeModel.fromUnifiedDbRow(completeRow());
    expect(recipe.ingredients, hasLength(13));
    expect(recipe.ingredients.last, '花生油');
    final eligibility = RecipeEligibility(dietaryRestrictions: ['花生']);
    expect(
      eligibility
          .evaluate(name: recipe.name, ingredients: recipe.ingredients)
          .allowed,
      isFalse,
    );
  });

  test('烹饪步骤和标签完整保留，显示层自行决定摘要长度', () {
    final recipe = RecipeModel.fromUnifiedDbRow(completeRow());
    expect(recipe.steps, hasLength(15));
    expect(recipe.steps.last, '确认全部食材熟透后出锅');
    expect(recipe.tags, hasLength(15));
  });

  test('统一库行保留已核验耗时与份量，缺省值不伪装成有效数据', () {
    final recipe = RecipeModel.fromUnifiedDbRow({
      ...completeRow(),
      'total_time_minutes': 35,
      'servings': 4,
    });
    expect(recipe.totalTimeMinutes, 35);
    expect(recipe.servings, 4);

    final unknown = RecipeModel.fromUnifiedDbRow({
      ...completeRow(),
      'total_time_minutes': null,
      'servings': 0,
    });
    expect(unknown.totalTimeMinutes, 0);
    expect(unknown.servings, 1);
  });

  test('统一库行保留食材用量与单位，做菜和购物清单不再丢数量', () {
    final recipe = RecipeModel.fromUnifiedDbRow({
      'dish_id': 9,
      'dish_name': '黄焖鸡',
      'ingredients': [
        {'name': '鸡腿', 'amount': '2', 'unit': '只'},
        {'name': '香菇', 'amount': '5', 'unit': '朵'},
        {'name': '盐'},
      ],
      'steps': [
        {'description': '焖煮'},
      ],
    });

    expect(recipe.ingredients, ['鸡腿 2只', '香菇 5朵', '盐']);
  });

  test('HowToCook 详情转换不把来源占位耗时/份量伪装成菜谱核验数据', () {
    const detail = HowToCookRecipeDetail(
      id: 'htc_1',
      name: '黄焖鸡',
      description: '',
      ingredients: ['鸡腿 2只'],
      steps: ['焖煮'],
      imageAssetUrls: [],
      category: '荤菜',
      subcategory: '家常',
      difficulty: 3,
      cookingTimeMinutes: 15,
      servings: 4,
      githubUrl: '',
      sourceProject: 'HowToCook',
      markdownPath: '',
    );

    final recipe = detail.toRecipeModel();

    expect(recipe.totalTimeMinutes, 0);
    expect(recipe.servings, 1);
  });
}
