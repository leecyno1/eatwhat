import 'dart:convert';

import 'package:eatwhat_app/v2/core/data/models/recommendation_funnel_snapshot.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_funnel_insights.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_shadow_insights.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('默认关闭且不会创建分桶身份', () async {
    final service = _service(verdict: _eligibleAssessment());

    final decision = await service.decide();

    expect(decision.useExperiment, isFalse);
    expect(decision.rankingVersion, 'local_rank_v2');
    expect(decision.algorithmVersion, 'hybrid_v3_0');
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getKeys().where((key) => key.contains('canary')),
      isEmpty,
    );
  });

  test('只读检查识别缺失、有效、过期和损坏配置且不修改存储', () async {
    var now = DateTime.utc(2026, 8, 5, 8);
    final service = V2RecommendationCanaryService(
      clock: () => now,
      assessmentLoader: ({
        required baselineVersion,
        required experimentVersion,
      }) async =>
          _eligibleAssessment(),
      outcomeVerdictLoader: ({
        required baselineVersion,
        required candidateVersion,
        since,
      }) async =>
          RecommendationAlgorithmVerdict.insufficientData,
      installationKeyFactory: () => 'installation_key_for_test',
    );

    expect(
      (await service.inspectConfiguration()).state,
      RecommendationCanaryConfigurationState.absent,
    );
    expect(
      await service.activateControlledCanary(
        experimentRankingVersion: 'local_rank_v3_quality_shadow',
        experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
        rolloutBasisPoints: 500,
        duration: const Duration(hours: 1),
      ),
      isTrue,
    );
    final prefs = await SharedPreferences.getInstance();
    final activeRaw = prefs.getString('v2_recommendation_canary_config_v1');

    final active = await service.inspectConfiguration();
    expect(active.state, RecommendationCanaryConfigurationState.active);
    expect(active.hasActiveConfiguration, isTrue);
    expect(active.config?.rolloutBasisPoints, 500);
    expect(
      prefs.getString('v2_recommendation_canary_installation_key_v1'),
      isNull,
    );

    now = now.add(const Duration(hours: 2));
    final expired = await service.inspectConfiguration();
    expect(expired.state, RecommendationCanaryConfigurationState.expired);
    expect(
      prefs.getString('v2_recommendation_canary_config_v1'),
      activeRaw,
    );

    await prefs.setString('v2_recommendation_canary_config_v1', '{not-json');
    final invalid = await service.inspectConfiguration();
    expect(invalid.state, RecommendationCanaryConfigurationState.invalid);
    expect(
      prefs.getString('v2_recommendation_canary_config_v1'),
      '{not-json',
    );
    expect(
      prefs.getString('v2_recommendation_canary_installation_key_v1'),
      isNull,
    );
  });

  test('只读检查把存储异常和进程内强制停用残留暴露为显式状态', () async {
    final unavailable = V2RecommendationCanaryService(
      preferencesLoader: () async => throw StateError('storage unavailable'),
      assessmentLoader: ({
        required baselineVersion,
        required experimentVersion,
      }) async =>
          _eligibleAssessment(),
    );
    expect(
      (await unavailable.inspectConfiguration()).state,
      RecommendationCanaryConfigurationState.unavailable,
    );

    final prefs = await SharedPreferences.getInstance();
    var loadCount = 0;
    final forcedDisabled = V2RecommendationCanaryService(
      preferencesLoader: () async {
        loadCount += 1;
        if (loadCount == 2) throw StateError('remove unavailable');
        return prefs;
      },
      clock: () => DateTime.utc(2026, 8, 5, 8),
      assessmentLoader: ({
        required baselineVersion,
        required experimentVersion,
      }) async =>
          _eligibleAssessment(),
      outcomeVerdictLoader: ({
        required baselineVersion,
        required candidateVersion,
        since,
      }) async =>
          RecommendationAlgorithmVerdict.insufficientData,
    );
    expect(
      await forcedDisabled.activateControlledCanary(
        experimentRankingVersion: 'local_rank_v3_quality_shadow',
        experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
        rolloutBasisPoints: 500,
      ),
      isTrue,
    );
    expect(await forcedDisabled.deactivate(), isFalse);

    final inspection = await forcedDisabled.inspectConfiguration();
    expect(
      inspection.state,
      RecommendationCanaryConfigurationState.forcedDisabled,
    );
    expect(inspection.hasActiveConfiguration, isFalse);
    expect(
      prefs.getString('v2_recommendation_canary_config_v1'),
      isNotNull,
    );
  });

  test('只有影子门禁通过才能显式启用且比例上限为百分之十', () async {
    final blocked = _service(
      verdict: _assessment(RecommendationShadowCanaryVerdict.blocked),
    );
    final ineligible = await blocked.activateControlledCanary(
      experimentRankingVersion: 'local_rank_v3_quality_shadow',
      experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
      rolloutBasisPoints: 500,
    );
    expect(ineligible, isFalse);

    final eligible = _service(verdict: _eligibleAssessment());
    expect(
      await eligible.activateControlledCanary(
        experimentRankingVersion: 'local_rank_v3_quality_shadow',
        experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
        rolloutBasisPoints: 1001,
      ),
      isFalse,
    );
    expect(
      await eligible.activateControlledCanary(
        experimentRankingVersion: 'local_rank_v3_quality_shadow',
        experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
        rolloutBasisPoints: 1000,
      ),
      isTrue,
    );
  });

  test('稳定分桶命中后返回实验版本且不把安装键写入配置', () async {
    final service = _service(
      verdict: _eligibleAssessment(),
      bucket: 499,
    );
    await service.activateControlledCanary(
      experimentRankingVersion: 'local_rank_v3_quality_shadow',
      experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
      rolloutBasisPoints: 500,
    );

    final first = await service.decide();
    final second = await service.decide();

    expect(first.useExperiment, isTrue);
    expect(second.useExperiment, isTrue);
    expect(first.rankingVersion, 'local_rank_v3_quality_shadow');
    expect(first.algorithmVersion, 'hybrid_v3_0_rank_v3_canary');
    final prefs = await SharedPreferences.getInstance();
    final configRaw = prefs.getString('v2_recommendation_canary_config_v1')!;
    expect(jsonDecode(configRaw), isA<Map<String, dynamic>>());
    expect(configRaw, isNot(contains('installation_key_for_test')));
    expect(
      prefs.getString('v2_recommendation_canary_installation_key_v1'),
      'installation_key_for_test',
    );
  });

  test('未命中、过期、门禁失效和手动停用均立即回到基线', () async {
    var now = DateTime.utc(2026, 8, 5, 8);
    var assessment = _eligibleAssessment();
    final service = V2RecommendationCanaryService(
      clock: () => now,
      assessmentLoader: ({
        required baselineVersion,
        required experimentVersion,
      }) async =>
          assessment,
      installationKeyFactory: () => 'installation_key_for_test',
      bucketResolver: (_, __) => 500,
    );
    await service.activateControlledCanary(
      experimentRankingVersion: 'local_rank_v3_quality_shadow',
      experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
      rolloutBasisPoints: 500,
      duration: const Duration(hours: 1),
    );
    expect((await service.decide()).useExperiment, isFalse);

    assessment = _assessment(RecommendationShadowCanaryVerdict.blocked);
    expect((await service.decide()).useExperiment, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('v2_recommendation_canary_config_v1'), isNull);

    assessment = _eligibleAssessment();
    await service.activateControlledCanary(
      experimentRankingVersion: 'local_rank_v3_quality_shadow',
      experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
      rolloutBasisPoints: 500,
      duration: const Duration(hours: 1),
    );
    now = now.add(const Duration(hours: 2));
    expect((await service.decide()).useExperiment, isFalse);
    expect(prefs.getString('v2_recommendation_canary_config_v1'), isNull);

    now = DateTime.utc(2026, 8, 5, 8);
    await service.activateControlledCanary(
      experimentRankingVersion: 'local_rank_v3_quality_shadow',
      experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
      rolloutBasisPoints: 500,
    );
    expect(await service.deactivate(), isTrue);
    expect((await service.decide()).useExperiment, isFalse);
  });

  test('停用持久化失败时当前进程仍立即关闭实验并显式返回失败', () async {
    final prefs = await SharedPreferences.getInstance();
    var preferencesLoadCount = 0;
    final service = V2RecommendationCanaryService(
      preferencesLoader: () async {
        preferencesLoadCount += 1;
        if (preferencesLoadCount == 2) {
          throw StateError('storage unavailable during deactivate');
        }
        return prefs;
      },
      clock: () => DateTime.utc(2026, 8, 5, 8),
      assessmentLoader: ({
        required baselineVersion,
        required experimentVersion,
      }) async =>
          _eligibleAssessment(),
      installationKeyFactory: () => 'installation_key_for_test',
      bucketResolver: (_, __) => 0,
    );
    expect(
      await service.activateControlledCanary(
        experimentRankingVersion: 'local_rank_v3_quality_shadow',
        experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
        rolloutBasisPoints: 500,
      ),
      isTrue,
    );

    expect(await service.deactivate(), isFalse);
    expect(
      prefs.getString('v2_recommendation_canary_config_v1'),
      isNotNull,
    );
    expect((await service.decide()).useExperiment, isFalse);
  });

  test('门禁结论版本不属于当前实验时立即停用', () async {
    var assessment = _eligibleAssessment();
    final service = V2RecommendationCanaryService(
      clock: () => DateTime.utc(2026, 8, 5, 8),
      assessmentLoader: ({
        required baselineVersion,
        required experimentVersion,
      }) async =>
          assessment,
      installationKeyFactory: () => 'installation_key_for_test',
      bucketResolver: (_, __) => 0,
    );
    await service.activateControlledCanary(
      experimentRankingVersion: 'local_rank_v3_quality_shadow',
      experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
      rolloutBasisPoints: 500,
    );
    assessment = RecommendationShadowCanaryAssessment(
      baselineVersion: 'local_rank_v2',
      experimentVersion: 'stale_experiment',
      verdict: RecommendationShadowCanaryVerdict.eligibleForCanary,
      byRecallPath: const {},
      reasons: const [],
    );

    expect((await service.decide()).useExperiment, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('v2_recommendation_canary_config_v1'), isNull);
    expect(
      prefs.getString('v2_recommendation_canary_installation_key_v1'),
      isNull,
    );
  });

  test('启用前已知真实结果回归时拒绝灰度', () async {
    final service = _service(
      verdict: _eligibleAssessment(),
      outcomeVerdict: RecommendationAlgorithmVerdict.regression,
    );

    expect(
      await service.activateControlledCanary(
        experimentRankingVersion: 'local_rank_v3_quality_shadow',
        experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
        rolloutBasisPoints: 500,
      ),
      isFalse,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('v2_recommendation_canary_config_v1'), isNull);
  });

  test('灰度期间真实结果回归会自动停用且不创建分桶身份', () async {
    var outcomeVerdict = RecommendationAlgorithmVerdict.insufficientData;
    DateTime? comparisonSince;
    final service = V2RecommendationCanaryService(
      clock: () => DateTime.utc(2026, 8, 5, 8),
      assessmentLoader: ({
        required baselineVersion,
        required experimentVersion,
      }) async =>
          _eligibleAssessment(),
      outcomeVerdictLoader: ({
        required baselineVersion,
        required candidateVersion,
        since,
      }) async {
        comparisonSince = since;
        return outcomeVerdict;
      },
      installationKeyFactory: () => 'installation_key_for_test',
      bucketResolver: (_, __) => 0,
    );
    expect(
      await service.activateControlledCanary(
        experimentRankingVersion: 'local_rank_v3_quality_shadow',
        experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
        rolloutBasisPoints: 500,
      ),
      isTrue,
    );
    outcomeVerdict = RecommendationAlgorithmVerdict.regression;

    expect((await service.decide()).useExperiment, isFalse);
    expect(comparisonSince, DateTime.utc(2026, 8, 5, 8));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('v2_recommendation_canary_config_v1'), isNull);
    expect(
      prefs.getString('v2_recommendation_canary_installation_key_v1'),
      isNull,
    );
  });

  test('真实漏斗聚合判定回归后自动撤销灰度', () async {
    var snapshots = <RecommendationFunnelSnapshot>[];
    final service = V2RecommendationCanaryService(
      clock: () => DateTime.utc(2026, 8, 5, 8),
      assessmentLoader: ({
        required baselineVersion,
        required experimentVersion,
      }) async =>
          _eligibleAssessment(),
      funnelInsights: V2RecommendationFunnelInsights(
        snapshotLoader: (_) async => snapshots,
      ),
      installationKeyFactory: () => 'installation_key_for_test',
      bucketResolver: (_, __) => 0,
    );
    expect(
      await service.activateControlledCanary(
        experimentRankingVersion: 'local_rank_v3_quality_shadow',
        experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
        rolloutBasisPoints: 500,
      ),
      isTrue,
    );
    snapshots = [
      _funnelSnapshot(
        algorithmVersion: 'hybrid_v3_0',
        exposures: 100,
        executionStarts: 50,
        executionCompletions: 35,
      ),
      _funnelSnapshot(
        algorithmVersion: 'hybrid_v3_0_rank_v3_canary',
        exposures: 100,
        executionStarts: 30,
        executionCompletions: 10,
      ),
    ];

    expect((await service.decide()).useExperiment, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('v2_recommendation_canary_config_v1'), isNull);
  });

  test('样本不足、中性或向好都不会自动扩量或改变显式配置', () async {
    for (final outcomeVerdict in [
      RecommendationAlgorithmVerdict.insufficientData,
      RecommendationAlgorithmVerdict.neutral,
      RecommendationAlgorithmVerdict.promising,
    ]) {
      SharedPreferences.setMockInitialValues({});
      final service = _service(
        verdict: _eligibleAssessment(),
        bucket: 499,
        outcomeVerdict: outcomeVerdict,
      );
      await service.activateControlledCanary(
        experimentRankingVersion: 'local_rank_v3_quality_shadow',
        experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
        rolloutBasisPoints: 500,
      );

      expect((await service.decide()).useExperiment, isTrue);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('v2_recommendation_canary_config_v1')!;
      expect(jsonDecode(raw)['rollout_basis_points'], 500);
    }
  });

  test('真实结果读取异常时本次请求回到基线并保留显式配置', () async {
    var outcomeReadFails = false;
    final service = V2RecommendationCanaryService(
      clock: () => DateTime.utc(2026, 8, 5, 8),
      assessmentLoader: ({
        required baselineVersion,
        required experimentVersion,
      }) async =>
          _eligibleAssessment(),
      outcomeVerdictLoader: ({
        required baselineVersion,
        required candidateVersion,
        since,
      }) async {
        if (outcomeReadFails) throw StateError('funnel unavailable');
        return RecommendationAlgorithmVerdict.insufficientData;
      },
      installationKeyFactory: () => 'installation_key_for_test',
      bucketResolver: (_, __) => 0,
    );
    await service.activateControlledCanary(
      experimentRankingVersion: 'local_rank_v3_quality_shadow',
      experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
      rolloutBasisPoints: 500,
    );
    outcomeReadFails = true;

    expect((await service.decide()).useExperiment, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('v2_recommendation_canary_config_v1'), isNotNull);
    expect(
      prefs.getString('v2_recommendation_canary_installation_key_v1'),
      isNull,
    );
  });

  test('损坏配置、持久化异常或非法分桶均关闭实验', () async {
    SharedPreferences.setMockInitialValues({
      'v2_recommendation_canary_config_v1': '{not-json',
    });
    expect(
      (await _service(verdict: _eligibleAssessment()).decide()).useExperiment,
      isFalse,
    );

    SharedPreferences.setMockInitialValues({
      'v2_recommendation_canary_config_v1': jsonEncode({
        'schema_version': 'v2',
        'baseline_ranking_version': 'local_rank_v2',
        'experiment_ranking_version': 'local_rank_v3_quality_shadow',
        'baseline_algorithm_version': 'hybrid_v3_0',
        'experiment_algorithm_version': 'hybrid_v3_0_rank_v3_canary',
        'rollout_basis_points': 500,
        'activated_at': '2026-08-05T07:00:00.000Z',
        'expires_at': '2026-08-05T09:00:00.000Z',
      }),
    });
    expect(
      (await _service(verdict: _eligibleAssessment()).decide()).useExperiment,
      isFalse,
    );

    final throwingService = V2RecommendationCanaryService(
      preferencesLoader: () async => throw StateError('storage unavailable'),
      assessmentLoader: ({
        required baselineVersion,
        required experimentVersion,
      }) async =>
          _eligibleAssessment(),
    );
    expect((await throwingService.decide()).useExperiment, isFalse);

    SharedPreferences.setMockInitialValues({});
    final illegalBucket = _service(
      verdict: _eligibleAssessment(),
      bucket: 10000,
    );
    await illegalBucket.activateControlledCanary(
      experimentRankingVersion: 'local_rank_v3_quality_shadow',
      experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
      rolloutBasisPoints: 1000,
    );
    expect((await illegalBucket.decide()).useExperiment, isFalse);
  });
}

