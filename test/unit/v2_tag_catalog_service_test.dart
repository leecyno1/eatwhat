import 'package:eatwhat_app/v2/core/data/repositories/tag_repository_v2.dart';
import 'package:eatwhat_app/v2/core/data/schema/unified_tag_model.dart';
import 'package:eatwhat_app/v2/core/services/v2_tag_catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('V2TagCatalogService', () {
    test('把统一菜谱库 tag 行转换成 V2 气泡标签', () async {
      final service = V2TagCatalogService(
        dbTagLoader: () async => const [
          {
            'id': 7,
            'category': 'howtocook_category',
            'key': '早餐',
            'name_cn': '早餐',
            'icon_key': 'breakfast_dining',
            'dish_count': 24,
          },
          {
            'id': 3,
            'category': 'ingredient',
            'key': '鸡翅',
            'name_cn': '鸡翅',
            'icon_key': null,
            'dish_count': 11,
          },
        ],
        fallbackRepository: _EmptyTagRepository(),
      );

      final tags = await service.loadTags(minimumFallbackCount: 0);

      expect(tags.map((tag) => tag.id),
          ['db_howtocook_category_7', 'db_ingredient_3']);
      expect(tags.first.label, '早餐');
      expect(tags.first.category, 'scene');
      expect(tags.first.iconAsset, 'breakfast_dining');
      expect(tags.first.weight, greaterThan(0.5));
      expect(tags.last.category, 'ingredient');
      expect(tags.last.visual.colors, isNotEmpty);
    });

    test('统一库标签不足时合并旧 V2 标签兜底且 DB 标签优先', () async {
      final service = V2TagCatalogService(
        dbTagLoader: () async => const [
          {
            'id': 1,
            'category': 'cuisine',
            'key': '家常菜',
            'name_cn': '家常菜',
            'icon_key': 'home',
            'dish_count': 3,
          },
        ],
        fallbackRepository: _StaticTagRepository([
          const UnifiedTagModel(
            id: 'f_spicy',
            label: '辣',
            category: 'flavor',
            iconAsset: 'local_fire_department',
            visual: VisualConfig(
              shapeType: 'chili',
              colors: ['0xFFFF5252', '0xFFD32F2F'],
              particleEffect: 'steam',
            ),
          ),
        ]),
      );

      final tags = await service.loadTags(minimumFallbackCount: 2);

      expect(tags.map((tag) => tag.id).toList(), ['db_cuisine_1', 'f_spicy']);
      expect(tags.first.label, '家常菜');
      expect(tags.first.category, 'cuisine');
    });

    test('taste signal 会携带 DB tag id、卡面素材与召回提示', () async {
      final service = V2TagCatalogService(
        dbTagLoader: () async => const [
          {
            'id': 8,
            'category': 'howtocook_category',
            'key': '素菜',
            'name_cn': '素菜',
            'icon_key': null,
            'dish_count': 18,
          },
        ],
        fallbackRepository: _EmptyTagRepository(),
      );

      final signals = await service.loadSignals(minimumFallbackCount: 0);
      final dbTagIds = await service.loadDbTagIdsForLabels(
        ['素菜'],
        minimumFallbackCount: 0,
      );

      expect(signals.single.id, 'db_howtocook_category_8');
      expect(signals.single.dbTagId, '8');
      expect(signals.single.artSpec.artKey, isNotEmpty);
      expect(signals.single.recallLabels, contains('素菜'));
      expect(dbTagIds, ['8']);
    });
  });
}

class _EmptyTagRepository extends TagRepositoryV2 {
  @override
  List<UnifiedTagModel> getAllTags() => const [];
}

class _StaticTagRepository extends TagRepositoryV2 {
  _StaticTagRepository(this.tags);

  final List<UnifiedTagModel> tags;

  @override
  List<UnifiedTagModel> getAllTags() => tags;
}
