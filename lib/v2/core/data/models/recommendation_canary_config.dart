class RecommendationCanaryConfig {
  const RecommendationCanaryConfig({
    required this.schemaVersion,
    required this.baselineRankingVersion,
    required this.experimentRankingVersion,
    required this.baselineAlgorithmVersion,
    required this.experimentAlgorithmVersion,
    required this.rolloutBasisPoints,
    required this.activatedAt,
    required this.expiresAt,
  });

  final String schemaVersion;
  final String baselineRankingVersion;
  final String experimentRankingVersion;
  final String baselineAlgorithmVersion;
  final String experimentAlgorithmVersion;
  final int rolloutBasisPoints;
  final DateTime activatedAt;
  final DateTime expiresAt;

  bool isActiveAt(DateTime now) {
    return expiresAt.isAfter(now) && !activatedAt.isAfter(now);
  }

  Map<String, dynamic> toJson() {
    return {
      'schema_version': schemaVersion,
      'baseline_ranking_version': baselineRankingVersion,
      'experiment_ranking_version': experimentRankingVersion,
      'baseline_algorithm_version': baselineAlgorithmVersion,
      'experiment_algorithm_version': experimentAlgorithmVersion,
      'rollout_basis_points': rolloutBasisPoints,
      'activated_at': activatedAt.toUtc().toIso8601String(),
      'expires_at': expiresAt.toUtc().toIso8601String(),
    };
  }

  static RecommendationCanaryConfig? tryFromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schema_version']?.toString().trim() ?? '';
    final baselineRankingVersion =
        json['baseline_ranking_version']?.toString().trim() ?? '';
    final experimentRankingVersion =
        json['experiment_ranking_version']?.toString().trim() ?? '';
    final baselineAlgorithmVersion =
        json['baseline_algorithm_version']?.toString().trim() ?? '';
    final experimentAlgorithmVersion =
        json['experiment_algorithm_version']?.toString().trim() ?? '';
    final rolloutBasisPoints = json['rollout_basis_points'] is int
        ? json['rollout_basis_points'] as int
        : int.tryParse(json['rollout_basis_points']?.toString() ?? '');
    final activatedAt =
        DateTime.tryParse(json['activated_at']?.toString() ?? '');
    final expiresAt = DateTime.tryParse(json['expires_at']?.toString() ?? '');

    if (schemaVersion != supportedSchemaVersion ||
        !_safeVersion.hasMatch(baselineRankingVersion) ||
        !_safeVersion.hasMatch(experimentRankingVersion) ||
        !_safeVersion.hasMatch(baselineAlgorithmVersion) ||
        !_safeVersion.hasMatch(experimentAlgorithmVersion) ||
        baselineRankingVersion == experimentRankingVersion ||
        baselineAlgorithmVersion == experimentAlgorithmVersion ||
        rolloutBasisPoints == null ||
        rolloutBasisPoints <= 0 ||
        rolloutBasisPoints > maximumRolloutBasisPoints ||
        activatedAt == null ||
        expiresAt == null ||
        !expiresAt.isAfter(activatedAt) ||
        expiresAt.difference(activatedAt) > maximumDuration) {
      return null;
    }

    return RecommendationCanaryConfig(
      schemaVersion: schemaVersion,
      baselineRankingVersion: baselineRankingVersion,
      experimentRankingVersion: experimentRankingVersion,
      baselineAlgorithmVersion: baselineAlgorithmVersion,
      experimentAlgorithmVersion: experimentAlgorithmVersion,
      rolloutBasisPoints: rolloutBasisPoints,
      activatedAt: activatedAt,
      expiresAt: expiresAt,
    );
  }

  static const String supportedSchemaVersion = 'v1';
  static const int maximumRolloutBasisPoints = 1000;
  static const Duration maximumDuration = Duration(days: 7);
  static final RegExp _safeVersion = RegExp(r'^[a-zA-Z0-9_.-]{1,64}$');
}
