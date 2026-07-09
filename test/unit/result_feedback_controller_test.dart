import 'package:eatwhat_app/v2/features/result/controllers/result_feedback_controller.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_feedback_band.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResultFeedbackController', () {
    test('enjoyed feedback records recipe and positive tags', () async {
      final chosenRecipes = <String>[];
      final positiveTags = <String>[];
      final negativeTags = <String>[];
      final controller = ResultFeedbackController(
        recordRecipeChosen: (recipeId) async {
          chosenRecipes.add(recipeId);
        },
        recordPositiveTag: (tagId) async {
          positiveTags.add(tagId);
        },
        recordNegativeTag: (tagId) async {
          negativeTags.add(tagId);
        },
      );

      final message = await controller.recordFeedback(
        recipeId: 'dish_1',
        tagIds: const ['f_hot', 'scene_dinner'],
        selection: ResultFeedbackSelection.enjoyed,
      );

      expect(chosenRecipes, ['dish_1']);
      expect(positiveTags, ['f_hot', 'scene_dinner']);
      expect(negativeTags, isEmpty);
      expect(message, '已记住：这口合你胃口');
    });

    test('not-for-me feedback records recipe and negative tags', () async {
      final chosenRecipes = <String>[];
      final positiveTags = <String>[];
      final negativeTags = <String>[];
      final controller = ResultFeedbackController(
        recordRecipeChosen: (recipeId) async {
          chosenRecipes.add(recipeId);
        },
        recordPositiveTag: (tagId) async {
          positiveTags.add(tagId);
        },
        recordNegativeTag: (tagId) async {
          negativeTags.add(tagId);
        },
      );

      final message = await controller.recordFeedback(
        recipeId: 'dish_2',
        tagIds: const ['f_spicy'],
        selection: ResultFeedbackSelection.notForMe,
      );

      expect(chosenRecipes, ['dish_2']);
      expect(positiveTags, isEmpty);
      expect(negativeTags, ['f_spicy']);
      expect(message, '已记住：下次少推这一类');
    });
  });
}
