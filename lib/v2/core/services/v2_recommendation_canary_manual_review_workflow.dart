import 'dart:convert';

import 'package:eatwhat_app/v2/core/data/models/recommendation_canary_manifest.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_manifest_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_manual_review_service.dart';

typedef V2CanaryManualReviewReportLoader
    = Future<RecommendationCanaryManualReviewReport> Function();
typedef V2CanaryManualReviewAcknowledger
    = Future<RecommendationCanaryManifestAcknowledgementResult> Function({
  required int revision,
  required String payloadDigest,
});

enum RecommendationCanaryManualReviewWorkflowState {
  noPendingReview,
  challengeReady,
  manifestRejected,
  manualInvestigationRequired,
  inputInvalid,
  challengeChanged,
  expired,
  acknowledged,
  alreadyAcknowledged,
  storageUnavailable,
  workflowUnavailable,
}

class RecommendationCanaryManualReviewChallenge {
  RecommendationCanaryManualReviewChallenge._({
    required this.revision,
    required this.payloadDigest,
    required this.expiresAt,
    required this.directive,
    required this.rolloutBasisPoints,
    required this.baselineRankingVersion,
    required this.experimentRankingVersion,
    required this.baselineAlgorithmVersion,
    required this.experimentAlgorithmVersion,
    required this.recommendation,
    required List<String> reasons,
  }) : reasons = List.unmodifiable(reasons);

  final int revision;
  final String payloadDigest;
  final DateTime expiresAt;
  final RecommendationCanaryManifestDirective directive;
  final int rolloutBasisPoints;
  final String baselineRankingVersion;
  final String experimentRankingVersion;
  final String baselineAlgorithmVersion;
  final String experimentAlgorithmVersion;
  final RecommendationCanaryManualReviewRecommendation recommendation;
  final List<String> reasons;

  bool get authorizesAutomaticActivation => false;
  bool get authorizesAutomaticExpansion => false;
  bool get authorizesAutomaticReduction => false;
  bool get authorizesAutomaticDeactivation => false;
  bool get authorizesAutomaticFullRollout => false;
  bool get authorizesRecommendationExecution => false;

  Map<String, Object> toJson() {
    return {
      'revision': revision,
      'payload_digest': payloadDigest,
      'expires_at': expiresAt.toUtc().toIso8601String(),
      'directive': directive.name,
      'rollout_basis_points': rolloutBasisPoints,
      'baseline_ranking_version': baselineRankingVersion,
      'experiment_ranking_version': experimentRankingVersion,
      'baseline_algorithm_version': baselineAlgorithmVersion,
      'experiment_algorithm_version': experimentAlgorithmVersion,
      'recommendation': recommendation.name,
      'reasons': reasons,
    };
  }

  bool hasSameContentAs(
    RecommendationCanaryManualReviewChallenge other,
  ) {
    return revision == other.revision &&
        payloadDigest == other.payloadDigest &&
        expiresAt.toUtc() == other.expiresAt.toUtc() &&
        directive == other.directive &&
        rolloutBasisPoints == other.rolloutBasisPoints &&
        baselineRankingVersion == other.baselineRankingVersion &&
        experimentRankingVersion == other.experimentRankingVersion &&
        baselineAlgorithmVersion == other.baselineAlgorithmVersion &&
        experimentAlgorithmVersion == other.experimentAlgorithmVersion &&
        recommendation == other.recommendation &&
        _sameStrings(reasons, other.reasons);
  }

  static bool _sameStrings(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}

class RecommendationCanaryManualReviewWorkflowResult {
  const RecommendationCanaryManualReviewWorkflowResult({
    required this.state,
    required this.reason,
    this.challenge,
    this.acknowledgement,
  });

  final RecommendationCanaryManualReviewWorkflowState state;
  final String reason;
  final RecommendationCanaryManualReviewChallenge? challenge;
  final RecommendationCanaryManifestAcknowledgementResult? acknowledgement;

  bool get authorizesAutomaticActivation => false;
  bool get authorizesAutomaticExpansion => false;
  bool get authorizesAutomaticReduction => false;
  bool get authorizesAutomaticDeactivation => false;
  bool get authorizesAutomaticFullRollout => false;
  bool get authorizesRecommendationExecution => false;

