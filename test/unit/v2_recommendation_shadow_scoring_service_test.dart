import 'dart:convert';

import 'package:eatwhat_app/v2/core/services/v2_recommendation_shadow_scoring_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_shadow_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/mock_analytics_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('稳定并列规则让同一批候选始终产生相同摘要', () {
    final service = V2RecommendationShadowScoringService(
      experimentalScorer: (_) => 1,
      reporter: (_) {},
      topK: 2,
    );
    final candidates = [
      _candidate(key: 'opaque_a', position: 0, diversityKey: 'tag_a|food_a'),
      _candidate(key: 'opaque_b', position: 1, diversityKey: 'tag_b|food_b'),
      _candidate(key: 'opaque_c', position: 2, diversityKey: 'tag_c|food_c'),
    ];

    final first = service.evaluate(
      candidates: candidates.reversed.toList(),
      recallPath: V2RecommendationRecallPath.direct,
    );
    final second = service.evaluate(
      candidates: candidates,
      recallPath: V2RecommendationRecallPath.direct,
    );

    expect(first.toProperties(), second.toProperties());
    expect(first.top1Changed, isFalse);
    expect(first.topKOverlap, 1);
    expect(first.meanAbsoluteRankDisplacement, 0);
  });

  test('默认实验权重能识别生产排序中的高质量候选', () {
    final service = V2RecommendationShadowScoringService(
      reporter: (_) {},
      topK: 2,
    );

    final summary = service.evaluate(
      candidates: [
        _candidate(
          key: 'opaque_a',
          position: 0,
          diversityKey: 'a',
          baselineScore: 70,
          rating: 3,
          popularity: 20,
        ),
        _candidate(
          key: 'opaque_b',
          position: 1,
          diversityKey: 'b',
          baselineScore: 65,
          rating: 5,
          popularity: 90,
        ),
      ],
      recallPath: V2RecommendationRecallPath.direct,
    );

    expect(summary.top1Changed, isTrue);
    expect(summary.meanAbsoluteRankDisplacement, 1);
  });

  test('匿名报告只包含聚合差异，不泄露候选或请求内容', () async {
    V2RecommendationShadowSummary? reported;
    final service = V2RecommendationShadowScoringService(
      experimentalScorer: (candidate) => candidate.baselinePosition * 1.0,
      reporter: (summary) => reported = summary,
      topK: 2,
    );

    await service.observe(
      candidates: [
        _candidate(
          key: 'dish_101',
          position: 0,
          diversityKey: '海鲜|虾仁',
        ),
        _candidate(
          key: 'dish_102',
          position: 1,
          diversityKey: '素菜|豆腐',
        ),
        _candidate(
          key: 'dish_103',
          position: 2,
          diversityKey: '汤羹|番茄',
        ),
      ],
      recallPath: V2RecommendationRecallPath.defaultPool,
    );

    final properties = reported!.toProperties();
    expect(properties.keys.toSet(), {
      'schema_version',
      'baseline_version',
      'experiment_version',
      'recall_path',
      'candidate_count',
      'comparison_depth',
      'top1_changed',
      'top_k_overlap',
      'mean_absolute_rank_displacement',
      'max_absolute_rank_displacement',
      'baseline_diversity',
      'experiment_diversity',
      'diversity_delta',
    });
    final encoded = jsonEncode(properties);
    for (final forbidden in [
      'dish_101',
      'dish_102',
      'dish_103',
      '海鲜',
      '虾仁',
      '素菜',
      '豆腐',
      '今晚不要辣',
      'candidate_id',
      'recipe_id',
      'dish_name',
      'freeform',
    ]) {
      expect(encoded, isNot(contains(forbidden)));
    }
    expect(reported!.top1Changed, isTrue);
    expect(reported!.topKOverlap, 0.5);
  });

  test('默认报告通道不关联用户、会话或页面', () async {
    final analytics = MockAnalyticsService()
      ..setUserId('user_123')
      ..trackPageEnter('result_page');
    final service = V2RecommendationShadowScoringService(
      analyticsService: analytics,
    );

    await service.observe(
      candidates: [
        _candidate(key: 'opaque_a', position: 0, diversityKey: 'a'),
      ],
      recallPath: V2RecommendationRecallPath.direct,
    );

    expect(analytics.recordedEvents, hasLength(1));
    final event = analytics.recordedEvents.single;
    expect(event.userId, isNull);
    expect(event.sessionId, isNull);
    expect(event.pageName, isNull);
    expect(event.properties, isNot(contains('_session_id')));
  });

  test('评分和报告异常均被影子服务吸收', () async {
    final services = [
      V2RecommendationShadowScoringService(
        experimentalScorer: (_) => throw StateError('bad score'),
        reporter: (_) {},
      ),
      V2RecommendationShadowScoringService(
        reporter: (_) async => throw StateError('sink unavailable'),
      ),
    ];

    for (final service in services) {
      await expectLater(
        service.observe(
          candidates: [
            _candidate(key: 'opaque_a', position: 0, diversityKey: 'a'),
          ],
          recallPath: V2RecommendationRecallPath.direct,
        ),
        completes,
      );
    }
  });

  test('默认报告双通道独立失败且均不影响影子观察', () async {
    final workingAnalytics = MockAnalyticsService();
    final workingStore = V2RecommendationShadowStore(
      clock: () => DateTime(2026, 8, 5),
    );
    final services = [
      V2RecommendationShadowScoringService(
        analyticsService: _FailingAnalyticsService(),
        shadowStore: workingStore,
      ),
      V2RecommendationShadowScoringService(
        analyticsService: workingAnalytics,
        shadowStore: _FailingShadowStore(),
      ),
    ];

    for (final service in services) {
      await expectLater(
        service.observe(
          candidates: [
            _candidate(key: 'opaque_a', position: 0, diversityKey: 'a'),
          ],
          recallPath: V2RecommendationRecallPath.direct,
        ),
        completes,
      );
    }

    expect((await workingStore.readSnapshots()).single.observations, 1);
    expect(workingAnalytics.recordedEvents, hasLength(1));
    expect(workingAnalytics.recordedEvents.single.userId, isNull);
  });

  test('非连续生产名次不会生成可能误导的摘要', () {
    final service = V2RecommendationShadowScoringService(
      reporter: (_) {},
    );

    expect(
      () => service.evaluate(
        candidates: [
          _candidate(key: 'opaque_a', position: 0, diversityKey: 'a'),
          _candidate(key: 'opaque_b', position: 2, diversityKey: 'b'),
        ],
        recallPath: V2RecommendationRecallPath.direct,
      ),
      throwsArgumentError,
    );
  });
}

class _FailingAnalyticsService extends MockAnalyticsService {
  @override
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? properties,
    bool recordMetrics = true,
    bool anonymous = false,
  }) async {
    throw StateError('analytics unavailable');
  }
}

class _FailingShadowStore extends V2RecommendationShadowStore {
  @override
  Future<void> record(Map<String, dynamic> properties) async {
    throw StateError('local persistence unavailable');
  }
}

V2RecommendationShadowCandidate _candidate({
  required String key,
  required int position,
  required String diversityKey,
  double? baselineScore,
  double rating = 4.5,
  double popularity = 50,
}) {
  return V2RecommendationShadowCandidate(
    candidateKey: key,
    baselinePosition: position,
    baselineScore: baselineScore ?? 100 - position * 10,
    rating: rating,
    popularity: popularity,
    preferenceBonus: 0,
    historyBonus: 0,
    favoriteBonus: 0,
    negativePenalty: 0,
    recentPenalty: 0,
    diversityKey: diversityKey,
  );
}
