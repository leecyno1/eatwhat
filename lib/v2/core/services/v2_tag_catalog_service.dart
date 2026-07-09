import 'package:eatwhat_app/core/services/unified_recipe_database_service.dart';
import 'package:eatwhat_app/v2/core/data/models/tag_art_spec.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_signal.dart';
import 'package:eatwhat_app/v2/core/data/repositories/tag_art_registry_v2.dart';
import 'package:eatwhat_app/v2/core/data/repositories/tag_repository_v2.dart';
import 'package:eatwhat_app/v2/core/data/schema/unified_tag_model.dart';

typedef DbTagCatalogLoader = Future<List<Map<String, dynamic>>> Function();
typedef TagArtSpecResolver = TagArtSpec Function(String tagId);

class V2TagCatalogService {
  V2TagCatalogService({
    DbTagCatalogLoader? dbTagLoader,
    TagRepositoryV2? fallbackRepository,
    TagArtSpecResolver artSpecResolver = TagArtRegistryV2.specFor,
  })  : _dbTagLoader = dbTagLoader ??
            UnifiedRecipeDatabaseService.instance.fetchTagCatalog,
        _fallbackRepository = fallbackRepository ?? TagRepositoryV2(),
        _artSpecResolver = artSpecResolver;

  static final V2TagCatalogService instance = V2TagCatalogService();

  final DbTagCatalogLoader _dbTagLoader;
  final TagRepositoryV2 _fallbackRepository;
  final TagArtSpecResolver _artSpecResolver;

  Future<List<UnifiedTagModel>> loadTags({
    int minimumFallbackCount = 36,
  }) async {
    final dbTags = await _loadDbTags();
    if (dbTags.length >= minimumFallbackCount) {
      return dbTags;
    }

    final merged = <String, UnifiedTagModel>{
      for (final tag in dbTags) tag.label: tag,
    };
    for (final tag in _fallbackRepository.getAllTags()) {
      merged.putIfAbsent(tag.label, () => tag);
    }
    return merged.values.toList();
  }

  Future<Map<String, String>> loadLabelToTagIdMap() async {
    final tags = await loadTags();
    return {
      for (final tag in tags)
        if (tag.label.trim().isNotEmpty) tag.label: tag.id,
    };
  }

  Future<List<TasteSignal>> loadSignals({
    int minimumFallbackCount = 36,
  }) async {
    final tags = await loadTags(minimumFallbackCount: minimumFallbackCount);
    return tags.map(_signalFromTag).toList();
  }

  Future<Map<String, TasteSignal>> loadLabelToSignalMap({
    int minimumFallbackCount = 36,
  }) async {
    final signals =
        await loadSignals(minimumFallbackCount: minimumFallbackCount);
    return {
      for (final signal in signals)
        if (signal.label.trim().isNotEmpty) signal.label: signal,
    };
  }

  Future<List<String>> loadDbTagIdsForLabels(
    List<String> labels, {
    int minimumFallbackCount = 36,
  }) async {
    final signalByLabel =
        await loadLabelToSignalMap(minimumFallbackCount: minimumFallbackCount);
    final ids = <String>[];
    for (final label in labels) {
      final id = signalByLabel[label.trim()]?.dbTagId;
      if (id != null && id.isNotEmpty) {
        ids.add(id);
      }
    }
    return ids.toSet().toList();
  }

  Future<List<UnifiedTagModel>> _loadDbTags() async {
    final rows = await _dbTagLoader();
    final tags = rows.map(_tagFromDbRow).whereType<UnifiedTagModel>().toList();
    return tags;
  }

  TasteSignal _signalFromTag(UnifiedTagModel tag) {
    return TasteSignal(
      tag: tag,
      dbTagId: _dbTagIdFromUnifiedTagId(tag.id),
      artSpec: _artSpecResolver(tag.id),
      recallLabels: _recallLabelsFor(tag),
    );
  }

  String? _dbTagIdFromUnifiedTagId(String tagId) {
    final match = RegExp(r'^db_[^_]+(?:_[^_]+)*_(\d+)$').firstMatch(tagId);
    return match?.group(1);
  }

  List<String> _recallLabelsFor(UnifiedTagModel tag) {
    final labels = <String>[tag.label.trim()];
    switch (tag.category) {
      case 'flavor':
        labels.addAll(_flavorRecallHints[tag.label] ?? const []);
      case 'ingredient':
        labels.addAll(_ingredientRecallHints[tag.label] ?? const []);
      case 'scene':
        labels.addAll(_sceneRecallHints[tag.label] ?? const []);
      case 'dietary':
        labels.addAll(_dietaryRecallHints[tag.label] ?? const []);
    }
    return labels.where((label) => label.isNotEmpty).toSet().toList();
  }

  UnifiedTagModel? _tagFromDbRow(Map<String, dynamic> row) {
    final rawId = row['id']?.toString().trim() ?? '';
    final rawCategory = row['category']?.toString().trim() ?? '';
    final label = row['name_cn']?.toString().trim() ??
        row['key']?.toString().trim() ??
        '';
    if (rawId.isEmpty || rawCategory.isEmpty || label.isEmpty) {
      return null;
    }

    final category = _normalizeCategory(rawCategory, label);
    return UnifiedTagModel(
      id: 'db_${rawCategory}_$rawId',
      label: label,
      category: category,
      iconAsset: _iconFor(row['icon_key']?.toString(), category, label),
      visual: _visualFor(category, label),
      weight: _weightFor(row['dish_count']),
    );
  }

