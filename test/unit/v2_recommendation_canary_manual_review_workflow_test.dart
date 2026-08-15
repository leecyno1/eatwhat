import 'dart:async';
import 'dart:convert';

import 'package:eatwhat_app/v2/core/data/models/recommendation_canary_manifest.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_manifest_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_manual_review_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_manual_review_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('无待复核清单时不生成挑战', () async {
    var acknowledgementCalls = 0;
    final workflow = _workflow(
      reportLoader: () async => _report(
        state: RecommendationCanaryStagedManifestState.absent,
        recommendation:
            RecommendationCanaryManualReviewRecommendation.noPendingManifest,
      ),
      acknowledger: ({required revision, required payloadDigest}) async {
        acknowledgementCalls += 1;
        return _acknowledged();
      },
    );

    final result = await workflow.loadChallenge();

    expect(
      result.state,
      RecommendationCanaryManualReviewWorkflowState.noPendingReview,
    );
    expect(result.challenge, isNull);
    expect(acknowledgementCalls, 0);
    _expectNoExecutionAuthority(result);
  });

  test('可信待复核清单只生成最小化挑战', () async {
    final workflow = _workflow(reportLoader: () async => _report());

    final result = await workflow.loadChallenge();

    expect(
      result.state,
      RecommendationCanaryManualReviewWorkflowState.challengeReady,
    );
    final challenge = result.challenge!;
    expect(challenge.revision, 7);
    expect(challenge.payloadDigest, 'a' * 64);
    expect(challenge.expiresAt, DateTime.utc(2026, 8, 6, 8));
    expect(
      challenge.directive,
      RecommendationCanaryManifestDirective.proposeControlledCanary,
    );
    expect(challenge.rolloutBasisPoints, 500);
    expect(
      challenge.recommendation,
      RecommendationCanaryManualReviewRecommendation
          .candidateForManualActivation,
    );
    expect(challenge.reasons, const ['signed_canary_proposal_received']);

    expect(
      challenge.toJson().keys.toSet(),
      {
        'revision',
        'payload_digest',
        'expires_at',
        'directive',
        'rollout_basis_points',
        'baseline_ranking_version',
        'experiment_ranking_version',
        'baseline_algorithm_version',
        'experiment_algorithm_version',
        'recommendation',
        'reasons',
      },
    );
    final encoded = jsonEncode(challenge.toJson());
    for (final forbidden in [
      'installation_key',
      'user_id',
      'session_id',
      'request_text',
      'dish_id',
      'candidate_id',
      'operations',
    ]) {
      expect(encoded, isNot(contains(forbidden)));
    }
    expect(challenge.authorizesAutomaticActivation, isFalse);
    expect(challenge.authorizesAutomaticExpansion, isFalse);
    expect(challenge.authorizesAutomaticReduction, isFalse);
    expect(challenge.authorizesAutomaticDeactivation, isFalse);
    expect(challenge.authorizesAutomaticFullRollout, isFalse);
    expect(challenge.authorizesRecommendationExecution, isFalse);
    _expectNoExecutionAuthority(result);
  });

  test('操作员输入的版本或摘要不精确匹配时绝不写入确认', () async {
    var acknowledgementCalls = 0;
    final workflow = _workflow(
      reportLoader: () async => _report(),
      acknowledger: ({required revision, required payloadDigest}) async {
        acknowledgementCalls += 1;
        return _acknowledged();
      },
    );
    final challenge = (await workflow.loadChallenge()).challenge!;

    final cases = [
      (revision: '07', digest: challenge.payloadDigest),
      (revision: '7 ', digest: challenge.payloadDigest),
      (revision: '8', digest: challenge.payloadDigest),
      (revision: '7', digest: 'A' * 64),
      (revision: '7', digest: 'b' * 64),
    ];
    for (final input in cases) {
      final result = await workflow.acknowledgeReview(
        expectedChallenge: challenge,
        operatorRevision: input.revision,
        operatorPayloadDigest: input.digest,
      );
      expect(
        result.state,
        RecommendationCanaryManualReviewWorkflowState.inputInvalid,
      );
    }
    expect(acknowledgementCalls, 0);
  });

  test('加载挑战后清单被替换时拒绝旧挑战', () async {
    var report = _report();
    var acknowledgementCalls = 0;
    final workflow = _workflow(
      reportLoader: () async => report,
      acknowledger: ({required revision, required payloadDigest}) async {
        acknowledgementCalls += 1;
        return _acknowledged();
      },
    );
    final challenge = (await workflow.loadChallenge()).challenge!;
    report = _report(
      manifest: _manifest(revision: 8),
      payloadDigest: 'b' * 64,
    );

    final result = await workflow.acknowledgeReview(
      expectedChallenge: challenge,
      operatorRevision: '7',
      operatorPayloadDigest: challenge.payloadDigest,
    );

    expect(
      result.state,
      RecommendationCanaryManualReviewWorkflowState.challengeChanged,
    );
    expect(acknowledgementCalls, 0);
  });

  test('挑战加载后过期、已复核或损坏时不能提交', () async {
    final cases = <(
      RecommendationCanaryStagedManifestState,
      RecommendationCanaryManualReviewRecommendation,
      RecommendationCanaryManualReviewWorkflowState
    )>[
      (
        RecommendationCanaryStagedManifestState.expired,
        RecommendationCanaryManualReviewRecommendation.rejectManifest,
        RecommendationCanaryManualReviewWorkflowState.expired,
      ),
      (
        RecommendationCanaryStagedManifestState.reviewed,
        RecommendationCanaryManualReviewRecommendation.noPendingManifest,
        RecommendationCanaryManualReviewWorkflowState.alreadyAcknowledged,
      ),
      (
        RecommendationCanaryStagedManifestState.invalid,
        RecommendationCanaryManualReviewRecommendation.rejectManifest,
        RecommendationCanaryManualReviewWorkflowState.manifestRejected,
      ),
    ];
    for (final testCase in cases) {
      var report = _report();
      var acknowledgementCalls = 0;
      final workflow = _workflow(
        reportLoader: () async => report,
        acknowledger: ({required revision, required payloadDigest}) async {
          acknowledgementCalls += 1;
          return _acknowledged();
        },
      );
      final challenge = (await workflow.loadChallenge()).challenge!;
      report = _report(
        state: testCase.$1,
        recommendation: testCase.$2,
      );

      final result = await workflow.acknowledgeReview(
        expectedChallenge: challenge,
        operatorRevision: '7',
        operatorPayloadDigest: challenge.payloadDigest,
      );

      expect(result.state, testCase.$3, reason: testCase.$1.name);
      expect(acknowledgementCalls, 0);
    }
  });

  test('有效且未变化的操作员输入只写入一次确认', () async {
    var acknowledgementCalls = 0;
    final workflow = _workflow(
      reportLoader: () async => _report(),
      acknowledger: ({required revision, required payloadDigest}) async {
        acknowledgementCalls += 1;
        expect(revision, 7);
        expect(payloadDigest, 'a' * 64);
        return _acknowledged();
      },
    );
    final challenge = (await workflow.loadChallenge()).challenge!;

    final result = await workflow.acknowledgeReview(
      expectedChallenge: challenge,
      operatorRevision: '7',
      operatorPayloadDigest: challenge.payloadDigest,
    );

    expect(
      result.state,
      RecommendationCanaryManualReviewWorkflowState.acknowledged,
    );
    expect(acknowledgementCalls, 1);
    _expectNoExecutionAuthority(result);
  });

  test('并发提交相同挑战会合并且不会重复写入', () async {
    final acknowledgementStarted = Completer<void>();
    final allowAcknowledgement = Completer<void>();
    var acknowledgementCalls = 0;
    final workflow = _workflow(
      reportLoader: () async => _report(),
      acknowledger: ({required revision, required payloadDigest}) async {
        acknowledgementCalls += 1;
        acknowledgementStarted.complete();
        await allowAcknowledgement.future;
        return _acknowledged();
      },
    );
    final challenge = (await workflow.loadChallenge()).challenge!;

    final first = workflow.acknowledgeReview(
      expectedChallenge: challenge,
      operatorRevision: '7',
      operatorPayloadDigest: challenge.payloadDigest,
    );
    final second = workflow.acknowledgeReview(
      expectedChallenge: challenge,
      operatorRevision: '7',
      operatorPayloadDigest: challenge.payloadDigest,
    );
    await acknowledgementStarted.future;
    expect(acknowledgementCalls, 1);
    allowAcknowledgement.complete();

    final results = await Future.wait([first, second]);
    expect(
      results.map((result) => result.state),
      everyElement(
        RecommendationCanaryManualReviewWorkflowState.acknowledged,
      ),
    );
    expect(acknowledgementCalls, 1);
  });

  test('确认存储失败或异常会保守暴露且不授予执行权', () async {
    for (final throwFailure in [false, true]) {
      final workflow = _workflow(
        reportLoader: () async => _report(),
        acknowledger: ({required revision, required payloadDigest}) async {
          if (throwFailure) throw StateError('secure storage unavailable');
          return const RecommendationCanaryManifestAcknowledgementResult(
            state: RecommendationCanaryManifestAcknowledgementState
                .storageUnavailable,
            reason: 'canary_manifest_acknowledgement_write_failed',
          );
        },
      );
      final challenge = (await workflow.loadChallenge()).challenge!;

      final result = await workflow.acknowledgeReview(
        expectedChallenge: challenge,
        operatorRevision: '7',
        operatorPayloadDigest: challenge.payloadDigest,
      );

      expect(
        result.state,
        RecommendationCanaryManualReviewWorkflowState.storageUnavailable,
      );
      _expectNoExecutionAuthority(result);
    }
  });

  test('复检后底层令牌失配按挑战变化处理而非确认成功', () async {
    final workflow = _workflow(
      reportLoader: () async => _report(),
      acknowledger: ({required revision, required payloadDigest}) async {
        return const RecommendationCanaryManifestAcknowledgementResult(
          state: RecommendationCanaryManifestAcknowledgementState.tokenMismatch,
          reason: 'canary_manifest_acknowledgement_token_mismatch',
        );
      },
    );
    final challenge = (await workflow.loadChallenge()).challenge!;

    final result = await workflow.acknowledgeReview(
      expectedChallenge: challenge,
      operatorRevision: '7',
      operatorPayloadDigest: challenge.payloadDigest,
    );

    expect(
      result.state,
      RecommendationCanaryManualReviewWorkflowState.challengeChanged,
    );
    _expectNoExecutionAuthority(result);
  });

  test('复核报告或时钟异常和需人工调查的报告均不会生成可提交挑战', () async {
    final unavailable = await _workflow(
      reportLoader: () async => throw StateError('review unavailable'),
    ).loadChallenge();
    final clockUnavailable = await _workflow(
      reportLoader: () async => _report(),
      clock: () => throw StateError('clock unavailable'),
    ).loadChallenge();
    final investigation = await _workflow(
      reportLoader: () async => _report(
        recommendation:
            RecommendationCanaryManualReviewRecommendation.manualReview,
      ),
    ).loadChallenge();

    expect(
      unavailable.state,
      RecommendationCanaryManualReviewWorkflowState.workflowUnavailable,
    );
    expect(unavailable.challenge, isNull);
    expect(
      clockUnavailable.state,
      RecommendationCanaryManualReviewWorkflowState.workflowUnavailable,
    );
    expect(clockUnavailable.challenge, isNull);
    expect(
      investigation.state,
      RecommendationCanaryManualReviewWorkflowState.manualInvestigationRequired,
    );
    expect(investigation.challenge, isNull);
  });
}

