import 'package:eatwhat_app/core/models/analytics_event.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_funnel_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('按日级 cohort 聚合漏斗且不持久化原始标识', () async {
    final store = V2RecommendationFunnelStore(
      clock: () => DateTime(2026, 8, 4, 18),
    );
    final properties = _properties(
      recommendationId: 'rec_private_1',
      recipeId: 'dish_private_1',
    );

    await store.record(AnalyticsEventType.recommendationShown, properties);
    await store.record(AnalyticsEventType.recommendationShown, properties);
    await store.record(
      AnalyticsEventType.recommendationClicked,
      {...properties, 'action': 'candidate_tap'},
    );
    await store.record(
      AnalyticsEventType.recommendationClicked,
      {...properties, 'action': 'confirm'},
    );
    await store.record(
      AnalyticsEventType.recommendationClicked,
      {...properties, 'action': 'reroll'},
    );
    await store.record(AnalyticsEventType.recommendationSkipped, properties);
    await store.record(
      AnalyticsEventType.foodFavoriteToggled,
      {...properties, 'is_favorited': true},
    );
    await store.record(
      AnalyticsEventType.foodFavoriteToggled,
      {...properties, 'is_favorited': false},
    );
    await store.record(
      AnalyticsEventType.tasteFeedbackGiven,
      {...properties, 'is_positive': true},
    );
    await store.record(
      AnalyticsEventType.tasteFeedbackGiven,
      {...properties, 'is_positive': false},
    );
    await store.record(
      AnalyticsEventType.recommendationExecutionStarted,
      properties,
    );
    await store.record(
      AnalyticsEventType.recommendationExecutionStarted,
      properties,
    );
    await store.record(
      AnalyticsEventType.recommendationExecutionCompleted,
      properties,
    );
    await store.record(
      AnalyticsEventType.recommendationExecutionDeferred,
      properties,
    );

    final snapshots = await store.readSnapshots();
    expect(snapshots, hasLength(1));
    final snapshot = snapshots.single;
    expect(snapshot.day, DateTime(2026, 8, 4));
    expect(snapshot.algorithmVersion, 'hybrid_v3_0');
    expect(snapshot.primarySource, 'unified_db');
    expect(snapshot.resolutionStatus, 'dbResolved');
    expect(snapshot.exposures, 2);
    expect(snapshot.candidateSelections, 1);
    expect(snapshot.confirmations, 1);
    expect(snapshot.rerolls, 1);
    expect(snapshot.favoriteAdds, 1);
    expect(snapshot.favoriteRemovals, 1);
    expect(snapshot.positiveFeedback, 1);
    expect(snapshot.negativeFeedback, 1);
    expect(snapshot.executionStarts, 2);
    expect(snapshot.executionCompletions, 1);
    expect(snapshot.executionDeferrals, 1);
    expect(snapshot.selectionActionsPerExposure, 1);
    expect(snapshot.rerollsPerExposure, 0.5);
    expect(snapshot.executionStartRate, 1);
    expect(snapshot.executionCompletionRate, 0.5);
    expect(snapshot.executionDeferralRate, 0.5);

    final prefs = await SharedPreferences.getInstance();
    final storageKey = prefs.getKeys().singleWhere(
          (key) => key.startsWith('v2_recommendation_funnel_aggregates'),
        );
    final raw = prefs.getString(storageKey)!;
    expect(raw, isNot(contains('rec_private_1')));
    expect(raw, isNot(contains('dish_private_1')));
    expect(raw, isNot(contains('candidate_ids')));
    expect(raw, isNot(contains('freeform_requirement')));
  });

  test('并发事件不会覆盖同一 cohort 的计数', () async {
    final store = V2RecommendationFunnelStore(
      clock: () => DateTime(2026, 8, 4),
    );
    final properties = _properties();

    await Future.wait([
      for (var index = 0; index < 80; index++)
        store.record(
          AnalyticsEventType.recommendationClicked,
          {...properties, 'action': 'candidate_tap'},
        ),
    ]);

    final snapshot = (await store.readSnapshots()).single;
    expect(snapshot.candidateSelections, 80);
  });

  test('不同算法 cohort 分开聚合并自动清理过期快照', () async {
    var now = DateTime(2026, 8);
    final store = V2RecommendationFunnelStore(
      clock: () => now,
      retentionDays: 3,
    );

    await store.record(
      AnalyticsEventType.recommendationShown,
      _properties(algorithmVersion: 'hybrid_v2'),
    );
    await store.record(
      AnalyticsEventType.recommendationShown,
      _properties(algorithmVersion: 'hybrid_v3'),
    );
    expect(await store.readSnapshots(), hasLength(2));

    now = DateTime(2026, 8, 4);
    await store.record(
      AnalyticsEventType.recommendationShown,
      _properties(algorithmVersion: 'hybrid_v4'),
    );

    final snapshots = await store.readSnapshots();
    expect(snapshots, hasLength(1));
    expect(snapshots.single.algorithmVersion, 'hybrid_v4');
    expect(snapshots.single.day, DateTime(2026, 8, 4));
  });

  test('支持按日期读取快照并清空本地聚合', () async {
    var now = DateTime(2026, 8, 3);
    final store = V2RecommendationFunnelStore(
      clock: () => now,
    );

    await store.record(
      AnalyticsEventType.recommendationShown,
      _properties(algorithmVersion: 'hybrid_v3'),
    );
    now = DateTime(2026, 8, 4);
    await store.record(
      AnalyticsEventType.recommendationShown,
      _properties(algorithmVersion: 'hybrid_v4'),
    );

    final recent = await store.readSnapshots(since: DateTime(2026, 8, 4));
    expect(recent, hasLength(1));
    expect(recent.single.algorithmVersion, 'hybrid_v4');

    await store.clear();
    expect(await store.readSnapshots(), isEmpty);
  });

  test('忽略无 cohort 上下文或非推荐漏斗事件', () async {
    final store = V2RecommendationFunnelStore(
      clock: () => DateTime(2026, 8, 4),
    );

    await store.record(
      AnalyticsEventType.recommendationShown,
      const {'recommendation_id': 'rec_without_context'},
    );
    await store.record(
      AnalyticsEventType.appLaunch,
      _properties(),
    );
    await store.record(
      AnalyticsEventType.recommendationClicked,
      _properties(),
    );
    await store.record(
      AnalyticsEventType.foodFavoriteToggled,
      _properties(),
    );

    expect(await store.readSnapshots(), isEmpty);
  });
}

Map<String, dynamic> _properties({
  String algorithmVersion = 'hybrid_v3_0',
  String recommendationId = 'rec_1',
  String recipeId = 'dish_1',
}) {
  return {
    'schema_version': 'v1',
    'algorithm_version': algorithmVersion,
    'primary_source': 'unified_db',
    'resolution_status': 'dbResolved',
    'recommendation_id': recommendationId,
    'recipe_id': recipeId,
    'candidate_ids': [recipeId, 'dish_2'],
    'freeform_requirement': '今晚想吃热一点',
  };
}
