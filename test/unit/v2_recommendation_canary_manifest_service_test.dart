import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_canary_manifest.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_manifest_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Ed25519 algorithm;
  late KeyPair keyPair;
  late List<int> publicKey;

  setUpAll(() async {
    algorithm = Ed25519();
    keyPair = await algorithm.newKeyPair();
    publicKey = (await keyPair.extractPublicKey() as SimplePublicKey).bytes;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('严格模型拒绝未知字段、超限比例、超长生命周期和不一致停用指令', () {
    final valid = _manifest().toJson();
    expect(
      RecommendationCanaryManifest.tryFromJson(
        Map<String, dynamic>.from(valid),
      ),
      isNotNull,
    );

    final invalidPayloads = [
      {...valid, 'unexpected': true},
      {...valid, 'rollout_basis_points': 1001},
      {
        ...valid,
        'expires_at': DateTime.utc(2026, 8, 13).toIso8601String(),
      },
      {
        ...valid,
        'directive': 'disable',
        'rollout_basis_points': 1,
      },
      {...valid, 'revision': 1.0},
      {...valid, 'issued_at': '2026-08-05T08:00:00+08:00'},
    ];
    for (final payload in invalidPayloads) {
      expect(
        RecommendationCanaryManifest.tryFromJson(
          Map<String, dynamic>.from(payload),
        ),
        isNull,
      );
    }
  });

  test('未配置可信公钥时默认关闭且不读取或写入状态', () async {
    var reads = 0;
    var writes = 0;
    final service = V2RecommendationCanaryManifestService(
      expectedAudience: _audience,
      expectedEnvironment: _environment,
      stateReader: () async {
        reads += 1;
        return null;
      },
      stateWriter: (_) async {
        writes += 1;
        return true;
      },
    );

    final result = await service.ingest('{}');

    expect(
      result.state,
      RecommendationCanaryManifestIngestionState.trustStoreUnconfigured,
    );
    expect(reads, 0);
    expect(writes, 0);
    _expectNoAutomaticAuthority(result);
  });

  test('真实 Ed25519 签名通过后只暂存供人工审核', () async {
    String? storedState;
    final manifest = _manifest();
    final service = _service(
      publicKey: publicKey,
      stateReader: () async => storedState,
      stateWriter: (value) async {
        storedState = value;
        return true;
      },
    );

    final result = await service.ingest(
      await _signedJson(algorithm, keyPair, manifest),
    );

    expect(
      result.state,
      RecommendationCanaryManifestIngestionState.acceptedForManualReview,
    );
    expect(result.manifest?.revision, 7);
    expect(result.payloadDigest, hasLength(64));
    expect(storedState, isNotNull);
    _expectNoAutomaticAuthority(result);

    final inspection = await service.inspectStagedManifest();
    expect(inspection.state, RecommendationCanaryStagedManifestState.staged);
    expect(inspection.hasPendingManualReview, isTrue);
    expect(inspection.manifest?.rolloutBasisPoints, 500);
    expect(inspection.authorizesCanaryActivation, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
  });

  test('签名绑定规范化载荷，篡改任何字段均拒绝且不写入', () async {
    String? storedState;
    final raw = await _signedJson(algorithm, keyPair, _manifest());
    final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final payload = Map<String, dynamic>.from(decoded['payload'] as Map);
    payload['rollout_basis_points'] = 900;
    decoded['payload'] = payload;
    final service = _service(
      publicKey: publicKey,
      stateReader: () async => storedState,
      stateWriter: (value) async {
        storedState = value;
        return true;
      },
    );

    final result = await service.ingest(jsonEncode(decoded));

    expect(
      result.state,
      RecommendationCanaryManifestIngestionState.invalidSignature,
    );
    expect(result.manifest, isNull);
    expect(storedState, isNull);
    _expectNoAutomaticAuthority(result);
  });

  test('未知密钥、跨应用、跨环境、未来签发和过期清单全部拒绝', () async {
    final cases = <(
      RecommendationCanaryManifest,
      String,
      RecommendationCanaryManifestIngestionState
    )>[
      (
        _manifest(),
        'unknown-key',
        RecommendationCanaryManifestIngestionState.unknownKey,
      ),
      (
        _manifest(audience: 'com.example.other'),
        _keyId,
        RecommendationCanaryManifestIngestionState.wrongAudience,
      ),
      (
        _manifest(environment: 'staging'),
        _keyId,
        RecommendationCanaryManifestIngestionState.wrongEnvironment,
      ),
      (
        _manifest(
          issuedAt: DateTime.utc(2026, 8, 5, 9, 6),
          expiresAt: DateTime.utc(2026, 8, 5, 12),
        ),
        _keyId,
        RecommendationCanaryManifestIngestionState.issuedInFuture,
      ),
      (
        _manifest(
          issuedAt: DateTime.utc(2026, 8, 4, 8),
          expiresAt: DateTime.utc(2026, 8, 5, 9),
        ),
        _keyId,
        RecommendationCanaryManifestIngestionState.expired,
      ),
    ];
    for (final testCase in cases) {
      String? storedState;
      final service = _service(
        publicKey: publicKey,
        stateReader: () async => storedState,
        stateWriter: (value) async {
          storedState = value;
          return true;
        },
      );

      final result = await service.ingest(
        await _signedJson(
          algorithm,
          keyPair,
          testCase.$1,
          keyId: testCase.$2,
        ),
      );

      expect(result.state, testCase.$3, reason: testCase.$3.name);
      if (testCase.$3 ==
          RecommendationCanaryManifestIngestionState.unknownKey) {
        expect(result.manifest, isNull);
      } else {
        expect(result.manifest, isNotNull);
      }
      expect(storedState, isNull);
      _expectNoAutomaticAuthority(result);
    }
  });

  test('相同或更低修订号不能回放，更高修订号才能替换暂存状态', () async {
    String? storedState;
    final service = _service(
      publicKey: publicKey,
      stateReader: () async => storedState,
      stateWriter: (value) async {
        storedState = value;
        return true;
      },
    );
    expect(
      (await service.ingest(
        await _signedJson(algorithm, keyPair, _manifest()),
      ))
          .acceptedForManualReview,
      isTrue,
    );

    for (final revision in [7, 6]) {
      final result = await service.ingest(
        await _signedJson(
          algorithm,
          keyPair,
          _manifest(revision: revision),
        ),
      );
      expect(
        result.state,
        RecommendationCanaryManifestIngestionState.replayedOrStale,
      );
    }

    final newer = await service.ingest(
      await _signedJson(algorithm, keyPair, _manifest(revision: 8)),
    );
    expect(newer.acceptedForManualReview, isTrue);
    expect(
      (await service.inspectStagedManifest()).manifest?.revision,
      8,
    );
  });

  test('被篡改的安全暂存状态不会被读取或被新清单静默覆盖', () async {
    String? storedState;
    final service = _service(
      publicKey: publicKey,
      stateReader: () async => storedState,
      stateWriter: (value) async {
        storedState = value;
        return true;
      },
    );
    await service.ingest(
      await _signedJson(algorithm, keyPair, _manifest()),
    );
    final decoded = Map<String, dynamic>.from(jsonDecode(storedState!) as Map);
    final signed = Map<String, dynamic>.from(
      decoded['signed_manifest'] as Map,
    );
    final payload = Map<String, dynamic>.from(signed['payload'] as Map);
    payload['rollout_basis_points'] = 900;
    signed['payload'] = payload;
    decoded['signed_manifest'] = signed;
    decoded['payload_digest'] = sha256
        .convert(
          RecommendationCanaryManifest.tryFromJson(payload)!
              .canonicalPayloadBytes(),
        )
        .toString();
    storedState = jsonEncode(decoded);
    final tamperedState = storedState;

    expect(
      (await service.inspectStagedManifest()).state,
      RecommendationCanaryStagedManifestState.invalid,
    );
    final result = await service.ingest(
      await _signedJson(algorithm, keyPair, _manifest(revision: 8)),
    );
    expect(
      result.state,
      RecommendationCanaryManifestIngestionState.stagedStateInvalid,
    );
    expect(storedState, tamperedState);
  });

  test('停用清单也只暂存供人工处理，不直接操作运行中灰度', () async {
    String? storedState;
    final service = _service(
      publicKey: publicKey,
      stateReader: () async => storedState,
      stateWriter: (value) async {
        storedState = value;
        return true;
      },
    );
    final manifest = _manifest(
      directive: RecommendationCanaryManifestDirective.disable,
      rolloutBasisPoints: 0,
    );

    final result = await service.ingest(
      await _signedJson(algorithm, keyPair, manifest),
    );

    expect(result.acceptedForManualReview, isTrue);
    expect(result.reason, 'canary_manifest_disable_staged_for_manual_review');
    _expectNoAutomaticAuthority(result);
    expect(
      (await service.inspectStagedManifest()).manifest?.directive,
      RecommendationCanaryManifestDirective.disable,
    );
  });

  test('安全存储失败、损坏状态和超大清单均保守失败', () async {
    final storageFailure = _service(
      publicKey: publicKey,
      stateReader: () async => null,
      stateWriter: (_) async => false,
    );
    expect(
      (await storageFailure.ingest(
        await _signedJson(algorithm, keyPair, _manifest()),
      ))
          .state,
      RecommendationCanaryManifestIngestionState.storageUnavailable,
    );

    final corrupted = _service(
      publicKey: publicKey,
      stateReader: () async => '{broken',
      stateWriter: (_) async => true,
    );
    expect(
      (await corrupted.inspectStagedManifest()).state,
      RecommendationCanaryStagedManifestState.invalid,
    );

    var verified = false;
    final oversized = V2RecommendationCanaryManifestService(
      expectedAudience: _audience,
      expectedEnvironment: _environment,
      trustedPublicKeys: {_keyId: publicKey},
      maximumManifestBytes: 8,
      stateReader: () async => null,
      stateWriter: (_) async => true,
      signatureVerifier: ({
        required message,
        required signature,
        required publicKey,
      }) async {
        verified = true;
        return true;
      },
    );
    expect(
      (await oversized.ingest('123456789')).state,
      RecommendationCanaryManifestIngestionState.manifestTooLarge,
    );
    expect(verified, isFalse);
  });

  test('已暂存清单到期后不再显示为待人工审核', () async {
    var now = DateTime.utc(2026, 8, 5, 9);
    String? storedState;
    final service = _service(
      publicKey: publicKey,
      clock: () => now,
      stateReader: () async => storedState,
      stateWriter: (value) async {
        storedState = value;
        return true;
      },
    );
    await service.ingest(
      await _signedJson(
        algorithm,
        keyPair,
        _manifest(expiresAt: DateTime.utc(2026, 8, 5, 10)),
      ),
    );

    now = DateTime.utc(2026, 8, 5, 10);
    final inspection = await service.inspectStagedManifest();
    expect(inspection.state, RecommendationCanaryStagedManifestState.expired);
    expect(inspection.hasPendingManualReview, isFalse);
    expect(inspection.authorizesCanaryActivation, isFalse);
  });

  test('人工确认必须匹配修订号和摘要且不授予任何灰度权限', () async {
    String? storedState;
    final service = _service(
      publicKey: publicKey,
      stateReader: () async => storedState,
      stateWriter: (value) async {
        storedState = value;
        return true;
      },
    );
    final ingestion = await service.ingest(
      await _signedJson(algorithm, keyPair, _manifest()),
    );

    final wrongRevision = await service.acknowledgeManualReview(
      revision: 6,
      payloadDigest: ingestion.payloadDigest!,
    );
    final wrongDigest = await service.acknowledgeManualReview(
      revision: 7,
      payloadDigest: 'b' * 64,
    );
    expect(
      wrongRevision.state,
      RecommendationCanaryManifestAcknowledgementState.tokenMismatch,
    );
    expect(
      wrongDigest.state,
      RecommendationCanaryManifestAcknowledgementState.tokenMismatch,
    );
    expect(
      (await service.inspectStagedManifest()).state,
      RecommendationCanaryStagedManifestState.staged,
    );

    final acknowledged = await service.acknowledgeManualReview(
      revision: 7,
      payloadDigest: ingestion.payloadDigest!,
    );
    expect(acknowledged.acknowledged, isTrue);
    expect(acknowledged.authorizesCanaryActivation, isFalse);
    expect(acknowledged.authorizesCanaryExpansion, isFalse);
    expect(acknowledged.authorizesCanaryDeactivation, isFalse);
    expect(acknowledged.authorizesFullRollout, isFalse);
    expect(
      (await service.inspectStagedManifest()).state,
      RecommendationCanaryStagedManifestState.reviewed,
    );
    expect(
      (await service.acknowledgeManualReview(
        revision: 7,
        payloadDigest: ingestion.payloadDigest!,
      ))
          .state,
      RecommendationCanaryManifestAcknowledgementState.alreadyAcknowledged,
    );
  });

  test('人工确认后仍保留最高修订号并阻止旧清单回放', () async {
    String? storedState;
    final service = _service(
      publicKey: publicKey,
      stateReader: () async => storedState,
      stateWriter: (value) async {
        storedState = value;
        return true;
      },
    );
    final first = await service.ingest(
      await _signedJson(algorithm, keyPair, _manifest()),
    );
    await service.acknowledgeManualReview(
      revision: 7,
      payloadDigest: first.payloadDigest!,
    );

    final replay = await service.ingest(
      await _signedJson(algorithm, keyPair, _manifest()),
    );
    expect(
      replay.state,
      RecommendationCanaryManifestIngestionState.replayedOrStale,
    );
    expect(
      (await service.inspectStagedManifest()).state,
      RecommendationCanaryStagedManifestState.reviewed,
    );
  });

  test('过期后不能再用旧审核令牌关闭待办', () async {
    var now = DateTime.utc(2026, 8, 5, 9);
    String? storedState;
    final service = _service(
      publicKey: publicKey,
      clock: () => now,
      stateReader: () async => storedState,
      stateWriter: (value) async {
        storedState = value;
        return true;
      },
    );
    final ingestion = await service.ingest(
      await _signedJson(
        algorithm,
        keyPair,
        _manifest(expiresAt: DateTime.utc(2026, 8, 5, 10)),
      ),
    );
    final originalState = storedState;
    now = DateTime.utc(2026, 8, 5, 10);

    final acknowledgement = await service.acknowledgeManualReview(
      revision: 7,
      payloadDigest: ingestion.payloadDigest!,
    );

    expect(
      acknowledgement.state,
      RecommendationCanaryManifestAcknowledgementState.expired,
    );
    expect(storedState, originalState);
  });

  test('人工确认的有效期判断和审核时间共用同一时间快照', () async {
    var clockReads = 0;
    String? storedState;
    final service = _service(
      publicKey: publicKey,
      clock: () {
        clockReads += 1;
        return clockReads <= 2
            ? DateTime.utc(2026, 8, 5, 9)
            : DateTime.utc(2026, 8, 5, 10);
      },
      stateReader: () async => storedState,
      stateWriter: (value) async {
        storedState = value;
        return true;
      },
    );
    final ingestion = await service.ingest(
      await _signedJson(
        algorithm,
        keyPair,
        _manifest(expiresAt: DateTime.utc(2026, 8, 5, 10)),
      ),
    );

    final acknowledgement = await service.acknowledgeManualReview(
      revision: 7,
      payloadDigest: ingestion.payloadDigest!,
    );

    expect(acknowledgement.acknowledged, isTrue);
    expect(clockReads, 2);
    final persisted =
        Map<String, dynamic>.from(jsonDecode(storedState!) as Map);
    expect(persisted['reviewed_at'], '2026-08-05T09:00:00.000Z');
  });
}

V2RecommendationCanaryManifestService _service({
  required List<int> publicKey,
  required V2CanaryManifestStateReader stateReader,
  required V2CanaryManifestStateWriter stateWriter,
  DateTime Function()? clock,
}) {
  return V2RecommendationCanaryManifestService(
    expectedAudience: _audience,
    expectedEnvironment: _environment,
    trustedPublicKeys: {_keyId: publicKey},
    stateReader: stateReader,
    stateWriter: stateWriter,
    clock: clock ?? () => DateTime.utc(2026, 8, 5, 9),
  );
}

RecommendationCanaryManifest _manifest({
  int revision = 7,
  String audience = _audience,
  String environment = _environment,
  RecommendationCanaryManifestDirective directive =
      RecommendationCanaryManifestDirective.proposeControlledCanary,
  DateTime? issuedAt,
  DateTime? expiresAt,
  int rolloutBasisPoints = 500,
}) {
  return RecommendationCanaryManifest(
    schemaVersion: RecommendationCanaryManifest.supportedSchemaVersion,
    revision: revision,
    audience: audience,
    environment: environment,
    directive: directive,
    issuedAt: issuedAt ?? DateTime.utc(2026, 8, 5, 8),
    expiresAt: expiresAt ?? DateTime.utc(2026, 8, 6, 8),
    baselineRankingVersion: 'local_rank_v2',
    experimentRankingVersion: 'local_rank_v3_quality_shadow',
    baselineAlgorithmVersion: 'hybrid_v3_0',
    experimentAlgorithmVersion: 'hybrid_v3_0_rank_v3_canary',
    rolloutBasisPoints: rolloutBasisPoints,
  );
}

Future<String> _signedJson(
  Ed25519 algorithm,
  KeyPair keyPair,
  RecommendationCanaryManifest manifest, {
  String keyId = _keyId,
}) async {
  final signature = await algorithm.sign(
    manifest.canonicalPayloadBytes(),
    keyPair: keyPair,
  );
  return jsonEncode(
    RecommendationCanarySignedManifest(
      manifest: manifest,
      keyId: keyId,
      signatureBytes: signature.bytes,
    ).toJson(),
  );
}

void _expectNoAutomaticAuthority(
  RecommendationCanaryManifestIngestionResult result,
) {
  expect(result.authorizesCanaryActivation, isFalse);
  expect(result.authorizesCanaryExpansion, isFalse);
  expect(result.authorizesFullRollout, isFalse);
}

const _audience = 'com.eatwhat.eatwhatApp';
const _environment = 'production';
const _keyId = 'recommendation-canary-2026-01';