  Map<String, Object?> toJson() {
    return {
      'state': state.name,
      'reason': reason,
      if (challenge != null) 'challenge': challenge!.toJson(),
      if (acknowledgement != null) ...{
        'acknowledgement_state': acknowledgement!.state.name,
        'acknowledgement_reason': acknowledgement!.reason,
      },
      'authorizes_automatic_activation': false,
      'authorizes_automatic_expansion': false,
      'authorizes_automatic_reduction': false,
      'authorizes_automatic_deactivation': false,
      'authorizes_automatic_full_rollout': false,
      'authorizes_recommendation_execution': false,
    };
  }
}

class V2RecommendationCanaryManualReviewWorkflow {
  V2RecommendationCanaryManualReviewWorkflow({
    required V2CanaryManualReviewReportLoader reviewLoader,
    required V2CanaryManualReviewAcknowledger acknowledgeManualReview,
    DateTime Function()? clock,
  })  : _reviewLoader = reviewLoader,
        _acknowledgeManualReview = acknowledgeManualReview,
        _clock = clock ?? DateTime.now;

  final V2CanaryManualReviewReportLoader _reviewLoader;
  final V2CanaryManualReviewAcknowledger _acknowledgeManualReview;
  final DateTime Function() _clock;
  final Map<String, Future<RecommendationCanaryManualReviewWorkflowResult>>
      _inFlightAcknowledgements = {};
  Future<void> _pendingAcknowledgement = Future<void>.value();

  Future<RecommendationCanaryManualReviewWorkflowResult> loadChallenge() async {
    RecommendationCanaryManualReviewReport report;
    DateTime now;
    try {
      report = await _reviewLoader();
      now = _clock().toUtc();
    } catch (_) {
      return _result(
        RecommendationCanaryManualReviewWorkflowState.workflowUnavailable,
        'canary_manual_review_report_unavailable',
      );
    }
    return _resultFromReport(report, now: now);
  }

  Future<RecommendationCanaryManualReviewWorkflowResult> acknowledgeReview({
    required RecommendationCanaryManualReviewChallenge expectedChallenge,
    required String operatorRevision,
    required String operatorPayloadDigest,
  }) {
    final requestKey = jsonEncode([
      expectedChallenge.toJson(),
      operatorRevision,
      operatorPayloadDigest,
    ]);
    final inFlight = _inFlightAcknowledgements[requestKey];
    if (inFlight != null) return inFlight;

    final operation = _enqueueAcknowledgement(
      () => _acknowledgeReview(
        expectedChallenge: expectedChallenge,
        operatorRevision: operatorRevision,
        operatorPayloadDigest: operatorPayloadDigest,
      ),
    );
    _inFlightAcknowledgements[requestKey] = operation;
    return operation.whenComplete(() {
      if (identical(_inFlightAcknowledgements[requestKey], operation)) {
        _inFlightAcknowledgements.remove(requestKey);
      }
    });
  }

  Future<RecommendationCanaryManualReviewWorkflowResult> _acknowledgeReview({
    required RecommendationCanaryManualReviewChallenge expectedChallenge,
    required String operatorRevision,
    required String operatorPayloadDigest,
  }) async {
    final parsedRevision = _parseOperatorRevision(operatorRevision);
    if (parsedRevision == null ||
        !_safeDigest.hasMatch(operatorPayloadDigest) ||
        parsedRevision != expectedChallenge.revision ||
        operatorPayloadDigest != expectedChallenge.payloadDigest) {
      return _result(
        RecommendationCanaryManualReviewWorkflowState.inputInvalid,
        'canary_manual_review_operator_input_invalid',
      );
    }

    final refreshed = await loadChallenge();
    final refreshedChallenge = refreshed.challenge;
    if (refreshedChallenge == null) {
      return switch (refreshed.state) {
        RecommendationCanaryManualReviewWorkflowState.noPendingReview =>
          _result(
            RecommendationCanaryManualReviewWorkflowState.challengeChanged,
            'canary_manual_review_challenge_no_longer_staged',
          ),
        _ => refreshed,
      };
    }
    if (!expectedChallenge.hasSameContentAs(refreshedChallenge)) {
      return _result(
        RecommendationCanaryManualReviewWorkflowState.challengeChanged,
        'canary_manual_review_challenge_changed',
      );
    }

    RecommendationCanaryManifestAcknowledgementResult acknowledgement;
    try {
      acknowledgement = await _acknowledgeManualReview(
        revision: parsedRevision,
        payloadDigest: operatorPayloadDigest,
      );
    } catch (_) {
      return _result(
        RecommendationCanaryManualReviewWorkflowState.storageUnavailable,
        'canary_manual_review_acknowledgement_unavailable',
      );
    }
    return _resultFromAcknowledgement(acknowledgement);
  }

