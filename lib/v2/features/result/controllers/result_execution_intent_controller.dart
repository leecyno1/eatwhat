import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_telemetry_context.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_pairing_band.dart';

class ResultExecutionIntentController {
  const ResultExecutionIntentController();

  ExecutionIntent buildIntent({
    required RecipeModel recipe,
    required ExecutionPath preferredPath,
    required List<PairingSuggestion> pairings,
    required List<String> displayTags,
    TasteStructuredConstraints? structuredConstraints,
    RecommendationTelemetryContext? recommendationContext,
    int? recommendationPosition,
  }) {
    final locationPreference = structuredConstraints?.locationPreference ==
            TasteLocationPreference.nearby
        ? ExecutionLocationPreference.nearby
        : ExecutionLocationPreference.any;

    return ExecutionIntent(
      recipe: recipe,
      pairings: pairings
          .map(
            (pairing) => PairingSelection(
              category: pairing.category,
              title: pairing.title,
              subtitle: pairing.subtitle,
            ),
          )
          .toList(),
      sourceTags: displayTags.isNotEmpty ? displayTags : recipe.tags,
      preferredPath: preferredPath,
      locationPreference: locationPreference,
      recommendationContext: recommendationContext,
      recommendationPosition: recommendationPosition,
    );
  }
}
