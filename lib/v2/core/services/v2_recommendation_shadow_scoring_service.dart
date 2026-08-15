import 'dart:async';

import 'package:eatwhat_app/core/models/analytics_event.dart';
import 'package:eatwhat_app/core/services/analytics_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_experimental_ranker.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_shadow_store.dart';

export 'package:eatwhat_app/v2/core/services/v2_recommendation_experimental_ranker.dart'
    show
        V2RecommendationExperimentalRanker,
        V2RecommendationExperimentalScorer,
        V2RecommendationShadowCandidate;

enum V2RecommendationRecallPath {
  direct,
  defaultPool,
}

typedef V2RecommendationShadowReporter = FutureOr<void> Function(
  V2RecommendationShadowSummary summary,
);

class V2RecommendationShadowSummary {
  const V2RecommendationShadowSummary({
    required this.baselineVersion,
    required this.experimentVersion,
    required this.recallPath,
    required this.candidateCount,
    required this.comparisonDepth,
    required this.top1Changed,
    required this.topKOverlap,
    required this.meanAbsoluteRankDisplacement,
    required this.maxAbsoluteRankDisplacement,
    required this.baselineDiversity,
    required this.experimentDiversity,
  });

  final String baselineVersion;
  final String experimentVersion;
  final V2RecommendationRecallPath recallPath;
  final int candidateCount;
  final int comparisonDepth;
  final bool top1Changed;
  final double topKOverlap;
  final double meanAbsoluteRankDisplacement;
  final int maxAbsoluteRankDisplacement;
  final double baselineDiversity;
  final double experimentDiversity;

  double get diversityDelta => experimentDiversity - baselineDiversity;

  /// Deliberately excludes candidate keys, recipe data, and request text.
  Map<String, dynamic> toProperties() {
    return {
      'schema_version': V2RecommendationShadowScoringService.schemaVersion,
      'baseline_version': baselineVersion,
      'experiment_version': experimentVersion,
      'recall_path': recallPath.name,
      'candidate_count': candidateCount,
      'comparison_depth': comparisonDepth,
      'top1_changed': top1Changed,
      'top_k_overlap': topKOverlap,
      'mean_absolute_rank_displacement': meanAbsoluteRankDisplacement,
      'max_absolute_rank_displacement': maxAbsoluteRankDisplacement,
      'baseline_diversity': baselineDiversity,
      'experiment_diversity': experimentDiversity,
      'diversity_delta': diversityDelta,
    };
  }
}

/// Compares an experimental local ranker with the production order.
///
/// Only aggregate differences leave this service. The experimental order is
/// never returned to the recommendation pipeline.
class V2RecommendationShadowScoringService {
  V2RecommendationShadowScoringService({
    V2RecommendationExperimentalScorer? experimentalScorer,
    V2RecommendationExperimentalRanker? experimentalRanker,
    V2RecommendationShadowReporter? reporter,
    AnalyticsService? analyticsService,
    V2RecommendationShadowStore? shadowStore,
    String baselineVersion = defaultBaselineVersion,
    String experimentVersion = defaultExperimentVersion,
    this.topK = 5,
  })  : assert(topK > 0),
        assert(experimentalScorer == null || experimentalRanker == null),
        _experimentalRanker = experimentalRanker ??
            V2RecommendationExperimentalRanker(
              scorer: experimentalScorer,
            ),
        _reporter = reporter ??
            _buildDefaultReporter(
              analyticsService ?? AnalyticsService(),
              shadowStore ?? V2RecommendationShadowStore.instance,
            ),
        baselineVersion = _safeVersion(baselineVersion),
        experimentVersion = _safeVersion(experimentVersion);

  static final V2RecommendationShadowScoringService instance =
      V2RecommendationShadowScoringService();

  static const String schemaVersion = 'v1';
  static const String defaultBaselineVersion = 'local_rank_v2';
  static const String defaultExperimentVersion = 'local_rank_v3_quality_shadow';

  final V2RecommendationExperimentalRanker _experimentalRanker;
  final V2RecommendationShadowReporter _reporter;
  final String baselineVersion;
  final String experimentVersion;
  final int topK;

  Future<void> observe({
    required List<V2RecommendationShadowCandidate> candidates,
    required V2RecommendationRecallPath recallPath,
  }) async {
    try {
      final summary = evaluate(
        candidates: candidates,
        recallPath: recallPath,
      );
      await _reporter(summary);
    } catch (_) {
      // Shadow scoring must never affect the production recommendation path.
    }
  }

  V2RecommendationShadowSummary evaluate({
    required List<V2RecommendationShadowCandidate> candidates,
    required V2RecommendationRecallPath recallPath,
  }) {
    final comparison = _experimentalRanker.compare(candidates);
    final baseline = comparison.baseline;
    final shadow = comparison.experiment;

    final comparisonDepth = baseline.length < topK ? baseline.length : topK;
    final baselinePositionByKey = <String, int>{
      for (var index = 0; index < baseline.length; index++)
        baseline[index].candidateKey: index,
    };
    var displacementTotal = 0;
    var maxDisplacement = 0;
    for (var shadowPosition = 0;
        shadowPosition < shadow.length;
        shadowPosition++) {
      final baselinePosition =
          baselinePositionByKey[shadow[shadowPosition].candidateKey]!;
      final displacement = (shadowPosition - baselinePosition).abs();
      displacementTotal += displacement;
      if (displacement > maxDisplacement) maxDisplacement = displacement;
    }

    final baselineTopKeys = baseline
        .take(comparisonDepth)
        .map((candidate) => candidate.candidateKey)
        .toSet();
    final shadowTopKeys =
        shadow.take(comparisonDepth).map((item) => item.candidateKey).toSet();
    final overlap = comparisonDepth == 0
        ? 1.0
        : baselineTopKeys.intersection(shadowTopKeys).length / comparisonDepth;

    return V2RecommendationShadowSummary(
      baselineVersion: baselineVersion,
      experimentVersion: experimentVersion,
      recallPath: recallPath,
      candidateCount: baseline.length,
      comparisonDepth: comparisonDepth,
      top1Changed: baseline.isNotEmpty &&
          baseline.first.candidateKey != shadow.first.candidateKey,
      topKOverlap: overlap,
      meanAbsoluteRankDisplacement:
          baseline.isEmpty ? 0 : displacementTotal / baseline.length,
      maxAbsoluteRankDisplacement: maxDisplacement,
      baselineDiversity: _diversity(baseline.take(comparisonDepth)),
      experimentDiversity: _diversity(
        shadow.take(comparisonDepth),
      ),
    );
  }

  static double _diversity(
    Iterable<V2RecommendationShadowCandidate> candidates,
  ) {
    final values = candidates.toList();
    if (values.isEmpty) return 0;
    return values.map((candidate) => candidate.diversityKey).toSet().length /
        values.length;
  }

  static V2RecommendationShadowReporter _buildDefaultReporter(
    AnalyticsService analyticsService,
    V2RecommendationShadowStore shadowStore,
  ) {
    return (summary) async {
      final properties = summary.toProperties();
      await Future.wait([
        _bestEffort(
          () => analyticsService.trackEvent(
            AnalyticsEventType.recommendationShadowScored.name,
            properties: properties,
            recordMetrics: false,
            anonymous: true,
          ),
        ),
        _bestEffort(() => shadowStore.record(properties)),
      ]);
    };
  }

  static Future<void> _bestEffort(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (_) {
      // Analytics and local aggregation fail independently by design.
    }
  }

  static String _safeVersion(String raw) {
    final safe = raw.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    return safe.isEmpty ? 'unknown' : safe;
  }
}