  RecommendationCanaryManualReviewWorkflowResult _resultFromReport(
    RecommendationCanaryManualReviewReport report, {
    required DateTime now,
  }) {
    final staged = report.stagedManifest;
    switch (staged.state) {
      case RecommendationCanaryStagedManifestState.absent:
        return _result(
          RecommendationCanaryManualReviewWorkflowState.noPendingReview,
          'canary_manual_review_not_pending',
        );
      case RecommendationCanaryStagedManifestState.reviewed:
        return _result(
          RecommendationCanaryManualReviewWorkflowState.alreadyAcknowledged,
          'canary_manual_review_already_acknowledged',
        );
      case RecommendationCanaryStagedManifestState.expired:
        return _result(
          RecommendationCanaryManualReviewWorkflowState.expired,
          'canary_manual_review_manifest_expired',
        );
      case RecommendationCanaryStagedManifestState.invalid:
        return _result(
          RecommendationCanaryManualReviewWorkflowState.manifestRejected,
          'canary_manual_review_manifest_invalid',
        );
      case RecommendationCanaryStagedManifestState.unavailable:
        return _result(
          RecommendationCanaryManualReviewWorkflowState
              .manualInvestigationRequired,
          'canary_manual_review_manifest_unavailable',
        );
      case RecommendationCanaryStagedManifestState.staged:
        break;
    }

    if (report.recommendation ==
        RecommendationCanaryManualReviewRecommendation.rejectManifest) {
      return _result(
        RecommendationCanaryManualReviewWorkflowState.manifestRejected,
        'canary_manual_review_recommendation_rejected',
      );
    }
    if (report.recommendation ==
        RecommendationCanaryManualReviewRecommendation.manualReview) {
      return _result(
        RecommendationCanaryManualReviewWorkflowState
            .manualInvestigationRequired,
        'canary_manual_review_investigation_required',
      );
    }
    if (report.recommendation ==
        RecommendationCanaryManualReviewRecommendation.noPendingManifest) {
      return _result(
        RecommendationCanaryManualReviewWorkflowState.workflowUnavailable,
        'canary_manual_review_report_inconsistent',
      );
    }

    final manifest = staged.manifest;
    final digest = staged.payloadDigest;
    if (manifest == null || digest == null) {
      return _result(
        RecommendationCanaryManualReviewWorkflowState.workflowUnavailable,
        'canary_manual_review_challenge_incomplete',
      );
    }
    if (!manifest.expiresAt.isAfter(now)) {
      return _result(
        RecommendationCanaryManualReviewWorkflowState.expired,
        'canary_manual_review_manifest_expired',
      );
    }
    if (!_isSafeChallenge(manifest, digest, report.reasons)) {
      return _result(
        RecommendationCanaryManualReviewWorkflowState
            .manualInvestigationRequired,
        'canary_manual_review_challenge_invalid',
      );
    }

    return _result(
      RecommendationCanaryManualReviewWorkflowState.challengeReady,
      'canary_manual_review_challenge_ready',
      challenge: RecommendationCanaryManualReviewChallenge._(
        revision: manifest.revision,
        payloadDigest: digest,
        expiresAt: manifest.expiresAt.toUtc(),
        directive: manifest.directive,
        rolloutBasisPoints: manifest.rolloutBasisPoints,
        baselineRankingVersion: manifest.baselineRankingVersion,
        experimentRankingVersion: manifest.experimentRankingVersion,
        baselineAlgorithmVersion: manifest.baselineAlgorithmVersion,
        experimentAlgorithmVersion: manifest.experimentAlgorithmVersion,
        recommendation: report.recommendation,
        reasons: report.reasons,
      ),
    );
  }

