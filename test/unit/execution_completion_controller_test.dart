import 'package:eatwhat_app/core/models/analytics_event.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_telemetry_context.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_telemetry_service.dart';
import 'package:eatwhat_app/v2/features/execution/controllers/execution_completion_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExecutionCompletionController', () {
    test('records completed execution with path and positive signals',
        () async {
      final completed = <_CompletedRecord>[];
      final chosenRecipes = <String>[];
      final telemetryEvents = <_TelemetryEvent>[];
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
        recommendationTelemetryService: _telemetry(telemetryEvents),
      );

      final message = await controller.recordCompleted(
        intent: _intent(),
        platform: 'meituan',
      );

      expect(message, '已记住这次开吃选择');
      expect(chosenRecipes, isEmpty);
      expect(completed, hasLength(1));
      expect(completed.single.recipeId, 'dish_1');
      expect(completed.single.path, ExecutionPath.delivery);
      expect(completed.single.positiveTagIds, ['热菜', '家常']);
      expect(telemetryEvents, hasLength(1));
      expect(
        telemetryEvents.single.type,
        AnalyticsEventType.recommendationExecutionCompleted,
      );
      expect(telemetryEvents.single.properties['recommendation_id'], 'rec_1');
      expect(telemetryEvents.single.properties['execution_path'], 'delivery');
    });

    test('records not-now feedback as recipe chosen only', () async {
      final completed = <_CompletedRecord>[];
      final chosenRecipes = <String>[];
      final telemetryEvents = <_TelemetryEvent>[];
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
        recommendationTelemetryService: _telemetry(telemetryEvents),
      );

      final message = await controller.recordNotNow(_intent());

      expect(message, '已记住：这次先不算完成');
      expect(chosenRecipes, ['dish_1']);
      expect(completed, isEmpty);
      expect(telemetryEvents, hasLength(1));
      expect(
        telemetryEvents.single.type,
        AnalyticsEventType.recommendationExecutionDeferred,
      );
      expect(telemetryEvents.single.properties['execution_path'], 'delivery');
    });
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
    preferredPath: ExecutionPath.delivery,
    recommendationContext: RecommendationTelemetryContext(
      recommendationId: 'rec_1',
      algorithmVersion: 'hybrid_v3_0',
      primarySource: 'unified_db',
      resolutionStatus: RecommendationResolutionStatus.dbResolved,
      recalledCount: 12,
      finalCount: 5,
      latencyMs: 200,
      diversityScore: 0.8,
      appliedConstraintCount: 1,
    ),
    recommendationPosition: 1,
  );
}

V2RecommendationTelemetryService _telemetry(List<_TelemetryEvent> events) {
  return V2RecommendationTelemetryService(
    sink: (type, properties) async {
      events.add(_TelemetryEvent(type, properties));
    },
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

class _TelemetryEvent {
  const _TelemetryEvent(this.type, this.properties);

  final AnalyticsEventType type;
  final Map<String, dynamic> properties;
}
