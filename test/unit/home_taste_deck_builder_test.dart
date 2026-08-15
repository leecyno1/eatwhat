import 'package:eatwhat_app/v2/core/data/models/tag_art_spec.dart';
import 'package:eatwhat_app/v2/core/data/schema/unified_tag_model.dart';
import 'package:eatwhat_app/v2/core/services/v2_tag_catalog_service.dart';
import 'package:eatwhat_app/v2/features/home/controllers/home_taste_deck_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeTasteDeckBuilder', () {
    test('uses history and favorites to prioritize appetite cards', () {
      final builder = HomeTasteDeckBuilder(
        tags: [
          _tag('f_spicy', '辣', 'flavor'),
          _tag('i_beef', '牛肉', 'ingredient'),
          _tag('s_snack', '夜宵', 'scene'),
          _tag('c_sichuan', '川菜', 'cuisine'),
        ],
        artSpecResolver: (_) => TagArtSpec.fallback,
      );

      final deck = builder.buildDeck(
        seed: 1,
        historyScores: const {'i_beef': 20},
        favoriteTagIds: const {'s_snack'},
        maxCards: 4,
      );

      expect(deck.map((card) => card.id).take(2),
          containsAll(['i_beef', 's_snack']));
      expect(deck.firstWhere((card) => card.id == 'i_beef').blurb,
          '围绕 牛肉 安排今天的主角食材');
      expect(deck.firstWhere((card) => card.id == 's_snack').backTitle, '场景脚本');
    });

    test('avoids long runs of the same category when mixed cards exist', () {
      final builder = HomeTasteDeckBuilder(
        tags: [
          _tag('f_1', '辣', 'flavor'),
          _tag('f_2', '甜', 'flavor'),
          _tag('f_3', '酸', 'flavor'),
          _tag('i_1', '牛肉', 'ingredient'),
          _tag('s_1', '夜宵', 'scene'),
        ],
        artSpecResolver: (_) => TagArtSpec.fallback,
      );

      final deck = builder.buildDeck(
        seed: 1,
        historyScores: const {
          'f_1': 30,
          'f_2': 28,
          'f_3': 26,
        },
        favoriteTagIds: const {},
        maxCards: 5,
      );

      for (var index = 2; index < deck.length; index += 1) {
        final run = [
          deck[index - 2].category,
          deck[index - 1].category,
          deck[index].category,
        ];
        expect(run.toSet().length, greaterThan(1));
      }
    });

    test('falls back to warm accent colors when tag colors are missing', () {
      final builder = HomeTasteDeckBuilder(
        tags: [
          _tag('custom', '随便', 'unknown', colors: const []),
        ],
        artSpecResolver: (_) => const TagArtSpec(
          artKey: 'custom-art',
          surfacePattern: 'paper',
          motionPreset: 'drift',
          symbolLayout: 'corner',
          headlineStyle: 'minimal',
        ),
      );

      final card = builder
          .buildDeck(
            seed: 1,
            historyScores: const {},
            favoriteTagIds: const {},
            maxCards: 1,
          )
          .single;

      expect(card.accentHexes, const ['0xFFC94B2C', '0xFFFFAB91']);
      expect(card.blurb, '把 随便 纳入口味签名');
      expect(card.examples, const ['随便', '今日签名']);
      expect(card.artKey, 'custom-art');
    });

    test('can build a deck directly from the unified catalog service',
        () async {
      final builder = HomeTasteDeckBuilder(
        tagCatalogService: _StaticCatalogService([
          _tag('db_taste_1', '辣', 'flavor'),
          _tag('db_scene_1', '夜宵', 'scene'),
        ]),
        artSpecResolver: (_) => TagArtSpec.fallback,
      );

      final deck = await builder.buildDeckFromCatalog(
        seed: 2,
        historyScores: const {'db_taste_1': 1},
        favoriteTagIds: const {'db_scene_1'},
        maxCards: 2,
      );

      expect(deck.map((card) => card.id), ['db_scene_1', 'db_taste_1']);
    });
  });
}

UnifiedTagModel _tag(
  String id,
  String label,
  String category, {
  List<String> colors = const ['0xFF111111', '0xFF222222'],
}) {
  return UnifiedTagModel(
    id: id,
    label: label,
    category: category,
    iconAsset: 'restaurant',
    visual: VisualConfig(
      shapeType: 'circle',
      colors: colors,
    ),
  );
}

class _StaticCatalogService extends V2TagCatalogService {
  _StaticCatalogService(this.tags) : super(dbTagLoader: () async => const []);

  final List<UnifiedTagModel> tags;

  @override
  Future<List<UnifiedTagModel>> loadTags(
      {int minimumFallbackCount = 36}) async {
    return tags;
  }
}
