import 'dart:async';
import 'dart:math' as math;

import 'package:eatwhat_app/core/services/unified_recipe_database_service.dart';
import 'package:eatwhat_app/v2/core/data/models/meal_planning_direction.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_signal.dart';
import 'package:eatwhat_app/v2/core/services/preference_recall_bridge.dart';
import 'package:eatwhat_app/v2/core/services/recipe_eligibility.dart';
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
typedef FavoriteTagLabelLoader = Future<Set<String>> Function(
  Set<String> tagIds,
);
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
    this.fallbackReason,
  });

  final List<RecipeModel> recipes;
  final Map<String, String> reasonsByRecipeId;
  final String summary;
  final String? fallbackReason;
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
    FavoriteTagLabelLoader? favoriteTagLabelLoader,
    FavoriteDishLoader? favoriteDishLoader,
    RecentRecipeLoader? recentRecipeLoader,
    V2RecommendationShadowScoringService? shadowScoringService,
    V2RecommendationCanaryService? canaryService,
    V2RecommendationCanaryDecisionLoader? canaryDecisionLoader,
    V2RecommendationExperimentalRanker? experimentalRanker,
    DateTime Function()? mealPeriodClock,
  })  : _db = db ?? UnifiedRecipeDatabaseService.instance,
        _tagCatalog = tagCatalogService ?? V2TagCatalogService.instance,
        _searchRecipeLoader = searchRecipeLoader,
        _tagRecipeLoader = tagRecipeLoader,
        _defaultRecipeLoader = defaultRecipeLoader,
        _tagScoreLoader =
            tagScoreLoader ?? V2PreferenceFeedbackService.instance.getTagScores,
        _favoriteTagLoader =
            favoriteTagLoader ?? V2FavoritesService.instance.getFavoriteTagIds,
        _favoriteTagLabelLoader = favoriteTagLabelLoader ??
            ((tagIds) => (tagCatalogService ?? V2TagCatalogService.instance)
                .loadLabelsForTagIds(tagIds)),
        _favoriteDishLoader = favoriteDishLoader ??
            V2FavoritesService.instance.getFavoriteDishIds,
        _recentRecipeLoader = recentRecipeLoader ??
            V2PreferenceFeedbackService.instance.getRecentRecipeIds,
        _shadowScoringService = shadowScoringService ??
            V2RecommendationShadowScoringService.instance,
        _canaryDecisionLoader = canaryDecisionLoader ??
            (canaryService ?? V2RecommendationCanaryService.instance).decide,
        _experimentalRanker =
            experimentalRanker ?? V2RecommendationExperimentalRanker.instance,
        _mealPeriodClock = mealPeriodClock;

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
  final FavoriteTagLabelLoader _favoriteTagLabelLoader;
  final FavoriteDishLoader _favoriteDishLoader;
  final RecentRecipeLoader _recentRecipeLoader;
  final V2RecommendationShadowScoringService _shadowScoringService;
  final V2RecommendationCanaryDecisionLoader _canaryDecisionLoader;
  final V2RecommendationExperimentalRanker _experimentalRanker;
  final DateTime Function()? _mealPeriodClock;

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
    int limit = 3,
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
    int limit = 3,
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
    final tagScores = await _tagScoreLoader();
    final longTermTasteLabels = _longTermTasteLabels(input, tagScores);
    final expandedRecallLabels = _expandRecallLabels(
      [...cleaned, ...longTermTasteLabels],
      signalByLabel,
    );
    final favoriteTagIds = await _favoriteTagLoader();
    var favoriteTagLabels = const <String>{};
    if (favoriteTagIds.isNotEmpty) {
      try {
        favoriteTagLabels = await _favoriteTagLabelLoader(favoriteTagIds);
      } catch (_) {
        // Favorites are a bonus; a catalog problem must not fail recall.
      }
    }
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
    // 餐食/占位边界必须早于排序和默认池决策，不能只在最终展示前过滤。
    bool allowsCandidate(Map<String, dynamic> row) =>
        !_isPlaceholderRecipe(row['dish_name']?.toString() ?? '') &&
        constraints.allows(row);
    var candidateRows = directRows;
    var rows = candidateRows.where(allowsCandidate).toList();
    var usedDefaultPool = false;

    // 精确召回为空，或所有精确候选都被硬约束过滤时，退回本地正式候选池。
    if (rows.isEmpty) {
      final defaultRows =
          await (_defaultRecipeLoader?.call(80) ?? _db.fetchDefaultRecipes());
      candidateRows = _dedupeRowsByDishId([...directRows, ...defaultRows]);
      rows = candidateRows.where(allowsCandidate).toList();
      usedDefaultPool = defaultRows.isNotEmpty;
    }
    if (rows.isEmpty) {
      return LocalRecommendationBundle(
        recipes: [],
        reasonsByRecipeId: {},
        summary: constraints.filteredSummary(candidateRows.length),
        fallbackReason: candidateRows.isEmpty
            ? 'local_empty'
            : 'candidate_constraints_rejected',
      );
    }

    double scoreForLabel(String label) {
      final signal = signalByLabel[label];
      // Feedback is written with display labels in some paths and signal IDs
      // in others. Read both so existing user history keeps working.
      final raw = signal == null
          ? tagScores[label] ?? 0
          : tagScores[signal.id] ?? tagScores[label] ?? 0;
      return _calibratedFeedbackWeight(raw);
    }

    final mealPeriodNow = _mealPeriodClock?.call() ?? DateTime.now();
    final cookingRequestLabels = constraints.isCooking
        ? _cookingRequestLabels(input.freeformRequirement)
        : const <String>[];
    final explicitRequestLabels = <String>{
      ...input.likedTagLabels,
      // Explicit freeform requests must be able to beat meal-period judgment
      // even when the chosen execution path is delivery or dine-in.
      ..._cookingRequestLabels(input.freeformRequirement),
    };
    final wantsBreakfast = input.likedTagLabels.any(
          (label) => label.contains('早餐') || label.contains('早饭'),
        ) ||
        RegExp(r'早餐|早饭').hasMatch(input.freeformRequirement);
    final mealPeriodLabel = mealPeriodNow.hour >= 5 && mealPeriodNow.hour < 10
        ? '早餐'
        : (mealPeriodNow.hour >= 21 || mealPeriodNow.hour < 5)
            ? '夜宵'
            : '';

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

      // 收藏偏好：命中收藏标签额外加成。收藏可能在本次召回标签之外，
      // 因此同时检查收藏标签本身和当前召回标签对应的 signal id。
      final favoriteLabelsForScoring = <String>{...favoriteTagLabels};
      for (final label in expandedRecallLabels) {
        final id = signalByLabel[label]?.id;
        if (id != null && favoriteTagIds.contains(id)) {
          favoriteLabelsForScoring.add(label);
        }
      }
      double favoriteTagBonus = 0.0;
      for (final label in favoriteLabelsForScoring) {
        if (_matchesSignal(name, tags, ingredients, label)) {
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
        longTermLabels: longTermTasteLabels,
        tagScores: tagScores,
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
      final mealPeriodBonus = _mealPeriodAdjustment(
        now: mealPeriodNow,
        name: name,
        tags: tags,
        isCooking: constraints.isCooking,
        difficulty: row['difficulty'] is num ? row['difficulty'] as num : null,
        wantsBreakfast: wantsBreakfast,
        explicitRequestLabels: explicitRequestLabels,
      );
      final planningDirectionBonus = _planningDirectionBonus(
        direction: input.planningDirection,
        tags: tags,
        ingredients: ingredients,
        name: name,
      );
      final healthNutritionBonus = _healthNutritionAdjustment(
        direction: input.planningDirection,
        nutrition: _nutritionOfRow(row),
      );
      final explicitPreferenceBonus = input.likedTagLabels
              .where(
                (label) => _matchesSignal(name, tags, ingredients, label),
              )
              .length *
          32.0;
      // 多个或重复自由文本请求最多加一次，不与同名喜欢标签重复加分。
      final cookingRequestBonus = cookingRequestLabels.any(
        (label) =>
            !input.likedTagLabels.contains(label) &&
            _matchesSignal(name, tags, ingredients, label),
      )
          ? 32.0
          : 0.0;

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
          cookingRequestBonus +
          healthNutritionBonus +
          mealPeriodBonus +
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
        mealPeriodBonus: mealPeriodBonus,
        mealPeriodLabel: mealPeriodLabel,
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
        .map((e) => RecipeModel.fromUnifiedDbRow(e.row))
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
      if (label.isEmpty ||
          !PreferenceRecallBridge.isFoodLabel(label) ||
          !_isSearchableLabel(label)) {
        return;
      }
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
      // Product cards such as 川菜/西餐/晚餐 have no same-named database tag;
      // bridge them to concrete taste, ingredient and dish-name vocabulary.
      PreferenceRecallBridge.hintsFor(label).forEach(addLabel);
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

  List<String> _cookingRequestLabels(String requirement) {
    // 仅识别完整的简短菜名/肯定句，不从「不想吃小龙虾」中截取正向词。
    final request = RegExp(
      r'^(?:我)?(?:今天|今晚|现在)?(?:想要|想|要|来|推荐|喜欢)?'
      r'(?:吃|做)?(?:点|些|一份)?\s*'
      r'([^\s，,。；;!！？?]{2,8}?)(?:吧|呀|啊)?$',
    );
    return requirement
        .split(RegExp(r'[，,。；;!！？?\n]'))
        .map((clause) => request.firstMatch(clause.trim())?.group(1))
        .whereType<String>()
        .where((label) => !RegExp(r'^(?:不|别|避免|忌)').hasMatch(label))
        .toSet()
        .toList();
  }

  double _historyPreferenceBonus({
    required TasteInferenceInput input,
    required List<String> tags,
    required List<String> ingredients,
    required String name,
    required List<String> longTermLabels,
    required Map<String, int> tagScores,
  }) {
    var bonus = 0.0;
    for (var i = 0; i < input.likedTagIds.length; i++) {
      final id = input.likedTagIds[i];
      final label =
          i < input.likedTagLabels.length ? input.likedTagLabels[i] : '';
      final weight = _calibratedFeedbackWeight(
        input.historyPreferenceSummary[id] ??
            input.historyPreferenceSummary[label] ??
            0,
      );
      if (weight == 0) continue;
      if (_matchesSignal(name, tags, ingredients, label)) {
        bonus += weight * 2.4;
      }
    }
    // With no preference picked for this meal, the decaying long-term taste
    // profile still shapes the first pick. Cap it below an explicit request.
    var longTermBonus = 0.0;
    for (final label in longTermLabels) {
      if (!_matchesSignal(name, tags, ingredients, label)) continue;
      longTermBonus += _calibratedFeedbackWeight(tagScores[label] ?? 0) * 1.6;
    }
    return bonus + math.min(longTermBonus, 32.0);
  }

  /// Strong, positive, food-like labels when the current session has no
  /// explicit food intent. Weak and negative history is ignored.
  List<String> _longTermTasteLabels(
    TasteInferenceInput input,
    Map<String, int> tagScores,
  ) {
    if (input.likedTagLabels.isNotEmpty ||
        input.freeformRequirement.trim().isNotEmpty ||
        input.skippedTagLabels.isNotEmpty ||
        input.planningDirection != MealPlanningDirection.balanced) {
      return const [];
    }
    final entries = tagScores.entries
        .where((entry) => entry.value >= _longTermTasteThreshold)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final labels = <String>[];
    for (final entry in entries) {
      final label = entry.key.trim();
      if (label.isEmpty ||
          !PreferenceRecallBridge.isFoodLabel(label) ||
          RegExp(r'^[a-z]+_').hasMatch(label) ||
          _nonTasteSourceLabels.contains(label) ||
          label.contains('外卖') ||
          label.contains('地图') ||
          input.dislikedTagLabels.contains(label)) {
        continue;
      }
      if (!labels.contains(label)) labels.add(label);
      if (labels.length >= 3) break;
    }
    return labels;
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

  /// 时段感知：只对错配感最强的早餐（5-10 点）与夜宵（21 点-次日 5 点）做调整，
  /// 其余时段保持中性，避免过度干预。只匹配菜名与标签，不匹配食材，
  /// 防止「鸡蛋」这类常见食材在早餐时段大面积误触发。
  static const List<String> _morningPositiveTerms = [
    '粥',
    '豆浆',
    '包子',
    '馒头',
    '鸡蛋',
    '牛奶',
    '燕麦',
    '面点',
    '清淡',
    '吐司',
    '馄饨',
    '蒸蛋',
    '面包',
    '三明治',
    '煎饼',
    '油条',
    '花卷',
  ];
  static const List<String> _morningHeavyTerms = [
    '红烧',
    '排骨',
    '猪蹄',
    '扣肉',
    '肥肠',
    '水煮',
    '干锅',
    '火锅',
    '烧烤',
    '麻辣',
    '香辣',
    '油炸',
    '炸鸡',
    '铁板',
    '孜然',
    '烤鱼',
    '小龙虾',
    '啤酒',
    '夜宵',
    '下饭',
    '聚餐',
  ];
  static const List<String> _lateNightPositiveTerms = [
    '夜宵',
    '烧烤',
    '小龙虾',
    '串',
    '炸鸡',
    '泡面',
    '卤味',
    '啤酒',
    '烤鱼',
    '面',
    '粉',
    '粥',
    '馄饨',
    '饺子',
    '汤羹',
  ];
  static const List<String> _lateNightHeavyTerms = [
    '红烧',
    '扣肉',
    '猪蹄',
    '肥肠',
    '整鸡',
    '烤鸭',
    '水煮',
    '干锅',
    '下饭',
    '聚餐',
  ];

  double _mealPeriodAdjustment({
    required DateTime now,
    required String name,
    required List<String> tags,
    required bool isCooking,
    required num? difficulty,
    required bool wantsBreakfast,
    required Set<String> explicitRequestLabels,
  }) {
    final hour = now.hour;
    final haystack = '$name|${tags.join('|')}';
    final isMorning = hour >= 5 && hour < 10;
    final isLateNight = hour >= 21 || hour < 5;
    final breakfastMismatch = tags.contains('早餐') && !wantsBreakfast;

    bool explicitlyAsked(String term) => explicitRequestLabels.any(
          (label) =>
              label.isNotEmpty &&
              (label.contains(term) || term.contains(label)),
        );

    if (isMorning) {
      var score = tags.contains('早餐') ? 30.0 : 0.0;
      for (final term in _morningPositiveTerms) {
        if (haystack.contains(term)) score += 8;
      }
      for (final term in _morningHeavyTerms) {
        if (haystack.contains(term) && !explicitlyAsked(term)) {
          score -= 26;
        }
      }
      return score;
    }
    if (isLateNight) {
      var score = 0.0;
      // 做饭时热的蒸蛋/粥可以是夜宵；外卖和堂食的早餐面包不是。
      if (breakfastMismatch && !isCooking && !explicitlyAsked('早餐')) {
        score -= 26;
      }
      for (final term in _lateNightHeavyTerms) {
        if (haystack.contains(term) && !explicitlyAsked(term)) {
          score -= 18;
        }
      }
      if (isCooking) {
        // 做饭只给低难度的实际简餐一次小加分，不让派生夜宵标签堆分。
        // 菜名不用于推断耗时；粥、面等也可能有已知的较长制作时间。
        final isSimple =
            difficulty != null && difficulty >= 1 && difficulty <= 2;
        final isSimpleDish = const ['面', '粥', '蒸蛋', '鸡蛋羹'].any(name.contains);
        return score + (isSimple && isSimpleDish ? 6.0 : 0.0);
      }
      for (final term in _lateNightPositiveTerms) {
        if (haystack.contains(term)) score += 10;
      }
      return score;
    }
    // 午餐和晚餐不应被早餐场景的菜挤占，除非本轮明确要早餐。
    if (breakfastMismatch && !explicitlyAsked('早餐')) return -14;
    return 0;
  }

  /// 行里的营养数据可能是任意泛型的 Map（含 const {}），统一转成 `Map<String, dynamic>`。
  static Map<String, dynamic> _nutritionOfRow(Map<String, dynamic> row) {
    final raw = row['nutrition'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  /// 健康向的营养数据调整：低卡 +8、高蛋白 +8、高钠 -10。
  /// 只在健康向生效，且要求行里有营养水合数据（nutrition_profile 表）。
  double _healthNutritionAdjustment({
    required MealPlanningDirection direction,
    required Map<String, dynamic> nutrition,
  }) {
    if (direction != MealPlanningDirection.health || nutrition.isEmpty) {
      return 0;
    }
    final calories = (nutrition['calories'] as num?)?.toDouble() ?? 0;
    final protein = (nutrition['protein'] as num?)?.toDouble() ?? 0;
    final sodium = (nutrition['sodium'] as num?)?.toDouble() ?? 0;

    var bonus = 0.0;
    if (calories > 0 && calories <= 500) bonus += 8;
    if (protein >= 20) bonus += 8;
    if (sodium >= 1500) bonus -= 10;
    return bonus;
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
    if (item.mealPeriodBonus > 0 && item.mealPeriodLabel.isNotEmpty) {
      pieces.add('按${item.mealPeriodLabel}时段优先');
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
        : 'HowToCook 已按本轮偏好与本地菜谱信号';
    final safetyText = constraints.eligibility.hasDietaryRestrictions
        ? RecipeEligibility.safetyNotice
        : '';
    return '$recallText收束出 $finalCount 道候选$rankingText$filterText。$safetyText';
  }

  static const List<String> _defaultRecallLabels = [
    '荤菜',
    '素菜',
    '主食',
    '汤羹',
    '快手',
  ];

  static const double _maximumFeedbackWeight = 8.0;
  static const int _longTermTasteThreshold = 6;
  static const Set<String> _nonTasteSourceLabels = {
    'HowToCook',
    'AI',
    '美团外卖',
    '饿了么',
    '大众点评',
    'Apple 地图',
  };

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
    required this.mealPeriodBonus,
    required this.mealPeriodLabel,
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
  final double mealPeriodBonus;
  final String mealPeriodLabel;
}

class _RecommendationConstraints {
  const _RecommendationConstraints({
    required this.eligibility,
    required this.isCooking,
    this.maxBudgetYuan,
    this.partySize,
  });

  factory _RecommendationConstraints.fromInput(TasteInferenceInput input) {
    final signalText = [
      input.freeformRequirement,
      ...input.likedTagLabels,
    ].join(' ');
    final structured = input.structuredConstraints;
    return _RecommendationConstraints(
      eligibility: RecipeEligibility(
        dietaryRestrictions: structured.dietaryRestrictions,
        dislikedLabels: input.dislikedTagLabels,
        freeformRequirement: input.freeformRequirement,
        explicitRequestLabels: input.likedTagLabels,
        maxTimeMinutes: structured.maxTimeMinutes ??
            RecipeEligibility.parseMaxTimeMinutes(signalText),
      ),
      // App 未指定执行方式时默认做饭；外卖/堂食不承担烹饪成本。
      isCooking:
          structured.executionPreference == TasteExecutionPreference.cook ||
              structured.executionPreference == TasteExecutionPreference.any,
      maxBudgetYuan: structured.maxBudgetYuan ??
          RecipeEligibility.parseMaxBudgetYuan(signalText),
      partySize: structured.partySize ?? _parsePartySize(signalText),
    );
  }

  final RecipeEligibility eligibility;
  final bool isCooking;
  int? get maxTimeMinutes => eligibility.maxTimeMinutes;
  final int? maxBudgetYuan;
  final int? partySize;

  bool get hasRankingSignals => maxBudgetYuan != null || partySize != null;

  List<String> get activeLabels => [
        if (maxTimeMinutes != null) '$maxTimeMinutes 分钟内',
        if (maxBudgetYuan != null) '$maxBudgetYuan 元内',
        if (partySize != null) '$partySize 人',
        if (eligibility.hasExclusions) '忌口',
      ];

  String get summaryLabel {
    final labels = <String>[
      if (maxTimeMinutes != null) '时间约束',
      if (maxBudgetYuan != null) '预算',
      if (partySize != null) '人数',
      if (eligibility.hasExclusions) '忌口',
    ];
    return labels.isEmpty ? '餐食候选' : labels.join('、');
  }

  String get rankingSummaryLabel {
    final labels = <String>[
      if (maxBudgetYuan != null) '预算',
      if (partySize != null) '人数',
    ];
    return labels.join('、');
  }

  bool allows(Map<String, dynamic> row) {
    // 在 RecipeModel 截断食材/标签之前检查完整库配方。
    return eligibility
        .evaluate(
          name: row['dish_name']?.toString() ?? '',
          description: row['recipe_description']?.toString() ?? '',
          category: row['cuisine']?.toString() ?? '',
          ingredients: (row['ingredients'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((item) => item['name']?.toString() ?? ''),
          tags: [
            ...?row['tags'] as List<dynamic>?,
            ...?row['scenes'] as List<dynamic>?,
            ...?row['health_tags'] as List<dynamic>?,
          ].map((item) => '$item'),
          totalTimeMinutes: _timeFor(row),
        )
        .allowed;
  }

  List<String> notesFor(Map<String, dynamic> row) {
    return [
      ...eligibility.timeNotes(_timeFor(row)),
      ..._budgetNotesFor(row),
      ..._partyNotesFor(row),
    ];
  }

  double scoreAdjustment(Map<String, dynamic> row) {
    return _budgetAdjustment(row) +
        _partyAdjustment(row) +
        _cookingPracticalityAdjustment(row);
  }

  double _cookingPracticalityAdjustment(Map<String, dynamic> row) {
    if (!isCooking) return 0;
    // 仅采用库中真实的 1..5 数值难度，未知值不推断为简单或复杂。
    final difficulty = row['difficulty'];
    final difficultyBonus =
        difficulty is num && difficulty >= 1 && difficulty <= 5
            ? (3 - difficulty) * 3.0
            : 0.0;
    // 总幅度 [-10, 10]，小于显式喜欢的 +32；缺失耗时始终中性。
    final minutes = _timeFor(row);
    if (minutes == null || minutes <= 0) return difficultyBonus;
    if (minutes <= 20) return difficultyBonus + 4.0;
    if (minutes >= 45) return difficultyBonus - 4.0;
    return difficultyBonus;
  }

  String filteredSummary(int recalledCount) {
    if (recalledCount <= 0) return 'HowToCook 暂时没有命中候选。';
    return 'HowToCook 已按$summaryLabel过滤 $recalledCount 道候选，但暂时没有剩余结果。';
  }

  int? _timeFor(Map<String, dynamic> row) {
    final raw = row['total_time_minutes'];
    return raw is num ? raw.toInt() : int.tryParse('$raw');
  }

  List<String> _budgetNotesFor(Map<String, dynamic> row) {
    final budget = maxBudgetYuan;
    if (budget == null) return const [];
    final cost = _estimatedCostLevel(row);
    if (cost <= 1) return const ['预算友好（食材成本估算，非实时报价）'];
    if (cost >= 3 && budget <= 60) return const ['估算预算略高，已下沉'];
    return const ['估算预算可接受'];
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
    if (servings == null || servings <= 0) return const [];
    if (servings == target) {
      return ['适合 $target 人（菜谱标注 $servings 人份）'];
    }
    if (servings < target) {
      return [
        target - servings <= 1
            ? '菜谱标注 $servings 人份，$target 人建议加量'
            : '菜谱标注 $servings 人份，$target 人需加量',
      ];
    }
    return ['菜谱标注 $servings 人份，$target 人可减量'];
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
}
