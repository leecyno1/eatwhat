import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/controllers/home_appetite_preview_resolver.dart';

class HomeAppetitePreviewController {
  const HomeAppetitePreviewController();

  TasteInferenceInput buildInput({
    required TasteDeckSessionState session,
    required HomeAppetitePreview preview,
    required String currentRequirement,
    required Map<String, int> historyScores,
  }) {
    final trimmedRequirement = currentRequirement.trim();
    final previewRequirement = trimmedRequirement.isEmpty
        ? '想吃${preview.title}'
        : '$trimmedRequirement，想吃${preview.title}';

    return TasteInferenceInput(
      likedTagIds: session.likedTagIds.isEmpty
          ? const ['home_appetite_preview']
          : List<String>.from(session.likedTagIds),
      likedTagLabels: session.likedTagLabels.isEmpty
          ? const ['家常', '热菜']
          : List<String>.from(session.likedTagLabels),
      dislikedTagIds: List<String>.from(session.dislikedTagIds),
      dislikedTagLabels: List<String>.from(session.dislikedTagLabels),
      skippedTagIds: List<String>.from(session.skippedTagIds),
      skippedTagLabels: List<String>.from(session.skippedTagLabels),
      freeformRequirement: previewRequirement,
      structuredConstraints: session.structuredConstraints,
      historyPreferenceSummary: Map<String, int>.from(historyScores),
    );
  }
}
