import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_canary_config.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_funnel_insights.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_shadow_insights.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef V2CanaryPreferencesLoader = Future<SharedPreferences> Function();
typedef V2CanaryAssessmentLoader = Future<RecommendationShadowCanaryAssessment>
    Function({
  required String baselineVersion,
  required String experimentVersion,
});
typedef V2CanaryOutcomeVerdictLoader = Future<RecommendationAlgorithmVerdict>
    Function({
  required String baselineVersion,
  required String candidateVersion,
  DateTime? since,
});
typedef V2CanaryInstallationKeyFactory = String Function();
typedef V2CanaryBucketResolver = int Function(
  String installationKey,
  String experimentVersion,
);

class RecommendationCanaryDecision {
  const RecommendationCanaryDecision({
    required this.useExperiment,
    required this.rankingVersion,
    required this.algorithmVersion,
  });

  final bool useExperiment;
  final String rankingVersion;
  final String algorithmVersion;
}

enum RecommendationCanaryConfigurationState {
  absent,
  active,
  scheduled,
  expired,
  invalid,
  incompatibleBaseline,
  forcedDisabled,
  unavailable,
}

class RecommendationCanaryConfigurationInspection {
  RecommendationCanaryConfigurationInspection({
    required this.state,
    required this.inspectedAt,
    required List<String> reasons,
    this.config,
  }) : reasons = List.unmodifiable(reasons);

  final RecommendationCanaryConfigurationState state;
  final DateTime inspectedAt;
  final RecommendationCanaryConfig? config;
  final List<String> reasons;

  bool get hasActiveConfiguration =>
      state == RecommendationCanaryConfigurationState.active;
}

class V2RecommendationCanaryService {
  V2RecommendationCanaryService({
    V2CanaryPreferencesLoader? preferencesLoader,
    V2RecommendationShadowInsights? insights,
    V2CanaryAssessmentLoader? assessmentLoader,
    V2RecommendationFunnelInsights? funnelInsights,
    V2CanaryOutcomeVerdictLoader? outcomeVerdictLoader,
    V2CanaryInstallationKeyFactory? installationKeyFactory,
    V2CanaryBucketResolver? bucketResolver,
    DateTime Function()? clock,
    this.baselineRankingVersion = 'local_rank_v2',
    this.baselineAlgorithmVersion = 'hybrid_v3_0',
  })  : assert(insights == null || assessmentLoader == null),
        assert(funnelInsights == null || outcomeVerdictLoader == null),
        _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
        _assessmentLoader =
            assessmentLoader ?? _buildAssessmentLoader(insights),
        _outcomeVerdictLoader =
            outcomeVerdictLoader ?? _buildOutcomeVerdictLoader(funnelInsights),
        _installationKeyFactory =
            installationKeyFactory ?? _createInstallationKey,
        _bucketResolver = bucketResolver ?? _stableBucket,
        _clock = clock ?? DateTime.now;

  static final V2RecommendationCanaryService instance =
      V2RecommendationCanaryService();

  static const String schemaVersion =
      RecommendationCanaryConfig.supportedSchemaVersion;
  static const String _configKey = 'v2_recommendation_canary_config_v1';
  static const String _installationKey =
      'v2_recommendation_canary_installation_key_v1';

  final V2CanaryPreferencesLoader _preferencesLoader;
  final V2CanaryAssessmentLoader _assessmentLoader;
  final V2CanaryOutcomeVerdictLoader _outcomeVerdictLoader;
  final V2CanaryInstallationKeyFactory _installationKeyFactory;
  final V2CanaryBucketResolver _bucketResolver;
  final DateTime Function() _clock;
  final String baselineRankingVersion;
  final String baselineAlgorithmVersion;
  Future<void> _pendingOperation = Future<void>.value();
  bool _forceDisabled = false;

  RecommendationCanaryDecision get baselineDecision {
    return RecommendationCanaryDecision(
      useExperiment: false,
      rankingVersion: baselineRankingVersion,
      algorithmVersion: baselineAlgorithmVersion,
    );
  }

