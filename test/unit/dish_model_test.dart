import 'package:eatwhat_app/v2/core/data/models/dish_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('统一库行会映射为菜品主实体', () {
    final dish = DishModel.fromUnifiedDbRow(_unifiedRow);

    expect(dish.id, 'dish-8');
    expect(dish.name, '可乐鸡翅');
    expect(dish.description, '甜咸收汁，适合下饭。');
    expect(dish.tags, containsAll(['家常', '下饭', '独食', '高蛋白']));
    expect(dish.source, 'unified_db');
    expect(dish.imageUrl, 'assets/images/prebuilt_dishes/dish-8-dish_768.jpg');
  });

  test('统一库 RecipeModel 的 id 同时提供 dishId 语义', () {
    final recipe = RecipeModel.fromUnifiedDbRow(_unifiedRow);

    expect(recipe.id, 'dish-8');
    expect(recipe.dishId, 'dish-8');
    expect(recipe.dish.id, 'dish-8');
    expect(recipe.dish.name, '可乐鸡翅');
    expect(recipe.dish.tags, recipe.tags);
  });

  test('AI 或外部菜谱也能形成稳定菜品身份', () {
    const recipe = RecipeModel(
      id: 'ai-golden-soup-beef',
      name: '金汤肥牛',
      description: '酸香热口，适合今晚。',
      tags: ['酸香', '热菜'],
      source: 'AI Recommendation',
    );

    expect(recipe.dishId, 'ai-golden-soup-beef');
    expect(recipe.dish.id, 'ai-golden-soup-beef');
    expect(recipe.dish.source, 'AI Recommendation');
  });
}

final _unifiedRow = <String, dynamic>{
  'dish_id': 'dish-8',
  'dish_name': '可乐鸡翅',
  'recipe_description': '甜咸收汁，适合下饭。',
  'ingredients': [
    {'name': '鸡翅'},
    {'name': '可乐'},
  ],
  'steps': [
    {'description': '鸡翅煎香。'},
    {'description': '加入可乐收汁。'},
  ],
  'difficulty': 2,
  'tags': ['家常', '下饭'],
  'scenes': ['独食'],
  'health_tags': ['高蛋白'],
  'source': 'unified_db',
  'cover_image_url': 'assets/images/prebuilt_dishes/dish-8-dish_768.jpg',
};
