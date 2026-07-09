import 'package:dio/dio.dart';
import 'package:eatwhat_app/v2/core/ai/ai_service.dart';
import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
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
  });

  final List<String> recallLabels;
  final int recalledCount;
  final List<RecipeModel> finalRecommendations;
  final Map<String, String> aiReasonsByRecipeId;
  final String? aiSummary;
  final bool isEstimated;
  final RecommendationResolutionStatus resolutionStatus;
  final String primarySource;
}

class V2Phase2RecommendationService {
  V2Phase2RecommendationService({
    LocalRecommendationLoader? localRecommendationLoader,
    RecommendationRefiner? recommendationRefiner,
    AiRecommendationLoader? aiRecommendationLoader,
    UnifiedRecommendationServiceV2? recommendationService,
    GenerationService? generationService,
    AiService? aiService,
    V2HowToCookRecipeService? howToCookRecipeService,
    Duration stageTimeout = const Duration(seconds: 6),
    Duration enrichmentTimeout = const Duration(seconds: 3),
  })  : _aiRecommendationLoader = aiRecommendationLoader,
        _aiService = aiService ?? AiService(Dio()),
        _howToCookRecipeService =
            howToCookRecipeService ?? V2HowToCookRecipeService.instance,
        _stageTimeout = stageTimeout,
        _enrichmentTimeout = enrichmentTimeout {
    _ignoreLegacyDependency(localRecommendationLoader);
    _ignoreLegacyDependency(recommendationRefiner);
    _ignoreLegacyDependency(recommendationService);
    _ignoreLegacyDependency(generationService);
  }

  final AiRecommendationLoader? _aiRecommendationLoader;
  final AiService _aiService;
  final V2HowToCookRecipeService _howToCookRecipeService;
  final Duration _stageTimeout;
  final Duration _enrichmentTimeout;

  Future<Phase2RecommendationBundle> buildRecommendations({
    required TasteInferenceInput input,
    int recallLimit = 12,
    int finalLimit = 5,
  }) async {
    final recallLabels = _recallLabels(input);
    final candidateLimit = recallLimit <= 0 ? finalLimit : recallLimit;
    List<RecipeModel> aiResults;
    Object? aiError;
    try {
      final userProfile = _buildAiRequirement(input);
      final loader = _aiRecommendationLoader;
      final aiFuture = Future<List<RecipeModel>>(() async {
        if (loader != null) {
          return loader(
            tags: recallLabels,
            userProfile: userProfile,
          );
        }
        return _aiService.recommendRecipes(
          tags: recallLabels,
          userProfile: userProfile,
        );
      });
      aiResults = await aiFuture
          .timeout(
        _stageTimeout,
        onTimeout: () => <RecipeModel>[],
      )
          .catchError((Object error, StackTrace stackTrace) {
        aiError = error;
        return <RecipeModel>[];
      });
    } catch (error) {
      aiError = error;
      aiResults = const [];
    }
    if (aiError != null) {
      return _fallbackBundle(
        recallLabels: recallLabels,
        recalledCount: 0,
        aiSummary: 'AI 推荐服务暂时不可用，未使用本地菜谱兜底生成结果。',
        primarySource: 'error',
      );
    }
    final results = _dedupe(
      _filterAiCandidates(_sanitizeCandidates(aiResults, input)),
    ).take(candidateLimit).toList();
    if (results.isEmpty) {
      return _fallbackBundle(
        recallLabels: recallLabels,
        recalledCount: 0,
        aiSummary: 'AI 本轮没有生成可展示的正式菜品。',
        primarySource: 'ai',
      );
    }

    final generatedRecommendations = results.take(finalLimit).toList();
    final finalRecommendations =
        await _enrichWithHowToCook(generatedRecommendations);

    return Phase2RecommendationBundle(
      recallLabels: recallLabels,
      recalledCount: results.length,
      finalRecommendations: finalRecommendations,
      aiReasonsByRecipeId: _buildAiReasons(
        generatedRecommendations,
        recallLabels,
      ),
      aiSummary:
          'AI 已根据口味签名生成 ${finalRecommendations.length} 道候选，HowToCook 只用于补充图片和做法。',
      isEstimated: true,
      resolutionStatus: RecommendationResolutionStatus.aiResolved,
      primarySource: 'ai',
    );
  }

  Phase2RecommendationBundle _fallbackBundle({
    required List<String> recallLabels,
    required int recalledCount,
    String? aiSummary,
    String primarySource = 'empty',
  }) {
    return Phase2RecommendationBundle(
      recallLabels: recallLabels,
      recalledCount: recalledCount,
      finalRecommendations: const [],
      aiReasonsByRecipeId: const {},
      aiSummary: aiSummary ?? '这轮没有命中合适的菜品。',
      isEstimated: true,
      resolutionStatus: RecommendationResolutionStatus.empty,
      primarySource: primarySource,
    );
  }

  List<String> _recallLabels(TasteInferenceInput input) {
    final labels = <String>[
      ...input.likedTagLabels,
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
      if (blockedLabels.any(haystack.contains)) {
        return false;
      }
      if (_isPlaceholderRecipe(recipe)) {
        return false;
      }
      return recipe.name.trim().isNotEmpty;
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
      final name = recipe.name.replaceAll(RegExp(r'\s+'), '').trim();
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

  Map<String, String> _buildAiReasons(
    List<RecipeModel> recipes,
    List<String> recallLabels,
  ) {
    final signalText = recallLabels.take(4).join('、');
    return {
      for (final recipe in recipes)
        recipe.id: recipe.description.trim().isNotEmpty
            ? recipe.description.trim()
            : (signalText.isEmpty
                ? '由 AI 根据本轮口味签名直接生成。'
                : '由 AI 根据 $signalText 直接生成。'),
    };
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

void _ignoreLegacyDependency(Object? dependency) {
  if (dependency == null) return;
}
