import 'dart:async';

import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';
import 'package:eatwhat_app/v2/core/data/models/meal_planning_direction.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/core/services/unified_recipe_database_service.dart';
import 'package:eatwhat_app/v2/core/services/generation_service.dart';
import 'package:eatwhat_app/v2/core/services/unified_recommendation_service_v2.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';

typedef LocalRecommendationLoader = Future<List<RecipeModel>> Function(
  TasteInferenceInput input,
  List<String> recallLabels,
  int limit,
);

typedef RecommendationRefiner = Future<AiRefinedRecommendations> Function({
  required List<String> selectedTags,
  required List<RecipeModel> candidates,
  required int limit,
  required String? customRequirement,
});

/// Legacy adapter used by older tests and callers.
///
/// Returned recipes are never allowed to become formal results directly. They
/// are resolved back to the locally recalled canonical candidate set by id or
/// normalized dish name.
typedef AiRecommendationLoader = Future<List<RecipeModel>> Function({
  required List<String> tags,
  required String userProfile,
});

class Phase2RecommendationBundle {
  const Phase2RecommendationBundle({
    required this.recallLabels,
    required this.recalledCount,
    required this.finalRecommendations,
    required this.aiReasonsByRecipeId,
    required this.aiSummary,
    required this.isEstimated,
    required this.resolutionStatus,
    required this.primarySource,
    this.algorithmVersion = V2Phase2RecommendationService.algorithmVersion,
    this.latency = Duration.zero,
    this.fallbackReason,
    this.appliedConstraints = const [],
    this.relaxedConstraints = const [],
    this.diversityScore = 0,
  });

  final List<String> recallLabels;
  final int recalledCount;
  final List<RecipeModel> finalRecommendations;
  final Map<String, String> aiReasonsByRecipeId;
  final String? aiSummary;
  final bool isEstimated;
  final RecommendationResolutionStatus resolutionStatus;
  final String primarySource;
  final String algorithmVersion;
  final Duration latency;
  final String? fallbackReason;
  final List<String> appliedConstraints;
  final List<String> relaxedConstraints;
  final double diversityScore;
}

/// Reliable V2 recommendation orchestrator.
///
/// The unified local database is the source of truth and always runs first.
/// AI may only reorder those canonical candidates or add short reasons. Any AI
/// timeout, malformed response, unknown dish id, or service error falls back to
/// the local ranking without interrupting the user journey.
class V2Phase2RecommendationService {
  V2Phase2RecommendationService({
    LocalRecommendationLoader? localRecommendationLoader,
    RecommendationRefiner? recommendationRefiner,
    AiRecommendationLoader? aiRecommendationLoader,
    UnifiedRecommendationServiceV2? recommendationService,
    GenerationService? generationService,
    V2HowToCookRecipeService? howToCookRecipeService,
    Duration stageTimeout = const Duration(seconds: 2),
    Duration refineTimeout = const Duration(seconds: 14),
    Duration enrichmentTimeout = const Duration(seconds: 3),
    bool enableAiEnhancement = true,
  })  : _localRecommendationLoader = localRecommendationLoader,
        _recommendationRefiner = recommendationRefiner,
        _aiRecommendationLoader = aiRecommendationLoader,
        _recommendationService =
            recommendationService ?? UnifiedRecommendationServiceV2.instance,
        _generationService = generationService ?? GenerationService.instance,
        _howToCookRecipeService =
            howToCookRecipeService ?? V2HowToCookRecipeService.instance,
        _stageTimeout = stageTimeout,
        _refineTimeout = refineTimeout,
        _enrichmentTimeout = enrichmentTimeout,
        _enableAiEnhancement = enableAiEnhancement;

  static const String algorithmVersion = 'hybrid_v3_0';

  final LocalRecommendationLoader? _localRecommendationLoader;
  final RecommendationRefiner? _recommendationRefiner;
  final AiRecommendationLoader? _aiRecommendationLoader;
  final UnifiedRecommendationServiceV2 _recommendationService;
  final GenerationService _generationService;
  final V2HowToCookRecipeService _howToCookRecipeService;
  final Duration _stageTimeout;
  final Duration _refineTimeout;
  final Duration _enrichmentTimeout;
  final bool _enableAiEnhancement;