  /// Reads the persisted canary state without repairing, deleting, or
  /// creating any local identifiers.
  Future<RecommendationCanaryConfigurationInspection>
      inspectConfiguration() async {
    final inspectedAt = _clock();
    try {
      final prefs = await _preferencesLoader();
      final raw = prefs.getString(_configKey);
      if (raw == null) {
        return RecommendationCanaryConfigurationInspection(
          state: RecommendationCanaryConfigurationState.absent,
          inspectedAt: inspectedAt,
          reasons: const ['canary_configuration_absent'],
        );
      }
      final config = _decodeConfig(raw);
      if (config == null) {
        return RecommendationCanaryConfigurationInspection(
          state: RecommendationCanaryConfigurationState.invalid,
          inspectedAt: inspectedAt,
          reasons: const ['canary_configuration_invalid'],
        );
      }
      if (config.baselineRankingVersion != baselineRankingVersion ||
          config.baselineAlgorithmVersion != baselineAlgorithmVersion) {
        return RecommendationCanaryConfigurationInspection(
          state: RecommendationCanaryConfigurationState.incompatibleBaseline,
          inspectedAt: inspectedAt,
          config: config,
          reasons: const ['canary_configuration_baseline_mismatch'],
        );
      }
      if (_forceDisabled) {
        return RecommendationCanaryConfigurationInspection(
          state: RecommendationCanaryConfigurationState.forcedDisabled,
          inspectedAt: inspectedAt,
          config: config,
          reasons: const ['canary_configuration_forced_disabled_in_process'],
        );
      }
      if (config.activatedAt.isAfter(inspectedAt)) {
        return RecommendationCanaryConfigurationInspection(
          state: RecommendationCanaryConfigurationState.scheduled,
          inspectedAt: inspectedAt,
          config: config,
          reasons: const ['canary_configuration_not_yet_active'],
        );
      }
      if (!config.expiresAt.isAfter(inspectedAt)) {
        return RecommendationCanaryConfigurationInspection(
          state: RecommendationCanaryConfigurationState.expired,
          inspectedAt: inspectedAt,
          config: config,
          reasons: const ['canary_configuration_expired'],
        );
      }
      return RecommendationCanaryConfigurationInspection(
        state: RecommendationCanaryConfigurationState.active,
        inspectedAt: inspectedAt,
        config: config,
        reasons: const ['canary_configuration_active'],
      );
    } catch (_) {
      return RecommendationCanaryConfigurationInspection(
        state: RecommendationCanaryConfigurationState.unavailable,
        inspectedAt: inspectedAt,
        reasons: const ['canary_configuration_read_failed'],
      );
    }
  }

  Future<bool> activateControlledCanary({
    required String experimentRankingVersion,
    required String experimentAlgorithmVersion,
    required int rolloutBasisPoints,
    Duration duration = const Duration(days: 1),
  }) {
    return _enqueue(() async {
      if (rolloutBasisPoints <= 0 ||
          rolloutBasisPoints >
              RecommendationCanaryConfig.maximumRolloutBasisPoints ||
          duration <= Duration.zero ||
          duration > RecommendationCanaryConfig.maximumDuration) {
        return false;
      }
      try {
        final assessment = await _assessmentLoader(
          baselineVersion: baselineRankingVersion,
          experimentVersion: experimentRankingVersion,
        );
        if (!assessment.eligibleForControlledCanary ||
            assessment.baselineVersion != baselineRankingVersion ||
            assessment.experimentVersion != experimentRankingVersion) {
          return false;
        }
        final outcomeVerdict = await _outcomeVerdictLoader(
          baselineVersion: baselineAlgorithmVersion,
          candidateVersion: experimentAlgorithmVersion,
        );
        if (outcomeVerdict == RecommendationAlgorithmVerdict.regression) {
          return false;
        }

        final now = _clock();
        final config = RecommendationCanaryConfig.tryFromJson({
          'schema_version': schemaVersion,
          'baseline_ranking_version': baselineRankingVersion,
          'experiment_ranking_version': experimentRankingVersion,
          'baseline_algorithm_version': baselineAlgorithmVersion,
          'experiment_algorithm_version': experimentAlgorithmVersion,
          'rollout_basis_points': rolloutBasisPoints,
          'activated_at': now.toUtc().toIso8601String(),
          'expires_at': now.add(duration).toUtc().toIso8601String(),
        });
        if (config == null) return false;
        final prefs = await _preferencesLoader();
        final saved = await prefs.setString(
          _configKey,
          jsonEncode(config.toJson()),
        );
        if (saved) _forceDisabled = false;
        return saved;
      } catch (_) {
        return false;
      }
    });
  }

