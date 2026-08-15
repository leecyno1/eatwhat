import 'dart:math';

import 'package:eatwhat_app/core/data/taste_visual_mapping.dart';
import 'package:eatwhat_app/v2/core/data/repositories/tag_repository_v2.dart';
import 'package:eatwhat_app/v2/core/data/schema/unified_tag_model.dart';
import 'package:eatwhat_app/v2/core/services/v2_favorites_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';
import 'package:flutter/material.dart';

class BubbleDataManager {
  final Random _random = Random();
  final V2FavoritesService _favorites = V2FavoritesService.instance;
  final V2PreferenceFeedbackService _feedback =
      V2PreferenceFeedbackService.instance;
  Set<String> _favoriteTagIds = {};
  Map<String, int> _tagScores = {};
  List<UnifiedTagModel> _allTags = const [];

  static const Map<String, Set<String>> categoryGroups = {
    'ingredient_dietary': {'ingredient', 'dietary'},
    'flavor_staple': {'flavor', 'staple'},
    'cuisine': {'cuisine'},
    'scene_fun': {'scene', 'meta', 'fortune'},
  };

  Future<void> initialize() async {
    try {
      _favoriteTagIds = await _favorites.getFavoriteTagIds();
    } catch (_) {}
    try {
      _tagScores = await _feedback.getTagScores();
    } catch (_) {}
    // The approved entity artwork is a stable one-to-one set for these 102
    // product preferences. Database tags are resolved later by label during
    // recommendation, so raw database IDs must not enter the visual asset pool.
    _allTags = TagRepositoryV2().getAllTags();
  }

  int get totalTagCount => _allTags.length;

  int countForCategory(String? category) {
    if (category == null || category.isEmpty) return _allTags.length;
    return _allTags.where((tag) => _matchesCategory(tag, category)).length;
  }

  List<BubbleData> getInitialBubbles(
    int count, {
    String? category,
    Set<String> excludedTagIds = const {},
  }) {
    final allTags = _allTags
        .where(
          (tag) =>
              (category == null ||
                  category.isEmpty ||
                  _matchesCategory(tag, category)) &&
              !excludedTagIds.contains(tag.id),
        )
        .toList();
    if (allTags.isEmpty || count <= 0) return const [];
    final targetCount = count.clamp(0, allTags.length);
    final List<BubbleData> bubbles = [];
    final Set<String> usedIds = {};

    // Ensure favorited tags show up (强注入)
    // Note: favorites are stored by tagId (e.g. 'f_spicy'), aligned with TagRepositoryV2 ids.
    // We inject them first (up to count), then fill the rest with variety.
    //
    // This is an in-memory call; favorites are persisted by SharedPreferences.
    for (final id in _favoriteTagIds) {
      if (bubbles.length >= targetCount) break;
      if (usedIds.contains(id)) continue;
      final matches = allTags.where((tag) => tag.id == id);
      if (matches.isEmpty) continue;
      final tag = matches.first;
      if (usedIds.contains(tag.id)) continue;
      bubbles.add(_buildBubbleData(tag));
      usedIds.add(tag.id);
    }

    // Keep the three signature entities from concept 4 visible on first load.
    if (category == null || category.isEmpty) {
      for (final label in const ['低碳', '辣', '鸡蛋']) {
        if (bubbles.length >= targetCount) break;
        final matches = allTags.where((tag) => tag.label == label);
        if (matches.isEmpty) continue;
        final tag = matches.first;
        if (usedIds.add(tag.id)) {
          bubbles.add(_buildBubbleData(tag));
        }
      }
    }

    // Ensure variety: Pick one from each category first
    final categories = [
      'cuisine',
      'ingredient',
      'flavor',
      'scene',
      'staple',
      'dietary',
      'fortune',
      'meta',
    ];

    for (final cat in categories) {
      if (bubbles.length >= targetCount) break;
      final catTags = allTags.where((t) => t.category == cat).toList();
      if (catTags.isNotEmpty) {
        final tag = _pickWeighted(catTags);
        if (usedIds.add(tag.id)) {
          bubbles.add(_buildBubbleData(tag));
        }
      }
    }

    // Fill the rest
    while (bubbles.length < targetCount) {
      final tag = _pickWeighted(allTags);
      if (usedIds.add(tag.id)) {
        bubbles.add(_buildBubbleData(tag));
      }
    }

    // Shuffle the result so categories aren't always first
    bubbles.shuffle(_random);

    return bubbles;
  }

  bool _matchesCategory(UnifiedTagModel tag, String category) {
    final grouped = categoryGroups[category];
    if (grouped != null) return grouped.contains(tag.category);
    return tag.category == category;
  }

  List<BubbleData> getRelatedBubbles(BubbleData source, {int count = 5}) {
    final List<UnifiedTagModel> allTags = _allTags;
    if (allTags.isEmpty || count <= 0) return const [];

    // Filter by same category
    final relatedTags =
        allTags.where((t) => t.category == source.tag.category).toList();

    // If not enough related, fallback to all tags
    if (relatedTags.length < 2) {
      relatedTags.addAll(allTags);
    }

    final List<BubbleData> bubbles = [];
    for (int i = 0; i < count; i++) {
      final tag = _pickWeighted(relatedTags);
      bubbles.add(_buildBubbleData(tag));
    }
    return bubbles;
  }

