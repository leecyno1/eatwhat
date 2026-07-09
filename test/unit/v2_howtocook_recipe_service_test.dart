import 'package:eatwhat_app/v2/core/data/models/howtocook_recipe_detail.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HowToCook 服务可按菜名命中详情并带出本地图片资产', () async {
    final service = V2HowToCookRecipeService(
      searchLoader: (query, limit) async => [
        {
          'id': 'htc_1',
          'name': '黄焖鸡',
          'description': '一道十分下饭的美食',
          'difficulty': 3,
          'category': '荤菜',
          'cooking_time': 35,
          'servings': 2,
          'github_url': 'https://github.com/Anduin2017/HowToCook/.../黄焖鸡.md',
        },
      ],
      completeLoader: (recipeId) async => {
        'id': 'htc_1',
        'name': '黄焖鸡',
        'description': '一道十分下饭的美食',
        'difficulty': 3,
        'category': '荤菜',
        'cooking_time': 35,
        'servings': 2,
        'github_url': 'https://github.com/Anduin2017/HowToCook/.../黄焖鸡.md',
        'ingredients': [
          {'name': '鸡腿', 'amount': '2', 'unit': '只'},
          {'name': '香菇', 'amount': '5', 'unit': '朵'},
        ],
        'steps': [
          {'description': '鸡腿洗净剁块。'},
          {'description': '焖煮 15 分钟后加入青椒。'},
        ],
      },
      assetIndexLoader: () async => '''
{
  "items": [
    {
      "recipeId": "htc_1",
      "name": "黄焖鸡",
      "aliases": ["黄焖鸡"],
      "assetImageUrls": ["assets/images/howtocook_gallery/huangmenji/1.jpg"],
      "markdownPath": "HowToCook/dishes/meat_dish/黄焖鸡.md",
      "sourceProject": "HowToCook"
    }
  ]
}
''',
    );

    final detail = await service.findBestDetailForRecipe(
      const RecipeModel(
        id: '19',
        name: '黄焖鸡',
        description: '统一库里的简化描述',
      ),
    );

    expect(detail, isNotNull);
    expect(detail!.id, 'htc_1');
    expect(detail.ingredients, contains('鸡腿 2只'));
    expect(detail.steps, contains('鸡腿洗净剁块。'));
    expect(detail.imageAssetUrls.first,
        'assets/images/howtocook_gallery/huangmenji/1.jpg');
  });

  test('HowToCook 服务可将推荐菜补全为完整 RecipeModel', () async {
    final service = V2HowToCookRecipeService(
      searchLoader: (query, limit) async => [
        {
          'id': 'htc_2',
          'name': '地三鲜',
          'description': '经典东北家常菜',
          'difficulty': 3,
          'category': '素菜',
          'cooking_time': 20,
          'servings': 2,
        },
      ],
      completeLoader: (recipeId) async => {
        'id': 'htc_2',
        'name': '地三鲜',
        'description': '经典东北家常菜',
        'difficulty': 3,
        'category': '素菜',
        'cooking_time': 20,
        'servings': 2,
        'ingredients': [
          {'name': '土豆', 'amount': '150', 'unit': 'g'},
          {'name': '茄子', 'amount': '100', 'unit': 'g'},
        ],
        'steps': [
          {'description': '土豆煎炸至微黄。'},
          {'description': '加入茄子和尖椒翻炒。'},
        ],
      },
      assetIndexLoader: () async => '''
{
  "items": [
    {
      "recipeId": "htc_2",
      "name": "地三鲜",
      "aliases": ["地三鲜"],
      "assetImageUrls": ["assets/images/howtocook_gallery/disanxian/1.jpg"],
      "markdownPath": "HowToCook/dishes/vegetable_dish/地三鲜.md",
      "sourceProject": "HowToCook"
    }
  ]
}
''',
    );

    final enriched = await service.enrichRecipe(
      const RecipeModel(
        id: '23',
        name: '地三鲜',
        description: '统一库简述',
      ),
    );

    expect(enriched.description, '经典东北家常菜');
    expect(enriched.ingredients, contains('土豆 150g'));
    expect(enriched.steps, contains('加入茄子和尖椒翻炒。'));
    expect(
        enriched.imageUrl, 'assets/images/howtocook_gallery/disanxian/1.jpg');
    expect(enriched.tags, contains('素菜'));
  });

  test('HowToCook 菜谱库可返回摘要列表', () async {
    final service = V2HowToCookRecipeService(
      allRecipesLoader: (limit) async => [
        {
          'id': 'htc_1',
          'name': '黄焖鸡',
          'description': '下饭热菜',
          'difficulty': 3,
          'category': '荤菜',
          'cooking_time': 35,
          'servings': 2,
        },
        {
          'id': 'htc_2',
          'name': '蒜蓉西兰花',
          'description': '清爽快手蔬菜',
          'difficulty': 2,
          'category': '素菜',
          'cooking_time': 10,
          'servings': 2,
        },
      ],
      assetIndexLoader: () async => '''
{
  "items": [
    {
      "recipeId": "htc_2",
      "name": "蒜蓉西兰花",
      "aliases": ["蒜蓉西兰花"],
      "assetImageUrls": ["assets/images/howtocook_gallery/xilanhua/1.jpg"],
      "markdownPath": "HowToCook/dishes/vegetable_dish/蒜蓉西兰花.md",
      "sourceProject": "HowToCook"
    }
  ]
}
''',
    );

    final items = await service.getLibraryRecipes(limit: 20);

    expect(items, hasLength(2));
    expect(items.last.imageAssetUrls.first,
        'assets/images/howtocook_gallery/xilanhua/1.jpg');
  });

  test('HowToCook 服务可返回分类列表并按分类过滤菜谱库', () async {
    final service = V2HowToCookRecipeService(
      allRecipesLoader: (limit) async => [
        {
          'id': 'htc_1',
          'name': '黄焖鸡',
          'description': '下饭热菜',
          'difficulty': 3,
          'category': '荤菜',
          'cooking_time': 35,
          'servings': 2,
        },
        {
          'id': 'htc_2',
          'name': '蒜蓉西兰花',
          'description': '清爽快手蔬菜',
          'difficulty': 2,
          'category': '素菜',
          'cooking_time': 10,
          'servings': 2,
        },
        {
          'id': 'htc_3',
          'name': '冬瓜排骨汤',
          'description': '清润热汤',
          'difficulty': 2,
          'category': '汤羹',
          'cooking_time': 40,
          'servings': 3,
        },
      ],
      assetIndexLoader: () async => '{"items":[]}',
    );

    final categories = await service.getLibraryCategories();
    final soups = await service.getLibraryRecipes(
      category: '汤羹',
      limit: 20,
    );

    expect(categories, containsAll(<String>['荤菜', '素菜', '汤羹']));
    expect(soups, hasLength(1));
    expect(soups.first.name, '冬瓜排骨汤');
  });

  test('HowToCook 服务可返回相似菜推荐', () async {
    final service = V2HowToCookRecipeService(
      allRecipesLoader: (limit) async => [
        {
          'id': 'htc_1',
          'name': '黄焖鸡',
          'description': '下饭热菜',
          'difficulty': 3,
          'category': '荤菜',
          'subcategory': '家常',
        },
        {
          'id': 'htc_2',
          'name': '可乐鸡翅',
          'description': '甜咸下饭',
          'difficulty': 2,
          'category': '荤菜',
          'subcategory': '家常',
        },
        {
          'id': 'htc_3',
          'name': '蒜蓉西兰花',
          'description': '清爽快手蔬菜',
          'difficulty': 2,
          'category': '素菜',
          'subcategory': '家常',
        },
      ],
      assetIndexLoader: () async => '{"items":[]}',
    );

    final related = await service.getRelatedRecipes(
      const RecipeModel(
        id: 'htc_1',
        name: '黄焖鸡',
        description: '下饭热菜',
        tags: ['荤菜', '家常'],
      ),
      limit: 3,
    );

    expect(related, hasLength(1));
    expect(related.first.name, '可乐鸡翅');
  });
}