  Future<RecommendationCanaryDecision> decide() {
    return _enqueue(() async {
      if (_forceDisabled) return baselineDecision;
      try {
        final prefs = await _preferencesLoader();
        final config = _decodeConfig(prefs.getString(_configKey));
        if (config == null) return baselineDecision;
        if (!config.isActiveAt(_clock()) ||
            config.baselineRankingVersion != baselineRankingVersion ||
            config.baselineAlgorithmVersion != baselineAlgorithmVersion) {
          await prefs.remove(_configKey);
          return baselineDecision;
        }

        final assessment = await _assessmentLoader(
          baselineVersion: config.baselineRankingVersion,
          experimentVersion: config.experimentRankingVersion,
        );
        if (!assessment.eligibleForControlledCanary ||
            assessment.baselineVersion != config.baselineRankingVersion ||
            assessment.experimentVersion != config.experimentRankingVersion) {
          await _disableConfig(prefs);
          return baselineDecision;
        }

        final outcomeVerdict = await _outcomeVerdictLoader(
          baselineVersion: config.baselineAlgorithmVersion,
          candidateVersion: config.experimentAlgorithmVersion,
          since: config.activatedAt,
        );
        if (outcomeVerdict == RecommendationAlgorithmVerdict.regression) {
          await _disableConfig(prefs);
          return baselineDecision;
        }

        final installationKey = await _loadOrCreateInstallationKey(prefs);
        final bucket = _bucketResolver(
          installationKey,
          config.experimentRankingVersion,
        );
        if (bucket < 0 || bucket >= 10000) {
          return baselineDecision;
        }
        if (bucket >= config.rolloutBasisPoints) return baselineDecision;
        return RecommendationCanaryDecision(
          useExperiment: true,
          rankingVersion: config.experimentRankingVersion,
          algorithmVersion: config.experimentAlgorithmVersion,
        );
      } catch (_) {
        return baselineDecision;
      }
    });
  }

  Future<bool> deactivate() {
    return _enqueue(() async {
      _forceDisabled = true;
      try {
        final prefs = await _preferencesLoader();
        return prefs.remove(_configKey);
      } catch (_) {
        return false;
      }
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _pendingOperation.then((_) => operation());
    _pendingOperation = result.then<void>(
      (_) {},
      onError: (_, __) {},
    );
    return result;
  }

  static V2CanaryAssessmentLoader _buildAssessmentLoader(
    V2RecommendationShadowInsights? insights,
  ) {
    final resolved = insights ?? V2RecommendationShadowInsights.instance;
    return resolved.evaluateCanaryEligibility;
  }

  static V2CanaryOutcomeVerdictLoader _buildOutcomeVerdictLoader(
    V2RecommendationFunnelInsights? insights,
  ) {
    final resolved = insights ?? V2RecommendationFunnelInsights.instance;
    return ({
      required baselineVersion,
      required candidateVersion,
      since,
    }) async {
      final comparison = await resolved.compareAlgorithms(
        baselineVersion: baselineVersion,
        candidateVersion: candidateVersion,
        since: since,
      );
      return comparison.verdict;
    };
  }

  Future<void> _disableConfig(SharedPreferences prefs) async {
    _forceDisabled = true;
    await prefs.remove(_configKey);
  }

  RecommendationCanaryConfig? _decodeConfig(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return RecommendationCanaryConfig.tryFromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String> _loadOrCreateInstallationKey(SharedPreferences prefs) async {
    final existing = prefs.getString(_installationKey)?.trim();
    if (existing != null && _safeInstallationKey.hasMatch(existing)) {
      return existing;
    }
    final created = _installationKeyFactory();
    if (!_safeInstallationKey.hasMatch(created)) {
      throw StateError('Invalid anonymous installation key.');
    }
    final saved = await prefs.setString(_installationKey, created);
    if (!saved) throw StateError('Failed to persist installation key.');
    return created;
  }

  static String _createInstallationKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(18, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static int _stableBucket(String installationKey, String experimentVersion) {
    final digest = sha256.convert(
      utf8.encode('$installationKey|$experimentVersion'),
    );
    final bytes = digest.bytes;
    final value =
        (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
    return value % 10000;
  }

  static final RegExp _safeInstallationKey = RegExp(r'^[a-zA-Z0-9_-]{16,64}$');
}
