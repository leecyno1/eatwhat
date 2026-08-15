import 'dart:convert';

enum RecommendationCanaryManifestDirective {
  proposeControlledCanary,
  disable,
}

class RecommendationCanaryManifest {
  const RecommendationCanaryManifest({
    required this.schemaVersion,
    required this.revision,
    required this.audience,
    required this.environment,
    required this.directive,
    required this.issuedAt,
    required this.expiresAt,
    required this.baselineRankingVersion,
    required this.experimentRankingVersion,
    required this.baselineAlgorithmVersion,
    required this.experimentAlgorithmVersion,
    required this.rolloutBasisPoints,
  });

  static const String supportedSchemaVersion = 'v1';
  static const Duration maximumLifetime = Duration(days: 7);
  static const int maximumRolloutBasisPoints = 1000;
  static const int maximumSafeRevision = 9007199254740991;

  final String schemaVersion;
  final int revision;
  final String audience;
  final String environment;
  final RecommendationCanaryManifestDirective directive;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String baselineRankingVersion;
  final String experimentRankingVersion;
  final String baselineAlgorithmVersion;
  final String experimentAlgorithmVersion;
  final int rolloutBasisPoints;

  bool get proposesControlledCanary =>
      directive ==
      RecommendationCanaryManifestDirective.proposeControlledCanary;

  Map<String, Object> toJson() {
    return {
      'schema_version': schemaVersion,
      'revision': revision,
      'audience': audience,
      'environment': environment,
      'directive': _directiveName(directive),
      'issued_at': issuedAt.toUtc().toIso8601String(),
      'expires_at': expiresAt.toUtc().toIso8601String(),
      'baseline_ranking_version': baselineRankingVersion,
      'experiment_ranking_version': experimentRankingVersion,
      'baseline_algorithm_version': baselineAlgorithmVersion,
      'experiment_algorithm_version': experimentAlgorithmVersion,
      'rollout_basis_points': rolloutBasisPoints,
    };
  }

  List<int> canonicalPayloadBytes() => utf8.encode(jsonEncode(toJson()));

  static RecommendationCanaryManifest? tryFromJson(
    Map<String, dynamic> json,
  ) {
    if (!_hasExactKeys(json, _payloadKeys)) return null;
    final schemaVersion = _string(json['schema_version']);
    final revision = json['revision'];
    final audience = _string(json['audience']);
    final environment = _string(json['environment']);
    final directive = _parseDirective(json['directive']);
    final issuedAt = _utcDate(json['issued_at']);
    final expiresAt = _utcDate(json['expires_at']);
    final baselineRankingVersion = _string(json['baseline_ranking_version']);
    final experimentRankingVersion =
        _string(json['experiment_ranking_version']);
    final baselineAlgorithmVersion =
        _string(json['baseline_algorithm_version']);
    final experimentAlgorithmVersion =
        _string(json['experiment_algorithm_version']);
    final rolloutBasisPoints = json['rollout_basis_points'];

    if (schemaVersion != supportedSchemaVersion ||
        revision is! int ||
        revision <= 0 ||
        revision > maximumSafeRevision ||
        !_safeAudience.hasMatch(audience) ||
        !_safeEnvironment.hasMatch(environment) ||
        directive == null ||
        issuedAt == null ||
        expiresAt == null ||
        !expiresAt.isAfter(issuedAt) ||
        expiresAt.difference(issuedAt) > maximumLifetime ||
        !_safeVersion.hasMatch(baselineRankingVersion) ||
        !_safeVersion.hasMatch(experimentRankingVersion) ||
        !_safeVersion.hasMatch(baselineAlgorithmVersion) ||
        !_safeVersion.hasMatch(experimentAlgorithmVersion) ||
        baselineRankingVersion == experimentRankingVersion ||
        baselineAlgorithmVersion == experimentAlgorithmVersion ||
        rolloutBasisPoints is! int ||
        !_validRollout(directive, rolloutBasisPoints)) {
      return null;
    }

    return RecommendationCanaryManifest(
      schemaVersion: schemaVersion,
      revision: revision,
      audience: audience,
      environment: environment,
      directive: directive,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      baselineRankingVersion: baselineRankingVersion,
      experimentRankingVersion: experimentRankingVersion,
      baselineAlgorithmVersion: baselineAlgorithmVersion,
      experimentAlgorithmVersion: experimentAlgorithmVersion,
      rolloutBasisPoints: rolloutBasisPoints,
    );
  }

