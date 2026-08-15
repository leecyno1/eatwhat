import 'dart:async';
import 'dart:math' as math;

import 'package:eatwhat_app/core/services/unified_recipe_database_service.dart';
import 'package:eatwhat_app/v2/core/data/models/meal_planning_direction.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_signal.dart';
import 'package:eatwhat_app/v2/core/services/v2_favorites_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_shadow_scoring_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_tag_catalog_service.dart';

typedef RecipeRowLoader = Future<List<Map<String, dynamic>>> Function(
  String query,
  int limit,
);
typedef TagRecipeRowLoader = Future<List<Map<String, dynamic>>> Function(
  List<String> tagIds,
  int limit,
);
typedef DefaultRecipeRowLoader = Future<List<Map<String, dynamic>>> Function(
  int limit,
);
typedef TagScoreLoader = Future<Map<String, int>> Function();
typedef FavoriteTagLoader = Future<Set<String>> Function();
typedef FavoriteDishLoader = Future<Set<String>> Function();
typedef RecentRecipeLoader = Future<List<String>> Function();
typedef V2RecommendationCanaryDecisionLoader
    = Future<RecommendationCanaryDecision> Function();

class LocalRecommendationBundle {
  const LocalRecommendationBundle({
    required this.recipes,
    required this.reasonsByRecipeId,
    required this.summary,
    this.rankingVersion = 'local_rank_v2',
    this.algorithmVersion = 'hybrid_v3_0',
  });

  final List<RecipeModel> recipes;
  final Map<String, String> reasonsByRecipeId;
  final String summary;
  final String rankingVersion;
  final String algorithmVersion;
}

/// V2 统一库推荐服务（第一版）
///
/// 目标：
/// - 以 `unified_recipes.db` 为底座产出推荐菜品
/// - 将“气泡选择的标签”映射为检索与打分信号
///
/// 说明：
/// - 当前版本为启发式打分（匹配度 + 人气 + 评分），后续可替换为 core 的推荐引擎实现。
class UnifiedRecommendationServiceV2 {
  UnifiedRecommendationServiceV2({
    UnifiedRecipeDatabaseService? db,
    V2TagCatalogService? tagCatalogService,
    RecipeRowLoader? searchRecipeLoader,
    TagRecipeRowLoader? tagRecipeLoader,
    DefaultRecipeRowLoader? defaultRecipeLoader,
    TagScoreLoader? tagScoreLoader,
    FavoriteTagLoader? favoriteTagLoader,
    FavoriteDishLoader? favoriteDishLoader,
    RecentRecipeLoader? recentRecipeLoader,
    V2RecommendationShadowScoringService? shadowScoringService,
    V2RecommendationCanaryService? canaryService,
    V2RecommendationCanaryDecisionLoader? canaryDecisionLoader,
    V2RecommendationExperimentalRanker? experimentalRanker,
  })  : _db = db ?? UnifiedRecipeDatabaseService.instance,
        _tagCatalog = tagCatalogService ?? V2TagCatalogService.instance,
        _searchRecipeLoader = searchRecipeLoader,
        _tagRecipeLoader = tagRecipeLoader,
        _defaultRecipeLoader = defaultRecipeLoader,
        _tagScoreLoader =
            tagScoreLoader ?? V2PreferenceFeedbackService.instance.getTagScores,
        _favoriteTagLoader =
            favoriteTagLoader ?? V2FavoritesService.instance.getFavoriteTagIds,
        _favoriteDishLoader = favoriteDishLoader ??
            V2FavoritesService.instance.getFavoriteDishIds,
        _recentRecipeLoader = recentRecipeLoader ??
            V2PreferenceFeedbackService.instance.getRecentRecipeIds,
        _shadowScoringService = shadowScoringService ??
            V2RecommendationShadowScoringService.instance,
        _canaryDecisionLoader = canaryDecisionLoader ??
            (canaryService ?? V2RecommendationCanaryService.instance).decide,
        _experimentalRanker =
            experimentalRanker ?? V2RecommendationExperimentalRanker.instance;

  UnifiedRecommendationServiceV2._internal() : this();
  static final UnifiedRecommendationServiceV2 instance =
      UnifiedRecommendationServiceV2._internal();

