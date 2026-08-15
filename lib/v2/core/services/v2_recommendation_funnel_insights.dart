import 'package:eatwhat_app/v2/core/data/models/recommendation_funnel_snapshot.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_funnel_store.dart';

typedef RecommendationFunnelSnapshotLoader
    = Future<List<RecommendationFunnelSnapshot>> Function(DateTime? since);

enum RecommendationAlgorithmVerdict {
  insufficientData,
  regression,
  neutral,
  promising,
}

class RecommendationFunnelGuardrails {
  const RecommendationFunnelGuardrails({
    this.minimumExposures = 20,
    this.minimumExecutionStarts = 10,
    this.maximumExecutionStartRateDrop = 0.05,
    this.maximumExecutionCompletionRateDrop = 0.05,
    this.maximumExecutionDeferralRateIncrease = 0.05,
    this.maximumRerollsPerExposureIncrease = 0.10,
    this.maximumNegativeFeedbackPerExposureIncrease = 0.05,
    this.minimumExecutionStartRateLift = 0.03,
    this.minimumExecutionCompletionRateLift = 0.03,
  })  : assert(minimumExposures > 0),
        assert(minimumExecutionStarts > 0),
        assert(maximumExecutionStartRateDrop >= 0),
        assert(maximumExecutionCompletionRateDrop >= 0),
        assert(maximumExecutionDeferralRateIncrease >= 0),
        assert(maximumRerollsPerExposureIncrease >= 0),
        assert(maximumNegativeFeedbackPerExposureIncrease >= 0),
        assert(minimumExecutionStartRateLift >= 0),
        assert(minimumExecutionCompletionRateLift >= 0);

  final int minimumExposures;
  final int minimumExecutionStarts;
  final double maximumExecutionStartRateDrop;
  final double maximumExecutionCompletionRateDrop;
  final double maximumExecutionDeferralRateIncrease;
  final double maximumRerollsPerExposureIncrease;
  final double maximumNegativeFeedbackPerExposureIncrease;
  final double minimumExecutionStartRateLift;
  final double minimumExecutionCompletionRateLift;
}

class RecommendationFunnelSummary {
  const RecommendationFunnelSummary({
    required this.label,
    required this.exposures,
    required this.candidateSelections,
    required this.confirmations,
    required this.rerolls,
    required this.favoriteAdds,
    required this.favoriteRemovals,
    required this.positiveFeedback,
    required this.negativeFeedback,
    required this.executionStarts,
    required this.executionCompletions,
    required this.executionDeferrals,
  });

  factory RecommendationFunnelSummary.empty(String label) {
    return RecommendationFunnelSummary(
      label: label,
      exposures: 0,
      candidateSelections: 0,
      confirmations: 0,
      rerolls: 0,
      favoriteAdds: 0,
      favoriteRemovals: 0,
      positiveFeedback: 0,
      negativeFeedback: 0,
      executionStarts: 0,
      executionCompletions: 0,
      executionDeferrals: 0,
    );
  }

  final String label;
  final int exposures;
  final int candidateSelections;
  final int confirmations;
  final int rerolls;
  final int favoriteAdds;
  final int favoriteRemovals;
  final int positiveFeedback;
  final int negativeFeedback;
  final int executionStarts;
  final int executionCompletions;
  final int executionDeferrals;

  int get selectionActions => candidateSelections + confirmations;

  double get selectionActionsPerExposure => _ratio(selectionActions, exposures);

  double get rerollsPerExposure => _ratio(rerolls, exposures);

  double get favoriteAddsPerExposure => _ratio(favoriteAdds, exposures);

  double get positiveFeedbackPerExposure => _ratio(positiveFeedback, exposures);

  double get negativeFeedbackPerExposure => _ratio(negativeFeedback, exposures);

  double get executionStartRate => _ratio(executionStarts, exposures);

  double get executionCompletionRate =>
      _ratio(executionCompletions, executionStarts);

  double get executionDeferralRate =>
      _ratio(executionDeferrals, executionStarts);

