import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';

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
  })  : _recordExecutionCompleted = recordExecutionCompleted ??
            V2PreferenceFeedbackService.instance.recordExecutionCompleted,
        _recordRecipeChosen = recordRecipeChosen ??
            V2PreferenceFeedbackService.instance.recordRecipeChosen;

  final ExecutionCompletionRecorder _recordExecutionCompleted;
  final ExecutionRecipeRecorder _recordRecipeChosen;

  Future<String> recordCompleted({
    required ExecutionIntent intent,
    required String platform,
  }) async {
    await _recordExecutionCompleted(
      recipeId: intent.recipe.id,
      path: executionPathForPlatform(platform),
      positiveTagIds: completionPositiveSignals(intent),
    );
    return '已记住这次开吃选择';
  }

  Future<String> recordNotNow(ExecutionIntent intent) async {
    await _recordRecipeChosen(intent.recipe.id);
    return '已记住：这次先不算完成';
  }
}

ExecutionPath executionPathForPlatform(String platform) {
  return switch (platform.trim().toLowerCase()) {
    'meituan' || 'eleme' => ExecutionPath.delivery,
    'dianping' || 'apple_maps' => ExecutionPath.dineIn,
    _ => ExecutionPath.any,
  };
}

List<String> completionPositiveSignals(ExecutionIntent intent) {
  return intent.sourceTags
      .take(3)
      .where((tag) => tag.trim().isNotEmpty)
      .toList();
}
