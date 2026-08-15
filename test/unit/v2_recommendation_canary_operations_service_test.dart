import 'dart:convert';

import 'package:eatwhat_app/v2/core/data/models/recommendation_canary_config.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_operations_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_funnel_insights.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_shadow_insights.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_shadow_scoring_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('未启用时按影子门禁和真实漏斗给出保守人工建议', () async {
    final cases = <(
      RecommendationShadowCanaryVerdict,
      RecommendationAlgorithmVerdict,
      RecommendationCanaryOperationsRecommendation
    )>[
      (
        RecommendationShadowCanaryVerdict.insufficientData,
        RecommendationAlgorithmVerdict.insufficientData,
        RecommendationCanaryOperationsRecommendation.collectShadowData,
      ),
      (
        RecommendationShadowCanaryVerdict.blocked,
        RecommendationAlgorithmVerdict.neutral,
        RecommendationCanaryOperationsRecommendation.keepDisabled,
      ),
      (
        RecommendationShadowCanaryVerdict.eligibleForCanary,
        RecommendationAlgorithmVerdict.insufficientData,
        RecommendationCanaryOperationsRecommendation.eligibleForManualCanary,
      ),
      (
        RecommendationShadowCanaryVerdict.eligibleForCanary,
        RecommendationAlgorithmVerdict.regression,
        RecommendationCanaryOperationsRecommendation.keepDisabled,
      ),
    ];

    for (final testCase in cases) {
      final report = await _service(
        configuration: _inspection(
          RecommendationCanaryConfigurationState.absent,
        ),
        shadowVerdict: testCase.$1,
        funnelVerdict: testCase.$2,
      ).buildReport(
        experimentRankingVersion: 'local_rank_v3_quality_shadow',
        experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
      );

      expect(
        report.recommendation,
        testCase.$3,
        reason: '${testCase.$1.name}/${testCase.$2.name}',
      );
      _expectNoAutomaticAuthority(report);
    }
  });

  test('有效灰度只允许继续采样、维持、人工评估扩量或停用建议', () async {
    final cases = <(
      RecommendationShadowCanaryVerdict,
      RecommendationAlgorithmVerdict,
      RecommendationCanaryOperationsRecommendation
    )>[
      (
        RecommendationShadowCanaryVerdict.eligibleForCanary,
        RecommendationAlgorithmVerdict.insufficientData,
        RecommendationCanaryOperationsRecommendation.continueCanarySampling,
      ),
      (
        RecommendationShadowCanaryVerdict.eligibleForCanary,
        RecommendationAlgorithmVerdict.neutral,
        RecommendationCanaryOperationsRecommendation.maintainCanary,
      ),
      (
        RecommendationShadowCanaryVerdict.eligibleForCanary,
        RecommendationAlgorithmVerdict.promising,
        RecommendationCanaryOperationsRecommendation.considerManualExpansion,
      ),
      (
        RecommendationShadowCanaryVerdict.eligibleForCanary,
        RecommendationAlgorithmVerdict.regression,
        RecommendationCanaryOperationsRecommendation.stopCanary,
      ),
      (
        RecommendationShadowCanaryVerdict.blocked,
        RecommendationAlgorithmVerdict.promising,
        RecommendationCanaryOperationsRecommendation.stopCanary,
      ),
    ];

    for (final testCase in cases) {
      final report = await _service(
        configuration: _inspection(
          RecommendationCanaryConfigurationState.active,
          config: _config(),
        ),
        shadowVerdict: testCase.$1,
        funnelVerdict: testCase.$2,
      ).buildReport(
        experimentRankingVersion: 'ignored_ranker',
        experimentAlgorithmVersion: 'ignored_algorithm',
      );

      expect(
        report.recommendation,
        testCase.$3,
        reason: '${testCase.$1.name}/${testCase.$2.name}',
      );
      expect(
        report.experimentRankingVersion,
        'local_rank_v3_quality_shadow',
      );
      expect(
        report.experimentAlgorithmVersion,
        'hybrid_v3_0_rank_v3_canary',
      );
      _expectNoAutomaticAuthority(report);
    }
  });

  test('报告透出样本和关键差值但不包含身份、菜品或请求内容', () async {
    DateTime? comparedSince;
    final report = await V2RecommendationCanaryOperationsService(
      clock: () => DateTime.utc(2026, 8, 5, 9),
      configurationInspector: () async => _inspection(
        RecommendationCanaryConfigurationState.active,
        config: _config(),
      ),
      assessmentLoader: ({
        required baselineVersion,
        required experimentVersion,
      }) async =>
          _assessment(RecommendationShadowCanaryVerdict.eligibleForCanary),
      comparisonLoader: ({
        required baselineVersion,
        required candidateVersion,
        since,
      }) async {
        comparedSince = since;
        return _comparison(RecommendationAlgorithmVerdict.promising);
      },
    ).buildReport(
      experimentRankingVersion: 'local_rank_v3_quality_shadow',
      experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
    );

    expect(comparedSince, DateTime.utc(2026, 8, 5, 8));
    final json = report.toJson();
    expect(json['recommendation'], 'considerManualExpansion');
    expect(
      (json['configuration'] as Map)['rollout_basis_points'],
      500,
    );
    expect(
      (json['configuration'] as Map)['rollout_percent'],
      5,
    );
    expect(
      (json['configuration'] as Map)['has_active_configuration'],
      isTrue,
    );
    expect(
      (json['real_funnel'] as Map)['candidate_exposures'],
      100,
    );
    expect(
      (json['real_funnel'] as Map)['execution_start_rate_delta'],
      closeTo(0.1, 0.0001),
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

  test('报告读取不会清理过期配置、创建安装键或改写灰度比例', () async {
    final config = _config(
      expiresAt: DateTime.utc(2026, 8, 5, 8, 30),
    );
    final rawConfig = jsonEncode(config.toJson());
    SharedPreferences.setMockInitialValues({
      'v2_recommendation_canary_config_v1': rawConfig,
    });
    final canaryService = V2RecommendationCanaryService(
      clock: () => DateTime.utc(2026, 8, 5, 9),
      assessmentLoader: ({
        required baselineVersion,
        required experimentVersion,
      }) async =>
          _assessment(RecommendationShadowCanaryVerdict.eligibleForCanary),
      installationKeyFactory: () => 'installation_key_must_not_be_created',
    );
    final service = V2RecommendationCanaryOperationsService(
      canaryService: canaryService,
      clock: () => DateTime.utc(2026, 8, 5, 9),
      assessmentLoader: ({
        required baselineVersion,
        required experimentVersion,
      }) async =>
          _assessment(RecommendationShadowCanaryVerdict.eligibleForCanary),
      comparisonLoader: ({
        required baselineVersion,
        required candidateVersion,
        since,
      }) async =>
          _comparison(RecommendationAlgorithmVerdict.insufficientData),
    );

    final report = await service.buildReport(
      experimentRankingVersion: 'local_rank_v3_quality_shadow',
      experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
    );

    expect(
      report.configuration.state,
      RecommendationCanaryConfigurationState.expired,
    );
    expect(
      report.recommendation,
      RecommendationCanaryOperationsRecommendation.eligibleForManualCanary,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('v2_recommendation_canary_config_v1'),
      rawConfig,
    );
    expect(
      prefs.getString('v2_recommendation_canary_installation_key_v1'),
      isNull,
    );
  });

  test('配置异常、数据读取失败或版本错配时只建议人工排查', () async {
    final manualReviewCases = [
      _service(
        configuration: _inspection(
          RecommendationCanaryConfigurationState.invalid,
        ),
        shadowVerdict: RecommendationShadowCanaryVerdict.eligibleForCanary,
        funnelVerdict: RecommendationAlgorithmVerdict.promising,
      ),
      V2RecommendationCanaryOperationsService(
        configurationInspector: () async => _inspection(
          RecommendationCanaryConfigurationState.absent,
        ),
        assessmentLoader: ({
          required baselineVersion,
          required experimentVersion,
        }) async =>
            throw StateError('shadow unavailable'),
        comparisonLoader: ({
          required baselineVersion,
          required candidateVersion,
          since,
        }) async =>
            _comparison(RecommendationAlgorithmVerdict.neutral),
      ),
      V2RecommendationCanaryOperationsService(
        configurationInspector: () async => _inspection(
          RecommendationCanaryConfigurationState.absent,
        ),
        assessmentLoader: ({
          required baselineVersion,
          required experimentVersion,
        }) async =>
            RecommendationShadowCanaryAssessment(
          baselineVersion: 'stale_baseline',
          experimentVersion: experimentVersion,
          verdict: RecommendationShadowCanaryVerdict.eligibleForCanary,
          byRecallPath: const {},
          reasons: const [],
        ),
        comparisonLoader: ({
          required baselineVersion,
          required candidateVersion,
          since,
        }) async =>
            _comparison(RecommendationAlgorithmVerdict.neutral),
      ),
      _service(
        configuration: _inspection(
          RecommendationCanaryConfigurationState.active,
        ),
        shadowVerdict: RecommendationShadowCanaryVerdict.eligibleForCanary,
        funnelVerdict: RecommendationAlgorithmVerdict.promising,
      ),
    ];

    for (final service in manualReviewCases) {
      final report = await service.buildReport(
        experimentRankingVersion: 'local_rank_v3_quality_shadow',
        experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
      );
      expect(
        report.recommendation,
        RecommendationCanaryOperationsRecommendation.manualReview,
      );
      _expectNoAutomaticAuthority(report);
    }
  });

  test('任意文本不能借版本字段进入运营报告', () async {
    final service = _service(
      configuration: _inspection(
        RecommendationCanaryConfigurationState.absent,
      ),
      shadowVerdict: RecommendationShadowCanaryVerdict.eligibleForCanary,
      funnelVerdict: RecommendationAlgorithmVerdict.neutral,
    );

    await expectLater(
      service.buildReport(
        experimentRankingVersion: '今晚想吃辣的',
        experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
      ),
      throwsArgumentError,
    );
  });
}

V2RecommendationCanaryOperationsService _service({
  required RecommendationCanaryConfigurationInspection configuration,
  required RecommendationShadowCanaryVerdict shadowVerdict,
  required RecommendationAlgorithmVerdict funnelVerdict,
}) {
  return V2RecommendationCanaryOperationsService(
    clock: () => DateTime.utc(2026, 8, 5, 9),
    configurationInspector: () async => configuration,
    assessmentLoader: ({
      required baselineVersion,
      required experimentVersion,
    }) async =>
        _assessment(shadowVerdict),
    comparisonLoader: ({
      required baselineVersion,
      required candidateVersion,
      since,
    }) async =>
        _comparison(funnelVerdict),
  );
}

RecommendationCanaryConfigurationInspection _inspection(
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

RecommendationCanaryConfig _config({DateTime? expiresAt}) {
  return RecommendationCanaryConfig(
    schemaVersion: RecommendationCanaryConfig.supportedSchemaVersion,
    baselineRankingVersion: 'local_rank_v2',
    experimentRankingVersion: 'local_rank_v3_quality_shadow',
    baselineAlgorithmVersion: 'hybrid_v3_0',
    experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
    rolloutBasisPoints: 500,
    activatedAt: DateTime.utc(2026, 8, 5, 8),
    expiresAt: expiresAt ?? DateTime.utc(2026, 8, 5, 12),
  );
}

RecommendationShadowCanaryAssessment _assessment(
  RecommendationShadowCanaryVerdict verdict,
) {
  const summary = RecommendationShadowPathSummary(
    recallPath: V2RecommendationRecallPath.direct,
    observations: 80,
    candidateCountSum: 400,
    comparisonDepthSum: 400,
    top1ChangeCount: 20,
    topKOverlapWeightedSum: 320,
    rankDisplacementSum: 200,
    maxAbsoluteRankDisplacement: 3,
    baselineDiversityWeightedSum: 280,
    experimentDiversityWeightedSum: 288,
  );
  return RecommendationShadowCanaryAssessment(
    baselineVersion: 'local_rank_v2',
    experimentVersion: 'local_rank_v3_quality_shadow',
    verdict: verdict,
    byRecallPath: {V2RecommendationRecallPath.direct: summary},
    reasons: ['shadow_${verdict.name}'],
  );
}

RecommendationAlgorithmComparison _comparison(
  RecommendationAlgorithmVerdict verdict,
) {
  return RecommendationAlgorithmComparison(
    baseline: _summary(
      'hybrid_v3_0',
      executionStarts: 40,
      executionCompletions: 20,
    ),
    candidate: _summary(
      'hybrid_v3_0_rank_v3_canary',
      executionStarts: 50,
      executionCompletions: 30,
    ),
    verdict: verdict,
    reasons: ['funnel_${verdict.name}'],
  );
}

RecommendationFunnelSummary _summary(
  String label, {
  required int executionStarts,
  required int executionCompletions,
}) {
  return RecommendationFunnelSummary(
    label: label,
    exposures: 100,
    candidateSelections: 60,
    confirmations: 20,
    rerolls: 10,
    favoriteAdds: 5,
    favoriteRemovals: 1,
    positiveFeedback: 8,
    negativeFeedback: 4,
    executionStarts: executionStarts,
    executionCompletions: executionCompletions,
    executionDeferrals: 4,
  );
}

void _expectNoAutomaticAuthority(
  RecommendationCanaryOperationsReport report,
) {
  expect(report.authorizesAutomaticActivation, isFalse);
  expect(report.authorizesAutomaticExpansion, isFalse);
  expect(report.authorizesAutomaticFullRollout, isFalse);
  final json = report.toJson();
  expect(json['authorizes_automatic_activation'], isFalse);
  expect(json['authorizes_automatic_expansion'], isFalse);
  expect(json['authorizes_automatic_full_rollout'], isFalse);
}
