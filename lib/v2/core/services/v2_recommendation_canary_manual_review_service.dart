import 'package:eatwhat_app/v2/core/data/models/recommendation_canary_manifest.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_manifest_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_operations_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_service.dart';

typedef V2CanaryStagedManifestInspector
    = Future<RecommendationCanaryStagedManifestInspection> Function();
typedef V2CanaryReviewConfigurationInspector
    = Future<RecommendationCanaryConfigurationInspection> Function();
typedef V2CanaryOperationsReportLoader
    = Future<RecommendationCanaryOperationsReport> Function({
  required String experimentRankingVersion,
  required String experimentAlgorithmVersion,
});

enum RecommendationCanaryManualReviewRecommendation {
  noPendingManifest,
  rejectManifest,
  keepDisabled,
  collectShadowData,
  candidateForManualActivation,
  continueCurrentCanary,
  candidateForManualExpansion,
  candidateForManualReduction,
  candidateForManualDeactivation,
  manualReview,
}

class RecommendationCanaryManualReviewReport {
  RecommendationCanaryManualReviewReport({
    required this.generatedAt,
    required this.stagedManifest,
    required this.recommendation,
    required List<String> reasons,
    this.operationsReport,
  }) : reasons = List.unmodifiable(reasons);

  final DateTime generatedAt;
  final RecommendationCanaryStagedManifestInspection stagedManifest;
  final RecommendationCanaryOperationsReport? operationsReport;
  final RecommendationCanaryManualReviewRecommendation recommendation;
  final List<String> reasons;

  bool get authorizesAutomaticActivation => false;
  bool get authorizesAutomaticExpansion => false;
  bool get authorizesAutomaticDeactivation => false;
  bool get authorizesAutomaticFullRollout => false;

  Map<String, Object?> toJson() {
    final manifest = stagedManifest.manifest;
    return {
      'generated_at': generatedAt.toUtc().toIso8601String(),
      'staged_manifest': {
        'state': stagedManifest.state.name,
        'has_pending_manual_review': stagedManifest.hasPendingManualReview,
        if (stagedManifest.acceptedAt != null)
          'accepted_at': stagedManifest.acceptedAt!.toUtc().toIso8601String(),
        if (stagedManifest.payloadDigest != null)
          'payload_digest': stagedManifest.payloadDigest,
        if (manifest != null) ...{
          'revision': manifest.revision,
          'directive': manifest.directive.name,
          'issued_at': manifest.issuedAt.toUtc().toIso8601String(),
          'expires_at': manifest.expiresAt.toUtc().toIso8601String(),
          'rollout_basis_points': manifest.rolloutBasisPoints,
          'rollout_percent': manifest.rolloutBasisPoints / 100,
          'baseline_ranking_version': manifest.baselineRankingVersion,
          'experiment_ranking_version': manifest.experimentRankingVersion,
          'baseline_algorithm_version': manifest.baselineAlgorithmVersion,
          'experiment_algorithm_version': manifest.experimentAlgorithmVersion,
        },
      },
      'operations': operationsReport?.toJson(),
      'recommendation': recommendation.name,
      'reasons': reasons,
      'authorizes_automatic_activation': false,
      'authorizes_automatic_expansion': false,
      'authorizes_automatic_deactivation': false,
      'authorizes_automatic_full_rollout': false,
    };
  }
}