  RecommendationCanaryManualReviewWorkflowResult _resultFromAcknowledgement(
    RecommendationCanaryManifestAcknowledgementResult acknowledgement,
  ) {
    final state = switch (acknowledgement.state) {
      RecommendationCanaryManifestAcknowledgementState.acknowledged =>
        RecommendationCanaryManualReviewWorkflowState.acknowledged,
      RecommendationCanaryManifestAcknowledgementState.alreadyAcknowledged =>
        RecommendationCanaryManualReviewWorkflowState.alreadyAcknowledged,
      RecommendationCanaryManifestAcknowledgementState.expired =>
        RecommendationCanaryManualReviewWorkflowState.expired,
      RecommendationCanaryManifestAcknowledgementState.stagedStateInvalid =>
        RecommendationCanaryManualReviewWorkflowState.manifestRejected,
      RecommendationCanaryManifestAcknowledgementState.storageUnavailable =>
        RecommendationCanaryManualReviewWorkflowState.storageUnavailable,
      RecommendationCanaryManifestAcknowledgementState.noStagedManifest ||
      RecommendationCanaryManifestAcknowledgementState.tokenMismatch =>
        RecommendationCanaryManualReviewWorkflowState.challengeChanged,
    };
    return _result(
      state,
      acknowledgement.reason,
      acknowledgement: acknowledgement,
    );
  }

  Future<RecommendationCanaryManualReviewWorkflowResult>
      _enqueueAcknowledgement(
    Future<RecommendationCanaryManualReviewWorkflowResult> Function() operation,
  ) {
    final result = _pendingAcknowledgement.then((_) => operation());
    _pendingAcknowledgement = result.then<void>(
      (_) {},
      onError: (_, __) {},
    );
    return result;
  }

  static int? _parseOperatorRevision(String raw) {
    if (!_safeRevision.hasMatch(raw)) return null;
    final parsed = int.tryParse(raw);
    if (parsed == null ||
        parsed <= 0 ||
        parsed > RecommendationCanaryManifest.maximumSafeRevision ||
        parsed.toString() != raw) {
      return null;
    }
    return parsed;
  }

  static bool _isSafeChallenge(
    RecommendationCanaryManifest manifest,
    String digest,
    List<String> reasons,
  ) {
    final rolloutIsValid = switch (manifest.directive) {
      RecommendationCanaryManifestDirective.proposeControlledCanary =>
        manifest.rolloutBasisPoints > 0 &&
            manifest.rolloutBasisPoints <=
                RecommendationCanaryManifest.maximumRolloutBasisPoints,
      RecommendationCanaryManifestDirective.disable =>
        manifest.rolloutBasisPoints == 0,
    };
    return manifest.revision > 0 &&
        manifest.revision <= RecommendationCanaryManifest.maximumSafeRevision &&
        _safeDigest.hasMatch(digest) &&
        rolloutIsValid &&
        _safeVersion.hasMatch(manifest.baselineRankingVersion) &&
        _safeVersion.hasMatch(manifest.experimentRankingVersion) &&
        _safeVersion.hasMatch(manifest.baselineAlgorithmVersion) &&
        _safeVersion.hasMatch(manifest.experimentAlgorithmVersion) &&
        reasons.isNotEmpty &&
        reasons.length <= 64 &&
        reasons.every(_safeReason.hasMatch);
  }

  static RecommendationCanaryManualReviewWorkflowResult _result(
    RecommendationCanaryManualReviewWorkflowState state,
    String reason, {
    RecommendationCanaryManualReviewChallenge? challenge,
    RecommendationCanaryManifestAcknowledgementResult? acknowledgement,
  }) {
    return RecommendationCanaryManualReviewWorkflowResult(
      state: state,
      reason: reason,
      challenge: challenge,
      acknowledgement: acknowledgement,
    );
  }

  static final RegExp _safeRevision = RegExp(r'^[1-9][0-9]{0,15}$');
  static final RegExp _safeDigest = RegExp(r'^[0-9a-f]{64}$');
  static final RegExp _safeVersion = RegExp(r'^[a-zA-Z0-9_.-]{1,64}$');
  static final RegExp _safeReason = RegExp(r'^[a-z0-9_.:-]{1,160}$');
}