  Future<Phase2RecommendationBundle> buildRecommendations({
    required TasteInferenceInput input,
    int recallLimit = 12,
    int finalLimit = 5,

    /// Per-call override: the decision page calls this with true to get the
    /// sub-second local bundle for instant navigation while the full bundle
    /// (with AI refinement) continues in the background.
    bool skipAiEnhancement = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    final recallLabels = _recallLabels(input);
    final candidateLimit = recallLimit <= 0 ? finalLimit : recallLimit;
    final resultLimit = finalLimit <= 0 ? 1 : finalLimit;
    _LocalRecommendationResult localResult;

    try {
      localResult = await _loadLocalRecommendations(
        input: input,
        recallLabels: recallLabels,
        limit: candidateLimit,
      );
    } catch (_) {
      stopwatch.stop();
      return _emptyBundle(
        recallLabels: recallLabels,
        summary: '本地菜谱库暂时不可用，请稍后重试。',
        fallbackReason: 'local_error',
        latency: stopwatch.elapsed,
        input: input,
      );
    }

    final localCandidates = _dedupe(
      _sanitizeCandidates(localResult.recipes, input),
    ).take(candidateLimit).toList();
    if (localCandidates.isEmpty) {
      stopwatch.stop();
      return _emptyBundle(
        recallLabels: recallLabels,
        summary: localResult.summary.trim().isNotEmpty
            ? localResult.summary
            : '本地菜谱库没有命中满足本轮约束的正式候选。',
        fallbackReason: 'local_empty',
        latency: stopwatch.elapsed,
        input: input,
      );
    }

    final localReasons = <String, String>{
      for (final recipe in localCandidates)
        recipe.id: localResult.reasonsByRecipeId[recipe.id] ??
            _buildLocalReason(recipe, recallLabels),
    };

    final enhancement = await _enhanceCandidates(
      input: input,
      recallLabels: recallLabels,
      localCandidates: localCandidates,
      limit: resultLimit,
      skipAiEnhancement: skipAiEnhancement,
    );
    final ordered = _orderCanonicalCandidates(
      localCandidates: localCandidates,
      preferredIds: enhancement.orderedIds,
    );
    // AI 融合菜优先入主榜；本地候选只补足数量，不再喧宾夺主。
    final fused = enhancement.extraRecipes;
    final List<RecipeModel> baseList;
    if (fused.isNotEmpty) {
      final fusedIds = fused.map((recipe) => recipe.id).toSet();
      baseList = [
        ...fused,
        ..._diversify(ordered, resultLimit)
            .where((recipe) => !fusedIds.contains(recipe.id)),
      ].take(resultLimit).toList();
    } else {
      baseList = _diversify(ordered, resultLimit);
    }
    final finalRecommendations = await _enrichWithHowToCook(baseList);
    final finalIds = finalRecommendations.map((recipe) => recipe.id).toSet();
    final reasons = <String, String>{
      for (final entry in localReasons.entries)
        if (finalIds.contains(entry.key)) entry.key: entry.value,
      for (final entry in enhancement.reasonsById.entries)
        if (finalIds.contains(entry.key)) entry.key: entry.value,
    };

    stopwatch.stop();
    if (!enhancement.attempted) {
      return Phase2RecommendationBundle(
        recallLabels: recallLabels,
        recalledCount: localCandidates.length,
        finalRecommendations: finalRecommendations,
        aiReasonsByRecipeId: reasons,
        // Say it out loud when the LLM never ran: the recommendation is a
        // pure local pick, not an AI one, so nobody mistakes speed for
        // intelligence.
        aiSummary: '本地精选：由口味档案与本地菜谱库直接排序，AI 点菜师未启用。',
        isEstimated: false,
        resolutionStatus: RecommendationResolutionStatus.dbResolved,
        primarySource: 'unified_db',
        latency: stopwatch.elapsed,
        appliedConstraints: _appliedConstraints(input),
        diversityScore: _calculateDiversityScore(finalRecommendations),
        algorithmVersion: localResult.algorithmVersion,
      );
    }

    if (!enhancement.succeeded) {
      return Phase2RecommendationBundle(
        recallLabels: recallLabels,
        recalledCount: localCandidates.length,
        finalRecommendations: finalRecommendations,
        aiReasonsByRecipeId: reasons,
        aiSummary: '智能增强暂时不可用，已使用 ${finalRecommendations.length} 道稳定的本地候选。',
        isEstimated: true,
        resolutionStatus: RecommendationResolutionStatus.localFallback,
        primarySource: 'local_fallback',
        fallbackReason: enhancement.fallbackReason,
        latency: stopwatch.elapsed,
        appliedConstraints: _appliedConstraints(input),
        diversityScore: _calculateDiversityScore(finalRecommendations),
        algorithmVersion: localResult.algorithmVersion,
      );
    }

    return Phase2RecommendationBundle(
      recallLabels: recallLabels,
      recalledCount: localCandidates.length,
      finalRecommendations: finalRecommendations,
      aiReasonsByRecipeId: reasons,
      aiSummary:
          enhancement.summary ?? '已从 ${localCandidates.length} 道本地正式候选中完成智能收束。',
      isEstimated: enhancement.isEstimated,
      resolutionStatus: RecommendationResolutionStatus.hybridResolved,
      primarySource: 'hybrid',
      latency: stopwatch.elapsed,
      appliedConstraints: _appliedConstraints(input),
      diversityScore: _calculateDiversityScore(finalRecommendations),
      algorithmVersion: localResult.algorithmVersion,
    );
  }

  Future<_LocalRecommendationResult> _loadLocalRecommendations({
    required TasteInferenceInput input,
    required List<String> recallLabels,
    required int limit,
  }) async {
    final loader = _localRecommendationLoader;
    if (loader != null) {
      final recipes = await loader(input, recallLabels, limit);
      return _LocalRecommendationResult(
        recipes: recipes,
        reasonsByRecipeId: const {},
        summary: recipes.isEmpty
            ? '本地菜谱库没有命中正式候选。'
            : '已从本地正式菜谱中召回 ${recipes.length} 道候选。',
        algorithmVersion: algorithmVersion,
      );
    }

    final bundle = await _recommendationService.buildRecommendationBundle(
      input: input,
      recallLabels: recallLabels,
      limit: limit,
    );
    return _LocalRecommendationResult(
      recipes: bundle.recipes,
      reasonsByRecipeId: bundle.reasonsByRecipeId,
      summary: bundle.summary,
      algorithmVersion: bundle.algorithmVersion,
    );
  }

  Future<_AiEnhancementResult> _enhanceCandidates({
    required TasteInferenceInput input,
    required List<String> recallLabels,
    required List<RecipeModel> localCandidates,
    required int limit,
    bool skipAiEnhancement = false,
  }) async {
    if (!_enableAiEnhancement || skipAiEnhancement) {
      return const _AiEnhancementResult.notAttempted();
    }

    try {
      final refiner = _recommendationRefiner;
      if (refiner != null) {
        final refined = await refiner(
          selectedTags: recallLabels,
          candidates: localCandidates,
          limit: limit,
          customRequirement: _buildAiRequirement(input),
        ).timeout(_refineTimeout);
        return _validateRefinement(refined, localCandidates);
      }

      final legacyLoader = _aiRecommendationLoader;
      if (legacyLoader != null) {
        final generated = await legacyLoader(
          tags: recallLabels,
          userProfile: _buildAiRequirement(input),
        ).timeout(_stageTimeout);
        return _resolveLegacyAiCandidates(generated, localCandidates);
      }

      if (!_generationService.isConfigured) {
        return const _AiEnhancementResult.notAttempted();
      }

      // 融合生成主路径：把用户选出的标签交给模型组合成新菜，
      // 再回库匹配现成菜谱与配图；库里没有就让模型生图。
      return _generateFusion(input: input, recallLabels: recallLabels);
    } on TimeoutException {
      return const _AiEnhancementResult.failed('ai_timeout');
    } catch (_) {
      return const _AiEnhancementResult.failed('ai_error');
    }
  }

  Future<_AiEnhancementResult> _generateFusion({
    required TasteInferenceInput input,
    required List<String> recallLabels,
  }) async {
    final generated = await _generationService
        .generateFusionDishes(
          tags: recallLabels,
          customRequirement: _buildAiRequirement(input),
          count: 4,
        )
        .timeout(_refineTimeout);
    if (generated.isEmpty) {
      return const _AiEnhancementResult.failed('fusion_empty');
    }

    final resolved = <RecipeModel>[];
    final reasonsById = <String, String>{};
    for (final dish in generated) {
      final matched = await _matchLibraryDish(dish);
      final recipe = matched ?? await _withGeneratedImage(dish);
      resolved.add(recipe);
      if (dish.description.trim().isNotEmpty) {
        reasonsById[recipe.id] = dish.description.trim();
      }
    }
    return _AiEnhancementResult.succeeded(
      orderedIds: resolved.map((recipe) => recipe.id).toList(),
      reasonsById: reasonsById,
      extraRecipes: resolved,
      summary: 'AI 融合创意：${resolved.map((recipe) => recipe.name).join('、')}',
    );
  }

  /// 把 AI 生成的菜名回库匹配：命中则继承库菜品的 id/步骤/配图，
  /// 只保留 AI 写的融合推荐理由。
  Future<RecipeModel?> _matchLibraryDish(RecipeModel dish) async {
    try {
      final rows = await UnifiedRecipeDatabaseService.instance
          .searchRecipes(dish.name, limit: 3);
      for (final row in rows) {
        final candidate = RecipeModel.fromUnifiedDbRow(row);
        if (_namesMatch(dish.name, candidate.name)) {
          return candidate.copyWith(
            description: dish.description.trim().isNotEmpty
                ? dish.description.trim()
                : candidate.description,
          );
        }
      }
    } catch (_) {
      // 库不可用时按未命中处理，走生图。
    }
    return null;
  }

  bool _namesMatch(String a, String b) {
    String norm(String value) =>
        value.replaceAll(RegExp(r'[\s·\-—（）()]'), '').trim();
    final na = norm(a);
    final nb = norm(b);
    if (na.isEmpty || nb.isEmpty) return false;
    return na == nb || na.contains(nb) || nb.contains(na);
  }

  /// 库里没有这道菜：让模型直接为它生成配图。
  Future<RecipeModel> _withGeneratedImage(RecipeModel dish) async {
    if (dish.imageUrl?.trim().isNotEmpty ?? false) return dish;
    try {
      final url = await _generationService.generateRecipeImageUrl(dish);
      if (url != null && url.trim().isNotEmpty) {
        return dish.copyWith(imageUrl: url.trim());
      }
    } catch (_) {
      // 生图失败则保留无图状态，由展示层走花字盘 fallback。
    }
    return dish;
  }

  _AiEnhancementResult _validateRefinement(
    AiRefinedRecommendations refined,
    List<RecipeModel> localCandidates,
  ) {
    final allowedIds = localCandidates.map((recipe) => recipe.id).toSet();
    final orderedIds = <String>[];
    for (final rawId in refined.recipeIds) {
      final id = rawId.trim();
      if (!allowedIds.contains(id) || orderedIds.contains(id)) continue;
      orderedIds.add(id);
    }
    if (refined.isEstimated || orderedIds.isEmpty) {
      return _AiEnhancementResult.failed(
        orderedIds.isEmpty ? 'ai_empty' : 'ai_estimated',
      );
    }
    return _AiEnhancementResult.succeeded(
      orderedIds: orderedIds,
      reasonsById: {
        for (final entry in refined.reasonsById.entries)
          if (allowedIds.contains(entry.key) && entry.value.trim().isNotEmpty)
            entry.key: entry.value.trim(),
      },
      summary: refined.summary,
      isEstimated: refined.isEstimated,
    );
  }

  _AiEnhancementResult _resolveLegacyAiCandidates(
    List<RecipeModel> generated,
    List<RecipeModel> localCandidates,
  ) {
    if (generated.isEmpty) {
      return const _AiEnhancementResult.failed('ai_empty');
    }
    final byId = {for (final recipe in localCandidates) recipe.id: recipe};
    final byName = {
      for (final recipe in localCandidates)
        _normalizeDishName(recipe.name): recipe,
    };
    final orderedIds = <String>[];
    final reasonsById = <String, String>{};
    for (final aiRecipe in _filterAiCandidates(generated)) {
      final canonical =
          byId[aiRecipe.id] ?? byName[_normalizeDishName(aiRecipe.name)];
      if (canonical == null || orderedIds.contains(canonical.id)) continue;
      orderedIds.add(canonical.id);
      final reason = aiRecipe.description.trim();
      if (reason.isNotEmpty) reasonsById[canonical.id] = reason;
    }
    if (orderedIds.isEmpty) {
      return const _AiEnhancementResult.failed('ai_unresolved');
    }
    return _AiEnhancementResult.succeeded(
      orderedIds: orderedIds,
      reasonsById: reasonsById,
      summary: 'AI 已在本地正式候选中完成辅助收束。',
    );
  }

  Phase2RecommendationBundle _emptyBundle({
    required List<String> recallLabels,
    required String summary,
    required String fallbackReason,
    required Duration latency,
    required TasteInferenceInput input,
  }) {
    return Phase2RecommendationBundle(
      recallLabels: recallLabels,
      recalledCount: 0,
      finalRecommendations: const [],
      aiReasonsByRecipeId: const {},
      aiSummary: summary,
      isEstimated: true,
      resolutionStatus: RecommendationResolutionStatus.empty,
      primarySource: 'unified_db',
      fallbackReason: fallbackReason,
      latency: latency,
      appliedConstraints: _appliedConstraints(input),
    );
  }

  List<String> _recallLabels(TasteInferenceInput input) {
    final labels = <String>[
      ...input.likedTagLabels,
      ...input.planningDirection.recallLabels,
      ...input.structuredConstraints.labels,
      ..._tokenize(input.freeformRequirement),
    ];
    final cleaned =
        labels.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    return cleaned.isEmpty ? ['家常', '热菜'] : cleaned;
  }

  List<String> _tokenize(String raw) {
    return raw
        .split(RegExp(r'[，,。.!！？?、/\s]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .where((e) => !_recallStopwords.contains(e))
        .where((e) => e.length <= 8)
        .take(4)
        .toList();
  }

  String _buildAiRequirement(TasteInferenceInput input) {
    final historyText = _buildHistorySummary(input.historyPreferenceSummary);
    final dislikeText = input.dislikedTagLabels.isEmpty
        ? ''
        : '不要：${input.dislikedTagLabels.join('、')}。\n';
    final skippedText = input.skippedTagLabels.isEmpty
        ? ''
        : '这轮略过：${input.skippedTagLabels.join('、')}。\n';
    final constraintText = input.structuredConstraints.labels.isEmpty
        ? ''
        : '硬性约束：${input.structuredConstraints.labels.join('、')}。\n';
    final freeform = input.freeformRequirement.trim();
    return [
      input.planningDirection.aiInstruction,
      if (freeform.isNotEmpty) freeform,
      if (constraintText.isNotEmpty) constraintText.trim(),
      if (historyText.isNotEmpty) historyText,
      if (dislikeText.isNotEmpty) dislikeText.trim(),
      if (skippedText.isNotEmpty) skippedText.trim(),
    ].join('\n');
  }

  String _buildHistorySummary(Map<String, int> historyPreferenceSummary) {
    if (historyPreferenceSummary.isEmpty) return '';
    final entries = historyPreferenceSummary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = entries.take(4).map((entry) {
      return '${entry.key}:${entry.value >= 0 ? '+' : ''}${entry.value}';
    }).join('，');
    return '历史偏好：$topEntries。';
  }

  List<RecipeModel> _sanitizeCandidates(
    List<RecipeModel> candidates,
    TasteInferenceInput input,
  ) {
    return candidates.where((recipe) {
      final haystack =
          '${recipe.name}|${recipe.description}|${recipe.ingredients.join('|')}|${recipe.tags.join('|')}';
      final blockedLabels = [
        ...input.dislikedTagLabels,
        ...input.skippedTagLabels,
      ].where((label) => label.trim().isNotEmpty);
      if (blockedLabels.any(haystack.contains)) return false;
      if (_isPlaceholderRecipe(recipe)) return false;
      return recipe.name.trim().isNotEmpty && recipe.id.trim().isNotEmpty;
    }).toList();
  }

  bool _isPlaceholderRecipe(RecipeModel recipe) {
    final name = recipe.name.trim().toLowerCase();
    return name.contains('示例菜谱') ||
        name.startsWith('soup_') ||
        name.startsWith('dessert_') ||
        name.startsWith('drink_') ||
        name.startsWith('condiment_') ||
        name.startsWith('semi-finished_') ||
        name.startsWith('aquatic_');
  }

  List<RecipeModel> _dedupe(List<RecipeModel> results) {
    final deduped = <RecipeModel>[];
    final seenIds = <String>{};
    final seenNames = <String>{};
    for (final recipe in results) {
      final id = recipe.id.trim();
      final name = _normalizeDishName(recipe.name);
      if (id.isNotEmpty && !seenIds.add(id)) continue;
      if (name.isNotEmpty && !seenNames.add(name)) continue;
      deduped.add(recipe);
    }
    return deduped;
  }

  List<RecipeModel> _filterAiCandidates(List<RecipeModel> candidates) {
    return candidates.where((recipe) {
      final name = recipe.name.trim();
      if (name.isEmpty) return false;
      if (name.contains('推荐')) return false;
      if (name.contains('今天') || name.contains('今晚')) return false;
      if (_isPlaceholderRecipe(recipe)) return false;
      return true;
    }).toList();
  }

  List<RecipeModel> _orderCanonicalCandidates({
    required List<RecipeModel> localCandidates,
    required List<String> preferredIds,
  }) {
    final byId = {for (final recipe in localCandidates) recipe.id: recipe};
    final ordered = <RecipeModel>[];
    final seen = <String>{};
    for (final id in preferredIds) {
      final recipe = byId[id];
      if (recipe != null && seen.add(recipe.id)) ordered.add(recipe);
    }
    for (final recipe in localCandidates) {
      if (seen.add(recipe.id)) ordered.add(recipe);
    }
    return ordered;
  }

  List<RecipeModel> _diversify(List<RecipeModel> ranked, int limit) {
    if (ranked.length <= 1) return ranked.take(limit).toList();
    final selected = <RecipeModel>[];
    final deferred = <RecipeModel>[];
    final tagCounts = <String, int>{};
    final ingredientCounts = <String, int>{};

    for (final recipe in ranked) {
      final tagKey = recipe.tags.isEmpty ? '' : recipe.tags.first.trim();
      final ingredientKey =
          recipe.ingredients.isEmpty ? '' : recipe.ingredients.first.trim();
      final tagCrowded = tagKey.isNotEmpty && (tagCounts[tagKey] ?? 0) >= 1;
      final ingredientCrowded = ingredientKey.isNotEmpty &&
          (ingredientCounts[ingredientKey] ?? 0) >= 1;
      if (tagCrowded || ingredientCrowded) {
        deferred.add(recipe);
        continue;
      }
      selected.add(recipe);
      if (tagKey.isNotEmpty) tagCounts[tagKey] = (tagCounts[tagKey] ?? 0) + 1;
      if (ingredientKey.isNotEmpty) {
        ingredientCounts[ingredientKey] =
            (ingredientCounts[ingredientKey] ?? 0) + 1;
      }
      if (selected.length >= limit) return selected;
    }

    for (final recipe in deferred) {
      if (selected.length >= limit) break;
      selected.add(recipe);
    }
    return selected;
  }

  String _buildLocalReason(
    RecipeModel recipe,
    List<String> recallLabels,
  ) {
    final signals = recallLabels.take(3).join('、');
    if (signals.isEmpty) return '来自本地正式菜谱库的稳定候选。';
    return '本地菜谱命中 $signals，并通过本轮约束筛选。';
  }

  List<String> _appliedConstraints(TasteInferenceInput input) {
    return <String>{
      input.planningDirection.label,
      ...input.structuredConstraints.labels,
      ...input.dislikedTagLabels,
    }.where((label) => label.trim().isNotEmpty).toList();
  }

  double _calculateDiversityScore(List<RecipeModel> recipes) {
    if (recipes.isEmpty) return 0;
    final signatures = recipes.map((recipe) {
      final tag = recipe.tags.isEmpty ? '' : recipe.tags.first.trim();
      final ingredient =
          recipe.ingredients.isEmpty ? '' : recipe.ingredients.first.trim();
      return '$tag|$ingredient';
    }).toSet();
    return signatures.length / recipes.length;
  }

  String _normalizeDishName(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\p{P}]', unicode: true), '');
  }

  Future<List<RecipeModel>> _enrichWithHowToCook(
    List<RecipeModel> candidates,
  ) async {
    if (candidates.isEmpty) return candidates;
    return Future.wait(
      candidates.map((recipe) async {
        try {
          final enriched = await _howToCookRecipeService
              .enrichRecipe(recipe)
              .timeout(_enrichmentTimeout);
          return enriched.copyWith(
            id: recipe.id,
            description: recipe.description.trim().isNotEmpty
                ? recipe.description
                : enriched.description,
            source: recipe.source.trim().isNotEmpty
                ? recipe.source
                : enriched.source,
          );
        } catch (_) {
          return recipe;
        }
      }),
    );
  }

  static const Set<String> _recallStopwords = {
    '今天',
    '今晚',
    '晚上',
    '中午',
    '早上',
    '现在',
    '一点',
    '一下',
    '有点',
    '想吃',
    '吃点',
    '想要',
    '来点',
  };
}

class _LocalRecommendationResult {
  const _LocalRecommendationResult({
    required this.recipes,
    required this.reasonsByRecipeId,
    required this.summary,
    required this.algorithmVersion,
  });

  final List<RecipeModel> recipes;
  final Map<String, String> reasonsByRecipeId;
  final String summary;
  final String algorithmVersion;
}

class _AiEnhancementResult {
  const _AiEnhancementResult._({
    required this.attempted,
    required this.succeeded,
    required this.orderedIds,
    required this.reasonsById,
    required this.isEstimated,
    this.summary,
    this.fallbackReason,
    this.extraRecipes = const [],
  });

  const _AiEnhancementResult.notAttempted()
      : this._(
          attempted: false,
          succeeded: false,
          orderedIds: const [],
          reasonsById: const {},
          isEstimated: false,
        );

  const _AiEnhancementResult.failed(String reason)
      : this._(
          attempted: true,
          succeeded: false,
          orderedIds: const [],
          reasonsById: const {},
          isEstimated: true,
          fallbackReason: reason,
        );

  factory _AiEnhancementResult.succeeded({
    required List<String> orderedIds,
    required Map<String, String> reasonsById,
    String? summary,
    bool isEstimated = false,
    List<RecipeModel> extraRecipes = const [],
  }) {
    return _AiEnhancementResult._(
      attempted: true,
      succeeded: true,
      orderedIds: orderedIds,
      reasonsById: reasonsById,
      extraRecipes: extraRecipes,
      summary: summary,
      isEstimated: isEstimated,
    );
  }

  final bool attempted;
  final bool succeeded;
  final List<String> orderedIds;
  final Map<String, String> reasonsById;
  final String? summary;
  final bool isEstimated;
  final String? fallbackReason;

  /// AI 融合生成的新菜品（可能不在本地库），优先进入最终候选。
  final List<RecipeModel> extraRecipes;
}