  static bool _validRollout(
    RecommendationCanaryManifestDirective directive,
    int rolloutBasisPoints,
  ) {
    return switch (directive) {
      RecommendationCanaryManifestDirective.proposeControlledCanary =>
        rolloutBasisPoints > 0 &&
            rolloutBasisPoints <= maximumRolloutBasisPoints,
      RecommendationCanaryManifestDirective.disable => rolloutBasisPoints == 0,
    };
  }

  static RecommendationCanaryManifestDirective? _parseDirective(
    Object? raw,
  ) {
    return switch (raw) {
      'propose_controlled_canary' =>
        RecommendationCanaryManifestDirective.proposeControlledCanary,
      'disable' => RecommendationCanaryManifestDirective.disable,
      _ => null,
    };
  }

  static String _directiveName(
    RecommendationCanaryManifestDirective directive,
  ) {
    return switch (directive) {
      RecommendationCanaryManifestDirective.proposeControlledCanary =>
        'propose_controlled_canary',
      RecommendationCanaryManifestDirective.disable => 'disable',
    };
  }

  static DateTime? _utcDate(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null || !raw.endsWith('Z')) return null;
    return parsed.toUtc();
  }

  static String _string(Object? raw) => raw is String ? raw : '';

  static bool _hasExactKeys(
    Map<String, dynamic> json,
    Set<String> expected,
  ) {
    return json.length == expected.length &&
        json.keys.toSet().containsAll(expected);
  }

  static const Set<String> _payloadKeys = {
    'schema_version',
    'revision',
    'audience',
    'environment',
    'directive',
    'issued_at',
    'expires_at',
    'baseline_ranking_version',
    'experiment_ranking_version',
    'baseline_algorithm_version',
    'experiment_algorithm_version',
    'rollout_basis_points',
  };
  static final RegExp _safeAudience = RegExp(r'^[a-zA-Z0-9_.-]{1,96}$');
  static final RegExp _safeEnvironment = RegExp(r'^[a-z][a-z0-9_-]{0,31}$');
  static final RegExp _safeVersion = RegExp(r'^[a-zA-Z0-9_.-]{1,64}$');
}

class RecommendationCanarySignedManifest {
  RecommendationCanarySignedManifest({
    required this.manifest,
    required this.keyId,
    required List<int> signatureBytes,
  }) : signatureBytes = List.unmodifiable(signatureBytes);

  static const String signatureAlgorithm = 'ed25519';

  final RecommendationCanaryManifest manifest;
  final String keyId;
  final List<int> signatureBytes;

  Map<String, Object> toJson() {
    return {
      'payload': manifest.toJson(),
      'signature': {
        'algorithm': signatureAlgorithm,
        'key_id': keyId,
        'value': base64UrlEncode(signatureBytes).replaceAll('=', ''),
      },
    };
  }

  static RecommendationCanarySignedManifest? tryFromJson(
    Map<String, dynamic> json,
  ) {
    if (!_hasExactKeys(json, const {'payload', 'signature'})) return null;
    final payloadRaw = json['payload'];
    final signatureRaw = json['signature'];
    if (payloadRaw is! Map || signatureRaw is! Map) return null;
    final payload = Map<String, dynamic>.from(payloadRaw);
    final signature = Map<String, dynamic>.from(signatureRaw);
    if (!_hasExactKeys(
      signature,
      const {'algorithm', 'key_id', 'value'},
    )) {
      return null;
    }
    if (signature['algorithm'] != signatureAlgorithm) return null;
    final keyId = signature['key_id'];
    final encodedSignature = signature['value'];
    if (keyId is! String ||
        !_safeKeyId.hasMatch(keyId) ||
        encodedSignature is! String) {
      return null;
    }
    final signatureBytes = _decodeBase64Url(encodedSignature);
    final manifest = RecommendationCanaryManifest.tryFromJson(payload);
    if (manifest == null || signatureBytes?.length != 64) return null;
    return RecommendationCanarySignedManifest(
      manifest: manifest,
      keyId: keyId,
      signatureBytes: signatureBytes!,
    );
  }

  static List<int>? _decodeBase64Url(String raw) {
    if (raw.isEmpty || !_safeBase64Url.hasMatch(raw)) return null;
    try {
      return base64Url.decode(base64Url.normalize(raw));
    } catch (_) {
      return null;
    }
  }

  static bool _hasExactKeys(
    Map<String, dynamic> json,
    Set<String> expected,
  ) {
    return json.length == expected.length &&
        json.keys.toSet().containsAll(expected);
  }

  static final RegExp _safeKeyId = RegExp(r'^[a-zA-Z0-9_.-]{1,64}$');
  static final RegExp _safeBase64Url = RegExp(r'^[a-zA-Z0-9_-]{1,128}$');
}
