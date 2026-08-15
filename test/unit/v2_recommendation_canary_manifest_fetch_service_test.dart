import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_canary_manifest.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_manifest_fetch_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_manifest_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('默认关闭时不创建网络客户端也不触碰信任边界', () async {
    var clients = 0;
    var ingestions = 0;
    final service = V2RecommendationCanaryManifestFetchService(
      manifestIngester: (rawManifest) async {
        ingestions += 1;
        return _ingestion();
      },
      httpClientFactory: () {
        clients += 1;
        return MockClient((_) async => http.Response('{}', 200));
      },
    );

    final result = await service.fetch();

    expect(result.state, RecommendationCanaryManifestFetchState.disabled);
    expect(clients, 0);
    expect(ingestions, 0);
    _expectNoAutomaticAuthority(result);
  });

  test('缺失、非 HTTPS 或带凭据和查询的端点均在联网前拒绝', () async {
    final endpoints = <(Uri?, RecommendationCanaryManifestFetchState)>[
      (null, RecommendationCanaryManifestFetchState.endpointUnconfigured),
      (
        Uri.parse('http://config.example.com/canary.json'),
        RecommendationCanaryManifestFetchState.insecureEndpoint,
      ),
      (
        Uri.parse('https://token@config.example.com/canary.json'),
        RecommendationCanaryManifestFetchState.endpointInvalid,
      ),
      (
        Uri.parse('https://config.example.com/canary.json?token=secret'),
        RecommendationCanaryManifestFetchState.endpointInvalid,
      ),
      (
        Uri.parse('/relative/canary.json'),
        RecommendationCanaryManifestFetchState.endpointInvalid,
      ),
    ];
    for (final testCase in endpoints) {
      var clients = 0;
      var ingestions = 0;
      final service = V2RecommendationCanaryManifestFetchService(
        enabled: true,
        endpoint: testCase.$1,
        manifestIngester: (rawManifest) async {
          ingestions += 1;
          return _ingestion();
        },
        httpClientFactory: () {
          clients += 1;
          return MockClient((_) async => http.Response('{}', 200));
        },
      );

      final result = await service.fetch();

      expect(result.state, testCase.$2, reason: testCase.$2.name);
      expect(clients, 0);
      expect(ingestions, 0);
      _expectNoAutomaticAuthority(result);
    }
  });

  test('成功响应使用单次无重定向 GET 并只交给清单信任边界', () async {
    var requests = 0;
    var ingestions = 0;
    String? ingestedBody;
    final service = V2RecommendationCanaryManifestFetchService(
      enabled: true,
      endpoint: Uri.parse('https://config.example.com/v1/canary.json'),
      manifestIngester: (rawManifest) async {
        ingestions += 1;
        ingestedBody = rawManifest;
        return _ingestion(
          RecommendationCanaryManifestIngestionState.acceptedForManualReview,
        );
      },
      httpClientFactory: () => MockClient((request) async {
        requests += 1;
        expect(request.method, 'GET');
        expect(request.url.scheme, 'https');
        expect(request.followRedirects, isFalse);
        expect(request.maxRedirects, 0);
        expect(request.persistentConnection, isFalse);
        expect(request.headers['accept'], 'application/json');
        expect(request.headers['cache-control'], 'no-store');
        expect(request.headers, isNot(contains('authorization')));
        expect(request.headers, isNot(contains('cookie')));
        return http.Response(
          '{"signed":"manifest"}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await service.fetch();

    expect(requests, 1);
    expect(ingestions, 1);
    expect(ingestedBody, '{"signed":"manifest"}');
    expect(result.deliveredToTrustBoundary, isTrue);
    expect(result.acceptedForManualReview, isTrue);
    _expectNoAutomaticAuthority(result);
  });

  test('并发获取共享同一在途请求且完成后允许下一次显式获取', () async {
    var requests = 0;
    var ingestions = 0;
    var responseGate = Completer<http.Response>();
    final service = _service(
      ingester: (rawManifest) async {
        ingestions += 1;
        return _ingestion();
      },
      clientFactory: () => MockClient((request) {
        requests += 1;
        return responseGate.future;
      }),
    );

    final first = service.fetch();
    final second = service.fetch();
    expect(identical(first, second), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(requests, 1);
    responseGate.complete(
      http.Response(
        '{}',
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    await Future.wait([first, second]);
    expect(requests, 1);
    expect(ingestions, 1);

    responseGate = Completer<http.Response>();
    final third = service.fetch();
    await Future<void>.delayed(Duration.zero);
    expect(requests, 2);
    responseGate.complete(
      http.Response(
        '{}',
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    await third;
    expect(ingestions, 2);
  });

  test('真实签名响应经 HTTPS 获取后仍只形成待人工审核状态', () async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPair();
    final publicKey = (await keyPair.extractPublicKey()).bytes;
    final manifest = RecommendationCanaryManifest(
      schemaVersion: RecommendationCanaryManifest.supportedSchemaVersion,
      revision: 12,
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
    final signature = await algorithm.sign(
      manifest.canonicalPayloadBytes(),
      keyPair: keyPair,
    );
    final responseBody = jsonEncode(
      RecommendationCanarySignedManifest(
        manifest: manifest,
        keyId: 'test-key-2026-01',
        signatureBytes: signature.bytes,
      ).toJson(),
    );
    String? storedState;
    final trustBoundary = V2RecommendationCanaryManifestService(
      expectedAudience: 'com.eatwhat.eatwhatApp',
      expectedEnvironment: 'production',
      trustedPublicKeys: {'test-key-2026-01': publicKey},
      stateReader: () async => storedState,
      stateWriter: (value) async {
        storedState = value;
        return true;
      },
      clock: () => DateTime.utc(2026, 8, 5, 9),
    );
    final service = V2RecommendationCanaryManifestFetchService(
      enabled: true,
      endpoint: Uri.parse('https://config.example.com/v1/canary.json'),
      manifestService: trustBoundary,
      httpClientFactory: () => MockClient((request) async => http.Response(
            responseBody,
            200,
            headers: {'content-type': 'application/json'},
          )),
    );

    final result = await service.fetch();

    expect(result.deliveredToTrustBoundary, isTrue);
    expect(result.acceptedForManualReview, isTrue);
    expect(
      result.ingestionResult?.state,
      RecommendationCanaryManifestIngestionState.acceptedForManualReview,
    );
    expect(
      (await trustBoundary.inspectStagedManifest()).state,
      RecommendationCanaryStagedManifestState.staged,
    );
    expect(storedState, isNotNull);
    _expectNoAutomaticAuthority(result);
  });

  test('重定向、错误状态和非 JSON 响应均不进入信任边界', () async {
    final cases =
        <(http.StreamedResponse, RecommendationCanaryManifestFetchState)>[
      (
        _response(
          302,
          headers: {
            'content-type': 'application/json',
            'location': 'https://other.example.com/canary.json',
          },
          isRedirect: true,
        ),
        RecommendationCanaryManifestFetchState.redirectRejected,
      ),
      (
        _response(503, headers: {'content-type': 'application/json'}),
        RecommendationCanaryManifestFetchState.httpStatusRejected,
      ),
      (
        _response(200, headers: {'content-type': 'text/plain'}),
        RecommendationCanaryManifestFetchState.contentTypeRejected,
      ),
    ];
    for (final testCase in cases) {
      var requests = 0;
      var ingestions = 0;
      final service = _service(
        ingester: (rawManifest) async {
          ingestions += 1;
          return _ingestion();
        },
        clientFactory: () => MockClient.streaming((request, bodyStream) async {
          requests += 1;
          return testCase.$1;
        }),
      );

      final result = await service.fetch();

      expect(result.state, testCase.$2, reason: testCase.$2.name);
      expect(requests, 1);
      expect(ingestions, 0);
      _expectNoAutomaticAuthority(result);
    }
  });

  test('声明长度和实际流量任一超限都会中止且不进入信任边界', () async {
    final cases = [
      _response(
        200,
        contentLength: 17,
        headers: {'content-type': 'application/json'},
      ),
      _response(
        200,
        bodyChunks: [utf8.encode('12345678'), utf8.encode('901234567')],
        contentLength: 15,
        headers: {'content-type': 'application/json'},
      ),
    ];
    for (final response in cases) {
      var ingestions = 0;
      final service = _service(
        maximumResponseBytes: 16,
        ingester: (rawManifest) async {
          ingestions += 1;
          return _ingestion();
        },
        clientFactory: () => MockClient.streaming(
          (request, bodyStream) async => response,
        ),
      );

      final result = await service.fetch();

      expect(
        result.state,
        RecommendationCanaryManifestFetchState.responseTooLarge,
      );
      expect(ingestions, 0);
      _expectNoAutomaticAuthority(result);
    }
  });

  test('无效 UTF-8、网络异常和超时均失败关闭且不重试', () async {
    var invalidUtf8Requests = 0;
    final invalidUtf8 = await _service(
      clientFactory: () => MockClient.streaming((request, bodyStream) async {
        invalidUtf8Requests += 1;
        return _response(
          200,
          bodyChunks: const [
            [0xC3, 0x28],
          ],
          headers: {'content-type': 'application/json'},
        );
      }),
    ).fetch();
    expect(
      invalidUtf8.state,
      RecommendationCanaryManifestFetchState.invalidUtf8,
    );
    expect(invalidUtf8Requests, 1);

    var networkRequests = 0;
    final unavailable = await _service(
      clientFactory: () => MockClient((request) async {
        networkRequests += 1;
        throw http.ClientException('offline');
      }),
    ).fetch();
    expect(
      unavailable.state,
      RecommendationCanaryManifestFetchState.networkUnavailable,
    );
    expect(networkRequests, 1);

    var timeoutRequests = 0;
    late _TrackingClient timeoutClient;
    final timedOut = await _service(
      requestTimeout: const Duration(milliseconds: 10),
      clientFactory: () {
        timeoutClient = _TrackingClient((request) {
          timeoutRequests += 1;
          return Completer<http.StreamedResponse>().future;
        });
        return timeoutClient;
      },
    ).fetch();
    expect(
      timedOut.state,
      RecommendationCanaryManifestFetchState.requestTimedOut,
    );
    expect(timeoutRequests, 1);
    expect(timeoutClient.closed, isTrue);
    _expectNoAutomaticAuthority(invalidUtf8);
    _expectNoAutomaticAuthority(unavailable);
    _expectNoAutomaticAuthority(timedOut);
  });

  test('信任边界拒绝或异常不会被获取层提升为灰度权限', () async {
    final rejected = await _service(
      ingester: (rawManifest) async => _ingestion(
        RecommendationCanaryManifestIngestionState.invalidSignature,
      ),
    ).fetch();
    expect(rejected.deliveredToTrustBoundary, isTrue);
    expect(rejected.acceptedForManualReview, isFalse);
    expect(
      rejected.ingestionResult?.state,
      RecommendationCanaryManifestIngestionState.invalidSignature,
    );

    final unavailable = await _service(
      ingester: (rawManifest) async => throw StateError('storage unavailable'),
    ).fetch();
    expect(
      unavailable.state,
      RecommendationCanaryManifestFetchState.trustBoundaryUnavailable,
    );
    _expectNoAutomaticAuthority(rejected);
    _expectNoAutomaticAuthority(unavailable);
  });
}

V2RecommendationCanaryManifestFetchService _service({
  V2CanaryManifestIngester? ingester,
  V2CanaryManifestHttpClientFactory? clientFactory,
  Duration requestTimeout = const Duration(seconds: 1),
  int maximumResponseBytes = 16 * 1024,
}) {
  return V2RecommendationCanaryManifestFetchService(
    enabled: true,
    endpoint: Uri.parse('https://config.example.com/v1/canary.json'),
    manifestIngester: ingester ?? (rawManifest) async => _ingestion(),
    httpClientFactory: clientFactory ??
        () => MockClient((request) async => http.Response(
              '{}',
              200,
              headers: {'content-type': 'application/json'},
            )),
    requestTimeout: requestTimeout,
    maximumResponseBytes: maximumResponseBytes,
  );
}

http.StreamedResponse _response(
  int statusCode, {
  List<List<int>> bodyChunks = const [],
  Map<String, String> headers = const {},
  int? contentLength,
  bool isRedirect = false,
}) {
  return http.StreamedResponse(
    Stream<List<int>>.fromIterable(bodyChunks),
    statusCode,
    headers: headers,
    contentLength: contentLength,
    isRedirect: isRedirect,
  );
}

RecommendationCanaryManifestIngestionResult _ingestion([
  RecommendationCanaryManifestIngestionState state =
      RecommendationCanaryManifestIngestionState.malformed,
]) {
  return RecommendationCanaryManifestIngestionResult(
    state: state,
    reason: 'test_ingestion_${state.name}',
  );
}

void _expectNoAutomaticAuthority(
  RecommendationCanaryManifestFetchResult result,
) {
  expect(result.authorizesCanaryActivation, isFalse);
  expect(result.authorizesCanaryExpansion, isFalse);
  expect(result.authorizesCanaryDeactivation, isFalse);
  expect(result.authorizesFullRollout, isFalse);
}

class _TrackingClient extends http.BaseClient {
  _TrackingClient(this.handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
      handler;
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return handler(request);
  }

  @override
  void close() {
    closed = true;
  }
}
