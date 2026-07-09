import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';

class TasteInferenceInput {
  const TasteInferenceInput({
    required this.likedTagIds,
    required this.likedTagLabels,
    required this.dislikedTagIds,
    required this.dislikedTagLabels,
    required this.skippedTagIds,
    required this.skippedTagLabels,
    required this.freeformRequirement,
    this.structuredConstraints = const TasteStructuredConstraints(),
    required this.historyPreferenceSummary,
  });

  factory TasteInferenceInput.fromSession(
    TasteDeckSessionState session, {
    required Map<String, int> historyPreferenceSummary,
  }) {
    return TasteInferenceInput(
      likedTagIds: List<String>.from(session.likedTagIds),
      likedTagLabels: List<String>.from(session.likedTagLabels),
      dislikedTagIds: List<String>.from(session.dislikedTagIds),
      dislikedTagLabels: List<String>.from(session.dislikedTagLabels),
      skippedTagIds: List<String>.from(session.skippedTagIds),
      skippedTagLabels: List<String>.from(session.skippedTagLabels),
      freeformRequirement: session.freeformRequirement,
      structuredConstraints: session.structuredConstraints,
      historyPreferenceSummary: Map<String, int>.from(historyPreferenceSummary),
    );
  }

  final List<String> likedTagIds;
  final List<String> likedTagLabels;
  final List<String> dislikedTagIds;
  final List<String> dislikedTagLabels;
  final List<String> skippedTagIds;
  final List<String> skippedTagLabels;
  final String freeformRequirement;
  final TasteStructuredConstraints structuredConstraints;
  final Map<String, int> historyPreferenceSummary;

  List<String> get primarySignals => [
        ...likedTagLabels,
        ...structuredConstraints.labels,
        if (freeformRequirement.trim().isNotEmpty) freeformRequirement.trim(),
      ];
}