V2RecommendationCanaryService _service({
  required RecommendationShadowCanaryAssessment verdict,
  int bucket = 0,
  RecommendationAlgorithmVerdict outcomeVerdict =
      RecommendationAlgorithmVerdict.insufficientData,
}) {
  return V2RecommendationCanaryService(
    clock: () => DateTime.utc(2026, 8, 5, 8),
    assessmentLoader: ({
      required baselineVersion,
      required experimentVersion,
    }) async =>
        verdict,
    outcomeVerdictLoader: ({
      required baselineVersion,
      required candidateVersion,
      since,
    }) async =>
        outcomeVerdict,
    installationKeyFactory: () => 'installation_key_for_test',
    bucketResolver: (_, __) => bucket,
  );
}

RecommendationShadowCanaryAssessment _eligibleAssessment() {
  return _assessment(RecommendationShadowCanaryVerdict.eligibleForCanary);
}

RecommendationShadowCanaryAssessment _assessment(
  RecommendationShadowCanaryVerdict verdict,
) {
  return RecommendationShadowCanaryAssessment(
    baselineVersion: 'local_rank_v2',
    experimentVersion: 'local_rank_v3_quality_shadow',
    verdict: verdict,
    byRecallPath: const {},
    reasons: const [],
  );
}

RecommendationFunnelSnapshot _funnelSnapshot({
  required String algorithmVersion,
  required int exposures,
  required int executionStarts,
  required int executionCompletions,
}) {
  return RecommendationFunnelSnapshot(
    day: DateTime.utc(2026, 8, 5),
    schemaVersion: 'v1',
    algorithmVersion: algorithmVersion,
    primarySource: 'unified_db',
    resolutionStatus: 'dbResolved',
    exposures: exposures,
    executionStarts: executionStarts,
    executionCompletions: executionCompletions,
  );
}
