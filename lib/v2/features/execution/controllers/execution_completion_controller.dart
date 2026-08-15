import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_telemetry_service.dart';

typedef ExecutionCompletionRecorder = Future<void> Function({
  required String recipeId,
  required ExecutionPath path,
  List<String> positiveTagIds,
});
typedef ExecutionRecipeRecorder = Future<void> Function(String recipeId);

class ExecutionCompletionController {
  ExecutionCompletionController({
    ExecutionCompletionRecorder? recordExecutionCompleted,
    ExecutionRecipeRecorder? recordRecipeChosen,
    V2RecommendationTelemetryService? recommendationTelemetryService,
  })  : _recordExecutionCompleted = recordExecutionCompleted ??
            V2PreferenceFeedbackService.instance.recordExecutionCompleted,
        _recordRecipeChosen = recordRecipeChosen ??
            V2PreferenceFeedbackService.instance.recordRecipeChosen,
        _recommendationTelemetry = recommendationTelemetryService ??
            V2RecommendationTelemetryService.instance;

  final ExecutionCompletionRecorder _recordExecutionCompleted;
  final ExecutionRecipeRecorder _recordRecipeChosen;
  final V2RecommendationTelemetryService _recommendationTelemetry;

  Future<String> recordCompleted({
    required ExecutionIntent intent,
    required String platform,
  }) async {
    final path = executionPathForPlatform(platform);
    await _recordExecutionCompleted(
      recipeId: intent.recipe.id,
      path: path,
      positiveTagIds: completionPositiveSignals(intent),
    );
    final recommendationContext = intent.recommendationContext;
    if (recommendationContext != null) {
      await _recommendationTelemetry.recordExecutionCompleted(
        context: recommendationContext,
        recipeId: intent.recipe.id,
        position: intent.recommendationPosition ?? 0,
        executionPath: path.name,
      );
    }
    return '已记住这次开吃选择';
  }

  Future<String> recordNotNow(ExecutionIntent intent) async {
    await _recordRecipeChosen(intent.recipe.id);
    final recommendationContext = intent.recommendationContext;
    if (recommendationContext != null) {
      await _recommendationTelemetry.recordExecutionDeferred(
        context: recommendationContext,
        recipeId: intent.recipe.id,
        position: intent.recommendationPosition ?? 0,
        executionPath: intent.preferredPath.name,
      );
    }
    return '已记住：这次先不算完成';
  }
}

ExecutionPath executionPathForPlatform(String platform) {
  return switch (platform.trim().toLowerCase()) {
    'delivery' ||
    'meituan' ||
    'eleme' ||
    'jd' ||
    'jd_delivery' =>
      ExecutionPath.delivery,
    'dine_in' || 'dianping' || 'apple_maps' => ExecutionPath.dineIn,
    _ => ExecutionPath.any,
  };
}

List<String> completionPositiveSignals(ExecutionIntent intent) {
  return intent.sourceTags
      .take(3)
      .where((tag) => tag.trim().isNotEmpty)
      .toList();
}