V2RecommendationCanaryManualReviewWorkflow _workflow({
  required V2CanaryManualReviewReportLoader reportLoader,
  V2CanaryManualReviewAcknowledger? acknowledger,
  DateTime Function()? clock,
}) {
  return V2RecommendationCanaryManualReviewWorkflow(
    reviewLoader: reportLoader,
    acknowledgeManualReview: acknowledger ??
        ({required revision, required payloadDigest}) async => _acknowledged(),
    clock: clock ?? () => DateTime.utc(2026, 8, 5, 9),
  );
}

RecommendationCanaryManualReviewReport _report({
  RecommendationCanaryStagedManifestState state =
      RecommendationCanaryStagedManifestState.staged,
  RecommendationCanaryManualReviewRecommendation recommendation =
      RecommendationCanaryManualReviewRecommendation
          .candidateForManualActivation,
  RecommendationCanaryManifest? manifest,
  String payloadDigest = '',
}) {
  final resolvedManifest = manifest ?? _manifest();
  final includesManifest =
      state != RecommendationCanaryStagedManifestState.absent &&
          state != RecommendationCanaryStagedManifestState.invalid &&
          state != RecommendationCanaryStagedManifestState.unavailable;
  return RecommendationCanaryManualReviewReport(
    generatedAt: DateTime.utc(2026, 8, 5, 9),
    stagedManifest: RecommendationCanaryStagedManifestInspection(
      state: state,
      manifest: includesManifest ? resolvedManifest : null,
      acceptedAt: includesManifest ? DateTime.utc(2026, 8, 5, 8, 30) : null,
      payloadDigest: includesManifest
          ? (payloadDigest.isEmpty ? 'a' * 64 : payloadDigest)
          : null,
    ),
    recommendation: recommendation,
    reasons: const ['signed_canary_proposal_received'],
  );
}

