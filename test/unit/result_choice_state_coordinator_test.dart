import 'package:eatwhat_app/v2/features/result/controllers/result_choice_state_coordinator.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_enrichment_controller.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_feedback_band.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResultChoiceStateCoordinator', () {
    test('uses cached pairings and clears feedback when selecting a cached dish',
        () {
      final enrichment = ResultEnrichmentController<String>()
        ..completePairings('r2', const ['酸梅汤', '凉拌黄瓜']);
      const coordinator = ResultChoiceStateCoordinator<String>();

      final state = coordinator.prepareSelection(
        recipeId: 'r2',
        enrichmentController: enrichment,
        currentFeedbackSelection: ResultFeedbackSelection.enjoyed,
      );

      expect(state.feedbackSelection, isNull);
      expect(state.pairings, ['酸梅汤', '凉拌黄瓜']);
      expect(enrichment.pairingStateFor('r2'), PairingLoadState.loaded);
    });

    test('clears pairings and marks loading when selecting an uncached dish', () {
      final enrichment = ResultEnrichmentController<String>();
      const coordinator = ResultChoiceStateCoordinator<String>();

      final state = coordinator.prepareSelection(
        recipeId: 'r3',
        enrichmentController: enrichment,
        currentFeedbackSelection: ResultFeedbackSelection.notForMe,
      );

      expect(state.feedbackSelection, isNull);
      expect(state.pairings, isEmpty);
      expect(enrichment.pairingStateFor('r3'), PairingLoadState.loading);
    });
  });
}