class V2RecommendationCanaryManualReviewService {
  V2RecommendationCanaryManualReviewService({
    V2RecommendationCanaryManifestService? manifestService,
    V2CanaryStagedManifestInspector? stagedManifestInspector,
    V2RecommendationCanaryService? canaryService,
    V2CanaryReviewConfigurationInspector? configurationInspector,
    V2RecommendationCanaryOperationsService? operationsService,
    V2CanaryOperationsReportLoader? operationsReportLoader,
    DateTime Function()? clock,
    String? baselineRankingVersion,
    String? baselineAlgorithmVersion,
  })  : assert(canaryService == null || configurationInspector == null),
        assert(operationsService == null || operationsReportLoader == null),
        _stagedManifestInspector = _resolveStagedManifestInspector(
          manifestService,
          stagedManifestInspector,
        ),
        _configurationInspector = configurationInspector ??
            (canaryService ?? V2RecommendationCanaryService.instance)
                .inspectConfiguration,
        _operationsReportLoader = operationsReportLoader ??
            (operationsService ??
                    V2RecommendationCanaryOperationsService.instance)
                .buildReport,
        _clock = clock ?? DateTime.now,
        baselineRankingVersion = baselineRankingVersion ??
            canaryService?.baselineRankingVersion ??
            operationsService?.baselineRankingVersion ??
            'local_rank_v2',
        baselineAlgorithmVersion = baselineAlgorithmVersion ??
            canaryService?.baselineAlgorithmVersion ??
            operationsService?.baselineAlgorithmVersion ??
            'hybrid_v3_0';

  final V2CanaryStagedManifestInspector _stagedManifestInspector;
  final V2CanaryReviewConfigurationInspector _configurationInspector;
  final V2CanaryOperationsReportLoader _operationsReportLoader;
  final DateTime Function() _clock;
  final String baselineRankingVersion;
  final String baselineAlgorithmVersion;

  static V2CanaryStagedManifestInspector _resolveStagedManifestInspector(
    V2RecommendationCanaryManifestService? manifestService,
    V2CanaryStagedManifestInspector? inspector,
  ) {
    if ((manifestService == null) == (inspector == null)) {
      throw ArgumentError(
        'Provide exactly one manifest service or staged manifest inspector.',
      );
    }
    return inspector ?? manifestService!.inspectStagedManifest;
  }

  Future<RecommendationCanaryManualReviewReport> buildReview() async {
    final generatedAt = _clock().toUtc();
    final stagedManifest = await _inspectManifest();
    if (stagedManifest.state ==
        RecommendationCanaryStagedManifestState.absent) {
      return _report(
        generatedAt: generatedAt,
        stagedManifest: stagedManifest,
        recommendation:
            RecommendationCanaryManualReviewRecommendation.noPendingManifest,
        reasons: const ['canary_manifest_not_staged'],
      );
    }
    if (stagedManifest.state ==
        RecommendationCanaryStagedManifestState.reviewed) {
      return _report(
        generatedAt: generatedAt,
        stagedManifest: stagedManifest,
        recommendation:
            RecommendationCanaryManualReviewRecommendation.noPendingManifest,
        reasons: const ['canary_manifest_already_reviewed'],
      );
    }
    if (stagedManifest.state ==
            RecommendationCanaryStagedManifestState.invalid ||
        stagedManifest.state ==
            RecommendationCanaryStagedManifestState.expired) {
      return _report(
        generatedAt: generatedAt,
        stagedManifest: stagedManifest,
        recommendation:
            RecommendationCanaryManualReviewRecommendation.rejectManifest,
        reasons: ['canary_manifest_${stagedManifest.state.name}'],
      );
    }
    final manifest = stagedManifest.manifest;
    if (stagedManifest.state ==
            RecommendationCanaryStagedManifestState.unavailable ||
        manifest == null) {
      return _report(
        generatedAt: generatedAt,
        stagedManifest: stagedManifest,
        recommendation:
            RecommendationCanaryManualReviewRecommendation.manualReview,
        reasons: const ['canary_manifest_inspection_unavailable'],
      );
    }
    if (manifest.directive == RecommendationCanaryManifestDirective.disable) {
      return _reviewDisable(generatedAt, stagedManifest);
    }
    if (manifest.baselineRankingVersion != baselineRankingVersion ||
        manifest.baselineAlgorithmVersion != baselineAlgorithmVersion) {
      return _report(
        generatedAt: generatedAt,
        stagedManifest: stagedManifest,
        recommendation:
            RecommendationCanaryManualReviewRecommendation.rejectManifest,
        reasons: const ['canary_manifest_baseline_mismatch'],
      );
    }
    return _reviewCanaryProposal(generatedAt, stagedManifest, manifest);
  }

