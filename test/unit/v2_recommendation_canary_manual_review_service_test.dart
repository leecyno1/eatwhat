import 'dart:convert';

import 'package:eatwhat_app/v2/core/data/models/recommendation_canary_config.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_canary_manifest.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_manifest_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_manual_review_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_operations_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_funnel_insights.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_shadow_insights.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('无暂存清单、过期和损坏清单不会进入运营评估', () async {
    final cases = <(
      RecommendationCanaryStagedManifestState,
      RecommendationCanaryManualReviewRecommendation
    )>[
      (
        RecommendationCanaryStagedManifestState.absent,
        RecommendationCanaryManualReviewRecommendation.noPendingManifest,
      ),
      (
        RecommendationCanaryStagedManifestState.reviewed,
        RecommendationCanaryManualReviewRecommendation.noPendingManifest,
      ),
      (
        RecommendationCanaryStagedManifestState.expired,
        RecommendationCanaryManualReviewRecommendation.rejectManifest,
      ),
      (
        RecommendationCanaryStagedManifestState.invalid,
        RecommendationCanaryManualReviewRecommendation.rejectManifest,
      ),
    ];
    for (final testCase in cases) {
      var operationsCalls = 0;
      final service = _service(
        staged: _staged(testCase.$1),
        operationsLoader: ({
          required experimentRankingVersion,
          required experimentAlgorithmVersion,
        }) async {
          operationsCalls += 1;
          return _operations(
            RecommendationCanaryOperationsRecommendation
                .eligibleForManualCanary,
          );
        },
      );

      final report = await service.buildReview();

      expect(report.recommendation, testCase.$2);
      expect(operationsCalls, 0);
      _expectNoAutomaticAuthority(report);
    }
  });

  test('签名停用清单只生成停止或保持关闭建议且不读取漏斗报告', () async {
    final cases = <(
      RecommendationCanaryConfigurationState,
      RecommendationCanaryManualReviewRecommendation
    )>[
      (
        RecommendationCanaryConfigurationState.absent,
        RecommendationCanaryManualReviewRecommendation.keepDisabled,
      ),
      (
        RecommendationCanaryConfigurationState.active,
        RecommendationCanaryManualReviewRecommendation
            .candidateForManualDeactivation,
      ),
      (
        RecommendationCanaryConfigurationState.invalid,
        RecommendationCanaryManualReviewRecommendation.manualReview,
      ),
    ];
    for (final testCase in cases) {
      var operationsCalls = 0;
      final service = _service(
        staged: _staged(
          RecommendationCanaryStagedManifestState.staged,
          manifest: _manifest(
            directive: RecommendationCanaryManifestDirective.disable,
            rolloutBasisPoints: 0,
          ),
        ),
        configuration: _configuration(
          testCase.$1,
          config: testCase.$1 == RecommendationCanaryConfigurationState.active
              ? _config()
              : null,
        ),
        operationsLoader: ({
          required experimentRankingVersion,
          required experimentAlgorithmVersion,
        }) async {
          operationsCalls += 1;
          return _operations(
            RecommendationCanaryOperationsRecommendation.manualReview,
          );
        },
      );

      final report = await service.buildReview();

      expect(report.recommendation, testCase.$2);
      expect(operationsCalls, 0);
      _expectNoAutomaticAuthority(report);
    }
  });

  test('停用清单与当前实验版本不一致时只进入人工核查', () async {
    final report = await _service(
      staged: _staged(
        RecommendationCanaryStagedManifestState.staged,
        manifest: _manifest(
          directive: RecommendationCanaryManifestDirective.disable,
          rolloutBasisPoints: 0,
        ),
      ),
      configuration: _configuration(
        RecommendationCanaryConfigurationState.active,
        config: _config(experimentRankingVersion: 'other_experiment'),
      ),
      operationsLoader: ({
        required experimentRankingVersion,
        required experimentAlgorithmVersion,
      }) async =>
          throw StateError('must not load operations'),
    ).buildReview();

    expect(
      report.recommendation,
      RecommendationCanaryManualReviewRecommendation.manualReview,
    );
    expect(
      report.reasons,
      contains('canary_disable_manifest_configuration_version_mismatch'),
    );
    _expectNoAutomaticAuthority(report);
  });

  test('可信提案按运营结论映射为人工开启、继续、扩量或停用候选', () async {
    final cases = <(
      RecommendationCanaryOperationsRecommendation,
      RecommendationCanaryConfigurationInspection,
      int,
      RecommendationCanaryManualReviewRecommendation
    )>[
      (
        RecommendationCanaryOperationsRecommendation.eligibleForManualCanary,
        _configuration(RecommendationCanaryConfigurationState.absent),
        500,
        RecommendationCanaryManualReviewRecommendation
            .candidateForManualActivation,
      ),
      (
        RecommendationCanaryOperationsRecommendation.continueCanarySampling,
        _configuration(
          RecommendationCanaryConfigurationState.active,
          config: _config(),
        ),
        500,
        RecommendationCanaryManualReviewRecommendation.continueCurrentCanary,
      ),
      (
        RecommendationCanaryOperationsRecommendation.considerManualExpansion,
        _configuration(
          RecommendationCanaryConfigurationState.active,
          config: _config(rolloutBasisPoints: 300),
        ),
        500,
        RecommendationCanaryManualReviewRecommendation
            .candidateForManualExpansion,
      ),
      (
        RecommendationCanaryOperationsRecommendation.stopCanary,
        _configuration(
          RecommendationCanaryConfigurationState.active,
          config: _config(),
        ),
        500,
        RecommendationCanaryManualReviewRecommendation
            .candidateForManualDeactivation,
      ),
    ];
    for (final testCase in cases) {
      final report = await _service(
        staged: _staged(
          RecommendationCanaryStagedManifestState.staged,
          manifest: _manifest(rolloutBasisPoints: testCase.$3),
        ),
        configuration: testCase.$2,
        operationsLoader: ({
          required experimentRankingVersion,
          required experimentAlgorithmVersion,
        }) async =>
            _operations(
          testCase.$1,
          configuration: testCase.$2,
        ),
      ).buildReview();

      expect(report.recommendation, testCase.$4, reason: testCase.$1.name);
      _expectNoAutomaticAuthority(report);
    }
  });

  test('低于当前比例的可信提案明确标记为人工缩量候选', () async {
    final configuration = _configuration(
      RecommendationCanaryConfigurationState.active,
      config: _config(),
    );
    final report = await _service(
      staged: _staged(
        RecommendationCanaryStagedManifestState.staged,
        manifest: _manifest(rolloutBasisPoints: 300),
      ),
      configuration: configuration,
      operationsLoader: ({
        required experimentRankingVersion,
        required experimentAlgorithmVersion,
      }) async =>
          _operations(
        RecommendationCanaryOperationsRecommendation.maintainCanary,
        configuration: configuration,
      ),
    ).buildReview();

    expect(
      report.recommendation,
      RecommendationCanaryManualReviewRecommendation
          .candidateForManualReduction,
    );
    _expectNoAutomaticAuthority(report);
  });

  test('真实回归或完整性异常优先于清单中的缩量提案', () async {
    final configuration = _configuration(
      RecommendationCanaryConfigurationState.active,
      config: _config(),
    );
    final cases = <(
      RecommendationCanaryOperationsRecommendation,
      RecommendationCanaryManualReviewRecommendation
    )>[
      (
        RecommendationCanaryOperationsRecommendation.stopCanary,
        RecommendationCanaryManualReviewRecommendation
            .candidateForManualDeactivation,
      ),
      (
        RecommendationCanaryOperationsRecommendation.manualReview,
        RecommendationCanaryManualReviewRecommendation.manualReview,
      ),
    ];
    for (final testCase in cases) {
      final report = await _service(
        staged: _staged(
          RecommendationCanaryStagedManifestState.staged,
          manifest: _manifest(rolloutBasisPoints: 300),
        ),
        configuration: configuration,
        operationsLoader: ({
          required experimentRankingVersion,
          required experimentAlgorithmVersion,
        }) async =>
            _operations(
          testCase.$1,
          configuration: configuration,
        ),
      ).buildReview();

      expect(report.recommendation, testCase.$2);
      _expectNoAutomaticAuthority(report);
    }
  });

  test('基线、实验版本冲突或运营报告异常均不会形成执行候选', () async {
    final baselineMismatch = await _service(
      staged: _staged(
        RecommendationCanaryStagedManifestState.staged,
        manifest: _manifest(baselineRankingVersion: 'stale_ranker'),
      ),
    ).buildReview();
    expect(
      baselineMismatch.recommendation,
      RecommendationCanaryManualReviewRecommendation.rejectManifest,
    );

    final experimentConflictConfiguration = _configuration(
      RecommendationCanaryConfigurationState.active,
      config: _config(experimentRankingVersion: 'other_experiment'),
    );
    final experimentConflict = await _service(
      staged: _staged(
        RecommendationCanaryStagedManifestState.staged,
        manifest: _manifest(),
      ),
      configuration: experimentConflictConfiguration,
      operationsLoader: ({
        required experimentRankingVersion,
        required experimentAlgorithmVersion,
      }) async =>
          _operations(
        RecommendationCanaryOperationsRecommendation.maintainCanary,
        configuration: experimentConflictConfiguration,
      ),
    ).buildReview();
    expect(
      experimentConflict.recommendation,
      RecommendationCanaryManualReviewRecommendation.manualReview,
    );

    final unavailable = await _service(
      staged: _staged(
        RecommendationCanaryStagedManifestState.staged,
        manifest: _manifest(),
      ),
      operationsLoader: ({
        required experimentRankingVersion,
        required experimentAlgorithmVersion,
      }) async =>
          throw StateError('operations unavailable'),
    ).buildReview();
    expect(
      unavailable.recommendation,
      RecommendationCanaryManualReviewRecommendation.manualReview,
    );
    _expectNoAutomaticAuthority(baselineMismatch);
    _expectNoAutomaticAuthority(experimentConflict);
    _expectNoAutomaticAuthority(unavailable);
  });

  test('审核报告只包含版本、汇总和摘要，不包含用户或请求内容', () async {
    final report = await _service(
      staged: _staged(
        RecommendationCanaryStagedManifestState.staged,
        manifest: _manifest(),
      ),
    ).buildReview();

    final json = report.toJson();
    expect(json['recommendation'], 'candidateForManualActivation');
    expect(
      (json['staged_manifest'] as Map)['rollout_percent'],
      5,
    );
    final encoded = jsonEncode(json);
    for (final forbidden in [
      'installation_key',
      'user_id',
      'session_id',
      'request_text',
      'dish',
    ]) {
      expect(encoded, isNot(contains(forbidden)));
    }
    _expectNoAutomaticAuthority(report);
  });
}