  final UnifiedRecipeDatabaseService _db;
  final V2TagCatalogService _tagCatalog;
  final RecipeRowLoader? _searchRecipeLoader;
  final TagRecipeRowLoader? _tagRecipeLoader;
  final DefaultRecipeRowLoader? _defaultRecipeLoader;
  final TagScoreLoader _tagScoreLoader;
  final FavoriteTagLoader _favoriteTagLoader;
  final FavoriteDishLoader _favoriteDishLoader;
  final RecentRecipeLoader _recentRecipeLoader;
  final V2RecommendationShadowScoringService _shadowScoringService;
  final V2RecommendationCanaryDecisionLoader _canaryDecisionLoader;
  final V2RecommendationExperimentalRanker _experimentalRanker;

  Map<String, TasteSignal>? _signalByLabelCache;

  Future<Map<String, TasteSignal>> _signalByLabel() async {
    if (_signalByLabelCache != null) return _signalByLabelCache!;
    final map = await _tagCatalog.loadLabelToSignalMap();
    _signalByLabelCache = map;
    return map;
  }

  Future<List<RecipeModel>> recommendRecipes({
    required TasteInferenceInput input,
    required List<String> recallLabels,
    int limit = 5,
  }) async {
    final bundle = await buildRecommendationBundle(
      input: input,
      recallLabels: recallLabels,
      limit: limit,
    );
    return bundle.recipes;
  }

