import 'dart:async';

import 'package:dio/dio.dart';
import 'package:eatwhat_app/core/services/unified_recipe_database_service.dart';
import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';
import 'package:eatwhat_app/v2/core/data/models/meal_planning_direction.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/services/generation_service.dart';
import 'package:eatwhat_app/v2/core/services/preference_recall_bridge.dart';
import 'package:eatwhat_app/v2/core/services/recipe_eligibility.dart';
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

class RecommendationSession {
  RecommendationSession({
    required this.local,
    required this.enhanced,
    void Function()? onCancel,
  }) : _onCancel = onCancel;

  final Phase2RecommendationBundle local;
  final Future<Phase2RecommendationBundle> enhanced;
  final void Function()? _onCancel;
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    _onCancel?.call();
  }
}

/// Reliable V2 recommendation orchestrator.
///
/// The unified local database always runs first. AI may refine canonical
/// candidates or propose fusion dishes; both paths share eligibility checks,
/// including after library matching and enrichment. Rejected AI dishes, timeouts,
/// and service errors leave eligible local candidates available.
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
    int finalLimit = 3,
    bool skipAiEnhancement = false,
  }) async {
    if (skipAiEnhancement) {
      final stage = await _prepareLocalStage(
        input: input,
        recallLimit: recallLimit,
        finalLimit: finalLimit,
      );
      return _buildLocalBundle(stage);
    }
    final session = await startRecommendationSession(
      input: input,
      recallLimit: recallLimit,
      finalLimit: finalLimit,
    );
    return session.enhanced;
  }

  Future<RecommendationSession> startRecommendationSession({
    required TasteInferenceInput input,
    int recallLimit = 12,
    int finalLimit = 3,
    Duration? localTimeout,
  }) async {
    var localFuture = () async {
      final stage = await _prepareLocalStage(
        input: input,
        recallLimit: recallLimit,
        finalLimit: finalLimit,
      );
      final local = await _buildLocalBundle(stage);
      return (stage: stage, local: local);
    }();
    if (localTimeout != null) {
      localFuture = localFuture.timeout(
        localTimeout,
        onTimeout: () {
          final stage = _timeoutLocalStage(input, finalLimit, localTimeout);
          return (stage: stage, local: stage.emptyBundle!);
        },
      );
    }
    final result = await localFuture;
    final cancelToken = CancelToken();
    final cancelled = Completer<void>();
    void cancel() {
      if (!cancelled.isCompleted) cancelled.complete();
      cancelToken.cancel();
    }

    final enhanced = _buildEnhancedBundle(
      result.stage,
      result.local,
      cancelToken,
      cancelled.future,
    );
    return RecommendationSession(
      local: result.local,
      enhanced: enhanced,
      onCancel: cancel,
    );
  }

  _RecommendationLocalStage _timeoutLocalStage(
    TasteInferenceInput input,
    int finalLimit,
    Duration timeout,
  ) {
    final bundle = Phase2RecommendationBundle(
      recallLabels: input.primarySignals,
      recalledCount: 0,
      finalRecommendations: const [],
      aiReasonsByRecipeId: const {},
      aiSummary: '这轮没有命中合适的菜品。',
      isEstimated: true,
      resolutionStatus: RecommendationResolutionStatus.empty,
      primarySource: 'empty',
      latency: timeout,
    );
    return _RecommendationLocalStage.empty(
      input: input,
      stopwatch: Stopwatch()..start(),
      recallLabels: input.primarySignals,
      resultLimit: finalLimit <= 0 ? 1 : finalLimit,
      bundle: bundle,
    );
  }

  Future<_RecommendationLocalStage> _prepareLocalStage({
    required TasteInferenceInput input,
    required int recallLimit,
    required int finalLimit,
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
      return _RecommendationLocalStage.empty(
        input: input,
        stopwatch: stopwatch,
        recallLabels: recallLabels,
        resultLimit: resultLimit,
        bundle: _emptyBundle(
          recallLabels: recallLabels,
          summary: '本地菜谱库暂时不可用，请稍后重试。',
          fallbackReason: 'local_error',
          latency: stopwatch.elapsed,
          input: input,
        ),
      );
    }

    final localCandidates = _dedupe(
      _sanitizeCandidates(localResult.recipes, input),
    ).take(candidateLimit).toList();
    if (localCandidates.isEmpty) {
      final eligibility = _eligibility(input);
      final rejections = localResult.recipes
          .map((recipe) => _assess(recipe, eligibility).rejectionReason)
          .whereType<String>()
          .toList();
      return _RecommendationLocalStage.empty(
        input: input,
        stopwatch: stopwatch,
        recallLabels: recallLabels,
        resultLimit: resultLimit,
        bundle: _emptyBundle(
          recallLabels: recallLabels,
          summary: rejections.isNotEmpty
              ? '${_rejectionSummary(rejections)}本轮没有剩余候选。'
              : localResult.summary.trim().isNotEmpty
                  ? localResult.summary
                  : '本地菜谱库没有命中满足本轮约束的正式候选。',
          fallbackReason: rejections.isEmpty
              ? localResult.fallbackReason ?? 'local_empty'
              : 'candidate_constraints_rejected',
          latency: stopwatch.elapsed,
          input: input,
        ),
      );
    }

    final localReasons = <String, String>{
      for (final recipe in localCandidates)
        recipe.id: localResult.reasonsByRecipeId[recipe.id] ??
            _buildLocalReason(recipe, recallLabels),
    };
    return _RecommendationLocalStage(
      input: input,
      stopwatch: stopwatch,
      recallLabels: recallLabels,
      resultLimit: resultLimit,
      localResult: localResult,
      localCandidates: localCandidates,
      localReasons: localReasons,
    );
  }

  Future<Phase2RecommendationBundle> _buildLocalBundle(
    _RecommendationLocalStage stage,
  ) {
    final empty = stage.emptyBundle;
    if (empty != null) return Future.value(empty);
    return _buildBundleWithEnhancement(
      stage,
      const _AiEnhancementResult.notAttempted(),
    );
  }

  Future<Phase2RecommendationBundle> _buildEnhancedBundle(
    _RecommendationLocalStage stage,
    Phase2RecommendationBundle local,
    CancelToken cancelToken,
    Future<void> cancelled,
  ) async {
    if (stage.emptyBundle != null || !_enableAiEnhancement) return local;
    if (_recommendationRefiner == null &&
        _aiRecommendationLoader == null &&
        !_generationService.isConfigured) {
      return local;
    }
    if (cancelToken.isCancelled) return local;

    final enhancement = await _enhanceCandidates(
      input: stage.input,
      recallLabels: stage.recallLabels,
      localCandidates: stage.localCandidates,
      limit: stage.resultLimit,
      cancelToken: cancelToken,
      cancelled: cancelled,
    );
    if (cancelToken.isCancelled) return local;
    final bundle = await _buildBundleWithEnhancement(
      stage,
      enhancement,
      cancelled: cancelled,
    );
    return cancelToken.isCancelled ? local : bundle;
  }

  Future<Phase2RecommendationBundle> _buildBundleWithEnhancement(
    _RecommendationLocalStage stage,
    _AiEnhancementResult enhancement, {
    Future<void>? cancelled,
  }) async {
    final localResult = stage.localResult!;
    final localCandidates = stage.localCandidates;
    final ordered = _orderCanonicalCandidates(
      localCandidates: localCandidates,
      preferredIds: enhancement.orderedIds,
    );
    final eligibility = _eligibility(stage.input);
    final hasBudget = stage.input.structuredConstraints.maxBudgetYuan != null ||
        RecipeEligibility.parseMaxBudgetYuan([
              stage.input.freeformRequirement,
              ...stage.input.likedTagLabels,
            ].join(' ')) !=
            null;
    // 无价格依据时不转述 AI 核价文案，保留本地召回依据与估算说明。
    final canUseAiCopy = eligibility.maxTimeMinutes == null && !hasBudget;
    final rejections = <String>[
      for (final recipe in localResult.recipes)
        if (!_assess(recipe, eligibility).allowed)
          _assess(recipe, eligibility).rejectionReason!,
    ];
    // 创意仍优先，但所有路径在最终候选边界共用约束；富化换料也要复核。
    final fusedIds =
        enhancement.extraRecipes.map((recipe) => recipe.id).toSet();
    final pending = _dedupe([
      ...enhancement.extraRecipes,
      ..._diversify(ordered, stage.resultLimit),
      ...ordered,
    ]);
    final finalRecommendations = <RecipeModel>[];
    final rejectedIds = <String>{};
    while (
        pending.isNotEmpty && finalRecommendations.length < stage.resultLimit) {
      final count = (stage.resultLimit - finalRecommendations.length)
          .clamp(0, pending.length);
      final batch = pending.take(count).toList();
      pending.removeRange(0, count);
      final safeBatch = <RecipeModel>[];
      for (final recipe in batch) {
        final assessment = _assess(recipe, eligibility,
            requireIngredients: fusedIds.contains(recipe.id));
        if (assessment.allowed) {
          safeBatch.add(recipe);
        } else {
          rejections.add(assessment.rejectionReason!);
          rejectedIds.add(recipe.id);
        }
      }
      final enriched =
          await _enrichWithHowToCook(safeBatch, cancelled: cancelled);
      for (final recipe in enriched) {
        final assessment = _assess(recipe, eligibility,
            requireIngredients: fusedIds.contains(recipe.id));
        if (assessment.allowed) {
          finalRecommendations.add(recipe);
        } else {
          rejections.add(assessment.rejectionReason!);
          rejectedIds.add(recipe.id);
        }
      }
    }
    String summaryWithConstraints(String summary) => [
          summary,
          if (rejections.isNotEmpty) _rejectionSummary(rejections),
          if (eligibility.hasDietaryRestrictions)
            RecipeEligibility.safetyNotice,
          if (eligibility.maxTimeMinutes != null)
            '未提供耗时的候选：${RecipeEligibility.unverifiedTimeNote}。',
          if (hasBudget) RecipeEligibility.unverifiedBudgetNote,
        ].join();
    final finalIds = finalRecommendations.map((recipe) => recipe.id).toSet();
    final survivingFusion = finalRecommendations
        .where((recipe) => fusedIds.contains(recipe.id))
        .toList();
    // refine 的本地排序也算有效贡献；不能仅以是否还有融合菜判断成功。
    final enhancementSurvived =
        enhancement.succeeded && enhancement.orderedIds.any(finalIds.contains);
    final aiSelectionPruned =
        enhancement.orderedIds.any((id) => !finalIds.contains(id));
    final aiRejected = enhancement.orderedIds.any(rejectedIds.contains);
    final fallbackReason = enhancement.fallbackReason ??
        (aiRejected
            ? 'ai_constraints_rejected'
            : rejections.isEmpty
                ? null
                : 'candidate_constraints_rejected');
    if (finalRecommendations.isEmpty) {
      return _emptyBundle(
        recallLabels: stage.recallLabels,
        summary: summaryWithConstraints('本轮没有剩余的合适候选。'),
        fallbackReason: fallbackReason ?? 'local_empty',
        latency: stage.stopwatch.elapsed,
        input: stage.input,
      );
    }
    final reasons = <String, String>{
      for (final entry in stage.localReasons.entries)
        if (finalIds.contains(entry.key)) entry.key: entry.value,
      for (final entry in enhancement.reasonsById.entries)
        if (finalIds.contains(entry.key) && canUseAiCopy && !aiSelectionPruned)
          entry.key: entry.value,
    };
    for (final recipe in finalRecommendations) {
      final timeNotes = !fusedIds.contains(recipe.id) &&
              localResult.reasonsByRecipeId.containsKey(recipe.id)
          ? const <String>[]
          : eligibility.timeNotes(null);
      reasons[recipe.id] = [
        reasons[recipe.id] ?? '按本轮偏好推荐。',
        ...timeNotes,
        if (hasBudget) RecipeEligibility.unverifiedBudgetNote,
      ].join();
    }

    if (!enhancement.attempted) {
      return Phase2RecommendationBundle(
        recallLabels: stage.recallLabels,
        recalledCount: localCandidates.length,
        finalRecommendations: finalRecommendations,
        aiReasonsByRecipeId: reasons,
        // Say it out loud when the LLM never ran: the recommendation is a
        // pure local pick, not an AI one, so nobody mistakes speed for
        // intelligence.
        aiSummary: summaryWithConstraints('本地精选：由口味档案与本地菜谱库直接排序，AI 点菜师未启用。'),
        fallbackReason: fallbackReason,
        isEstimated: false,
        resolutionStatus: RecommendationResolutionStatus.dbResolved,
        primarySource: 'unified_db',
        latency: stage.stopwatch.elapsed,
        appliedConstraints: _appliedConstraints(stage.input),
        diversityScore: _calculateDiversityScore(finalRecommendations),
        algorithmVersion: localResult.algorithmVersion,
      );
    }

    if (!enhancementSurvived) {
      final failureSummary = enhancement.succeeded
          ? '智能增强候选未通过最终筛选。'
          : enhancement.summary ?? '智能增强暂时不可用。';
      return Phase2RecommendationBundle(
        recallLabels: stage.recallLabels,
        recalledCount: localCandidates.length,
        finalRecommendations: finalRecommendations,
        aiReasonsByRecipeId: reasons,
        aiSummary: summaryWithConstraints(
          '$failureSummary已使用 ${finalRecommendations.length} 道本地候选。',
        ),
        isEstimated: true,
        resolutionStatus: RecommendationResolutionStatus.localFallback,
        primarySource: 'local_fallback',
        fallbackReason: fallbackReason,
        latency: stage.stopwatch.elapsed,
        appliedConstraints: _appliedConstraints(stage.input),
        diversityScore: _calculateDiversityScore(finalRecommendations),
        algorithmVersion: localResult.algorithmVersion,
      );
    }

    return Phase2RecommendationBundle(
      recallLabels: stage.recallLabels,
      recalledCount: localCandidates.length,
      finalRecommendations: finalRecommendations,
      aiReasonsByRecipeId: reasons,
      aiSummary: summaryWithConstraints(
        hasBudget ||
                (eligibility.maxTimeMinutes != null &&
                    enhancement.fallbackReason == null)
            ? '已按本轮偏好完成智能收束。'
            : aiSelectionPruned
                ? survivingFusion.isNotEmpty
                    ? 'AI 融合创意：${survivingFusion.map((recipe) => recipe.name).join('、')}。'
                    : '已在最终保留的本地候选中完成智能收束。'
                : enhancement.summary ??
                    '已从 ${localCandidates.length} 道本地正式候选中完成智能收束。',
      ),
      fallbackReason: fallbackReason,
      isEstimated: enhancement.isEstimated,
      resolutionStatus: RecommendationResolutionStatus.hybridResolved,
      primarySource: 'hybrid',
      latency: stage.stopwatch.elapsed,
      appliedConstraints: _appliedConstraints(stage.input),
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
      fallbackReason: bundle.fallbackReason,
    );
  }

  Future<_AiEnhancementResult> _enhanceCandidates({
    required TasteInferenceInput input,
    required List<String> recallLabels,
    required List<RecipeModel> localCandidates,
    required int limit,
    bool skipAiEnhancement = false,
    CancelToken? cancelToken,
    Future<void>? cancelled,
  }) async {
    if (!_enableAiEnhancement || skipAiEnhancement) {
      return const _AiEnhancementResult.notAttempted();
    }

    try {
      final refiner = _recommendationRefiner;
      if (refiner != null) {
        final refinerFuture = refiner(
          selectedTags: recallLabels,
          candidates: localCandidates,
          limit: limit,
          customRequirement: _buildAiRequirement(input),
        );
        final refined = await _awaitWithCancellation(
          refinerFuture,
          _refineTimeout,
          cancelled,
        );
        if (cancelToken?.isCancelled == true) {
          return const _AiEnhancementResult.failed('cancelled');
        }
        return _validateRefinement(refined, localCandidates);
      }

      final legacyLoader = _aiRecommendationLoader;
      if (legacyLoader != null) {
        final generatedFuture = legacyLoader(
          tags: recallLabels,
          userProfile: _buildAiRequirement(input),
        );
        final generated = await _awaitWithCancellation(
          generatedFuture,
          _stageTimeout,
          cancelled,
        );
        if (cancelToken?.isCancelled == true) {
          return const _AiEnhancementResult.failed('cancelled');
        }
        return _resolveLegacyAiCandidates(
            generated, localCandidates, _eligibility(input));
      }

      if (!_generationService.isConfigured) {
        return const _AiEnhancementResult.notAttempted();
      }

      // 融合生成主路径：把用户选出的标签交给模型组合成新菜，
      // 再回库匹配现成菜谱与配图；库里没有就让模型生图。
      return await _awaitWithCancellation(
        _generateFusion(
          input: input,
          recallLabels: recallLabels,
          cancelToken: cancelToken,
          cancelled: cancelled,
        ),
        _refineTimeout,
        cancelled,
      );
    } on _RecommendationCancelled {
      return const _AiEnhancementResult.failed('cancelled');
    } on TimeoutException {
      return const _AiEnhancementResult.failed('ai_timeout');
    } catch (_) {
      return const _AiEnhancementResult.failed('ai_error');
    }
  }

  Future<_AiEnhancementResult> _generateFusion({
    required TasteInferenceInput input,
    required List<String> recallLabels,
    CancelToken? cancelToken,
    Future<void>? cancelled,
  }) async {
    final generatedFuture = _generationService.generateFusionDishes(
      tags: recallLabels,
      customRequirement: _buildAiRequirement(input),
      cancelToken: cancelToken,
    );
    final generated = await _awaitWithCancellation(
      generatedFuture,
      _refineTimeout,
      cancelled,
    );
    if (cancelToken?.isCancelled == true) {
      return const _AiEnhancementResult.failed('cancelled');
    }
    if (generated.isEmpty) {
      return const _AiEnhancementResult.failed('fusion_empty');
    }

    final resolved = <RecipeModel>[];
    final reasonsById = <String, String>{};
    final eligibility = _eligibility(input);
    final rejections = <String>[];
    for (final dish in generated) {
      if (cancelToken?.isCancelled == true) {
        return const _AiEnhancementResult.failed('cancelled');
      }
      final generatedAssessment =
          _assess(dish, eligibility, requireIngredients: true);
      if (!generatedAssessment.allowed) {
        rejections.add(generatedAssessment.rejectionReason!);
        continue;
      }
      final matched = await _matchLibraryDish(dish, eligibility);
      if (matched?.rejectionReason != null) {
        rejections.add(matched!.rejectionReason!);
        continue;
      }
      final recipe = matched?.recipe ??
          await _withLibraryCousinImage(dish, cancelToken: cancelToken);
      final assessment = _assess(recipe, eligibility, requireIngredients: true);
      if (!assessment.allowed) {
        rejections.add(assessment.rejectionReason!);
        continue;
      }
      resolved.add(recipe);
      if (dish.description.trim().isNotEmpty) {
        reasonsById[recipe.id] = dish.description.trim();
      }
    }
    if (resolved.isEmpty) {
      return _AiEnhancementResult.failed('ai_constraints_rejected',
          summary: _rejectionSummary(rejections));
    }
    return _AiEnhancementResult.succeeded(
      orderedIds: resolved.map((recipe) => recipe.id).toList(),
      reasonsById: reasonsById,
      extraRecipes: resolved,
      fallbackReason: rejections.isEmpty ? null : 'ai_constraints_rejected',
      summary:
          'AI 融合创意：${resolved.map((recipe) => recipe.name).join('、')}。${_rejectionSummary(rejections)}',
    );
  }

  /// 把 AI 生成的菜名回库匹配：命中则继承库菜品的 id/步骤/配图，
  /// 只保留 AI 写的融合推荐理由。
  Future<({RecipeModel recipe, String? rejectionReason})?> _matchLibraryDish(
    RecipeModel dish,
    RecipeEligibility eligibility,
  ) async {
    try {
      final rows = await UnifiedRecipeDatabaseService.instance
          .searchRecipes(dish.name, limit: 3);
      for (final row in rows) {
        final candidate = RecipeModel.fromUnifiedDbRow(row);
        if (_namesMatch(dish.name, candidate.name)) {
          // 检查完整库配方，不能只检查 RecipeModel 截断后的前十项食材。
          final rawTime = row['total_time_minutes'];
          final assessment = eligibility.evaluate(
            name: candidate.name,
            description: candidate.description,
            category: row['cuisine']?.toString() ?? '',
            ingredients: (row['ingredients'] as List<dynamic>? ?? const [])
                .whereType<Map>()
                .map((item) => item['name']?.toString() ?? ''),
            tags: [
              ...?row['tags'] as List<dynamic>?,
              ...?row['scenes'] as List<dynamic>?,
              ...?row['health_tags'] as List<dynamic>?,
            ].map((item) => '$item'),
            totalTimeMinutes:
                rawTime is num ? rawTime.toInt() : int.tryParse('$rawTime'),
            requireIngredients: true,
          );
          return (
            recipe: candidate.copyWith(
              description: dish.description.trim().isNotEmpty
                  ? dish.description.trim()
                  : candidate.description,
            ),
            rejectionReason: assessment.rejectionReason,
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

  /// 库里没有这道菜：先「借近亲图」——融合菜是 AI 现造的，不可能有预构建
  /// 图，但它的食材/口味与库中某道菜高度接近时（如麻辣豆腐牛肉粒盖饭
  /// 之于麻婆豆腐），借用近亲的预构建图比花字盘更有食欲，也符合
  /// 「图片必须预构建、禁在线生成」的项目规则。借不到再退到在线生图。
  Future<RecipeModel> _withLibraryCousinImage(
    RecipeModel dish, {
    CancelToken? cancelToken,
  }) async {
    if (dish.imageUrl?.trim().isNotEmpty ?? false) return dish;
    final terms = {
      ...dish.ingredients.take(3),
      ...dish.tags.take(2),
    }.where((e) => e.trim().isNotEmpty).toList();
    if (terms.isNotEmpty) {
      final candidates = <String, RecipeModel>{};
      for (final term in terms) {
        try {
          final rows = await UnifiedRecipeDatabaseService.instance
              .searchRecipes(term, limit: 5);
          for (final row in rows) {
            final candidate = RecipeModel.fromUnifiedDbRow(row);
            if (candidate.imageUrl?.trim().isNotEmpty ?? false) {
              candidates[candidate.id] = candidate;
            }
          }
        } catch (_) {
          // 单个词检索失败不影响其余词。
        }
      }
      final cousin = pickImageCousin(dish, candidates.values);
      if (cousin != null) return dish.copyWith(imageUrl: cousin.imageUrl);
    }
    return _withGeneratedImage(dish, cancelToken: cancelToken);
  }

  /// 在库候选中为融合菜挑选「近亲」：食材/口味信号重叠 ≥2 才借图，
  /// 避免仅凭一个词撞上就挂上牵强配图。抽成静态纯函数以便单测。
  static RecipeModel? pickImageCousin(
    RecipeModel fusion,
    Iterable<RecipeModel> candidates,
  ) {
    String norm(String value) =>
        value.replaceAll(RegExp(r'[\s·\-—（）()]'), '').trim();
    final tokens = {
      ...fusion.ingredients.map(norm),
      ...fusion.tags.map(norm),
    }.where((e) => e.isNotEmpty).toSet();
    if (tokens.isEmpty) return null;

    RecipeModel? best;
    var bestScore = 1; // 至少 2 个信号重叠才借图
    for (final candidate in candidates) {
      final haystack = norm(
        '${candidate.name} '
        '${candidate.ingredients.join(' ')} '
        '${candidate.tags.join(' ')}',
      );
      var score = 0;
      for (final token in tokens) {
        if (haystack.contains(token)) score++;
      }
      if (score > bestScore) {
        best = candidate;
        bestScore = score;
      }
    }
    return best;
  }

  /// 库里没有这道菜：让模型直接为它生成配图。
  Future<RecipeModel> _withGeneratedImage(
    RecipeModel dish, {
    CancelToken? cancelToken,
  }) async {
    if (dish.imageUrl?.trim().isNotEmpty ?? false) return dish;
    try {
      final url = await _generationService.generateRecipeImageUrl(
        dish,
        cancelToken: cancelToken,
      );
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
    RecipeEligibility eligibility,
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
    final rejections = <String>[];
    for (final aiRecipe in _filterAiCandidates(generated)) {
      final assessment =
          _assess(aiRecipe, eligibility, requireIngredients: true);
      if (!assessment.allowed) {
        rejections.add(assessment.rejectionReason!);
        continue;
      }
      final canonical =
          byId[aiRecipe.id] ?? byName[_normalizeDishName(aiRecipe.name)];
      if (canonical == null || orderedIds.contains(canonical.id)) continue;
      final canonicalAssessment =
          _assess(canonical, eligibility, requireIngredients: true);
      if (!canonicalAssessment.allowed) {
        rejections.add(canonicalAssessment.rejectionReason!);
        continue;
      }
      orderedIds.add(canonical.id);
      final reason = aiRecipe.description.trim();
      if (reason.isNotEmpty) reasonsById[canonical.id] = reason;
    }
    if (orderedIds.isEmpty) {
      return rejections.isEmpty
          ? const _AiEnhancementResult.failed('ai_unresolved')
          : _AiEnhancementResult.failed('ai_constraints_rejected',
              summary: _rejectionSummary(rejections));
    }
    return _AiEnhancementResult.succeeded(
      orderedIds: orderedIds,
      reasonsById: reasonsById,
      fallbackReason: rejections.isEmpty ? null : 'ai_constraints_rejected',
      summary: 'AI 已在本地正式候选中完成辅助收束。${_rejectionSummary(rejections)}',
    );
  }

  String _rejectionSummary(List<String> rejections) => rejections.isEmpty
      ? ''
      : '已排除 ${rejections.length} 道候选：${rejections.toSet().join('、')}。';

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
      // Dietary restrictions are food signals; execution channel, location,
      // time, budget and party size are hard constraints and must not narrow
      // the candidate pool by being treated as dish labels.
      ...input.structuredConstraints.dietaryRestrictions,
      ..._tokenize(input.freeformRequirement),
    ];
    final cleaned = labels
        .map((e) => e.trim())
        .where(PreferenceRecallBridge.isFoodLabel)
        .toSet()
        .toList();
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

  RecipeEligibility _eligibility(TasteInferenceInput input) =>
      RecipeEligibility(
        dietaryRestrictions: input.structuredConstraints.dietaryRestrictions,
        dislikedLabels: input.dislikedTagLabels,
        freeformRequirement: input.freeformRequirement,
        explicitRequestLabels: input.likedTagLabels,
        maxTimeMinutes: input.structuredConstraints.maxTimeMinutes ??
            RecipeEligibility.parseMaxTimeMinutes(
              [input.freeformRequirement, ...input.likedTagLabels].join(' '),
            ),
      );

  RecipeEligibilityResult _assess(
    RecipeModel recipe,
    RecipeEligibility eligibility, {
    bool requireIngredients = false,
  }) {
    if (_isPlaceholderRecipe(recipe) ||
        recipe.name.trim().isEmpty ||
        recipe.id.trim().isEmpty) {
      return const RecipeEligibilityResult('无效或占位菜品');
    }
    return eligibility.evaluate(
      name: recipe.name,
      description: recipe.description,
      ingredients: recipe.ingredients,
      tags: recipe.tags,
      requireIngredients: requireIngredients,
    );
  }

  List<RecipeModel> _sanitizeCandidates(
    List<RecipeModel> candidates,
    TasteInferenceInput input,
  ) {
    final eligibility = _eligibility(input);
    return candidates
        .where((recipe) => _assess(recipe, eligibility).allowed)
        .toList();
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
    return '本地菜谱按 $signals 召回。';
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

  Future<T> _awaitWithCancellation<T>(
    Future<T> future,
    Duration timeout,
    Future<void>? cancelled,
  ) {
    if (cancelled == null) return future.timeout(timeout);
    final completer = Completer<T>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('推荐阶段超时', timeout));
      }
    });
    future.then((value) {
      timer.cancel();
      if (!completer.isCompleted) completer.complete(value);
    }, onError: (Object error, StackTrace stackTrace) {
      timer.cancel();
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    });
    cancelled.then((_) {
      timer.cancel();
      if (!completer.isCompleted) {
        completer.completeError(const _RecommendationCancelled());
      }
    });
    return completer.future;
  }

  Future<List<RecipeModel>> _enrichWithHowToCook(
    List<RecipeModel> candidates, {
    Future<void>? cancelled,
  }) async {
    if (candidates.isEmpty) return candidates;
    return Future.wait(
      candidates.map((recipe) async {
        try {
          final enriched = await _awaitWithCancellation(
            _howToCookRecipeService.enrichRecipe(recipe),
            _enrichmentTimeout,
            cancelled,
          );
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

class _RecommendationCancelled implements Exception {
  const _RecommendationCancelled();
}

class _RecommendationLocalStage {
  const _RecommendationLocalStage({
    required this.input,
    required this.stopwatch,
    required this.recallLabels,
    required this.resultLimit,
    required this.localResult,
    required this.localCandidates,
    required this.localReasons,
  }) : emptyBundle = null;

  const _RecommendationLocalStage.empty({
    required this.input,
    required this.stopwatch,
    required this.recallLabels,
    required this.resultLimit,
    required Phase2RecommendationBundle bundle,
  })  : localResult = null,
        localCandidates = const [],
        localReasons = const {},
        emptyBundle = bundle;

  final TasteInferenceInput input;
  final Stopwatch stopwatch;
  final List<String> recallLabels;
  final int resultLimit;
  final _LocalRecommendationResult? localResult;
  final List<RecipeModel> localCandidates;
  final Map<String, String> localReasons;
  final Phase2RecommendationBundle? emptyBundle;
}

class _LocalRecommendationResult {
  const _LocalRecommendationResult({
    required this.recipes,
    required this.reasonsByRecipeId,
    required this.summary,
    required this.algorithmVersion,
    this.fallbackReason,
  });

  final List<RecipeModel> recipes;
  final Map<String, String> reasonsByRecipeId;
  final String summary;
  final String algorithmVersion;
  final String? fallbackReason;
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

  const _AiEnhancementResult.failed(String reason, {String? summary})
      : this._(
          attempted: true,
          succeeded: false,
          orderedIds: const [],
          reasonsById: const {},
          isEstimated: true,
          fallbackReason: reason,
          summary: summary,
        );

  factory _AiEnhancementResult.succeeded({
    required List<String> orderedIds,
    required Map<String, String> reasonsById,
    String? summary,
    bool isEstimated = false,
    List<RecipeModel> extraRecipes = const [],
    String? fallbackReason,
  }) {
    return _AiEnhancementResult._(
      attempted: true,
      succeeded: true,
      orderedIds: orderedIds,
      reasonsById: reasonsById,
      extraRecipes: extraRecipes,
      fallbackReason: fallbackReason,
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
