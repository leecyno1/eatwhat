import 'package:eatwhat_app/v2/core/config/client_config.dart';
import 'package:eatwhat_app/v2/core/services/generation_service.dart';
import 'package:eatwhat_app/v2/core/services/unified_recommendation_service_v2.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';

class AppDependencies {
  const AppDependencies({
    required this.generationService,
    required this.howToCookRecipeService,
    required this.recommendationFlowService,
  });

  factory AppDependencies.standard() {
    final config = ClientConfig.fromEnvConfig();
    final generation = GenerationService.withConfig(config);
    final howToCook = V2HowToCookRecipeService.instance;
    return AppDependencies(
      generationService: generation,
      howToCookRecipeService: howToCook,
      recommendationFlowService: V2Phase2RecommendationService(
        recommendationService: UnifiedRecommendationServiceV2.instance,
        generationService: generation,
        howToCookRecipeService: howToCook,
      ),
    );
  }

  final GenerationService generationService;
  final V2HowToCookRecipeService howToCookRecipeService;
  final V2Phase2RecommendationService recommendationFlowService;
}
