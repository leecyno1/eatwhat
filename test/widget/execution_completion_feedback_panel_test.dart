import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/features/execution/controllers/execution_completion_controller.dart';
import 'package:eatwhat_app/v2/features/execution/widgets/execution_completion_feedback_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('完成反馈面板会记录完成并给用户确认', (tester) async {
    final completed = <_CompletedRecord>[];
    final chosenRecipes = <String>[];
    final controller = ExecutionCompletionController(
      recordExecutionCompleted: ({
        required recipeId,
        required path,
        positiveTagIds = const [],
      }) async {
        completed.add(
          _CompletedRecord(
            recipeId: recipeId,
            path: path,
            positiveTagIds: positiveTagIds,
          ),
        );
      },
      recordRecipeChosen: (recipeId) async {
        chosenRecipes.add(recipeId);
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExecutionCompletionFeedbackPanel(
            intent: _intent(),
            platform: 'meituan',
            controller: controller,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('execution-completion-done')));
    await tester.pumpAndSettle();

    expect(find.text('已记住这次开吃选择'), findsOneWidget);
    expect(chosenRecipes, isEmpty);
    expect(completed, hasLength(1));
    expect(completed.single.recipeId, 'dish_1');
    expect(completed.single.path, ExecutionPath.delivery);
    expect(completed.single.positiveTagIds, ['热菜', '家常']);
  });

  testWidgets('暂不完成反馈只记录本次菜品选择', (tester) async {
    final completed = <_CompletedRecord>[];
    final chosenRecipes = <String>[];
    final controller = ExecutionCompletionController(
      recordExecutionCompleted: ({
        required recipeId,
        required path,
        positiveTagIds = const [],
      }) async {
        completed.add(
          _CompletedRecord(
            recipeId: recipeId,
            path: path,
            positiveTagIds: positiveTagIds,
          ),
        );
      },
      recordRecipeChosen: (recipeId) async {
        chosenRecipes.add(recipeId);
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExecutionCompletionFeedbackPanel(
            intent: _intent(),
            platform: 'dianping',
            controller: controller,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('execution-completion-not-now')));
    await tester.pumpAndSettle();

    expect(find.text('已记住：这次先不算完成'), findsOneWidget);
    expect(chosenRecipes, ['dish_1']);
    expect(completed, isEmpty);
  });
}

ExecutionIntent _intent() {
  return const ExecutionIntent(
    recipe: RecipeModel(
      id: 'dish_1',
      name: '番茄肥牛锅',
      description: '热乎下饭',
    ),
    pairings: [],
    sourceTags: ['热菜', '家常'],
  );
}

class _CompletedRecord {
  const _CompletedRecord({
    required this.recipeId,
    required this.path,
    required this.positiveTagIds,
  });

  final String recipeId;
  final ExecutionPath path;
  final List<String> positiveTagIds;
}
