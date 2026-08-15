import 'package:eatwhat_app/v2/core/data/models/recommendation_canary_config.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_funnel_insights.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_shadow_insights.dart';

typedef V2CanaryConfigurationInspector
    = Future<RecommendationCanaryConfigurationInspection> Function();
typedef V2CanaryOperationsAssessmentLoader
    = Future<RecommendationShadowCanaryAssessment> Function({
  required String baselineVersion,
  required String experimentVersion,
});
typedef V2CanaryOperationsComparisonLoader
    = Future<RecommendationAlgorithmComparison> Function({
  required String baselineVersion,
  required String candidateVersion,
  DateTime? since,
});

enum RecommendationCanaryOperationsRecommendation {
  keepDisabled,
  collectShadowData,
  eligibleForManualCanary,
  continueCanarySampling,
  maintainCanary,
  considerManualExpansion,
  stopCanary,
  manualReview,
}

class RecommendationCanaryOperationsReport {
  RecommendationCanaryOperationsReport({
    required this.generatedAt,
    required this.configuration,
    required this.baselineRankingVersion,
    required this.experimentRankingVersion,
    required this.baselineAlgorithmVersion,
    required this.experimentAlgorithmVersion,
    required this.recommendation,
    required List<String> reasons,
    this.shadowAssessment,
    this.funnelComparison,
  }) : reasons = List.unmodifiable(reasons);

  final DateTime generatedAt;
  final RecommendationCanaryConfigurationInspection configuration;
  final String baselineRankingVersion;
  final String experimentRankingVersion;
  final String baselineAlgorithmVersion;
  final String experimentAlgorithmVersion;
  final RecommendationShadowCanaryAssessment? shadowAssessment;
  final RecommendationAlgorithmComparison? funnelComparison;
  final RecommendationCanaryOperationsRecommendation recommendation;
  final List<String> reasons;

  bool get authorizesAutomaticActivation => false;
  bool get authorizesAutomaticExpansion => false;
  bool get authorizesAutomaticFullRollout => false;

  Map<String, Object?> toJson() {
    final config = configuration.config;
    final assessment = shadowAssessment;
    final comparison = funnelComparison;
    return {
      'generated_at': generatedAt.toUtc().toIso8601String(),
      'configuration': {
        'state': configuration.state.name,
        'has_active_configuration': configuration.hasActiveConfiguration,
        'reasons': configuration.reasons,
        if (config != null) ..._configurationJson(config),
      },
      'versions': {
        'baseline_ranking': baselineRankingVersion,
        'experiment_ranking': experimentRankingVersion,
        'baseline_algorithm': baselineAlgorithmVersion,
        'experiment_algorithm': experimentAlgorithmVersion,
      },
      'shadow_gate': assessment == null
          ? null
          : {
              'verdict': assessment.verdict.name,
              'reasons': assessment.reasons,
              'recall_paths': {
                for (final entry in assessment.byRecallPath.entries)
                  entry.key.name: {
                    'observations': entry.value.observations,
                    'top_k_overlap': entry.value.meanTopKOverlap,
                    'mean_rank_displacement':
                        entry.value.meanAbsoluteRankDisplacement,
                    'max_rank_displacement':
                        entry.value.maxAbsoluteRankDisplacement,
                    'diversity_delta': entry.value.diversityDelta,
                  },
              },
            },
      'real_funnel': comparison == null
          ? null
          : {
              'verdict': comparison.verdict.name,
              'reasons': comparison.reasons,
              'baseline_exposures': comparison.baseline.exposures,
              'candidate_exposures': comparison.candidate.exposures,
              'baseline_execution_starts': comparison.baseline.executionStarts,
              'candidate_execution_starts':
                  comparison.candidate.executionStarts,
              'execution_start_rate_delta': comparison.executionStartRateDelta,
              'execution_completion_rate_delta':
                  comparison.executionCompletionRateDelta,
              'execution_deferral_rate_delta':
                  comparison.executionDeferralRateDelta,
              'rerolls_per_exposure_delta': comparison.rerollsPerExposureDelta,
              'negative_feedback_per_exposure_delta':
                  comparison.negativeFeedbackPerExposureDelta,
            },
      'recommendation': recommendation.name,
      'reasons': reasons,
      'authorizes_automatic_activation': false,
      'authorizes_automatic_expansion': false,
      'authorizes_automatic_full_rollout': false,
    };
  }

  static Map<String, Object?> _configurationJson(
    RecommendationCanaryConfig config,
  ) {
    return {
      'rollout_basis_points': config.rolloutBasisPoints,
      'rollout_percent': config.rolloutBasisPoints / 100,
      'activated_at': config.activatedAt.toUtc().toIso8601String(),
      'expires_at': config.expiresAt.toUtc().toIso8601String(),
      'baseline_ranking_version': config.baselineRankingVersion,
      'experiment_ranking_version': config.experimentRankingVersion,
      'baseline_algorithm_version': config.baselineAlgorithmVersion,
      'experiment_algorithm_version': config.experimentAlgorithmVersion,
    };
  }
}