V2RecommendationCanaryManualReviewService _service({
  required RecommendationCanaryStagedManifestInspection staged,
  RecommendationCanaryConfigurationInspection? configuration,
  V2CanaryOperationsReportLoader? operationsLoader,
}) {
  return V2RecommendationCanaryManualReviewService(
    stagedManifestInspector: () async => staged,
    configurationInspector: () async =>
        configuration ??
        _configuration(RecommendationCanaryConfigurationState.absent),
    operationsReportLoader: operationsLoader ??
        ({
          required experimentRankingVersion,
          required experimentAlgorithmVersion,
        }) async =>
            _operations(
              RecommendationCanaryOperationsRecommendation
                  .eligibleForManualCanary,
            ),
    clock: () => DateTime.utc(2026, 8, 5, 9),
  );
}

RecommendationCanaryStagedManifestInspection _staged(
  RecommendationCanaryStagedManifestState state, {
  RecommendationCanaryManifest? manifest,
}) {
  return RecommendationCanaryStagedManifestInspection(
    state: state,
    manifest: manifest,
    acceptedAt: manifest == null ? null : DateTime.utc(2026, 8, 5, 8, 30),
    payloadDigest: manifest == null ? null : 'a' * 64,
  );
}

RecommendationCanaryManifest _manifest({
  RecommendationCanaryManifestDirective directive =
      RecommendationCanaryManifestDirective.proposeControlledCanary,
  int rolloutBasisPoints = 500,
  String baselineRankingVersion = 'local_rank_v2',
}) {
  return RecommendationCanaryManifest(
    schemaVersion: RecommendationCanaryManifest.supportedSchemaVersion,
    revision: 7,
    audience: 'com.eatwhat.eatwhatApp',
    environment: 'production',
    directive: directive,
    issuedAt: DateTime.utc(2026, 8, 5, 8),
    expiresAt: DateTime.utc(2026, 8, 6, 8),
    baselineRankingVersion: baselineRankingVersion,
    experimentRankingVersion: 'local_rank_v3_quality_shadow',
    baselineAlgorithmVersion: 'hybrid_v3_0',
    experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
    rolloutBasisPoints: rolloutBasisPoints,
  );
}

