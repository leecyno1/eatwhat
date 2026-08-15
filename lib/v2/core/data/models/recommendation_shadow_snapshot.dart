class RecommendationShadowSnapshot {
  const RecommendationShadowSnapshot({
    required this.day,
    required this.schemaVersion,
    required this.baselineVersion,
    required this.experimentVersion,
    required this.recallPath,
    this.observations = 0,
    this.candidateCountSum = 0,
    this.comparisonDepthSum = 0,
    this.top1ChangeCount = 0,
    this.topKOverlapWeightedSum = 0,
    this.rankDisplacementSum = 0,
    this.maxAbsoluteRankDisplacement = 0,
    this.baselineDiversityWeightedSum = 0,
    this.experimentDiversityWeightedSum = 0,
  });

  final DateTime day;
  final String schemaVersion;
  final String baselineVersion;
  final String experimentVersion;
  final String recallPath;
  final int observations;
  final int candidateCountSum;
  final int comparisonDepthSum;
  final int top1ChangeCount;
  final double topKOverlapWeightedSum;
  final double rankDisplacementSum;
  final int maxAbsoluteRankDisplacement;
  final double baselineDiversityWeightedSum;
  final double experimentDiversityWeightedSum;

  bool belongsTo({
    required DateTime day,
    required String schemaVersion,
    required String baselineVersion,
    required String experimentVersion,
    required String recallPath,
  }) {
    return _dayKey(this.day) == _dayKey(day) &&
        this.schemaVersion == schemaVersion &&
        this.baselineVersion == baselineVersion &&
        this.experimentVersion == experimentVersion &&
        this.recallPath == recallPath;
  }

  RecommendationShadowSnapshot addObservation({
    required int candidateCount,
    required int comparisonDepth,
    required bool top1Changed,
    required double topKOverlap,
    required double meanAbsoluteRankDisplacement,
    required int observationMaxAbsoluteRankDisplacement,
    required double baselineDiversity,
    required double experimentDiversity,
  }) {
    return RecommendationShadowSnapshot(
      day: day,
      schemaVersion: schemaVersion,
      baselineVersion: baselineVersion,
      experimentVersion: experimentVersion,
      recallPath: recallPath,
      observations: observations + 1,
      candidateCountSum: candidateCountSum + candidateCount,
      comparisonDepthSum: comparisonDepthSum + comparisonDepth,
      top1ChangeCount: top1ChangeCount + (top1Changed ? 1 : 0),
      topKOverlapWeightedSum:
          topKOverlapWeightedSum + topKOverlap * comparisonDepth,
      rankDisplacementSum:
          rankDisplacementSum + meanAbsoluteRankDisplacement * candidateCount,
      maxAbsoluteRankDisplacement:
          observationMaxAbsoluteRankDisplacement > maxAbsoluteRankDisplacement
              ? observationMaxAbsoluteRankDisplacement
              : maxAbsoluteRankDisplacement,
      baselineDiversityWeightedSum:
          baselineDiversityWeightedSum + baselineDiversity * comparisonDepth,
      experimentDiversityWeightedSum: experimentDiversityWeightedSum +
          experimentDiversity * comparisonDepth,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': _dayKey(day),
      'schema_version': schemaVersion,
      'baseline_version': baselineVersion,
      'experiment_version': experimentVersion,
      'recall_path': recallPath,
      'observations': observations,
      'candidate_count_sum': candidateCountSum,
      'comparison_depth_sum': comparisonDepthSum,
      'top1_change_count': top1ChangeCount,
      'top_k_overlap_weighted_sum': topKOverlapWeightedSum,
      'rank_displacement_sum': rankDisplacementSum,
      'max_absolute_rank_displacement': maxAbsoluteRankDisplacement,
      'baseline_diversity_weighted_sum': baselineDiversityWeightedSum,
      'experiment_diversity_weighted_sum': experimentDiversityWeightedSum,
    };
  }

  static RecommendationShadowSnapshot? tryFromJson(
    Map<String, dynamic> json,
  ) {
    final day = DateTime.tryParse(json['day']?.toString() ?? '');
    final schemaVersion = json['schema_version']?.toString().trim() ?? '';
    final baselineVersion = json['baseline_version']?.toString().trim() ?? '';
    final experimentVersion =
        json['experiment_version']?.toString().trim() ?? '';
    final recallPath = json['recall_path']?.toString().trim() ?? '';
    final observations = _count(json['observations']);
    final candidateCountSum = _count(json['candidate_count_sum']);
    final comparisonDepthSum = _count(json['comparison_depth_sum']);
    final top1ChangeCount = _count(json['top1_change_count']);
    final topKOverlapWeightedSum =
        _finiteNonNegative(json['top_k_overlap_weighted_sum']);
    final rankDisplacementSum =
        _finiteNonNegative(json['rank_displacement_sum']);
    final maxAbsoluteRankDisplacement =
        _count(json['max_absolute_rank_displacement']);
    final baselineDiversityWeightedSum =
        _finiteNonNegative(json['baseline_diversity_weighted_sum']);
    final experimentDiversityWeightedSum =
        _finiteNonNegative(json['experiment_diversity_weighted_sum']);

    if (day == null ||
        !_safeVersion.hasMatch(schemaVersion) ||
        !_safeVersion.hasMatch(baselineVersion) ||
        !_safeVersion.hasMatch(experimentVersion) ||
        !_supportedRecallPaths.contains(recallPath) ||
        observations == null ||
        observations == 0 ||
        candidateCountSum == null ||
        candidateCountSum == 0 ||
        comparisonDepthSum == null ||
        comparisonDepthSum == 0 ||
        comparisonDepthSum > candidateCountSum ||
        top1ChangeCount == null ||
        top1ChangeCount > observations ||
        topKOverlapWeightedSum == null ||
        _exceedsTotal(topKOverlapWeightedSum, comparisonDepthSum) ||
        rankDisplacementSum == null ||
        maxAbsoluteRankDisplacement == null ||
        baselineDiversityWeightedSum == null ||
        _exceedsTotal(baselineDiversityWeightedSum, comparisonDepthSum) ||
        experimentDiversityWeightedSum == null ||
        _exceedsTotal(experimentDiversityWeightedSum, comparisonDepthSum)) {
      return null;
    }

    return RecommendationShadowSnapshot(
      day: DateTime(day.year, day.month, day.day),
      schemaVersion: schemaVersion,
      baselineVersion: baselineVersion,
      experimentVersion: experimentVersion,
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

  static int? _count(dynamic value) {
    final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  static double? _finiteNonNegative(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (parsed == null || !parsed.isFinite || parsed < 0) return null;
    return parsed;
  }

  static bool _exceedsTotal(double value, int total) {
    return value - total > 0.000000001;
  }

  static String _dayKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static const Set<String> _supportedRecallPaths = {
    'direct',
    'defaultPool',
  };
  static final RegExp _safeVersion = RegExp(r'^[a-zA-Z0-9_.-]{1,64}$');
}
