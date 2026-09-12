import 'package:eatwhat_app/v2/core/services/generation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GenerationService 能解析 MiniMax image_urls 数组', () {
    final url = GenerationService.extractMiniMaxImageUrl({
      'data': {
        'image_urls': [
          'https://example.com/generated-dish.jpg',
        ],
      },
      'base_resp': {
        'status_code': 0,
        'status_msg': 'success',
      },
    });

    expect(url, 'https://example.com/generated-dish.jpg');
  });

  group('parseFusionDishes', () {
    test('解析融合菜的步骤（字符串数组）', () {
      final dishes = GenerationService.parseFusionDishes(
        {
          'dishes': [
            {
              'name': '麻辣豆腐牛肉粒盖饭',
              'reason': '麻辣鲜香叠加牛肉的满足感',
              'ingredients': ['牛肉粒', '嫩豆腐'],
              'tags': ['麻辣'],
              'steps': ['牛肉粒滑油至变色。', '下豆腐轻推入味。', '盖在热米饭上。'],
            },
          ],
        },
        ['辣', '下饭'],
      );

      expect(dishes, hasLength(1));
      final dish = dishes.single;
      expect(dish.name, '麻辣豆腐牛肉粒盖饭');
      expect(dish.source, 'ai_fusion');
      expect(dish.steps, ['牛肉粒滑油至变色。', '下豆腐轻推入味。', '盖在热米饭上。']);
      expect(dish.ingredients, ['牛肉粒', '嫩豆腐']);
    });

    test('步骤兼容 {description: ...} 对象数组形态', () {
      final dishes = GenerationService.parseFusionDishes(
        {
          'dishes': [
            {
              'name': '泡椒双脆',
              'reason': '脆上加脆',
              'steps': [
                {'description': '土豆切条泡水。'},
                {'description': '鸡胗打花刀快炒。'},
              ],
            },
          ],
        },
        ['脆'],
      );

      expect(dishes.single.steps, ['土豆切条泡水。', '鸡胗打花刀快炒。']);
    });

    test('空菜名跳过、无理由走默认描述、非数组返回空', () {
      final dishes = GenerationService.parseFusionDishes(
        {
          'dishes': [
            {'name': '  ', 'reason': 'x'},
            {'name': '香辣番茄牛腩炖锅'},
          ],
        },
        ['辣', '番茄'],
      );

      expect(dishes, hasLength(1));
      expect(dishes.single.description, contains('组合成的一道创意菜'));
      expect(GenerationService.parseFusionDishes({'dishes': 'oops'}, ['辣']),
          isEmpty);
    });
  });
}