  static RecommendationFunnelSummary aggregate(
    String label,
    Iterable<RecommendationFunnelSnapshot> snapshots,
  ) {
    var exposures = 0;
    var candidateSelections = 0;
    var confirmations = 0;
    var rerolls = 0;
    var favoriteAdds = 0;
    var favoriteRemovals = 0;
    var positiveFeedback = 0;
    var negativeFeedback = 0;
    var executionStarts = 0;
    var executionCompletions = 0;
    var executionDeferrals = 0;
    for (final snapshot in snapshots) {
      exposures += snapshot.exposures;
      candidateSelections += snapshot.candidateSelections;
      confirmations += snapshot.confirmations;
      rerolls += snapshot.rerolls;
      favoriteAdds += snapshot.favoriteAdds;
      favoriteRemovals += snapshot.favoriteRemovals;
      positiveFeedback += snapshot.positiveFeedback;
      negativeFeedback += snapshot.negativeFeedback;
      executionStarts += snapshot.executionStarts;
      executionCompletions += snapshot.executionCompletions;
      executionDeferrals += snapshot.executionDeferrals;
    }
    return RecommendationFunnelSummary(
      label: label,
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

  static double _ratio(int numerator, int denominator) {
    if (denominator <= 0) return 0;
    return numerator / denominator;
  }
}

class RecommendationFunnelReport {
  RecommendationFunnelReport({
    required this.periodStart,
    required this.periodEnd,
    required this.overall,
    required List<RecommendationFunnelSummary> byAlgorithm,
    required List<RecommendationFunnelSummary> byPrimarySource,
    required List<RecommendationFunnelSummary> byResolutionStatus,
  })  : byAlgorithm = List.unmodifiable(byAlgorithm),
        byPrimarySource = List.unmodifiable(byPrimarySource),
        byResolutionStatus = List.unmodifiable(byResolutionStatus);

  final DateTime? periodStart;
  final DateTime? periodEnd;
  final RecommendationFunnelSummary overall;
  final List<RecommendationFunnelSummary> byAlgorithm;
  final List<RecommendationFunnelSummary> byPrimarySource;
  final List<RecommendationFunnelSummary> byResolutionStatus;

  RecommendationFunnelSummary? algorithm(String algorithmVersion) {
    for (final summary in byAlgorithm) {
      if (summary.label == algorithmVersion) return summary;
    }
    return null;
  }
}

class RecommendationAlgorithmComparison {
  RecommendationAlgorithmComparison({
    required this.baseline,
    required this.candidate,
    required this.verdict,
    required List<String> reasons,
  }) : reasons = List.unmodifiable(reasons);

  final RecommendationFunnelSummary baseline;
  final RecommendationFunnelSummary candidate;
  final RecommendationAlgorithmVerdict verdict;
  final List<String> reasons;

  double get executionStartRateDelta =>
      candidate.executionStartRate - baseline.executionStartRate;

  double get executionCompletionRateDelta =>
      candidate.executionCompletionRate - baseline.executionCompletionRate;

  double get executionDeferralRateDelta =>
      candidate.executionDeferralRate - baseline.executionDeferralRate;

  double get rerollsPerExposureDelta =>
      candidate.rerollsPerExposure - baseline.rerollsPerExposure;

  double get negativeFeedbackPerExposureDelta =>
      candidate.negativeFeedbackPerExposure -
      baseline.negativeFeedbackPerExposure;
}

class V2RecommendationFunnelInsights {
  V2RecommendationFunnelInsights({
    V2RecommendationFunnelStore? store,
    RecommendationFunnelSnapshotLoader? snapshotLoader,
    this.guardrails = const RecommendationFunnelGuardrails(),
  }) : _snapshotLoader = snapshotLoader ??
            ((since) => (store ?? V2RecommendationFunnelStore.instance)
                .readSnapshots(since: since));

  static final V2RecommendationFunnelInsights instance =
      V2RecommendationFunnelInsights();

  final RecommendationFunnelSnapshotLoader _snapshotLoader;
  final RecommendationFunnelGuardrails guardrails;

  Future<RecommendationFunnelReport> loadReport({DateTime? since}) async {
    final snapshots = await _snapshotLoader(since);
    final sortedDays = snapshots.map((snapshot) => snapshot.day).toList()
      ..sort();
    return RecommendationFunnelReport(
      periodStart: sortedDays.isEmpty ? null : sortedDays.first,
      periodEnd: sortedDays.isEmpty ? null : sortedDays.last,
      overall: RecommendationFunnelSummary.aggregate('overall', snapshots),
      byAlgorithm: _group(
        snapshots,
        (snapshot) => snapshot.algorithmVersion,
      ),
      byPrimarySource: _group(
        snapshots,
        (snapshot) => snapshot.primarySource,
      ),
      byResolutionStatus: _group(
        snapshots,
        (snapshot) => snapshot.resolutionStatus,
      ),
    );
  }

  Future<RecommendationAlgorithmComparison> compareAlgorithms({
    required String baselineVersion,
    required String candidateVersion,
    DateTime? since,
  }) async {
    if (baselineVersion == candidateVersion) {
      throw ArgumentError.value(
        candidateVersion,
        'candidateVersion',
        'Candidate and baseline versions must be different.',
      );
    }
    final report = await loadReport(since: since);
    final baseline = report.algorithm(baselineVersion);
    final candidate = report.algorithm(candidateVersion);
    final resolvedBaseline =
        baseline ?? RecommendationFunnelSummary.empty(baselineVersion);
    final resolvedCandidate =
        candidate ?? RecommendationFunnelSummary.empty(candidateVersion);

    final sampleReasons = <String>[
      if (baseline == null) 'baseline_algorithm_missing',
      if (candidate == null) 'candidate_algorithm_missing',
      if (baseline != null) ..._sampleReasons('baseline', baseline),
      if (candidate != null) ..._sampleReasons('candidate', candidate),
    ];
    if (sampleReasons.isNotEmpty) {
      return RecommendationAlgorithmComparison(
        baseline: resolvedBaseline,
        candidate: resolvedCandidate,
        verdict: RecommendationAlgorithmVerdict.insufficientData,
        reasons: sampleReasons,
      );
    }

    final comparison = RecommendationAlgorithmComparison(
      baseline: resolvedBaseline,
      candidate: resolvedCandidate,
      verdict: RecommendationAlgorithmVerdict.neutral,
      reasons: const [],
    );
    final regressionReasons = <String>[
      if (comparison.executionStartRateDelta <
          -guardrails.maximumExecutionStartRateDrop)
        'execution_start_rate_drop',
      if (comparison.executionCompletionRateDelta <
          -guardrails.maximumExecutionCompletionRateDrop)
        'execution_completion_rate_drop',
      if (comparison.executionDeferralRateDelta >
          guardrails.maximumExecutionDeferralRateIncrease)
        'execution_deferral_rate_increase',
      if (comparison.rerollsPerExposureDelta >
          guardrails.maximumRerollsPerExposureIncrease)
        'rerolls_per_exposure_increase',
      if (comparison.negativeFeedbackPerExposureDelta >
          guardrails.maximumNegativeFeedbackPerExposureIncrease)
        'negative_feedback_per_exposure_increase',
    ];
    if (regressionReasons.isNotEmpty) {
      return RecommendationAlgorithmComparison(
        baseline: resolvedBaseline,
        candidate: resolvedCandidate,
        verdict: RecommendationAlgorithmVerdict.regression,
        reasons: regressionReasons,
      );
    }

    final promisingReasons = <String>[
      if (comparison.executionStartRateDelta >=
          guardrails.minimumExecutionStartRateLift)
        'execution_start_rate_lift',
      if (comparison.executionCompletionRateDelta >=
          guardrails.minimumExecutionCompletionRateLift)
        'execution_completion_rate_lift',
    ];
    if (promisingReasons.isNotEmpty) {
      return RecommendationAlgorithmComparison(
        baseline: resolvedBaseline,
        candidate: resolvedCandidate,
        verdict: RecommendationAlgorithmVerdict.promising,
        reasons: promisingReasons,
      );
    }

    return RecommendationAlgorithmComparison(
      baseline: resolvedBaseline,
      candidate: resolvedCandidate,
      verdict: RecommendationAlgorithmVerdict.neutral,
      reasons: const ['no_material_change'],
    );
  }

  List<String> _sampleReasons(
    String prefix,
    RecommendationFunnelSummary summary,
  ) {
    return [
      if (summary.exposures < guardrails.minimumExposures)
        '${prefix}_exposures_below_minimum',
      if (summary.executionStarts < guardrails.minimumExecutionStarts)
        '${prefix}_execution_starts_below_minimum',
    ];
  }

  List<RecommendationFunnelSummary> _group(
    List<RecommendationFunnelSnapshot> snapshots,
    String Function(RecommendationFunnelSnapshot snapshot) keyFor,
  ) {
    final grouped = <String, List<RecommendationFunnelSnapshot>>{};
    for (final snapshot in snapshots) {
      grouped.putIfAbsent(keyFor(snapshot), () => []).add(snapshot);
    }
    final summaries = grouped.entries
        .map(
          (entry) => RecommendationFunnelSummary.aggregate(
            entry.key,
            entry.value,
          ),
        )
        .toList()
      ..sort((left, right) {
        final exposureComparison = right.exposures.compareTo(left.exposures);
        if (exposureComparison != 0) return exposureComparison;
        return left.label.compareTo(right.label);
      });
    return summaries;
  }
}
