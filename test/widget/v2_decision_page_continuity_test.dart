import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';
import 'package:eatwhat_app/v2/features/decision/decision_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapTestEnvironment();
  });

  testWidgets('DecisionPage 接收口味签名并展示原收束舞台', (tester) async {
    final logs = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: DecisionPage(
            autoNavigateToResult: false,
            input: const TasteInferenceInput(
              likedTagIds: ['f_spicy', 'c_hotpot'],
              likedTagLabels: ['辣', '火锅'],
              dislikedTagIds: ['f_sweet'],
              dislikedTagLabels: ['甜'],
              skippedTagIds: ['scene_party'],
              skippedTagLabels: ['聚会'],
              freeformRequirement: '今晚想吃热一点，有锅气',
              historyPreferenceSummary: {'f_spicy': 4, 'f_sweet': -2},
            ),
            recommendationFlowService: _ImmediateRecommendationService(),
          ),
        ),
      );
      await tester.pump();

      expect(
        logs.where((e) => e.contains('databaseFactory not initialized')),
        isEmpty,
      );
      expect(find.text('TASTE BOARD'), findsNothing);
      expect(find.text('口味收束台'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('decision-stage-shell')), findsOneWidget);
      expect(find.text('正在组合你的口味签名'), findsOneWidget);
      expect(find.text('暖食编辑部'), findsNothing);
      expect(find.textContaining('本地召回'), findsWidgets);
      expect(find.textContaining('智能收束'), findsWidgets);
    } finally {
      debugPrint = previousDebugPrint;
    }
  });
}

class _ImmediateRecommendationService extends V2Phase2RecommendationService {
  _ImmediateRecommendationService();

  @override
  Future<Phase2RecommendationBundle> buildRecommendations({
    required TasteInferenceInput input,
    int recallLimit = 12,
    int finalLimit = 5,
  }) async {
    return Phase2RecommendationBundle(
      recallLabels: input.primarySignals,
      recalledCount: 0,
      finalRecommendations: const [],
      aiReasonsByRecipeId: const {},
      aiSummary: '测试环境已跳过真实推荐流程。',
      isEstimated: true,
      resolutionStatus: RecommendationResolutionStatus.empty,
      primarySource: 'test',
    );
  }
}
