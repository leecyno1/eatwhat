import 'package:eatwhat_app/core/models/analytics_event.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_funnel_snapshot.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_funnel_insights.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_funnel_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('可直接从本地聚合模块读取算法报告', () async {
    final store = V2RecommendationFunnelStore(
      clock: () => DateTime(2026, 8, 4),
    );
    const properties = {
      'schema_version': 'v1',
      'algorithm_version': 'hybrid_v3',
      'primary_source': 'unified_db',
      'resolution_status': 'dbResolved',
    };
    await store.record(
      AnalyticsEventType.recommendationShown,
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

    final report = await V2RecommendationFunnelInsights(
      store: store,
    ).loadReport();

    expect(report.overall.exposures, 1);
    expect(report.overall.executionStartRate, 1);
    expect(report.overall.executionCompletionRate, 1);
    expect(report.algorithm('hybrid_v3'), isNotNull);
  });

  test('报告使用汇总计数计算加权比率并按关键维度分组', () async {
    DateTime? requestedSince;
    final insights = V2RecommendationFunnelInsights(
      snapshotLoader: (since) async {
        requestedSince = since;
        return [
          _snapshot(
            day: DateTime(2026, 8, 3),
            algorithmVersion: 'hybrid_v3',
            exposures: 1,
            executionStarts: 1,
            executionCompletions: 1,
          ),
          _snapshot(
            day: DateTime(2026, 8, 4),
            algorithmVersion: 'hybrid_v3',
            primarySource: 'local_fallback',
            resolutionStatus: 'localFallback',
            exposures: 9,
            executionStarts: 1,
          ),
          _snapshot(
            day: DateTime(2026, 8, 4),
            algorithmVersion: 'hybrid_v4',
            exposures: 10,
            executionStarts: 5,
            executionCompletions: 3,
          ),
        ];
      },
    );

    final since = DateTime(2026, 8, 3);
    final report = await insights.loadReport(since: since);

    expect(requestedSince, same(since));
    expect(report.periodStart, DateTime(2026, 8, 3));
    expect(report.periodEnd, DateTime(2026, 8, 4));
    expect(report.overall.exposures, 20);
    expect(report.byAlgorithm, hasLength(2));
    final hybridV3 = report.algorithm('hybrid_v3')!;
    expect(hybridV3.exposures, 10);
    expect(hybridV3.executionStarts, 2);
    expect(hybridV3.executionStartRate, 0.2);
    expect(hybridV3.executionCompletionRate, 0.5);
    expect(
      report.byPrimarySource.map((summary) => summary.label),
      containsAll(['unified_db', 'local_fallback']),
    );
    expect(
      report.byResolutionStatus.map((summary) => summary.label),
      containsAll(['dbResolved', 'localFallback']),
    );
  });

  test('算法缺失或样本不足时返回 insufficientData', () async {
    final insights = _insights([
      _snapshot(
        algorithmVersion: 'hybrid_v3',
        exposures: 30,
        executionStarts: 12,
        executionCompletions: 7,
      ),
      _snapshot(
        algorithmVersion: 'hybrid_v4',
        exposures: 8,
        executionStarts: 3,
        executionCompletions: 2,
      ),
    ]);

    final comparison = await insights.compareAlgorithms(
      baselineVersion: 'hybrid_v3',
      candidateVersion: 'hybrid_v4',
    );

    expect(
      comparison.verdict,
      RecommendationAlgorithmVerdict.insufficientData,
    );
    expect(
      comparison.reasons,
      containsAll([
        'candidate_exposures_below_minimum',
        'candidate_execution_starts_below_minimum',
      ]),
    );
  });

  test('候选算法触发执行和反馈护栏时判定 regression', () async {
    final insights = _insights([
      _snapshot(
        algorithmVersion: 'hybrid_v3',
        exposures: 100,
        rerolls: 10,
        negativeFeedback: 5,
        executionStarts: 50,
        executionCompletions: 35,
        executionDeferrals: 5,
      ),
      _snapshot(
        algorithmVersion: 'hybrid_v4',
        exposures: 100,
        rerolls: 25,
        negativeFeedback: 15,
        executionStarts: 40,
        executionCompletions: 20,
        executionDeferrals: 10,
      ),
    ]);

    final comparison = await insights.compareAlgorithms(
      baselineVersion: 'hybrid_v3',
      candidateVersion: 'hybrid_v4',
    );

    expect(comparison.verdict, RecommendationAlgorithmVerdict.regression);
    expect(
      comparison.reasons,
      containsAll([
        'execution_start_rate_drop',
        'execution_completion_rate_drop',
        'execution_deferral_rate_increase',
        'rerolls_per_exposure_increase',
        'negative_feedback_per_exposure_increase',
      ]),
    );
  });

  test('没有护栏回归且执行率显著提升时判定 promising', () async {
    final insights = _insights([
      _snapshot(
        algorithmVersion: 'hybrid_v3',
        exposures: 100,
        rerolls: 10,
        negativeFeedback: 5,
        executionStarts: 40,
        executionCompletions: 20,
      ),
      _snapshot(
        algorithmVersion: 'hybrid_v4',
        exposures: 100,
        rerolls: 9,
        negativeFeedback: 4,
        executionStarts: 50,
        executionCompletions: 30,
      ),
    ]);

    final comparison = await insights.compareAlgorithms(
      baselineVersion: 'hybrid_v3',
      candidateVersion: 'hybrid_v4',
    );

    expect(comparison.verdict, RecommendationAlgorithmVerdict.promising);
    expect(
      comparison.reasons,
      containsAll([
        'execution_start_rate_lift',
        'execution_completion_rate_lift',
      ]),
    );
  });

  test('无显著变化时保持 neutral 且拒绝同版本比较', () async {
    final insights = _insights([
      _snapshot(
        algorithmVersion: 'hybrid_v3',
        exposures: 100,
        executionStarts: 40,
        executionCompletions: 20,
      ),
      _snapshot(
        algorithmVersion: 'hybrid_v4',
        exposures: 100,
        executionStarts: 41,
        executionCompletions: 21,
      ),
    ]);

    final comparison = await insights.compareAlgorithms(
      baselineVersion: 'hybrid_v3',
      candidateVersion: 'hybrid_v4',
    );
    expect(comparison.verdict, RecommendationAlgorithmVerdict.neutral);
    expect(comparison.reasons, ['no_material_change']);

    await expectLater(
      insights.compareAlgorithms(
        baselineVersion: 'hybrid_v3',
        candidateVersion: 'hybrid_v3',
      ),
      throwsArgumentError,
    );
  });
}