  Future<RecommendationCanaryManualReviewReport> _reviewDisable(
    DateTime generatedAt,
    RecommendationCanaryStagedManifestInspection stagedManifest,
  ) async {
    final configuration = await _inspectConfiguration();
    final manifest = stagedManifest.manifest!;
    final config = configuration.config;
    final targetsCurrentConfiguration = config != null &&
        config.baselineRankingVersion == manifest.baselineRankingVersion &&
        config.baselineAlgorithmVersion == manifest.baselineAlgorithmVersion &&
        config.experimentRankingVersion == manifest.experimentRankingVersion &&
        config.experimentAlgorithmVersion ==
            manifest.experimentAlgorithmVersion;
    return switch (configuration.state) {
      RecommendationCanaryConfigurationState.absent ||
      RecommendationCanaryConfigurationState.expired =>
        _report(
          generatedAt: generatedAt,
          stagedManifest: stagedManifest,
          recommendation:
              RecommendationCanaryManualReviewRecommendation.keepDisabled,
          reasons: [
            'signed_disable_manifest_received',
            ...configuration.reasons,
          ],
        ),
      RecommendationCanaryConfigurationState.active ||
      RecommendationCanaryConfigurationState.scheduled ||
      RecommendationCanaryConfigurationState.incompatibleBaseline ||
      RecommendationCanaryConfigurationState.forcedDisabled =>
        targetsCurrentConfiguration
            ? _report(
                generatedAt: generatedAt,
                stagedManifest: stagedManifest,
                recommendation: RecommendationCanaryManualReviewRecommendation
                    .candidateForManualDeactivation,
                reasons: [
                  'signed_disable_manifest_received',
                  ...configuration.reasons,
                ],
              )
            : _report(
                generatedAt: generatedAt,
                stagedManifest: stagedManifest,
                recommendation:
                    RecommendationCanaryManualReviewRecommendation.manualReview,
                reasons: const [
                  'canary_disable_manifest_configuration_version_mismatch',
                ],
              ),
      RecommendationCanaryConfigurationState.invalid ||
      RecommendationCanaryConfigurationState.unavailable =>
        _report(
          generatedAt: generatedAt,
          stagedManifest: stagedManifest,
          recommendation:
              RecommendationCanaryManualReviewRecommendation.manualReview,
          reasons: [
            'signed_disable_manifest_received',
            ...configuration.reasons,
          ],
        ),
    };
  }