  String _normalizeCategory(String category, String label) {
    switch (category) {
      case 'cuisine':
        return 'cuisine';
      case 'taste':
      case 'texture':
        return 'flavor';
      case 'scene':
      case 'occasion':
        return 'scene';
      case 'health':
        return 'dietary';
      case 'ingredient':
        return 'ingredient';
      case 'howtocook_category':
        return _howToCookCategoryFor(label);
      default:
        return _inferredCategoryFor(label);
    }
  }

  String _howToCookCategoryFor(String label) {
    switch (label) {
      case '早餐':
        return 'scene';
      case '荤菜':
      case '素菜':
      case '水产':
        return 'ingredient';
      case '主食':
      case '汤羹':
      case '甜品':
      case '饮品':
      case '调料':
      case '半成品加工':
        return 'cuisine';
      default:
        return 'cuisine';
    }
  }

  String _inferredCategoryFor(String label) {
    if (_flavorLabels.any(label.contains)) return 'flavor';
    if (_sceneLabels.any(label.contains)) return 'scene';
    if (_dietaryLabels.any(label.contains)) return 'dietary';
    if (_ingredientLabels.any(label.contains)) return 'ingredient';
    return 'cuisine';
  }

  String _iconFor(String? rawIcon, String category, String label) {
    final icon = rawIcon?.trim() ?? '';
    if (icon.isNotEmpty && icon != label) return icon;
    switch (category) {
      case 'flavor':
        return 'local_fire_department';
      case 'ingredient':
        return 'restaurant';
      case 'scene':
        return label.contains('早餐') ? 'breakfast_dining' : 'schedule';
      case 'dietary':
        return 'spa';
      case 'cuisine':
      default:
        return 'restaurant_menu';
    }
  }

  VisualConfig _visualFor(String category, String label) {
    switch (category) {
      case 'flavor':
        return const VisualConfig(
          shapeType: 'chili',
          colors: ['0xFFF45B33', '0xFFFFB545'],
          particleEffect: 'steam',
        );
      case 'ingredient':
        return const VisualConfig(
          shapeType: 'squircle',
          colors: ['0xFF4F9D69', '0xFF7ABF88'],
        );
      case 'scene':
        return const VisualConfig(
          shapeType: 'circle',
          colors: ['0xFF45A6D8', '0xFF8A7CF7'],
          particleEffect: 'bubble',
        );
      case 'dietary':
        return const VisualConfig(
          shapeType: 'leaf',
          colors: ['0xFF7ABF88', '0xFF4F9D69'],
        );
      case 'cuisine':
      default:
        return VisualConfig(
          shapeType: label.contains('汤') ? 'drop' : 'circle',
          colors: const ['0xFFFFB545', '0xFFF45B33'],
          particleEffect: label.contains('汤') ? 'steam' : 'none',
        );
    }
  }

  double _weightFor(Object? rawCount) {
    final count = rawCount is num ? rawCount.toDouble() : 0.0;
    if (count <= 0) return 0.5;
    return (0.5 + count.clamp(0, 80) / 160).clamp(0.5, 1.0);
  }

  static const _flavorLabels = ['辣', '甜', '酸', '咸', '鲜', '麻', '香', '清淡'];
  static const _sceneLabels = ['早餐', '夜宵', '聚会', '午餐', '晚餐', '加班'];
  static const _dietaryLabels = ['减肥', '健康', '低脂', '轻食', '素'];
  static const _ingredientLabels = [
    '鸡',
    '鸭',
    '牛',
    '猪',
    '羊',
    '鱼',
    '虾',
    '水产',
    '豆腐',
    '蔬菜',
  ];

  static const _flavorRecallHints = {
    '麻': ['麻辣', '花椒'],
    '辣': ['香辣', '麻辣', '川菜'],
    '鲜': ['鲜香', '海鲜'],
    '清淡': ['素菜', '汤羹'],
    '咖喱': ['咖喱', '鸡肉', '牛肉'],
  };

  static const _ingredientRecallHints = {
    '土豆': ['马铃薯', '家常菜'],
    '豆腐': ['素菜', '家常菜'],
    '牛肉': ['荤菜', '高蛋白'],
    '海鲜': ['水产', '鲜'],
    '鸡肉': ['荤菜', '快手'],
  };

  static const _sceneRecallHints = {
    '早餐': ['主食', '快手'],
    '夜宵': ['快手', '热菜'],
    '下午茶': ['甜品', '饮品'],
    '聚会': ['火锅', '荤菜'],
  };

  static const _dietaryRecallHints = {
    '低碳': ['高蛋白', '荤菜'],
    '高蛋白': ['牛肉', '鸡肉', '鱼'],
    '健康': ['素菜', '清淡'],
    '素食': ['素菜', '豆腐'],
  };
}
