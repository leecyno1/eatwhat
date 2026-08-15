import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';

class RecommendationTelemetryContext {
  const RecommendationTelemetryContext({
    required this.recommendationId,
    required this.algorithmVersion,
    required this.primarySource,
    required this.resolutionStatus,
    required this.recalledCount,
    required this.finalCount,
    required this.latencyMs,
    required this.diversityScore,
    required this.appliedConstraintCount,
    this.fallbackReason,
  });

  final String recommendationId;
  final String algorithmVersion;
  final String primarySource;
  final RecommendationResolutionStatus resolutionStatus;
  final int recalledCount;
  final int finalCount;
  final int latencyMs;
  final double diversityScore;
  final int appliedConstraintCount;
  final String? fallbackReason;

  Map<String, dynamic> toAnalyticsProperties() {
    return {
      'recommendation_id': recommendationId,
      'algorithm_version': algorithmVersion,
      'primary_source': primarySource,
      'resolution_status': resolutionStatus.name,
      'recalled_count': recalledCount,
      'final_count': finalCount,
      'latency_ms': latencyMs,
      'diversity_score': diversityScore,
      'applied_constraint_count': appliedConstraintCount,
      'has_fallback': fallbackReason?.trim().isNotEmpty ?? false,
      if (fallbackReason?.trim().isNotEmpty ?? false)
        'fallback_reason': fallbackReason!.trim(),
    };
  }
}