  Future<LocalRecommendationBundle> buildRecommendationBundle({
    required TasteInferenceInput input,
    required List<String> recallLabels,
    int limit = 5,
  }) async {
    if (_searchRecipeLoader == null || _tagRecipeLoader == null) {
      await _db.ensureInitialized();
    }

    final cleaned = [
      ...recallLabels,
      ...input.planningDirection.recallLabels,
    ]
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList();

    final signalByLabel = await _signalByLabel();
    final expandedRecallLabels = _expandRecallLabels(
      cleaned,
      signalByLabel,
    );
    final tagScores = await _tagScoreLoader();
    final favoriteTagIds = await _favoriteTagLoader();
    final favoriteDishIds = await _favoriteDishLoader();
    final recentRecipeIds = (await _recentRecipeLoader()).toSet();

    // 1) 召回：dish_tag 精确召回 + 每个有效信号独立搜索。
    // FTS5 的空格语义是 AND，不能把自由文本和标签直接拼成一个查询。
    final dbTagIds =
        await _tagCatalog.loadDbTagIdsForLabels(expandedRecallLabels);
    final constraints = _RecommendationConstraints.fromInput(input);
    var tagRows = const <Map<String, dynamic>>[];
    if (dbTagIds.isNotEmpty) {
      try {
        tagRows = await (_tagRecipeLoader?.call(dbTagIds, 80) ??
            _db.fetchRecipesByTagIds(dbTagIds));
      } catch (_) {
        // Continue through text recall and the deterministic local pool.
      }
    }
    final searchLabels = expandedRecallLabels.take(6).toList();
    final perSearchLimit = searchLabels.length <= 2 ? 40 : 24;
    final searchBatches = await Future.wait(
      searchLabels.map(
        (label) async {
          try {
            return await (_searchRecipeLoader?.call(label, perSearchLimit) ??
                _db.searchRecipes(label, limit: perSearchLimit));
          } catch (_) {
            return const <Map<String, dynamic>>[];
          }
        },
      ),
    );
    final directRows = _dedupeRowsByDishId([
      ...tagRows,
      for (final batch in searchBatches) ...batch,
    ]);
    var candidateRows = directRows;
    var rows = candidateRows.where(constraints.allows).toList();
    var usedDefaultPool = false;

    // 精确召回为空，或所有精确候选都被硬约束过滤时，退回本地正式候选池。
    if (rows.isEmpty) {
      final defaultRows =
          await (_defaultRecipeLoader?.call(80) ?? _db.fetchDefaultRecipes());
      candidateRows = _dedupeRowsByDishId([...directRows, ...defaultRows]);
      rows = candidateRows.where(constraints.allows).toList();
      usedDefaultPool = defaultRows.isNotEmpty;
    }
    if (rows.isEmpty) {
      return LocalRecommendationBundle(
        recipes: [],
        reasonsByRecipeId: {},
        summary: constraints.filteredSummary(candidateRows.length),
      );
    }

    double scoreForLabel(String label) {
      final signal = signalByLabel[label];
      if (signal == null) return 0;
      return _calibratedFeedbackWeight(tagScores[signal.id] ?? 0);
    }

    // 2) 打分：匹配度 + 人气 + 评分 + 偏好学习/收藏/去重
    final scored = rows.map((row) {
      final tags = List<String>.from(row['tags'] ?? const []);
      final ingredients = (row['ingredients'] as List<dynamic>? ?? const [])
          .map((e) => (e as Map)['name']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
      final name = row['dish_name']?.toString() ?? '';

      int matchCount = 0;
      final matchedLabels = <String>[];
      for (final label in expandedRecallLabels) {
        var matched = false;
        if (tags.any((t) => t.contains(label))) {
          matchCount += 2;
          matched = true;
        }
        if (ingredients.any((i) => i.contains(label))) {
          matchCount += 1;
          matched = true;
        }
        if (name.contains(label)) {
          matchCount += 2;
          matched = true;
        }
        if (matched) matchedLabels.add(label);
      }

      final popularity = (row['popularity_score'] ?? 0) as num;
      final rating = (row['average_rating'] ?? 0) as num;

      // 偏好学习：对命中的标签加权（正向提升/负向惩罚）
      double preferenceBonus = 0.0;
      for (final label in expandedRecallLabels) {
        if (_matchesSignal(name, tags, ingredients, label)) {
          preferenceBonus += scoreForLabel(label) * 0.6;
        }
      }
      for (final t in tags.take(12)) {
        preferenceBonus += scoreForLabel(t) * 0.12;
      }
      for (final i in ingredients.take(10)) {
        preferenceBonus += scoreForLabel(i) * 0.06;
      }

      // 收藏偏好：命中收藏标签额外加成
      double favoriteTagBonus = 0.0;
      for (final label in expandedRecallLabels) {
        final id = signalByLabel[label]?.id;
        if (id != null &&
            favoriteTagIds.contains(id) &&
            _matchesSignal(name, tags, ingredients, label)) {
          favoriteTagBonus += 6.0;
        }
      }

      // 收藏菜品：轻微上浮，方便复访
      final dishId = row['dish_id'].toString();
      final favoriteRecipeBonus = favoriteDishIds.contains(dishId) ? 18.0 : 0.0;

      // 去重：近期刚选中过的菜品下沉
      final recentPenalty = recentRecipeIds.contains(dishId) ? 35.0 : 0.0;

      final historyBonus = _historyPreferenceBonus(
        input: input,
        tags: tags,
        ingredients: ingredients,
        name: name,
      );

      final skipPenalty = _negativeSignalPenalty(
        blockedLabels: input.skippedTagLabels,
        tags: tags,
        ingredients: ingredients,
        name: name,
      );

      final dislikePenalty = _negativeSignalPenalty(
        blockedLabels: input.dislikedTagLabels,
        tags: tags,
        ingredients: ingredients,
        name: name,
      );
      final constraintAdjustment = constraints.scoreAdjustment(row);
      final planningDirectionBonus = _planningDirectionBonus(
        direction: input.planningDirection,
        tags: tags,
        ingredients: ingredients,
        name: name,
      );
      final explicitPreferenceBonus = input.likedTagLabels
              .where(
                (label) => _matchesSignal(name, tags, ingredients, label),
              )
              .length *
          32.0;

      final score = matchCount * 10.0 +
          popularity * 0.02 +
          rating * 5.0 +
          preferenceBonus +
          historyBonus +
          favoriteTagBonus +
          favoriteRecipeBonus -
          skipPenalty -
          dislikePenalty -
          recentPenalty +
          planningDirectionBonus +
          explicitPreferenceBonus +
          constraintAdjustment;
      return _ScoredRecipeRow(
        row: row,
        score: score,
        matchedLabels: matchedLabels.toSet().toList(),
        constraintNotes: constraints.notesFor(row),
        popularity: popularity,
        rating: rating,
        preferenceBonus: preferenceBonus,
        favoriteTagBonus: favoriteTagBonus,
        favoriteRecipeBonus: favoriteRecipeBonus,
        historyBonus: historyBonus,
        negativePenalty: skipPenalty + dislikePenalty,
        recentPenalty: recentPenalty,
        planningDirectionBonus: planningDirectionBonus,
        planningDirection: input.planningDirection,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final shadowCandidates = [
      for (var index = 0; index < scored.length; index++)
        _shadowCandidate(scored[index], index),
    ];
    unawaited(
      _shadowScoringService.observe(
        candidates: shadowCandidates,
        recallPath: usedDefaultPool
            ? V2RecommendationRecallPath.defaultPool
            : V2RecommendationRecallPath.direct,
      ),
    );

    var servedScored = scored;
    var servedRankingVersion = 'local_rank_v2';
    var servedAlgorithmVersion = 'hybrid_v3_0';
    const baselineDecision = RecommendationCanaryDecision(
      useExperiment: false,
      rankingVersion: 'local_rank_v2',
      algorithmVersion: 'hybrid_v3_0',
    );
    try {
      final canaryDecision = await _canaryDecisionLoader();
      if (canaryDecision.useExperiment) {
        final experimentalOrder =
            _experimentalRanker.compare(shadowCandidates).experiment;
        servedScored = [
          for (final candidate in experimentalOrder)
            scored[candidate.baselinePosition],
        ];
        servedRankingVersion = canaryDecision.rankingVersion;
        servedAlgorithmVersion = canaryDecision.algorithmVersion;
      }
    } catch (_) {
      servedScored = scored;
      servedRankingVersion = baselineDecision.rankingVersion;
      servedAlgorithmVersion = baselineDecision.algorithmVersion;
    }

    // 4) 输出映射到 V2 RecipeModel
    final finalRecipes = servedScored
        .where(
          (item) => !_isPlaceholderRecipe(
            item.row['dish_name']?.toString() ?? '',
          ),
        )
        .map((e) => RecipeModel.fromUnifiedDbRow(e.row))
        .where(
            (recipe) => !_containsBlockedSignal(recipe, input.skippedTagLabels))
        .where((recipe) =>
            !_containsBlockedSignal(recipe, input.dislikedTagLabels))
        .take(limit)
        .toList();
    final finalRecipeIds = finalRecipes.map((recipe) => recipe.id).toSet();
    final reasons = <String, String>{
      for (final item in servedScored)
        if (finalRecipeIds.contains(item.row['dish_id'].toString()))
          item.row['dish_id'].toString(): _reasonFor(item),
    };
    return LocalRecommendationBundle(
      recipes: finalRecipes,
      reasonsByRecipeId: reasons,
      summary: _summaryFor(
        finalRecipes.length,
        candidateRows.length - rows.length,
        constraints,
        usedDefaultPool: usedDefaultPool,
      ),
      rankingVersion: servedRankingVersion,
      algorithmVersion: servedAlgorithmVersion,
    );
  }

  List<String> _expandRecallLabels(
    List<String> labels,
    Map<String, TasteSignal> signalByLabel,
  ) {
    final expanded = <String>{};

    void addLabel(String rawLabel) {
      final label = rawLabel.trim();
      if (label.isEmpty || !_isSearchableLabel(label)) return;
      expanded.add(label);
    }

    final sourceLabels = labels.isEmpty ? _defaultRecallLabels : labels;
    for (final rawLabel in sourceLabels) {
      final label = rawLabel.trim();
      final exactSignal = signalByLabel[label];
      if (exactSignal != null) {
        exactSignal.recallLabels.forEach(addLabel);
      } else {
        for (final entry in signalByLabel.entries) {
          if (entry.key.isEmpty || !label.contains(entry.key)) continue;
          entry.value.recallLabels.forEach(addLabel);
        }
      }

      final aliases = _recallAliases[label];
      if (aliases != null) {
        aliases.forEach(addLabel);
      }
      for (final entry in _recallAliases.entries) {
        if (label.contains(entry.key)) entry.value.forEach(addLabel);
      }
      addLabel(label);
    }

    return expanded.isEmpty ? List.of(_defaultRecallLabels) : expanded.toList();
  }

  bool _isSearchableLabel(String label) {
    final compact = label.replaceAll(' ', '');
    if (compact.isEmpty || RegExp(r'^\d+$').hasMatch(compact)) return false;
    if (RegExp(r'^\d+(?:分钟|分|元|块|人)(?:内|以内)?$').hasMatch(compact)) {
      return false;
    }
    if (_freeformNoise.any(compact.contains)) return false;
    return compact.length <= 8;
  }

  List<Map<String, dynamic>> _dedupeRowsByDishId(
    List<Map<String, dynamic>> rows,
  ) {
    final seen = <String>{};
    final deduped = <Map<String, dynamic>>[];
    for (final row in rows) {
      final id = row['dish_id']?.toString() ?? '';
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      deduped.add(row);
    }
    return deduped;
  }

  double _historyPreferenceBonus({
    required TasteInferenceInput input,
    required List<String> tags,
    required List<String> ingredients,
    required String name,
  }) {
    if (input.historyPreferenceSummary.isEmpty) return 0.0;

    var bonus = 0.0;
    for (var i = 0; i < input.likedTagIds.length; i++) {
      final id = input.likedTagIds[i];
      final label =
          i < input.likedTagLabels.length ? input.likedTagLabels[i] : '';
      final weight = _calibratedFeedbackWeight(
        input.historyPreferenceSummary[id] ?? 0,
      );
      if (weight == 0) continue;
      if (_matchesSignal(name, tags, ingredients, label)) {
        bonus += weight * 2.4;
      }
    }
    return bonus;
  }

  double _negativeSignalPenalty({
    required List<String> blockedLabels,
    required List<String> tags,
    required List<String> ingredients,
    required String name,
  }) {
    var penalty = 0.0;
    for (final label in blockedLabels) {
      if (_matchesSignal(name, tags, ingredients, label)) {
        penalty += 120.0;
      }
    }
    return penalty;
  }

  double _planningDirectionBonus({
    required MealPlanningDirection direction,
    required List<String> tags,
    required List<String> ingredients,
    required String name,
  }) {
    if (direction == MealPlanningDirection.balanced) return 0;
    final haystack = '$name|${tags.join('|')}|${ingredients.join('|')}';
    final positiveTerms = switch (direction) {
      MealPlanningDirection.health => const [
          '轻食',
          '清淡',
          '高蛋白',
          '低脂',
          '蔬菜',
          '豆腐',
          '鱼',
          '鸡胸',
          '蒸',
          '煮',
          '无糖',
          '粗粮',
        ],
      MealPlanningDirection.experience => const [
          '浓郁',
          '香辣',
          '麻辣',
          '火锅',
          '烧烤',
          '咖喱',
          '芝士',
          '特色',
        ],
      MealPlanningDirection.balanced => const <String>[],
    };
    final negativeTerms = direction == MealPlanningDirection.health
        ? const ['油炸', '重油', '肥腻', '可乐', '雪碧', '奶茶', '含糖', '炸鸡']
        : const <String>[];
    final positiveMatches = positiveTerms.where(haystack.contains).length;
    final negativeMatches = negativeTerms.where(haystack.contains).length;
    return positiveMatches * 10.0 - negativeMatches * 36.0;
  }

  bool _matchesSignal(
    String name,
    List<String> tags,
    List<String> ingredients,
    String label,
  ) {
    if (label.trim().isEmpty) return false;
    return name.contains(label) ||
        tags.any((tag) => tag.contains(label)) ||
        ingredients.any((ingredient) => ingredient.contains(label));
  }

  double _calibratedFeedbackWeight(int rawScore) {
    if (rawScore == 0) return 0;
    final magnitude = math.min(
      _maximumFeedbackWeight,
      math.sqrt(rawScore.abs().toDouble()),
    );
    return rawScore.isNegative ? -magnitude : magnitude;
  }

  bool _containsBlockedSignal(RecipeModel recipe, List<String> blockedLabels) {
    if (blockedLabels.isEmpty) return false;
    final haystack =
        '${recipe.name}|${recipe.description}|${recipe.ingredients.join('|')}|${recipe.tags.join('|')}';
    return blockedLabels
        .any((label) => label.trim().isNotEmpty && haystack.contains(label));
  }

  bool _isPlaceholderRecipe(String name) {
    final compact = name.trim().toLowerCase();
    return compact.contains('示例菜谱') ||
        compact.startsWith('soup_') ||
        compact.startsWith('dessert_') ||
        compact.startsWith('drink_') ||
        compact.startsWith('condiment_') ||
        compact.startsWith('semi-finished_') ||
        compact.startsWith('aquatic_');
  }

  V2RecommendationShadowCandidate _shadowCandidate(
    _ScoredRecipeRow item,
    int baselinePosition,
  ) {
    final tags = (item.row['tags'] as List<dynamic>? ?? const [])
        .map((tag) => tag.toString().trim())
        .where((tag) => tag.isNotEmpty);
    final ingredients = (item.row['ingredients'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((ingredient) => ingredient['name']?.toString().trim() ?? '')
        .where((ingredient) => ingredient.isNotEmpty);
    final firstTag = tags.isEmpty ? '' : tags.first;
    final firstIngredient = ingredients.isEmpty ? '' : ingredients.first;
    return V2RecommendationShadowCandidate(
      candidateKey: 'candidate_$baselinePosition',
      baselinePosition: baselinePosition,
      baselineScore: item.score,
      rating: item.rating.toDouble(),
      popularity: item.popularity.toDouble(),
      preferenceBonus: item.preferenceBonus,
      historyBonus: item.historyBonus,
      favoriteBonus: item.favoriteTagBonus + item.favoriteRecipeBonus,
      negativePenalty: item.negativePenalty,
      recentPenalty: item.recentPenalty,
      diversityKey: '$firstTag|$firstIngredient',
    );
  }

  String _reasonFor(_ScoredRecipeRow item) {
    final pieces = <String>[];
    if (item.matchedLabels.isNotEmpty) {
      pieces.add('命中 ${item.matchedLabels.take(3).join('、')}');
    }
    pieces.addAll(item.constraintNotes);
    if (item.rating > 0) {
      pieces.add('评分 ${item.rating.toStringAsFixed(1)}');
    }
    if (item.popularity > 0) {
      pieces.add('人气 ${item.popularity.toStringAsFixed(0)}');
    }
    if (item.preferenceBonus > 0 || item.historyBonus > 0) {
      pieces.add('贴合你的历史偏好');
    }
    if (item.planningDirectionBonus > 0) {
      pieces.add('符合${item.planningDirection.label}规划');
    }
    if (item.favoriteTagBonus > 0) {
      pieces.add('包含收藏口味');
    }
    if (item.negativePenalty > 0) {
      pieces.add('已避开不合适信号');
    }
    if (item.recentPenalty > 0) {
      pieces.add('近期吃过，已轻微下沉');
    }
    if (pieces.isEmpty) {
      pieces.add('综合 HowToCook 菜谱信息排序靠前');
    }
    return '${pieces.join('，')}。';
  }

  String _summaryFor(
    int finalCount,
    int filteredCount,
    _RecommendationConstraints constraints, {
    required bool usedDefaultPool,
  }) {
    if (finalCount == 0) {
      return constraints.filteredSummary(filteredCount);
    }
    final rankingText = constraints.hasRankingSignals
        ? '，并参考${constraints.rankingSummaryLabel}调整排序'
        : '';
    final filterText = filteredCount > 0
        ? '，已按${constraints.summaryLabel}过滤 $filteredCount 道不合适候选'
        : '';
    final recallText = usedDefaultPool
        ? '精确标签未命中，HowToCook 已从本地正式菜谱池'
        : 'HowToCook 已按偏好标签、评分、人气和近期反馈';
    return '$recallText收束出 $finalCount 道候选$rankingText$filterText。';
  }

  static const List<String> _defaultRecallLabels = [
    '荤菜',
    '素菜',
    '主食',
    '汤羹',
    '快手',
  ];

  static const double _maximumFeedbackWeight = 8.0;

  static const Map<String, List<String>> _recallAliases = {
    '家常': _defaultRecallLabels,
    '家常菜': _defaultRecallLabels,
    '清淡': ['清爽', '蒸', '素菜', '汤羹'],
    '热一点': ['热菜', '汤羹', '主食'],
    '热乎': ['热菜', '汤羹', '主食'],
    '暖胃': ['汤羹', '主食'],
  };

  static const List<String> _freeformNoise = [
    '想吃',
    '吃点',
    '来点',
    '今晚',
    '今天',
    '现在',
    '一点',
    '一下',
  ];
}

class _ScoredRecipeRow {
  const _ScoredRecipeRow({
    required this.row,
    required this.score,
    required this.matchedLabels,
    required this.constraintNotes,
    required this.popularity,
    required this.rating,
    required this.preferenceBonus,
    required this.favoriteTagBonus,
    required this.favoriteRecipeBonus,
    required this.historyBonus,
    required this.negativePenalty,
    required this.recentPenalty,
    required this.planningDirectionBonus,
    required this.planningDirection,
  });

  final Map<String, dynamic> row;
  final double score;
  final List<String> matchedLabels;
  final List<String> constraintNotes;
  final num popularity;
  final num rating;
  final double preferenceBonus;
  final double favoriteTagBonus;
  final double favoriteRecipeBonus;
  final double historyBonus;
  final double negativePenalty;
  final double recentPenalty;
  final double planningDirectionBonus;
  final MealPlanningDirection planningDirection;
}

class _RecommendationConstraints {
  const _RecommendationConstraints({
    this.maxTimeMinutes,
    this.maxBudgetYuan,
    this.partySize,
    this.blockedTerms = const [],
  });

  factory _RecommendationConstraints.fromInput(TasteInferenceInput input) {
    final signalText = [
      input.freeformRequirement,
      ...input.dislikedTagLabels,
      ...input.skippedTagLabels,
      ...input.likedTagLabels,
    ].join(' ');
    final structured = input.structuredConstraints;
    return _RecommendationConstraints(
      maxTimeMinutes:
          structured.maxTimeMinutes ?? _parseMaxTimeMinutes(signalText),
      maxBudgetYuan:
          structured.maxBudgetYuan ?? _parseMaxBudgetYuan(signalText),
      partySize: structured.partySize ?? _parsePartySize(signalText),
      blockedTerms: _parseBlockedTerms(input, signalText),
    );
  }

  final int? maxTimeMinutes;
  final int? maxBudgetYuan;
  final int? partySize;
  final List<String> blockedTerms;

  bool get hasAny =>
      maxTimeMinutes != null ||
      maxBudgetYuan != null ||
      partySize != null ||
      blockedTerms.isNotEmpty;

  bool get hasRankingSignals => maxBudgetYuan != null || partySize != null;

  List<String> get activeLabels => [
        if (maxTimeMinutes != null) '$maxTimeMinutes 分钟内',
        if (maxBudgetYuan != null) '$maxBudgetYuan 元内',
        if (partySize != null) '$partySize 人',
        if (blockedTerms.isNotEmpty) '忌口',
      ];

  String get summaryLabel {
    final labels = <String>[
      if (maxTimeMinutes != null) '时间约束',
      if (maxBudgetYuan != null) '预算',
      if (partySize != null) '人数',
      if (blockedTerms.isNotEmpty) '忌口',
    ];
    return labels.join('、');
  }

  String get rankingSummaryLabel {
    final labels = <String>[
      if (maxBudgetYuan != null) '预算',
      if (partySize != null) '人数',
    ];
    return labels.join('、');
  }

  bool allows(Map<String, dynamic> row) {
    if (!_allowsTime(row)) return false;
    if (!_allowsBlockedTerms(row)) return false;
    return true;
  }

  List<String> notesFor(Map<String, dynamic> row) {
    return [
      if (maxTimeMinutes != null) '$maxTimeMinutes 分钟内可完成',
      ..._budgetNotesFor(row),
      ..._partyNotesFor(row),
    ];
  }

  double scoreAdjustment(Map<String, dynamic> row) {
    return _budgetAdjustment(row) + _partyAdjustment(row);
  }

  String filteredSummary(int recalledCount) {
    if (!hasAny) return 'HowToCook 暂时没有命中候选。';
    if (recalledCount <= 0) return 'HowToCook 暂时没有命中候选。';
    return 'HowToCook 已按$summaryLabel过滤 $recalledCount 道候选，但暂时没有剩余结果。';
  }

  bool _allowsTime(Map<String, dynamic> row) {
    final maxTime = maxTimeMinutes;
    if (maxTime == null) return true;
    final raw = row['total_time_minutes'];
    final minutes = raw is num ? raw.toInt() : int.tryParse('$raw');
    if (minutes == null || minutes <= 0) return true;
    return minutes <= maxTime;
  }

  bool _allowsBlockedTerms(Map<String, dynamic> row) {
    if (blockedTerms.isEmpty) return true;
    final ingredients = (row['ingredients'] as List<dynamic>? ?? const [])
        .map((item) => (item as Map)['name']?.toString() ?? '')
        .join('|');
    final haystack = [
      row['dish_name']?.toString() ?? '',
      row['recipe_description']?.toString() ?? '',
      ingredients,
      ...(row['tags'] as List<dynamic>? ?? const []).map((item) => '$item'),
      ...(row['scenes'] as List<dynamic>? ?? const []).map((item) => '$item'),
      ...(row['health_tags'] as List<dynamic>? ?? const [])
          .map((item) => '$item'),
    ].join('|');
    return !blockedTerms.any(haystack.contains);
  }

  List<String> _budgetNotesFor(Map<String, dynamic> row) {
    final budget = maxBudgetYuan;
    if (budget == null) return const [];
    final cost = _estimatedCostLevel(row);
    if (cost <= 1) return const ['预算友好'];
    if (cost >= 3 && budget <= 60) return const ['预算略高，已下沉'];
    return const ['预算可接受'];
  }

  double _budgetAdjustment(Map<String, dynamic> row) {
    final budget = maxBudgetYuan;
    if (budget == null) return 0;
    final cost = _estimatedCostLevel(row);
    if (budget <= 30) {
      return switch (cost) {
        1 => 18,
        2 => 0,
        _ => -42,
      };
    }
    if (budget <= 60) {
      return switch (cost) {
        1 => 10,
        2 => 6,
        _ => -18,
      };
    }
    return cost >= 3 ? 6 : 0;
  }

  List<String> _partyNotesFor(Map<String, dynamic> row) {
    final target = partySize;
    if (target == null) return const [];
    final servings = _servingsFor(row);
    if (servings == null) return const [];
    final diff = (servings - target).abs();
    if (diff <= (target <= 2 ? 1 : 2)) {
      return ['适合 $target 人'];
    }
    return ['分量与 $target 人不完全匹配，已下沉'];
  }

  double _partyAdjustment(Map<String, dynamic> row) {
    final target = partySize;
    if (target == null) return 0;
    final servings = _servingsFor(row);
    if (servings == null || servings <= 0) return 0;
    final diff = (servings - target).abs();
    if (diff == 0) return 22;
    if (diff <= (target <= 2 ? 1 : 2)) return 12;
    if (target <= 2 && servings >= 5) return -45;
    return -18;
  }

  int _estimatedCostLevel(Map<String, dynamic> row) {
    final ingredients = (row['ingredients'] as List<dynamic>? ?? const [])
        .map((item) => (item as Map)['name']?.toString() ?? '')
        .join('|');
    final haystack = [
      row['dish_name']?.toString() ?? '',
      ingredients,
      ...(row['tags'] as List<dynamic>? ?? const []).map((item) => '$item'),
    ].join('|');
    if (['帝王蟹', '鲍鱼', '海参', '龙虾', '蟹', '海鲜锅'].any(haystack.contains)) {
      return 3;
    }
    if (['牛肉', '羊肉', '肥牛', '排骨', '虾'].any(haystack.contains)) {
      return 2;
    }
    if (['豆腐', '青菜', '土豆', '鸡蛋', '番茄', '面'].any(haystack.contains)) {
      return 1;
    }
    return 2;
  }

  int? _servingsFor(Map<String, dynamic> row) {
    final raw = row['servings'];
    return raw is num ? raw.toInt() : int.tryParse('$raw');
  }

  static int? _parseMaxTimeMinutes(String text) {
    final normalized = text.replaceAll(' ', '');
    final match = RegExp(r'(\d+)(?:分钟|分|min|m)(?:内|以内)?').firstMatch(
      normalized,
    );
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    if (normalized.contains('快手') || normalized.contains('马上')) return 20;
    if (normalized.contains('不着急')) return null;
    return null;
  }

  static int? _parseMaxBudgetYuan(String text) {
    final normalized = text.replaceAll(' ', '');
    final match = RegExp(r'(\d+)(?:元|块|rmb|¥)(?:内|以内)?').firstMatch(
      normalized.toLowerCase(),
    );
    if (match != null) return int.tryParse(match.group(1)!);
    if (normalized.contains('经济') || normalized.contains('便宜')) return 30;
    if (normalized.contains('想吃好一点')) return 100;
    return null;
  }

  static int? _parsePartySize(String text) {
    final normalized = text.replaceAll(' ', '');
    final range = RegExp(r'(\d+)-(\d+)人').firstMatch(normalized);
    if (range != null) {
      final low = int.tryParse(range.group(1)!);
      final high = int.tryParse(range.group(2)!);
      if (low != null && high != null) return ((low + high) / 2).round();
    }
    final single = RegExp(r'(\d+)人').firstMatch(normalized);
    if (single != null) return int.tryParse(single.group(1)!);
    if (normalized.contains('一人食')) return 1;
    return null;
  }

  static List<String> _parseBlockedTerms(
    TasteInferenceInput input,
    String text,
  ) {
    final terms = <String>{};
    void addAll(Iterable<String> items) {
      for (final item in items) {
        if (item.trim().isNotEmpty) terms.add(item.trim());
      }
    }

    for (final label in [
      ...input.dislikedTagLabels,
      ...input.skippedTagLabels,
      ...input.structuredConstraints.dietaryRestrictions,
    ]) {
      if (label.contains('无忌口')) continue;
      if (label.contains('海鲜')) addAll(['海鲜', '虾', '鱼', '蟹', '贝']);
      if (label.contains('芒果')) addAll(['芒果']);
      if (label.contains('乳糖')) addAll(['奶', '奶油', '奶酪', '牛奶']);
      if (label.contains('清真')) addAll(['猪肉', '猪', '五花肉']);
      if (label.contains('素食')) addAll(['猪', '牛', '羊', '鸡', '鸭', '鱼', '虾']);
    }

    if (text.contains('不要海鲜') || text.contains('海鲜过敏')) {
      addAll(['海鲜', '虾', '鱼', '蟹', '贝']);
    }
    if (text.contains('素食') || text.contains('吃素') || text.contains('素一点')) {
      addAll(['猪', '牛', '羊', '鸡', '鸭', '鱼', '虾', '肉', '荤', '排骨', '五花肉']);
    }
    if (text.contains('清真') || text.contains('不吃猪肉')) {
      addAll(['猪肉', '猪', '五花肉', '肥肉', '培根', '火腿']);
    }
    if (text.contains('不要辣') || text.contains('不吃辣')) {
      addAll(['辣', '麻辣', '香辣']);
    }
    return terms.toList();
  }
}