class V2RecommendationCanaryOperationsService {
  V2RecommendationCanaryOperationsService({
    V2RecommendationCanaryService? canaryService,
    V2CanaryConfigurationInspector? configurationInspector,
    V2RecommendationShadowInsights? shadowInsights,
    V2CanaryOperationsAssessmentLoader? assessmentLoader,
    V2RecommendationFunnelInsights? funnelInsights,
    V2CanaryOperationsComparisonLoader? comparisonLoader,
    DateTime Function()? clock,
    String? baselineRankingVersion,
    String? baselineAlgorithmVersion,
  })  : assert(canaryService == null || configurationInspector == null),
        assert(shadowInsights == null || assessmentLoader == null),
        assert(funnelInsights == null || comparisonLoader == null),
        _configurationInspector = configurationInspector ??
            (canaryService ?? V2RecommendationCanaryService.instance)
                .inspectConfiguration,
        _assessmentLoader = assessmentLoader ??
            (shadowInsights ?? V2RecommendationShadowInsights.instance)
                .evaluateCanaryEligibility,
        _comparisonLoader = comparisonLoader ??
            (funnelInsights ?? V2RecommendationFunnelInsights.instance)
                .compareAlgorithms,
        _clock = clock ?? DateTime.now,
        baselineRankingVersion = baselineRankingVersion ??
            canaryService?.baselineRankingVersion ??
            'local_rank_v2',
        baselineAlgorithmVersion = baselineAlgorithmVersion ??
            canaryService?.baselineAlgorithmVersion ??
            'hybrid_v3_0';

  static final V2RecommendationCanaryOperationsService instance =
      V2RecommendationCanaryOperationsService();

  final V2CanaryConfigurationInspector _configurationInspector;
  final V2CanaryOperationsAssessmentLoader _assessmentLoader;
  final V2CanaryOperationsComparisonLoader _comparisonLoader;
  final DateTime Function() _clock;
  final String baselineRankingVersion;
  final String baselineAlgorithmVersion;

  Future<RecommendationCanaryOperationsReport> buildReport({
    required String experimentRankingVersion,
    required String experimentAlgorithmVersion,
  }) async {
    _validateVersion(baselineRankingVersion, 'baselineRankingVersion');
    _validateVersion(baselineAlgorithmVersion, 'baselineAlgorithmVersion');
    _validateVersion(experimentRankingVersion, 'experimentRankingVersion');
    _validateVersion(experimentAlgorithmVersion, 'experimentAlgorithmVersion');
    final generatedAt = _clock();
    final configuration = await _inspectConfiguration(generatedAt);
    final persistedConfig = configuration.config;
    final resolvedExperimentRankingVersion =
        persistedConfig?.experimentRankingVersion ?? experimentRankingVersion;
    final resolvedExperimentAlgorithmVersion =
        persistedConfig?.experimentAlgorithmVersion ??
            experimentAlgorithmVersion;

    RecommendationShadowCanaryAssessment? shadowAssessment;
    RecommendationAlgorithmComparison? funnelComparison;
    final readFailureReasons = <String>[];

    try {
      shadowAssessment = await _assessmentLoader(
        baselineVersion: baselineRankingVersion,
        experimentVersion: resolvedExperimentRankingVersion,
      );
    } catch (_) {
      readFailureReasons.add('shadow_gate_read_failed');
    }
    try {
      funnelComparison = await _comparisonLoader(
        baselineVersion: baselineAlgorithmVersion,
        candidateVersion: resolvedExperimentAlgorithmVersion,
        since: configuration.hasActiveConfiguration
            ? persistedConfig?.activatedAt
            : null,
      );
    } catch (_) {
      readFailureReasons.add('real_funnel_read_failed');
    }

    final integrityReasons = <String>[
      ...readFailureReasons,
      ..._configurationIntegrityReasons(configuration),
      if (shadowAssessment != null &&
          (shadowAssessment.baselineVersion != baselineRankingVersion ||
              shadowAssessment.experimentVersion !=
                  resolvedExperimentRankingVersion))
        'shadow_gate_version_mismatch',
      if (funnelComparison != null &&
          (funnelComparison.baseline.label != baselineAlgorithmVersion ||
              funnelComparison.candidate.label !=
                  resolvedExperimentAlgorithmVersion))
        'real_funnel_version_mismatch',
    ];
    final recommendation = _recommend(
      configuration: configuration,
      shadowAssessment: shadowAssessment,
      funnelComparison: funnelComparison,
      hasIntegrityFailure: integrityReasons.isNotEmpty,
    );
    return RecommendationCanaryOperationsReport(
      generatedAt: generatedAt,
      configuration: configuration,
      baselineRankingVersion: baselineRankingVersion,
      experimentRankingVersion: resolvedExperimentRankingVersion,
      baselineAlgorithmVersion: baselineAlgorithmVersion,
      experimentAlgorithmVersion: resolvedExperimentAlgorithmVersion,
      shadowAssessment: shadowAssessment,
      funnelComparison: funnelComparison,
      recommendation: recommendation,
      reasons: [
        ...configuration.reasons,
        ...integrityReasons,
        if (shadowAssessment != null) ...shadowAssessment.reasons,
        if (funnelComparison != null) ...funnelComparison.reasons,
      ],
    );
  }