RecommendationCanaryConfigurationInspection _configuration(
  RecommendationCanaryConfigurationState state, {
  RecommendationCanaryConfig? config,
}) {
  return RecommendationCanaryConfigurationInspection(
    state: state,
    inspectedAt: DateTime.utc(2026, 8, 5, 9),
    config: config,
    reasons: ['configuration_${state.name}'],
  );
}

RecommendationCanaryConfig _config({
  int rolloutBasisPoints = 500,
  String experimentRankingVersion = 'local_rank_v3_quality_shadow',
}) {
  return RecommendationCanaryConfig(
    schemaVersion: RecommendationCanaryConfig.supportedSchemaVersion,
    baselineRankingVersion: 'local_rank_v2',
    experimentRankingVersion: experimentRankingVersion,
    baselineAlgorithmVersion: 'hybrid_v3_0',
    experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
    rolloutBasisPoints: rolloutBasisPoints,
    activatedAt: DateTime.utc(2026, 8, 5, 8),
    expiresAt: DateTime.utc(2026, 8, 5, 12),
  );
}

RecommendationCanaryOperationsReport _operations(
  RecommendationCanaryOperationsRecommendation recommendation, {
  RecommendationCanaryConfigurationInspection? configuration,
  String experimentRankingVersion = 'local_rank_v3_quality_shadow',
  String experimentAlgorithmVersion = 'hybrid_v3_0_rank_v3_canary',
}) {
  return RecommendationCanaryOperationsReport(
    generatedAt: DateTime.utc(2026, 8, 5, 9),
    configuration: configuration ??
        _configuration(RecommendationCanaryConfigurationState.absent),
    baselineRankingVersion: 'local_rank_v2',
    experimentRankingVersion: experimentRankingVersion,
    baselineAlgorithmVersion: 'hybrid_v3_0',
    experimentAlgorithmVersion: experimentAlgorithmVersion,
    recommendation: recommendation,
    reasons: ['operations_${recommendation.name}'],
    shadowAssessment: RecommendationShadowCanaryAssessment(
      baselineVersion: 'local_rank_v2',
      experimentVersion: experimentRankingVersion,
      verdict: RecommendationShadowCanaryVerdict.eligibleForCanary,
      byRecallPath: const {},
      reasons: const ['shadow_guardrails_passed'],
    ),
    funnelComparison: RecommendationAlgorithmComparison(
      baseline: RecommendationFunnelSummary.empty('hybrid_v3_0'),
      candidate: RecommendationFunnelSummary.empty(
        experimentAlgorithmVersion,
      ),
      verdict: RecommendationAlgorithmVerdict.neutral,
      reasons: const ['no_material_change'],
    ),
  );
}

void _expectNoAutomaticAuthority(
  RecommendationCanaryManualReviewReport report,
) {
  expect(report.authorizesAutomaticActivation, isFalse);
  expect(report.authorizesAutomaticExpansion, isFalse);
  expect(report.authorizesAutomaticDeactivation, isFalse);
  expect(report.authorizesAutomaticFullRollout, isFalse);
  final json = report.toJson();
  expect(json['authorizes_automatic_activation'], isFalse);
  expect(json['authorizes_automatic_expansion'], isFalse);
  expect(json['authorizes_automatic_deactivation'], isFalse);
  expect(json['authorizes_automatic_full_rollout'], isFalse);
}
