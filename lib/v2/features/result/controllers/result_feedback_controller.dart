import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_feedback_band.dart';

typedef RecipeChoiceRecorder = Future<void> Function(String recipeId);
typedef TagFeedbackRecorder = Future<void> Function(String tagId);

class ResultFeedbackController {
  ResultFeedbackController({
    RecipeChoiceRecorder? recordRecipeChosen,
    TagFeedbackRecorder? recordPositiveTag,
    TagFeedbackRecorder? recordNegativeTag,
  })  : _recordRecipeChosen = recordRecipeChosen ??
            V2PreferenceFeedbackService.instance.recordRecipeChosen,
        _recordPositiveTag = recordPositiveTag ??
            V2PreferenceFeedbackService.instance.recordPositiveTag,
        _recordNegativeTag = recordNegativeTag ??
            V2PreferenceFeedbackService.instance.recordNegativeTag;

  final RecipeChoiceRecorder _recordRecipeChosen;
  final TagFeedbackRecorder _recordPositiveTag;
  final TagFeedbackRecorder _recordNegativeTag;

  Future<String> recordFeedback({
    required String recipeId,
    required List<String> tagIds,
    required ResultFeedbackSelection selection,
  }) async {
    final isPositive = selection == ResultFeedbackSelection.enjoyed;
    final operations = <Future<void>>[
      _recordRecipeChosen(recipeId),
      for (final tagId in tagIds)
        isPositive ? _recordPositiveTag(tagId) : _recordNegativeTag(tagId),
    ];
    await Future.wait(operations);
    return isPositive ? '已记住：这口合你胃口' : '已记住：下次少推这一类';
  }
}
