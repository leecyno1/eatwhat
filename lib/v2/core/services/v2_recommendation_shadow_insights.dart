import 'package:eatwhat_app/v2/core/data/models/recommendation_shadow_snapshot.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_shadow_scoring_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_shadow_store.dart';

typedef RecommendationShadowSnapshotLoader
    = Future<List<RecommendationShadowSnapshot>> Function(DateTime? since);

enum RecommendationShadowCanaryVerdict {
  insufficientData,
  blocked,
  eligibleForCanary,
}

class RecommendationShadowGuardrails {
  const RecommendationShadowGuardrails({
    this.minimumObservationsPerRecallPath = 50,
    this.minimumTopKOverlap = 0.60,
    this.maximumMeanAbsoluteRankDisplacement = 2.5,
    this.maximumAbsoluteRankDisplacement = 10,
    this.maximumDiversityDrop = 0.05,
  })  : assert(minimumObservationsPerRecallPath > 0),
        assert(minimumTopKOverlap >= 0 && minimumTopKOverlap <= 1),
        assert(maximumMeanAbsoluteRankDisplacement >= 0),
        assert(maximumAbsoluteRankDisplacement >= 0),
        assert(maximumDiversityDrop >= 0 && maximumDiversityDrop <= 1);

  final int minimumObservationsPerRecallPath;
  final double minimumTopKOverlap;
  final double maximumMeanAbsoluteRankDisplacement;
  final int maximumAbsoluteRankDisplacement;
  final double maximumDiversityDrop;
}

class RecommendationShadowPathSummary {
  const RecommendationShadowPathSummary({
    required this.recallPath,
    required this.observations,
    required this.candidateCountSum,
    required this.comparisonDepthSum,
    required this.top1ChangeCount,
    required this.topKOverlapWeightedSum,
    required this.rankDisplacementSum,
    required this.maxAbsoluteRankDisplacement,
    required this.baselineDiversityWeightedSum,
    required this.experimentDiversityWeightedSum,
  });

  factory RecommendationShadowPathSummary.empty(
    V2RecommendationRecallPath recallPath,
  ) {
    return RecommendationShadowPathSummary(
      recallPath: recallPath,
      observations: 0,
      candidateCountSum: 0,
      comparisonDepthSum: 0,
      top1ChangeCount: 0,
      topKOverlapWeightedSum: 0,
      rankDisplacementSum: 0,
      maxAbsoluteRankDisplacement: 0,
      baselineDiversityWeightedSum: 0,
      experimentDiversityWeightedSum: 0,
    );
  }

  final V2RecommendationRecallPath recallPath;
  final int observations;
  final int candidateCountSum;
  final int comparisonDepthSum;
  final int top1ChangeCount;
  final double topKOverlapWeightedSum;
  final double rankDisplacementSum;
  final int maxAbsoluteRankDisplacement;
  final double baselineDiversityWeightedSum;
  final double experimentDiversityWeightedSum;

  double get averageCandidateCount => _ratio(candidateCountSum, observations);
  double get top1ChangeRate => _ratio(top1ChangeCount, observations);
  double get meanTopKOverlap =>
      comparisonDepthSum == 0 ? 1 : topKOverlapWeightedSum / comparisonDepthSum;
  double get meanAbsoluteRankDisplacement =>
      _ratio(rankDisplacementSum, candidateCountSum);
  double get meanBaselineDiversity => comparisonDepthSum == 0
      ? 0
      : baselineDiversityWeightedSum / comparisonDepthSum;
  double get meanExperimentDiversity => comparisonDepthSum == 0
      ? 0
      : experimentDiversityWeightedSum / comparisonDepthSum;
  double get diversityDelta => meanExperimentDiversity - meanBaselineDiversity;

  static RecommendationShadowPathSummary aggregate(
    V2RecommendationRecallPath recallPath,
    Iterable<RecommendationShadowSnapshot> snapshots,
  ) {
    var observations = 0;
    var candidateCountSum = 0;
    var comparisonDepthSum = 0;
    var top1ChangeCount = 0;
    var topKOverlapWeightedSum = 0.0;
    var rankDisplacementSum = 0.0;
    var maxAbsoluteRankDisplacement = 0;
    var baselineDiversityWeightedSum = 0.0;
    var experimentDiversityWeightedSum = 0.0;
    for (final snapshot in snapshots) {
      observations += snapshot.observations;
      candidateCountSum += snapshot.candidateCountSum;
      comparisonDepthSum += snapshot.comparisonDepthSum;
      top1ChangeCount += snapshot.top1ChangeCount;
      topKOverlapWeightedSum += snapshot.topKOverlapWeightedSum;
      rankDisplacementSum += snapshot.rankDisplacementSum;
      if (snapshot.maxAbsoluteRankDisplacement > maxAbsoluteRankDisplacement) {
        maxAbsoluteRankDisplacement = snapshot.maxAbsoluteRankDisplacement;
      }
      baselineDiversityWeightedSum += snapshot.baselineDiversityWeightedSum;
      experimentDiversityWeightedSum += snapshot.experimentDiversityWeightedSum;
    }
    return RecommendationShadowPathSummary(
      recallPath: recallPath,
      observations: observations,
      candidateCountSum: candidateCountSum,
      comparisonDepthSum: comparisonDepthSum,
      top1ChangeCount: top1ChangeCount,
      topKOverlapWeightedSum: topKOverlapWeightedSum,
      rankDisplacementSum: rankDisplacementSum,
      maxAbsoluteRankDisplacement: maxAbsoluteRankDisplacement,
      baselineDiversityWeightedSum: baselineDiversityWeightedSum,
      experimentDiversityWeightedSum: experimentDiversityWeightedSum,
    );
  }

