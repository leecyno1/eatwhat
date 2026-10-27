import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_telemetry_context.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/external/platform/meituan_delivery_order_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';

class AppV2Routes {
  const AppV2Routes._();

  static const String home = '/';
  static const String decision = '/decision';
  static const String result = '/result';
  static const String recipeDetail = '/recipe-detail';
  static const String recipeDetailDemo = '/recipe-detail-demo';
  static const String execution = '/execution';
  static const String executionDelivery = '/execution-delivery';
  static const String executionDineIn = '/execution-dine-in';
  static const String decisionDemo = '/decision-demo';
  static const String resultDemo = '/result-demo';
  static const String favorites = '/favorites';
  static const String howtocookLibrary = '/howtocook';
  static const String executionDemo = '/execution-demo';
  static const String deliveryDemo = '/delivery-demo';
  static const String orderDemo = '/order-demo';
  static const String login = '/login';
  static const String register = '/register';
}

class AppV2DecisionRouteData {
  const AppV2DecisionRouteData({
    required this.input,
    this.recommendationFlowService,
    this.autoNavigateToResult = true,
  });

  final TasteInferenceInput input;
  final V2Phase2RecommendationService? recommendationFlowService;
  final bool autoNavigateToResult;
}

class AppV2ResultRouteData {
  const AppV2ResultRouteData({
    required this.recommendations,
    required this.inferenceInput,
    this.fallbackTags = const [],
    this.recallLabels = const [],
    this.recalledCount = 0,
    this.aiReasonsByRecipeId = const {},
    this.aiSummary,
    this.resolutionStatus,
    this.primarySource,
    this.recommendationContext,
    this.aiEnhancement,
    this.cancelAiEnhancement,
  });

  final List<RecipeModel> recommendations;
  final TasteInferenceInput inferenceInput;
  final List<String> fallbackTags;
  final List<String> recallLabels;
  final int recalledCount;
  final Map<String, String> aiReasonsByRecipeId;
  final String? aiSummary;
  final RecommendationResolutionStatus? resolutionStatus;
  final String? primarySource;
  final RecommendationTelemetryContext? recommendationContext;

  /// Background MiniMax refine running behind the already-shown local
  /// results; the result page updates its reason line when it lands.
  final Future<Phase2RecommendationBundle>? aiEnhancement;
  final void Function()? cancelAiEnhancement;
}

class AppV2RecipeDetailRouteData {
  const AppV2RecipeDetailRouteData({
    required this.recipe,
    this.howToCookRecipeService,
    this.startInCookingMode = false,
  });

  final RecipeModel recipe;
  final V2HowToCookRecipeService? howToCookRecipeService;
  final bool startInCookingMode;
}

class AppV2HowToCookLibraryRouteData {
  const AppV2HowToCookLibraryRouteData({
    this.service,
    this.initialCategory = '',
    this.initialQuery = '',
  });

  final V2HowToCookRecipeService? service;
  final String initialCategory;
  final String initialQuery;
}

class AppV2ExecutionRouteData {
  const AppV2ExecutionRouteData({
    required this.intent,
  });

  final ExecutionIntent intent;
}

class AppV2DeliveryExecutionRouteData {
  const AppV2DeliveryExecutionRouteData({
    required this.intent,
    this.snapshot,
    this.meituanOrderClient,
    this.locationResolver,
  });

  final ExecutionIntent intent;
  final DeliveryExecutionSnapshot? snapshot;
  final MeituanDeliveryOrderClient? meituanOrderClient;
  final Future<GeoPoint> Function()? locationResolver;
}

class AppV2DineInExecutionRouteData {
  const AppV2DineInExecutionRouteData({
    required this.intent,
    this.snapshot,
  });

  final ExecutionIntent intent;
  final DineInExecutionSnapshot? snapshot;
}
