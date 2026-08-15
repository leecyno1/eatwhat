import 'dart:convert';

import 'package:eatwhat_app/v2/core/services/v2_recommendation_shadow_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('直达和默认池按同一匿名数值结构分别聚合', () async {
    final store = V2RecommendationShadowStore(
      clock: () => DateTime(2026, 8, 5, 18),
    );

    await store.record(_properties(recallPath: 'direct'));
    await store.record(_properties(recallPath: 'defaultPool'));

    final snapshots = await store.readSnapshots();
    expect(snapshots, hasLength(2));
    expect(
      snapshots.map((snapshot) => snapshot.recallPath).toSet(),
      {'direct', 'defaultPool'},
    );
    final expectedKeys = snapshots.first.toJson().keys.toSet();
    for (final snapshot in snapshots) {
      expect(snapshot.toJson().keys, unorderedEquals(expectedKeys));
      expect(snapshot.observations, 1);
      expect(snapshot.candidateCountSum, 4);
      expect(snapshot.comparisonDepthSum, 3);
      expect(snapshot.top1ChangeCount, 1);
      expect(snapshot.topKOverlapWeightedSum, closeTo(2.25, 0.0001));
      expect(snapshot.rankDisplacementSum, closeTo(6, 0.0001));
      expect(snapshot.baselineDiversityWeightedSum, closeTo(2.4, 0.0001));
      expect(snapshot.experimentDiversityWeightedSum, closeTo(2.1, 0.0001));
    }
  });

  test('并发写入不会覆盖同一 cohort 的聚合', () async {
    final store = V2RecommendationShadowStore(
      clock: () => DateTime(2026, 8, 5),
    );

    await Future.wait([
      for (var index = 0; index < 80; index++)
        store.record(_properties(recallPath: 'direct')),
    ]);

    final snapshot = (await store.readSnapshots()).single;
    expect(snapshot.observations, 80);
    expect(snapshot.candidateCountSum, 320);
    expect(snapshot.top1ChangeCount, 80);
  });

  test('持久化内容不包含候选、菜名、排名或自由文本', () async {
    final store = V2RecommendationShadowStore(
      clock: () => DateTime(2026, 8, 5),
    );
    final properties = {
      ..._properties(recallPath: 'direct'),
      'candidate_ids': const ['dish_private_101'],
      'candidate_keys': const ['opaque_private_key'],
      'dish_name': '私密菜名',
      'diversity_keys': const ['海鲜|虾仁'],
      'baseline_ranking': const ['dish_private_101'],
      'freeform_requirement': '今晚不要辣',
    };

    await store.record(properties);

    final prefs = await SharedPreferences.getInstance();
    final storageKey = prefs.getKeys().singleWhere(
          (key) => key.startsWith('v2_recommendation_shadow_aggregates'),
        );
    final raw = prefs.getString(storageKey)!;
    for (final forbidden in [
      'dish_private_101',
      'opaque_private_key',
      '私密菜名',
      '海鲜',
      '虾仁',
      'baseline_ranking',
      'candidate_ids',
      'candidate_keys',
      'diversity_keys',
      'freeform_requirement',
      '今晚不要辣',
    ]) {
      expect(raw, isNot(contains(forbidden)));
    }

    await store.record({
      ..._properties(recallPath: 'direct'),
      'baseline_version': '今晚不要辣',
    });
    expect((await store.readSnapshots()).single.observations, 1);
  });

  test('自动清理过期数据，支持日期过滤和清空', () async {
    var now = DateTime(2026, 8);
    final store = V2RecommendationShadowStore(
      clock: () => now,
      retentionDays: 3,
    );
    await store.record(_properties(recallPath: 'direct'));
    now = DateTime(2026, 8, 3);
    await store.record(_properties(recallPath: 'defaultPool'));

    final recent = await store.readSnapshots(since: DateTime(2026, 8, 3));
    expect(recent, hasLength(1));
    expect(recent.single.recallPath, 'defaultPool');

    now = DateTime(2026, 8, 4);
    final retained = await store.readSnapshots();
    expect(retained, hasLength(1));
    expect(retained.single.day, DateTime(2026, 8, 3));

    await store.clear();
    expect(await store.readSnapshots(), isEmpty);
  });

  test('损坏数据和无有效比较的事件会被忽略并可恢复写入', () async {
    SharedPreferences.setMockInitialValues({
      'v2_recommendation_shadow_aggregates_v1': '{not-json',
    });
    final store = V2RecommendationShadowStore(
      clock: () => DateTime(2026, 8, 5),
    );

    expect(await store.readSnapshots(), isEmpty);
    await store.record({
      ..._properties(recallPath: 'direct'),
      'candidate_count': 0,
      'comparison_depth': 0,
    });
    expect(await store.readSnapshots(), isEmpty);

    await store.record(_properties(recallPath: 'direct'));
    expect((await store.readSnapshots()).single.observations, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(
      () => jsonDecode(
        prefs.getString('v2_recommendation_shadow_aggregates_v1')!,
      ),
      returnsNormally,
    );
  });
}

Map<String, dynamic> _properties({required String recallPath}) {
  return {
    'schema_version': 'v1',
    'baseline_version': 'local_rank_v2',
    'experiment_version': 'local_rank_v3_shadow',
    'recall_path': recallPath,
    'candidate_count': 4,
    'comparison_depth': 3,
    'top1_changed': true,
    'top_k_overlap': 0.75,
    'mean_absolute_rank_displacement': 1.5,
    'max_absolute_rank_displacement': 3,
    'baseline_diversity': 0.8,
    'experiment_diversity': 0.7,
    'diversity_delta': -0.1,
  };
}