  BubbleData _buildBubbleData(UnifiedTagModel tag) {
    final score = _tagScores[tag.id] ?? 0;
    return BubbleData(
      tag: tag,
      usageCount: score > 0 ? score : 0,
    );
  }

  double _weightForTag(UnifiedTagModel tag) {
    final score = _tagScores[tag.id] ?? 0;
    final positive = score.clamp(0, 200);
    final negative = (-score).clamp(0, 200);

    var weight = 1.0 + positive * 0.03;
    weight = weight / (1.0 + negative * 0.05);

    if (_favoriteTagIds.contains(tag.id)) {
      weight *= 3.0;
    }

    if (weight.isNaN || weight.isInfinite) return 1.0;
    return weight.clamp(0.1, 20.0);
  }

  UnifiedTagModel _pickWeighted(List<UnifiedTagModel> tags) {
    if (tags.isEmpty) {
      throw ArgumentError('tags must not be empty');
    }

    final weights = tags.map(_weightForTag).toList();
    final total = weights.fold<double>(0.0, (sum, w) => sum + w);
    var r = _random.nextDouble() * total;

    for (var i = 0; i < tags.length; i++) {
      r -= weights[i];
      if (r <= 0) return tags[i];
    }
    return tags.last;
  }

  // Helper to parse hex color
  static Color parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.startsWith('0x')) {
        return Color(int.parse(hexColor));
      }
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      debugPrint('Error parsing color: $hexColor');
      return Colors.grey;
    }
  }
}

enum BubbleType {
  cuisine,
  ingredient,
  flavor,
  scene,
  meta,
  staple,
  dietary,
  fortune
}

class BubbleData {
  BubbleData({required this.tag, this.usageCount = 0});

  final UnifiedTagModel tag;

  String get id => tag.id;
  String get label => tag.label;
  String get iconName => tag.iconAsset;
  String get assetName => 'preference_entities/$id.png';
  String get assetPath => 'assets/images/$assetName';
  TasteVisualSpec get visualSpec => TasteVisualMapping.guess(label);

  BubbleType get type {
    switch (tag.category) {
      case 'cuisine':
        return BubbleType.cuisine;
      case 'ingredient':
        return BubbleType.ingredient;
      case 'flavor':
        return BubbleType.flavor;
      case 'scene':
        return BubbleType.scene;
      case 'meta':
        return BubbleType.meta;
      case 'staple':
        return BubbleType.staple;
      case 'dietary':
        return BubbleType.dietary;
      case 'fortune':
        return BubbleType.fortune;
      default:
        return BubbleType.cuisine;
    }
  }

  Color get primaryColor {
    if (tag.visual.colors.isNotEmpty) {
      return BubbleDataManager.parseColor(tag.visual.colors.first);
    }
    return visualSpec.color;
  }

  Color get secondaryColor {
    if (tag.visual.colors.length > 1) {
      return BubbleDataManager.parseColor(tag.visual.colors[1]);
    }
    return visualSpec.color.withValues(alpha: 0.72);
  }

  String get shapeType {
    if (label.contains('火锅') || label.contains('锅')) return 'pot';
    if (label.contains('辣')) return 'chili';
    if (label.contains('夜') || label.contains('夜宵')) return 'moon';
    if (label.contains('健康') || label.contains('低碳') || label.contains('高蛋白')) {
      return 'shield';
    }
    if (label.contains('清淡') || label.contains('轻食') || label.contains('素')) {
      return 'leaf';
    }
    if (label.contains('甜') || label.contains('下午茶')) return 'petal';
    if (label.contains('聚餐') || label.contains('自助')) return 'ticket';
    if (label.contains('米饭') ||
        label.contains('面') ||
        label.contains('馒头') ||
        label.contains('包子')) {
      return 'capsule';
    }
    if (label.contains('鲜') || label.contains('海')) return 'drop';
    if (tag.visual.shapeType != 'circle') {
      return tag.visual.shapeType;
    }
    switch (type) {
      case BubbleType.cuisine:
      case BubbleType.scene:
        return 'squircle';
      case BubbleType.ingredient:
        return 'drop';
      case BubbleType.staple:
      case BubbleType.meta:
        return 'hexagon';
      case BubbleType.dietary:
        return 'leaf';
      case BubbleType.fortune:
        return 'star';
      case BubbleType.flavor:
        return visualSpec.shapeType;
    }
  }

  String get particleEffect {
    if (tag.visual.particleEffect != 'none') {
      return tag.visual.particleEffect;
    }
    switch (type) {
      case BubbleType.fortune:
        return 'sparkle';
      case BubbleType.scene:
      case BubbleType.meta:
        return 'glow';
      case BubbleType.ingredient:
      case BubbleType.dietary:
        return 'bubble';
      case BubbleType.flavor:
      case BubbleType.cuisine:
      case BubbleType.staple:
        return visualSpec.particleEffect;
    }
  }

  // Memory system: usage count
  int usageCount;

  // Dynamic size multiplier based on usage
  double get sizeMultiplier {
    if (usageCount <= 0) return 1.0;
    // Logarithmic growth: 10 uses = 1.5x, 100 uses = 2.0x
    return 1.0 + (log(usageCount + 1) / log(10)) * 0.5;
  }
}
