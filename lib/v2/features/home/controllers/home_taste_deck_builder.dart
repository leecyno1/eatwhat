import 'dart:math';

import 'package:eatwhat_app/v2/core/data/models/tag_art_spec.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_signal.dart';
import 'package:eatwhat_app/v2/core/data/repositories/tag_art_registry_v2.dart';
import 'package:eatwhat_app/v2/core/data/repositories/tag_repository_v2.dart';
import 'package:eatwhat_app/v2/core/data/schema/unified_tag_model.dart';
import 'package:eatwhat_app/v2/core/services/v2_tag_catalog_service.dart';

class HomeTasteDeckBuilder {
  const HomeTasteDeckBuilder({
    TagRepositoryV2? tagRepository,
    V2TagCatalogService? tagCatalogService,
    List<UnifiedTagModel>? tags,
    TagArtSpecResolver artSpecResolver = TagArtRegistryV2.specFor,
  })  : _tagRepository = tagRepository,
        _tagCatalogService = tagCatalogService,
        _tags = tags,
        _artSpecResolver = artSpecResolver;

  final TagRepositoryV2? _tagRepository;
  final V2TagCatalogService? _tagCatalogService;
  final List<UnifiedTagModel>? _tags;
  final TagArtSpecResolver _artSpecResolver;

  Future<List<TasteDeckCard>> buildDeckFromCatalog({
    required int seed,
    required Map<String, int> historyScores,
    required Set<String> favoriteTagIds,
    int maxCards = 24,
  }) async {
    List<TasteSignal> signals;
    try {
      signals = _tags == null
          ? await (_tagCatalogService ?? V2TagCatalogService.instance)
              .loadSignals()
          : _tags.map(_signalFromTag).toList();
    } catch (_) {
      signals = const [];
    }
    final deck = buildDeck(
      seed: seed,
      historyScores: historyScores,
      favoriteTagIds: favoriteTagIds,
      maxCards: maxCards,
      signalsOverride: signals,
    );
    if (deck.isNotEmpty) {
      return deck;
    }
    return buildDeck(
      seed: seed,
      historyScores: historyScores,
      favoriteTagIds: favoriteTagIds,
      maxCards: maxCards,
    );
  }

