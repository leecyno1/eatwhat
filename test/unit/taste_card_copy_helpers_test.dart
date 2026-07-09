import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_copy_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('taste card copy helpers', () {
    test('returns category labels and action descriptors', () {
      final flavor = _card(category: 'flavor', label: '重辣');
      final meta = _card(category: 'meta', label: '随机');

      expect(tasteCardCategoryLabel('flavor'), '口味');
      expect(tasteCardCategoryLabel('unknown'), '标签');
      expect(tasteCardDescriptor(flavor), '锁定味型');
      expect(tasteCardDescriptor(meta), '交给一点随机');
    });

    test('uses explicit back copy before category fallbacks', () {
      final explicit = _card(
        category: 'ingredient',
        label: '牛肉',
        backTitle: '蛋白主角',
        examples: const ['嫩', '香'],
      );
      final fallback = _card(category: 'scene', label: '加班夜');

      expect(tasteCardBackTitle(explicit), '蛋白主角');
      expect(tasteCardBackExamples(explicit), ['嫩', '香']);
      expect(tasteCardBackTitle(fallback), '场景脚本');
      expect(tasteCardBackExamples(fallback), ['加班夜', '节奏稳', '氛围到']);
    });

    test('builds default blurbs and compact codes', () {
      final cuisine = _card(
        id: 'sichuan_hot',
        category: 'cuisine',
        label: '川菜',
        artKey: 'spicy-map',
      );

      expect(
        tasteCardDefaultBlurb(cuisine),
        '用 川菜 锁定地区风格，避免推荐跨度过大。',
      );
      expect(tasteCardMicroCode(cuisine.id), 'SICH');
      expect(tasteCardArtCode(cuisine.artKey), 'SM');
      expect(tasteCardArtCode('---'), 'ART');
    });
  });
}

TasteDeckCard _card({
  String id = 'card_1',
  required String category,
  required String label,
  String? backTitle,
  List<String> examples = const [],
  String artKey = 'default',
}) {
  return TasteDeckCard(
    id: id,
    label: label,
    category: category,
    accentHexes: const ['#F46B40', '#7ABF88'],
    iconName: 'restaurant',
    backTitle: backTitle,
    examples: examples,
    artKey: artKey,
  );
}
