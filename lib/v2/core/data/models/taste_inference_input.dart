import 'package:eatwhat_app/v2/core/data/models/meal_planning_direction.dart';
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
    this.planningDirection = MealPlanningDirection.balanced,
  });

  factory TasteInferenceInput.fromSession(
    TasteDeckSessionState session, {
    required Map<String, int> historyPreferenceSummary,
    MealPlanningDirection planningDirection = MealPlanningDirection.balanced,
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
      planningDirection: planningDirection,
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
  final MealPlanningDirection planningDirection;

  List<String> get primarySignals => [
        ...likedTagLabels,
        ...planningDirection.recallLabels,
        ...structuredConstraints.labels,
        if (freeformRequirement.trim().isNotEmpty) freeformRequirement.trim(),
      ];

  TasteInferenceInput copyWith({
    List<String>? likedTagIds,
    List<String>? likedTagLabels,
    List<String>? dislikedTagIds,
    List<String>? dislikedTagLabels,
    List<String>? skippedTagIds,
    List<String>? skippedTagLabels,
    String? freeformRequirement,
    TasteStructuredConstraints? structuredConstraints,
    Map<String, int>? historyPreferenceSummary,
    MealPlanningDirection? planningDirection,
  }) {
    return TasteInferenceInput(
      likedTagIds: likedTagIds ?? this.likedTagIds,
      likedTagLabels: likedTagLabels ?? this.likedTagLabels,
      dislikedTagIds: dislikedTagIds ?? this.dislikedTagIds,
      dislikedTagLabels: dislikedTagLabels ?? this.dislikedTagLabels,
      skippedTagIds: skippedTagIds ?? this.skippedTagIds,
      skippedTagLabels: skippedTagLabels ?? this.skippedTagLabels,
      freeformRequirement: freeformRequirement ?? this.freeformRequirement,
      structuredConstraints:
          structuredConstraints ?? this.structuredConstraints,
      historyPreferenceSummary:
          historyPreferenceSummary ?? this.historyPreferenceSummary,
      planningDirection: planningDirection ?? this.planningDirection,
    );
  }
}
