import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';

class HomeRecentSuccessController {
  const HomeRecentSuccessController();

  TasteInferenceInput? buildInput({
    required TasteDeckSessionState session,
    required Map<String, int> historyScores,
    required List<String> recentRecipeIds,
  }) {
    if (recentRecipeIds.isEmpty) return null;

    return TasteInferenceInput(
      likedTagIds: const ['recent_success'],
      likedTagLabels: const ['最近成功'],
      dislikedTagIds: List<String>.from(session.dislikedTagIds),
      dislikedTagLabels: List<String>.from(session.dislikedTagLabels),
      skippedTagIds: List<String>.from(session.skippedTagIds),
      skippedTagLabels: List<String>.from(session.skippedTagLabels),
      freeformRequirement: '复用上次吃得很爽的选择',
      structuredConstraints: session.structuredConstraints,
      historyPreferenceSummary: Map<String, int>.from(historyScores),
    );
  }
}