  Future<RecommendationCanaryManualReviewReport> _reviewCanaryProposal(
    DateTime generatedAt,
    RecommendationCanaryStagedManifestInspection stagedManifest,
    RecommendationCanaryManifest manifest,
  ) async {
    RecommendationCanaryOperationsReport operationsReport;
    try {
      operationsReport = await _operationsReportLoader(
        experimentRankingVersion: manifest.experimentRankingVersion,
        experimentAlgorithmVersion: manifest.experimentAlgorithmVersion,
      );
    } catch (_) {
      return _report(
        generatedAt: generatedAt,
        stagedManifest: stagedManifest,
        recommendation:
            RecommendationCanaryManualReviewRecommendation.manualReview,
        reasons: const ['canary_operations_report_unavailable'],
      );
    }
    if (operationsReport.baselineRankingVersion != baselineRankingVersion ||
        operationsReport.baselineAlgorithmVersion != baselineAlgorithmVersion ||
        operationsReport.experimentRankingVersion !=
            manifest.experimentRankingVersion ||
        operationsReport.experimentAlgorithmVersion !=
            manifest.experimentAlgorithmVersion) {
      return _report(
        generatedAt: generatedAt,
        stagedManifest: stagedManifest,
        operationsReport: operationsReport,
        recommendation:
            RecommendationCanaryManualReviewRecommendation.manualReview,
        reasons: const ['canary_manifest_operations_version_mismatch'],
      );
    }
    final currentConfig = operationsReport.configuration.config;
    if (operationsReport.configuration.hasActiveConfiguration &&
        (currentConfig == null ||
            currentConfig.experimentRankingVersion !=
                manifest.experimentRankingVersion ||
            currentConfig.experimentAlgorithmVersion !=
                manifest.experimentAlgorithmVersion)) {
      return _report(
        generatedAt: generatedAt,
        stagedManifest: stagedManifest,
        operationsReport: operationsReport,
        recommendation:
            RecommendationCanaryManualReviewRecommendation.manualReview,
        reasons: const ['canary_manifest_conflicts_with_active_experiment'],
      );
    }

    final proposesReduction = currentConfig != null &&
        manifest.rolloutBasisPoints < currentConfig.rolloutBasisPoints;
    final recommendation = switch (operationsReport.recommendation) {
      RecommendationCanaryOperationsRecommendation.keepDisabled =>
        RecommendationCanaryManualReviewRecommendation.keepDisabled,
      RecommendationCanaryOperationsRecommendation.collectShadowData =>
        RecommendationCanaryManualReviewRecommendation.collectShadowData,
      RecommendationCanaryOperationsRecommendation.eligibleForManualCanary =>
        RecommendationCanaryManualReviewRecommendation
            .candidateForManualActivation,
      RecommendationCanaryOperationsRecommendation.continueCanarySampling ||
      RecommendationCanaryOperationsRecommendation.maintainCanary =>
        proposesReduction
            ? RecommendationCanaryManualReviewRecommendation
                .candidateForManualReduction
            : RecommendationCanaryManualReviewRecommendation
                .continueCurrentCanary,
      RecommendationCanaryOperationsRecommendation.considerManualExpansion =>
        proposesReduction
            ? RecommendationCanaryManualReviewRecommendation
                .candidateForManualReduction
            : currentConfig != null &&
                    manifest.rolloutBasisPoints >
                        currentConfig.rolloutBasisPoints
                ? RecommendationCanaryManualReviewRecommendation
                    .candidateForManualExpansion
                : RecommendationCanaryManualReviewRecommendation
                    .continueCurrentCanary,
      RecommendationCanaryOperationsRecommendation.stopCanary =>
        RecommendationCanaryManualReviewRecommendation
            .candidateForManualDeactivation,
      RecommendationCanaryOperationsRecommendation.manualReview =>
        RecommendationCanaryManualReviewRecommendation.manualReview,
    };
    return _report(
      generatedAt: generatedAt,
      stagedManifest: stagedManifest,
      operationsReport: operationsReport,
      recommendation: recommendation,
      reasons: [
        'signed_canary_proposal_received',
        ...operationsReport.reasons,
      ],
    );
  }

  Future<RecommendationCanaryStagedManifestInspection>
      _inspectManifest() async {
    try {
      return await _stagedManifestInspector();
    } catch (_) {
      return const RecommendationCanaryStagedManifestInspection(
        state: RecommendationCanaryStagedManifestState.unavailable,
      );
    }
  }

  Future<RecommendationCanaryConfigurationInspection>
      _inspectConfiguration() async {
    try {
      return await _configurationInspector();
    } catch (_) {
      return RecommendationCanaryConfigurationInspection(
        state: RecommendationCanaryConfigurationState.unavailable,
        inspectedAt: _clock(),
        reasons: const ['canary_configuration_read_failed'],
      );
    }
  }

  RecommendationCanaryManualReviewReport _report({
    required DateTime generatedAt,
    required RecommendationCanaryStagedManifestInspection stagedManifest,
    required RecommendationCanaryManualReviewRecommendation recommendation,
    required List<String> reasons,
    RecommendationCanaryOperationsReport? operationsReport,
  }) {
    return RecommendationCanaryManualReviewReport(
      generatedAt: generatedAt,
      stagedManifest: stagedManifest,
      operationsReport: operationsReport,
      recommendation: recommendation,
      reasons: reasons,
    );
  }
}