  static double _ratio(num numerator, int denominator) {
    if (denominator <= 0) return 0;
    return numerator / denominator;
  }
}

class RecommendationShadowCanaryAssessment {
  RecommendationShadowCanaryAssessment({
    required this.baselineVersion,
    required this.experimentVersion,
    required this.verdict,
    required Map<V2RecommendationRecallPath, RecommendationShadowPathSummary>
        byRecallPath,
    required List<String> reasons,
  })  : byRecallPath = Map.unmodifiable(byRecallPath),
        reasons = List.unmodifiable(reasons);

  final String baselineVersion;
  final String experimentVersion;
  final RecommendationShadowCanaryVerdict verdict;
  final Map<V2RecommendationRecallPath, RecommendationShadowPathSummary>
      byRecallPath;
  final List<String> reasons;

  bool get eligibleForControlledCanary =>
      verdict == RecommendationShadowCanaryVerdict.eligibleForCanary;

  /// Shadow comparisons never observe user outcomes and cannot promote a ranker.
  bool get authorizesProductionPromotion => false;
}

class V2RecommendationShadowInsights {
  V2RecommendationShadowInsights({
    V2RecommendationShadowStore? store,
    RecommendationShadowSnapshotLoader? snapshotLoader,
    this.guardrails = const RecommendationShadowGuardrails(),
  }) : _snapshotLoader = snapshotLoader ??
            ((since) => (store ?? V2RecommendationShadowStore.instance)
                .readSnapshots(since: since));

  static final V2RecommendationShadowInsights instance =
      V2RecommendationShadowInsights();

  final RecommendationShadowSnapshotLoader _snapshotLoader;
  final RecommendationShadowGuardrails guardrails;

  Future<RecommendationShadowCanaryAssessment> evaluateCanaryEligibility({
    required String baselineVersion,
    required String experimentVersion,
    DateTime? since,
    String schemaVersion = V2RecommendationShadowStore.schemaVersion,
  }) async {
    if (baselineVersion == experimentVersion) {
      throw ArgumentError.value(
        experimentVersion,
        'experimentVersion',
        'Experiment and baseline versions must be different.',
      );
    }
    final snapshots = (await _snapshotLoader(since))
        .where(
          (snapshot) =>
              snapshot.schemaVersion == schemaVersion &&
              snapshot.baselineVersion == baselineVersion &&
              snapshot.experimentVersion == experimentVersion,
        )
        .toList();
    final summaries = {
      for (final path in V2RecommendationRecallPath.values)
        path: RecommendationShadowPathSummary.aggregate(
          path,
          snapshots.where((snapshot) => snapshot.recallPath == path.name),
        ),
    };

    final sampleReasons = <String>[
      for (final entry in summaries.entries)
        if (entry.value.observations <
            guardrails.minimumObservationsPerRecallPath)
          '${_pathKey(entry.key)}_observations_below_minimum',
    ];
    if (sampleReasons.isNotEmpty) {
      return RecommendationShadowCanaryAssessment(
        baselineVersion: baselineVersion,
        experimentVersion: experimentVersion,
        verdict: RecommendationShadowCanaryVerdict.insufficientData,
        byRecallPath: summaries,
        reasons: sampleReasons,
      );
    }

    final blockerReasons = <String>[
      for (final entry in summaries.entries) ...[
        if (entry.value.meanTopKOverlap < guardrails.minimumTopKOverlap)
          '${_pathKey(entry.key)}_top_k_overlap_below_minimum',
        if (entry.value.meanAbsoluteRankDisplacement >
            guardrails.maximumMeanAbsoluteRankDisplacement)
          '${_pathKey(entry.key)}_mean_rank_displacement_above_maximum',
        if (entry.value.maxAbsoluteRankDisplacement >
            guardrails.maximumAbsoluteRankDisplacement)
          '${_pathKey(entry.key)}_max_rank_displacement_above_maximum',
        if (entry.value.diversityDelta < -guardrails.maximumDiversityDrop)
          '${_pathKey(entry.key)}_diversity_regression',
      ],
    ];
    return RecommendationShadowCanaryAssessment(
      baselineVersion: baselineVersion,
      experimentVersion: experimentVersion,
      verdict: blockerReasons.isEmpty
          ? RecommendationShadowCanaryVerdict.eligibleForCanary
          : RecommendationShadowCanaryVerdict.blocked,
      byRecallPath: summaries,
      reasons: blockerReasons.isEmpty
          ? const ['shadow_guardrails_passed_for_all_recall_paths']
          : blockerReasons,
    );
  }

  static String _pathKey(V2RecommendationRecallPath path) {
    return path == V2RecommendationRecallPath.defaultPool
        ? 'default_pool'
        : 'direct';
  }
}
