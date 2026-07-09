import 'package:eatwhat_app/v2/features/result/controllers/result_enrichment_controller.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_feedback_band.dart';

class ResultChoiceSelectionState<TPairing> {
  const ResultChoiceSelectionState({
    required this.feedbackSelection,
    required this.pairings,
  });

  final ResultFeedbackSelection? feedbackSelection;
  final List<TPairing> pairings;
}

class ResultChoiceStateCoordinator<TPairing> {
  const ResultChoiceStateCoordinator();

  ResultChoiceSelectionState<TPairing> prepareSelection({
    required String recipeId,
    required ResultEnrichmentController<TPairing> enrichmentController,
    required ResultFeedbackSelection? currentFeedbackSelection,
  }) {
    final cachedPairings = enrichmentController.pairingsFor(recipeId);
    if (cachedPairings != null && cachedPairings.isNotEmpty) {
      return ResultChoiceSelectionState<TPairing>(
        feedbackSelection: null,
        pairings: cachedPairings,
      );
    }
    enrichmentController.markPairingsLoading(recipeId);
    return ResultChoiceSelectionState<TPairing>(
      feedbackSelection: null,
      pairings: const [],
    );
  }
}
