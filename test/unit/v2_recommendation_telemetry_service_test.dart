import 'package:eatwhat_app/core/models/analytics_event.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_telemetry_context.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_funnel_store.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_telemetry_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/mock_analytics_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('推荐曝光包含版本化漏斗上下文且不记录具体约束内容', () async {
    final events = <_RecordedTelemetryEvent>[];
    final service = _service(events);
    final context = _context(
      recommendationId: service.createRecommendationId(
        algorithmVersion: 'hybrid_v3_0',
      ),
    );

    await service.recordExposure(
      context: context,
      recipeIds: const ['101', '102', '103'],
    );

    expect(events, hasLength(1));
    final event = events.single;
    expect(event.type, AnalyticsEventType.recommendationShown);
    expect(event.properties['schema_version'], 'v1');
    expect(event.properties['algorithm_version'], 'hybrid_v3_0');
    expect(event.properties['candidate_ids'], ['101', '102', '103']);
    expect(event.properties['applied_constraint_count'], 2);
    expect(event.properties, isNot(contains('applied_constraints')));
    expect(event.properties, isNot(contains('freeform_requirement')));
  });

  test('选择、换菜、收藏和执行事件共享同一个推荐批次 ID', () async {
    final events = <_RecordedTelemetryEvent>[];
    final service = _service(events);
    final context = _context(recommendationId: 'rec_shared');

    await service.recordSelection(
      context: context,
      recipeId: '101',
      position: 0,
      action: 'confirm',
    );
    await service.recordReroll(
      context: context,
      fromRecipeId: '101',
      toRecipeId: '102',
      fromPosition: 0,
      toPosition: 1,
    );
    await service.recordFavoriteToggled(
      context: context,
      recipeId: '102',
      position: 1,
      isFavorited: true,
    );
    await service.recordExecutionStarted(
      context: context,
      recipeId: '102',
      position: 1,
      executionPath: 'cook',
    );
    await service.recordExecutionCompleted(
      context: context,
      recipeId: '102',
      position: 1,
      executionPath: 'cook',
    );

    expect(events, hasLength(5));
    expect(
      events.map((event) => event.properties['recommendation_id']).toSet(),
      {'rec_shared'},
    );
    expect(events.map((event) => event.type), [
      AnalyticsEventType.recommendationClicked,
      AnalyticsEventType.recommendationSkipped,
      AnalyticsEventType.foodFavoriteToggled,
      AnalyticsEventType.recommendationExecutionStarted,
      AnalyticsEventType.recommendationExecutionCompleted,
    ]);
  });

  test('遥测写入失败不会打断产品流程', () async {
    final service = V2RecommendationTelemetryService(
      sink: (_, __) async => throw StateError('analytics unavailable'),
    );

    await expectLater(
      service.recordExposure(
        context: _context(recommendationId: 'rec_safe'),
        recipeIds: const ['101'],
      ),
      completes,
    );
  });

  test('默认 sink 同时写入分析适配器和本地聚合快照', () async {
    final analytics = MockAnalyticsService();
    final funnelStore = V2RecommendationFunnelStore(
      clock: () => DateTime(2026, 8, 4),
    );
    final service = V2RecommendationTelemetryService(
      analyticsService: analytics,
      funnelStore: funnelStore,
    );

    await service.recordExposure(
      context: _context(recommendationId: 'rec_default_sink'),
      recipeIds: const ['101', '102'],
    );

    expect(analytics.recordedEvents, hasLength(1));
    expect(
      analytics.recordedEvents.single.type,
      AnalyticsEventType.recommendationShown,
    );
    final snapshot = (await funnelStore.readSnapshots()).single;
    expect(snapshot.exposures, 1);
    expect(snapshot.algorithmVersion, 'hybrid_v3_0');
  });
}

V2RecommendationTelemetryService _service(
  List<_RecordedTelemetryEvent> events,
) {
  return V2RecommendationTelemetryService(
    clock: () => DateTime.utc(2026, 8, 4),
    sink: (type, properties) async {
      events.add(_RecordedTelemetryEvent(type, properties));
    },
  );
}

RecommendationTelemetryContext _context({
  required String recommendationId,
}) {
  return RecommendationTelemetryContext(
    recommendationId: recommendationId,
    algorithmVersion: 'hybrid_v3_0',
    primarySource: 'unified_db',
    resolutionStatus: RecommendationResolutionStatus.dbResolved,
    recalledCount: 12,
    finalCount: 5,
    latencyMs: 180,
    diversityScore: 0.8,
    appliedConstraintCount: 2,
  );
}

class _RecordedTelemetryEvent {
  const _RecordedTelemetryEvent(this.type, this.properties);

  final AnalyticsEventType type;
  final Map<String, dynamic> properties;
}
