typedef V2RecommendationExperimentalScorer = double Function(
  V2RecommendationShadowCandidate candidate,
);

class V2RecommendationShadowCandidate {
  const V2RecommendationShadowCandidate({
    required this.candidateKey,
    required this.baselinePosition,
    required this.baselineScore,
    required this.rating,
    required this.popularity,
    required this.preferenceBonus,
    required this.historyBonus,
    required this.favoriteBonus,
    required this.negativePenalty,
    required this.recentPenalty,
    required this.diversityKey,
  });

  /// Used only while comparing the two in-memory rankings.
  final String candidateKey;
  final int baselinePosition;
  final double baselineScore;
  final double rating;
  final double popularity;
  final double preferenceBonus;
  final double historyBonus;
  final double favoriteBonus;
  final double negativePenalty;
  final double recentPenalty;
  final String diversityKey;
}

class V2RecommendationRankComparison {
  V2RecommendationRankComparison({
    required List<V2RecommendationShadowCandidate> baseline,
    required List<V2RecommendationShadowCandidate> experiment,
  })  : baseline = List.unmodifiable(baseline),
        experiment = List.unmodifiable(experiment);

  final List<V2RecommendationShadowCandidate> baseline;
  final List<V2RecommendationShadowCandidate> experiment;
}

class V2RecommendationExperimentalRanker {
  V2RecommendationExperimentalRanker({
    V2RecommendationExperimentalScorer? scorer,
  }) : _scorer = scorer ?? defaultScore;

  static final V2RecommendationExperimentalRanker instance =
      V2RecommendationExperimentalRanker();

  final V2RecommendationExperimentalScorer _scorer;

  V2RecommendationRankComparison compare(
    List<V2RecommendationShadowCandidate> candidates,
  ) {
    final baseline = List<V2RecommendationShadowCandidate>.of(candidates)
      ..sort(
        (left, right) =>
            left.baselinePosition.compareTo(right.baselinePosition),
      );
    _validateBaseline(baseline);

    final experiment = baseline.map((candidate) {
      final score = _scorer(candidate);
      if (!score.isFinite) {
        throw StateError('Experimental score must be finite.');
      }
      return _RankedCandidate(candidate: candidate, score: score);
    }).toList()
      ..sort((left, right) {
        final scoreOrder = right.score.compareTo(left.score);
        if (scoreOrder != 0) return scoreOrder;
        return left.candidate.baselinePosition.compareTo(
          right.candidate.baselinePosition,
        );
      });

    return V2RecommendationRankComparison(
      baseline: baseline,
      experiment: experiment.map((item) => item.candidate).toList(),
    );
  }

  static double defaultScore(V2RecommendationShadowCandidate candidate) {
    return candidate.baselineScore * 0.2 +
        candidate.rating * 12 +
        candidate.popularity.clamp(0, 100).toDouble() * 0.1 +
        candidate.preferenceBonus * 1.1 +
        candidate.historyBonus * 1.3 +
        candidate.favoriteBonus * 0.5 -
        candidate.negativePenalty -
        candidate.recentPenalty * 0.65 -
        candidate.baselinePosition * 0.35;
  }

  static void _validateBaseline(
    List<V2RecommendationShadowCandidate> baseline,
  ) {
    final candidateKeys = baseline.map((item) => item.candidateKey).toSet();
    if (candidateKeys.length != baseline.length ||
        candidateKeys.any((key) => key.isEmpty)) {
      throw ArgumentError('Shadow candidates must have unique opaque keys.');
    }
    for (var index = 0; index < baseline.length; index++) {
      if (baseline[index].baselinePosition != index) {
        throw ArgumentError(
          'Shadow candidates must have contiguous baseline positions.',
        );
      }
    }
  }
}

class _RankedCandidate {
  const _RankedCandidate({
    required this.candidate,
    required this.score,
  });

  final V2RecommendationShadowCandidate candidate;
  final double score;
}
