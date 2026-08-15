import 'package:eatwhat_app/v2/core/data/models/recommendation_shadow_snapshot.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_shadow_insights.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_shadow_scoring_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const guardrails = RecommendationShadowGuardrails(
    minimumObservationsPerRecallPath: 10,
    maximumMeanAbsoluteRankDisplacement: 2,
    maximumAbsoluteRankDisplacement: 5,
  );

  test('任一路径样本不足时不会获得灰度资格', () async {
    final insights = V2RecommendationShadowInsights(
      guardrails: guardrails,
      snapshotLoader: (_) async => [
        _snapshot(path: V2RecommendationRecallPath.direct, observations: 10),
      ],
    );

    final assessment = await insights.evaluateCanaryEligibility(
      baselineVersion: 'baseline_v2',
      experimentVersion: 'experiment_v3',
    );

    expect(
      assessment.verdict,
      RecommendationShadowCanaryVerdict.insufficientData,
    );
    expect(assessment.reasons,
        contains('default_pool_observations_below_minimum'));
    expect(assessment.eligibleForControlledCanary, isFalse);
    expect(assessment.authorizesProductionPromotion, isFalse);
  });

  test('任一路径越过排序或多样性护栏时阻断灰度', () async {
    final insights = V2RecommendationShadowInsights(
      guardrails: guardrails,
      snapshotLoader: (_) async => [
        _snapshot(path: V2RecommendationRecallPath.direct, observations: 10),
        _snapshot(
          path: V2RecommendationRecallPath.defaultPool,
          observations: 10,
          meanTopKOverlap: 0.4,
          meanDisplacement: 2.5,
          maxDisplacement: 6,
          baselineDiversity: 0.8,
          experimentDiversity: 0.6,
        ),
      ],
    );

    final assessment = await insights.evaluateCanaryEligibility(
      baselineVersion: 'baseline_v2',
      experimentVersion: 'experiment_v3',
    );

    expect(assessment.verdict, RecommendationShadowCanaryVerdict.blocked);
    expect(
        assessment.reasons,
        containsAll([
          'default_pool_top_k_overlap_below_minimum',
          'default_pool_mean_rank_displacement_above_maximum',
          'default_pool_max_rank_displacement_above_maximum',
          'default_pool_diversity_regression',
        ]));
    expect(assessment.authorizesProductionPromotion, isFalse);
  });

  test('两条路径均通过时只授予受控灰度资格', () async {
    final snapshots = [
      _snapshot(path: V2RecommendationRecallPath.direct, observations: 6),
      _snapshot(path: V2RecommendationRecallPath.direct, observations: 4),
      _snapshot(path: V2RecommendationRecallPath.defaultPool, observations: 10),
      _snapshot(
        path: V2RecommendationRecallPath.direct,
        observations: 100,
        baselineVersion: 'other_baseline',
      ),
    ];
    final insights = V2RecommendationShadowInsights(
      guardrails: guardrails,
      snapshotLoader: (_) async => snapshots,
    );

    final assessment = await insights.evaluateCanaryEligibility(
      baselineVersion: 'baseline_v2',
      experimentVersion: 'experiment_v3',
    );

    expect(
      assessment.verdict,
      RecommendationShadowCanaryVerdict.eligibleForCanary,
    );
    expect(assessment.eligibleForControlledCanary, isTrue);
    expect(assessment.authorizesProductionPromotion, isFalse);
    expect(
      assessment.byRecallPath[V2RecommendationRecallPath.direct]!.observations,
      10,
    );
    expect(
      assessment
          .byRecallPath[V2RecommendationRecallPath.defaultPool]!.observations,
      10,
    );
    expect(snapshots, hasLength(4));
  });

  test('跨快照指标按候选数和比较深度加权而非二次平均', () {
    final summary = RecommendationShadowPathSummary.aggregate(
      V2RecommendationRecallPath.direct,
      [
        RecommendationShadowSnapshot(
          day: DateTime(2026, 8, 4),
          schemaVersion: 'v1',
          baselineVersion: 'baseline_v2',
          experimentVersion: 'experiment_v3',
          recallPath: 'direct',
          observations: 1,
          candidateCountSum: 1,
          comparisonDepthSum: 1,
          top1ChangeCount: 1,
          rankDisplacementSum: 4,
          maxAbsoluteRankDisplacement: 4,
          baselineDiversityWeightedSum: 1,
        ),
        RecommendationShadowSnapshot(
          day: DateTime(2026, 8, 5),
          schemaVersion: 'v1',
          baselineVersion: 'baseline_v2',
          experimentVersion: 'experiment_v3',
          recallPath: 'direct',
          observations: 1,
          candidateCountSum: 9,
          comparisonDepthSum: 5,
          topKOverlapWeightedSum: 5,
          baselineDiversityWeightedSum: 5,
          experimentDiversityWeightedSum: 5,
        ),
      ],
    );

    expect(summary.top1ChangeRate, 0.5);
    expect(summary.meanTopKOverlap, closeTo(5 / 6, 0.0001));
    expect(summary.meanAbsoluteRankDisplacement, 0.4);
    expect(summary.meanBaselineDiversity, 1);
    expect(summary.meanExperimentDiversity, closeTo(5 / 6, 0.0001));
    expect(summary.maxAbsoluteRankDisplacement, 4);
  });
}

RecommendationShadowSnapshot _snapshot({
  required V2RecommendationRecallPath path,
  required int observations,
  String baselineVersion = 'baseline_v2',
  String experimentVersion = 'experiment_v3',
  double meanTopKOverlap = 0.8,
  double meanDisplacement = 1,
  int maxDisplacement = 3,
  double baselineDiversity = 0.7,
  double experimentDiversity = 0.72,
}) {
  const candidateCount = 5;
  const comparisonDepth = 5;
  return RecommendationShadowSnapshot(
    day: DateTime(2026, 8, 5),
    schemaVersion: 'v1',
    baselineVersion: baselineVersion,
    experimentVersion: experimentVersion,
    recallPath: path.name,
    observations: observations,
    candidateCountSum: observations * candidateCount,
    comparisonDepthSum: observations * comparisonDepth,
    top1ChangeCount: observations ~/ 2,
    topKOverlapWeightedSum: observations * comparisonDepth * meanTopKOverlap,
    rankDisplacementSum: observations * candidateCount * meanDisplacement,
    maxAbsoluteRankDisplacement: maxDisplacement,
    baselineDiversityWeightedSum:
        observations * comparisonDepth * baselineDiversity,
    experimentDiversityWeightedSum:
        observations * comparisonDepth * experimentDiversity,
  );
}