V2RecommendationFunnelInsights _insights(
  List<RecommendationFunnelSnapshot> snapshots,
) {
  return V2RecommendationFunnelInsights(
    snapshotLoader: (_) async => snapshots,
  );
}

RecommendationFunnelSnapshot _snapshot({
  DateTime? day,
  required String algorithmVersion,
  String primarySource = 'unified_db',
  String resolutionStatus = 'dbResolved',
  int exposures = 0,
  int candidateSelections = 0,
  int confirmations = 0,
  int rerolls = 0,
  int favoriteAdds = 0,
  int favoriteRemovals = 0,
  int positiveFeedback = 0,
  int negativeFeedback = 0,
  int executionStarts = 0,
  int executionCompletions = 0,
  int executionDeferrals = 0,
}) {
  return RecommendationFunnelSnapshot(
    day: day ?? DateTime(2026, 8, 4),
    schemaVersion: 'v1',
    algorithmVersion: algorithmVersion,
    primarySource: primarySource,
    resolutionStatus: resolutionStatus,
    exposures: exposures,
    candidateSelections: candidateSelections,
    confirmations: confirmations,
    rerolls: rerolls,
    favoriteAdds: favoriteAdds,
    favoriteRemovals: favoriteRemovals,
    positiveFeedback: positiveFeedback,
    negativeFeedback: negativeFeedback,
    executionStarts: executionStarts,
    executionCompletions: executionCompletions,
    executionDeferrals: executionDeferrals,
  );
}