  List<TasteDeckCard> buildDeck({
    required int seed,
    required Map<String, int> historyScores,
    required Set<String> favoriteTagIds,
    int maxCards = 24,
    List<UnifiedTagModel>? tagsOverride,
    List<TasteSignal>? signalsOverride,
  }) {
    final random = Random(seed);
    final signals = signalsOverride ??
        (tagsOverride ??
                _tags ??
                (_tagRepository ?? TagRepositoryV2()).getAllTags())
            .map(_signalFromTag)
            .toList();
    final cardsByLabel = <String, TasteDeckCard>{};
    for (final signal in signals) {
      final card = _cardFromSignal(signal);
      if (card == null) continue;
      cardsByLabel.putIfAbsent(card.label, () => card);
    }
    final tags = cardsByLabel.values.toList();

    final scored = tags.map((card) {
      final historyScore = historyScores[card.id] ?? 0;
      final favoriteBoost = favoriteTagIds.contains(card.id) ? 80 : 0;
      final shuffle = random.nextDouble() * 24;
      return MapEntry(card, favoriteBoost + historyScore * 6 + shuffle);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final grouped = <String, List<TasteDeckCard>>{};
    for (final entry in scored) {
      grouped.putIfAbsent(entry.key.category, () => []).add(entry.key);
    }

    final orderedCategories = grouped.keys.toList()
      ..sort((a, b) {
        final aScore =
            scored.firstWhere((entry) => entry.key.category == a).value;
        final bScore =
            scored.firstWhere((entry) => entry.key.category == b).value;
        return bScore.compareTo(aScore);
      });

    final deck = <TasteDeckCard>[];
    while (deck.length < maxCards &&
        grouped.values.any((list) => list.isNotEmpty)) {
      var addedThisPass = false;
      for (final category in orderedCategories) {
        final queue = grouped[category]!;
        if (queue.isEmpty) continue;
        if (_wouldCreateCategoryRun(deck, category)) {
          continue;
        }
        deck.add(queue.removeAt(0));
        addedThisPass = true;
        if (deck.length >= maxCards) break;
      }

      if (!addedThisPass) {
        final nextQueue = grouped.values.firstWhere(
          (queue) => queue.isNotEmpty,
          orElse: () => const [],
        );
        if (nextQueue.isEmpty) break;
        deck.add(nextQueue.removeAt(0));
      }
    }

    return deck.isEmpty ? tags.take(18).toList() : deck;
  }

  TasteSignal _signalFromTag(UnifiedTagModel tag) {
    return TasteSignal(
      tag: tag,
      artSpec: _artSpecResolver(tag.id),
    );
  }

  TasteDeckCard? _cardFromSignal(TasteSignal signal) {
    final tag = signal.tag;
    final artSpec = signal.artSpec;
    final label = _localizedLabel(tag.label);
    if (label == null) return null;
    final colors = tag.visual.colors.isEmpty
        ? const ['0xFFC94B2C', '0xFFFFAB91']
        : tag.visual.colors;
    return TasteDeckCard(
      id: tag.id,
      label: label,
      category: tag.category,
      accentHexes: colors.take(2).toList(),
      iconName: tag.iconAsset,
      blurb: cardBlurbFor(tag.category, label),
      backTitle: cardBackTitleFor(tag.category),
      examples: cardBackExamplesFor(tag.category, label),
      artKey: artSpec.artKey,
      surfacePattern: artSpec.surfacePattern,
      motionPreset: artSpec.motionPreset,
      symbolLayout: artSpec.symbolLayout,
      headlineStyle: artSpec.headlineStyle,
    );
  }

  String? _localizedLabel(String rawLabel) {
    final label = rawLabel.trim();
    if (label.isEmpty) return null;
    const translations = {
      'aquatic': '水产',
      'breakfast': '早餐',
      'condiment': '调料',
      'dessert': '甜品',
      'drink': '饮品',
      'meat_dish': '荤菜',
      'semi-finished': '半成品',
      'soup': '汤羹',
      'staple': '主食',
      'vegetable_dish': '素菜',
    };
    final localized = translations[label.toLowerCase()];
    if (localized != null) return localized;
    return RegExp(r'[\u3400-\u9FFF]').hasMatch(label) ? label : null;
  }

  bool _wouldCreateCategoryRun(List<TasteDeckCard> deck, String category) {
    return deck.length >= 2 &&
        deck[deck.length - 1].category == category &&
        deck[deck.length - 2].category == category;
  }

  static String cardBlurbFor(String category, String label) {
    switch (category) {
      case 'flavor':
        return '把 $label 收进今天的味型骨架';
      case 'ingredient':
        return '围绕 $label 安排今天的主角食材';
      case 'scene':
        return '让这顿饭贴合 $label 的状态';
      case 'cuisine':
        return '以 $label 作为这轮菜系方向';
      case 'fortune':
        return '给今天加一点 $label 的趣味信号';
      default:
        return '把 $label 纳入口味签名';
    }
  }

  static String cardBackTitleFor(String category) {
    switch (category) {
      case 'flavor':
        return '辣度轮廓';
      case 'ingredient':
        return '食材角色';
      case 'scene':
        return '场景脚本';
      case 'cuisine':
        return '菜系方向';
      case 'fortune':
        return '趣味线索';
      default:
        return '偏好注释';
    }
  }

  static List<String> cardBackExamplesFor(String category, String label) {
    switch (category) {
      case 'flavor':
        return [label, '更热', '更醒'];
      case 'ingredient':
        return [label, '主角感', '好搭配'];
      case 'scene':
        return [label, '节奏稳', '氛围到'];
      case 'cuisine':
        return [label, '地域感', '风格强'];
      case 'fortune':
        return [label, '娱乐向', '轻玄学'];
      default:
        return [label, '今日签名'];
    }
  }
}

typedef TagArtSpecResolver = TagArtSpec Function(String tagId);
