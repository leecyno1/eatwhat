import 'dart:async';

import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';
import 'package:eatwhat_app/v2/features/result/result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ResultPage AI 包落地后换入重排候选与理由并切换状态徽章', (tester) async {
    final completer = Completer<Phase2RecommendationBundle>();

    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          recommendations: const [
            RecipeModel(
              id: 'r1',
              name: '麻婆豆腐',
              description: '本地候选一。',
            ),
            RecipeModel(
              id: 'r2',
              name: '红烧肉',
              description: '本地候选二。',
            ),
          ],
          aiReasonsByRecipeId: const {'r1': '本地理由'},
          aiEnhancement: completer.future,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    // Before the bundle lands: enhancing chip up, local reason in place.
    expect(find.byKey(const ValueKey('ai-chef-enhancing')), findsOneWidget);
    expect(find.text('AI 点菜师增强中…'), findsOneWidget);
    expect(find.text('本地理由'), findsOneWidget);
    expect(find.text('清蒸鲈鱼'), findsNothing);

    completer.complete(
      Phase2RecommendationBundle(
        recallLabels: const ['辣'],
        recalledCount: 2,
        finalRecommendations: const [
          RecipeModel(
            id: 'r2',
            name: '红烧肉',
            description: 'AI 重排保留。',
          ),
          RecipeModel(
            id: 'r3',
            name: '清蒸鲈鱼',
            description: 'AI 新引入的组合菜。',
          ),
        ],
        aiReasonsByRecipeId: const {'r2': 'AI 组合理由'},
        aiSummary: null,
        isEstimated: false,
        resolutionStatus: RecommendationResolutionStatus.aiResolved,
        primarySource: 'unified_db',
      ),
    );
    await tester.pumpAndSettle();

    // After the bundle lands: enhanced chip, dropped local dish is gone,
    // the AI-only candidate joined, and the reason line shows the AI-written
    // per-dish reason for the preserved current dish (r2).
    expect(find.byKey(const ValueKey('ai-chef-enhanced')), findsOneWidget);
    expect(find.text('AI 点菜师已重排'), findsOneWidget);
    expect(find.text('麻婆豆腐'), findsNothing);
    expect(find.text('清蒸鲈鱼'), findsWidgets);
    expect(find.text('AI 组合理由'), findsOneWidget);
    expect(find.text('本地理由'), findsNothing);
  });

  testWidgets('ResultPage AI 增强失败时熄灭徽章并保留本地候选与理由', (tester) async {
    final completer = Completer<Phase2RecommendationBundle>();

    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          recommendations: const [
            RecipeModel(
              id: 'r1',
              name: '麻婆豆腐',
              description: '本地候选一。',
            ),
          ],
          aiReasonsByRecipeId: const {'r1': '本地理由'},
          aiEnhancement: completer.future,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byKey(const ValueKey('ai-chef-enhancing')), findsOneWidget);

    completer.completeError(StateError('minimax timeout'));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byKey(const ValueKey('ai-chef-enhancing')), findsNothing);
    expect(find.byKey(const ValueKey('ai-chef-enhanced')), findsNothing);
    expect(find.text('本地理由'), findsOneWidget);
  });
}
