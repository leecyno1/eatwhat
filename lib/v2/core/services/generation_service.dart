import 'package:dio/dio.dart';
import 'package:eatwhat_app/v2/core/config/client_config.dart';
import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/services/dish_enhancement_service.dart';
import 'package:eatwhat_app/v2/core/services/generation_transport.dart';
import 'package:eatwhat_app/v2/core/services/v2_ai_cache_service.dart';
import 'package:flutter/foundation.dart';

/// 保留现有调用入口的 AI 生成 facade。
class GenerationService {
  GenerationService._internal()
      : _enhancement = DishEnhancementService(
          transport: GenerationTransport(),
          cache: V2AiCacheService.instance,
        );

  GenerationService.withConfig(ClientConfig config)
      : _enhancement = DishEnhancementService(
          transport: GenerationTransport(config: config),
          cache: V2AiCacheService.instance,
          config: config,
        );

  static final GenerationService instance = GenerationService._internal();

  final DishEnhancementService _enhancement;

  bool get isConfigured => _enhancement.isConfigured;

  Future<String?> generateRecipeImageUrl(
    RecipeModel recipe, {
    CancelToken? cancelToken,
  }) {
    return _enhancement.generateRecipeImageUrl(
      recipe,
      cancelToken: cancelToken,
    );
  }

  Future<String?> generateDishIntroduction(
    RecipeModel recipe, {
    String? recommendationReason,
    String? userRequirement,
  }) {
    return _enhancement.generateDishIntroduction(
      recipe,
      recommendationReason: recommendationReason,
      userRequirement: userRequirement,
    );
  }

  @visibleForTesting
  static String? extractMiniMaxImageBase64(dynamic payload) {
    return GenerationTransport.extractMiniMaxImageBase64(payload);
  }

  @visibleForTesting
  static String? extractMiniMaxImageUrl(dynamic payload) {
    return GenerationTransport.extractMiniMaxImageUrl(payload);
  }

  Future<List<RecipeModel>> generateFusionDishes({
    required List<String> tags,
    String? customRequirement,
    int count = 4,
    CancelToken? cancelToken,
  }) {
    return _enhancement.generateFusionDishes(
      tags: tags,
      customRequirement: customRequirement,
      count: count,
      cancelToken: cancelToken,
    );
  }

  static List<RecipeModel> parseFusionDishes(
    Map<String, dynamic> jsonMap,
    List<String> cleanedTags,
  ) {
    return DishEnhancementService.parseFusionDishes(jsonMap, cleanedTags);
  }

  Future<NutritionAnalysis> getNutritionAnalysis(RecipeModel recipe) {
    return _enhancement.getNutritionAnalysis(recipe);
  }

  Future<WinePairing> getWinePairing(RecipeModel recipe) {
    return _enhancement.getWinePairing(recipe);
  }

  Future<FortuneResult> getFortune({
    required RecipeModel recipe,
    String fortuneType = 'daily',
  }) {
    return _enhancement.getFortune(
      recipe: recipe,
      fortuneType: fortuneType,
    );
  }
}