RecommendationCanaryManifest _manifest({int revision = 7}) {
  return RecommendationCanaryManifest(
    schemaVersion: RecommendationCanaryManifest.supportedSchemaVersion,
    revision: revision,
    audience: 'com.eatwhat.eatwhatApp',
    environment: 'production',
    directive: RecommendationCanaryManifestDirective.proposeControlledCanary,
    issuedAt: DateTime.utc(2026, 8, 5, 8),
    expiresAt: DateTime.utc(2026, 8, 6, 8),
    baselineRankingVersion: 'local_rank_v2',
    experimentRankingVersion: 'local_rank_v3_quality_shadow',
    baselineAlgorithmVersion: 'hybrid_v3_0',
    experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
    rolloutBasisPoints: 500,
  );
}

RecommendationCanaryManifestAcknowledgementResult _acknowledged() {
  return const RecommendationCanaryManifestAcknowledgementResult(
    state: RecommendationCanaryManifestAcknowledgementState.acknowledged,
    reason: 'canary_manifest_manual_review_acknowledged',
  );
}

void _expectNoExecutionAuthority(
  RecommendationCanaryManualReviewWorkflowResult result,
) {
  expect(result.authorizesAutomaticActivation, isFalse);
  expect(result.authorizesAutomaticExpansion, isFalse);
  expect(result.authorizesAutomaticReduction, isFalse);
  expect(result.authorizesAutomaticDeactivation, isFalse);
  expect(result.authorizesAutomaticFullRollout, isFalse);
  expect(result.authorizesRecommendationExecution, isFalse);
  expect(result.toJson()['authorizes_recommendation_execution'], isFalse);
}