  Future<RecommendationCanaryConfigurationInspection> _inspectConfiguration(
    DateTime inspectedAt,
  ) async {
    try {
      return await _configurationInspector();
    } catch (_) {
      return RecommendationCanaryConfigurationInspection(
        state: RecommendationCanaryConfigurationState.unavailable,
        inspectedAt: inspectedAt,
        reasons: const ['canary_configuration_read_failed'],
      );
    }
  }

  RecommendationCanaryOperationsRecommendation _recommend({
    required RecommendationCanaryConfigurationInspection configuration,
    required RecommendationShadowCanaryAssessment? shadowAssessment,
    required RecommendationAlgorithmComparison? funnelComparison,
    required bool hasIntegrityFailure,
  }) {
    if (hasIntegrityFailure ||
        _requiresManualReview(configuration.state) ||
        shadowAssessment == null ||
        funnelComparison == null) {
      return RecommendationCanaryOperationsRecommendation.manualReview;
    }

    final active = configuration.hasActiveConfiguration;
    if (shadowAssessment.verdict !=
        RecommendationShadowCanaryVerdict.eligibleForCanary) {
      if (active) {
        return RecommendationCanaryOperationsRecommendation.stopCanary;
      }
      return shadowAssessment.verdict ==
              RecommendationShadowCanaryVerdict.insufficientData
          ? RecommendationCanaryOperationsRecommendation.collectShadowData
          : RecommendationCanaryOperationsRecommendation.keepDisabled;
    }

    if (funnelComparison.verdict == RecommendationAlgorithmVerdict.regression) {
      return active
          ? RecommendationCanaryOperationsRecommendation.stopCanary
          : RecommendationCanaryOperationsRecommendation.keepDisabled;
    }
    if (!active) {
      return RecommendationCanaryOperationsRecommendation
          .eligibleForManualCanary;
    }
    return switch (funnelComparison.verdict) {
      RecommendationAlgorithmVerdict.insufficientData =>
        RecommendationCanaryOperationsRecommendation.continueCanarySampling,
      RecommendationAlgorithmVerdict.neutral =>
        RecommendationCanaryOperationsRecommendation.maintainCanary,
      RecommendationAlgorithmVerdict.promising =>
        RecommendationCanaryOperationsRecommendation.considerManualExpansion,
      RecommendationAlgorithmVerdict.regression =>
        RecommendationCanaryOperationsRecommendation.stopCanary,
    };
  }

  bool _requiresManualReview(RecommendationCanaryConfigurationState state) {
    return switch (state) {
      RecommendationCanaryConfigurationState.absent ||
      RecommendationCanaryConfigurationState.active ||
      RecommendationCanaryConfigurationState.expired =>
        false,
      RecommendationCanaryConfigurationState.scheduled ||
      RecommendationCanaryConfigurationState.invalid ||
      RecommendationCanaryConfigurationState.incompatibleBaseline ||
      RecommendationCanaryConfigurationState.forcedDisabled ||
      RecommendationCanaryConfigurationState.unavailable =>
        true,
    };
  }

  List<String> _configurationIntegrityReasons(
    RecommendationCanaryConfigurationInspection inspection,
  ) {
    final config = inspection.config;
    final state = inspection.state;
    final requiresConfig = switch (state) {
      RecommendationCanaryConfigurationState.active ||
      RecommendationCanaryConfigurationState.scheduled ||
      RecommendationCanaryConfigurationState.expired ||
      RecommendationCanaryConfigurationState.incompatibleBaseline ||
      RecommendationCanaryConfigurationState.forcedDisabled =>
        true,
      RecommendationCanaryConfigurationState.absent ||
      RecommendationCanaryConfigurationState.invalid ||
      RecommendationCanaryConfigurationState.unavailable =>
        false,
    };
    return [
      if (requiresConfig && config == null)
        'canary_configuration_details_missing',
      if (!requiresConfig && config != null)
        'canary_configuration_state_conflict',
      if (config != null &&
          (config.baselineRankingVersion != baselineRankingVersion ||
              config.baselineAlgorithmVersion != baselineAlgorithmVersion))
        'canary_configuration_baseline_mismatch',
      if (config != null &&
          state == RecommendationCanaryConfigurationState.active &&
          !config.isActiveAt(inspection.inspectedAt))
        'canary_configuration_time_state_conflict',
      if (config != null &&
          state == RecommendationCanaryConfigurationState.scheduled &&
          !config.activatedAt.isAfter(inspection.inspectedAt))
        'canary_configuration_time_state_conflict',
      if (config != null &&
          state == RecommendationCanaryConfigurationState.expired &&
          config.expiresAt.isAfter(inspection.inspectedAt))
        'canary_configuration_time_state_conflict',
    ];
  }

  void _validateVersion(String version, String argumentName) {
    if (!_safeVersion.hasMatch(version)) {
      throw ArgumentError.value(version, argumentName, 'Invalid version.');
    }
  }

  static final RegExp _safeVersion = RegExp(r'^[a-zA-Z0-9_.-]{1,64}$');
}
