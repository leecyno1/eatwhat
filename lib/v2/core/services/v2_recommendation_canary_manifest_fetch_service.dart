import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_manifest_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_manifest_transport_support.dart';
import 'package:http/http.dart' as http;

typedef V2CanaryManifestIngester
    = Future<RecommendationCanaryManifestIngestionResult> Function(
  String rawManifest,
);
typedef V2CanaryManifestHttpClientFactory = http.Client Function();

enum RecommendationCanaryManifestFetchState {
  disabled,
  endpointUnconfigured,
  endpointInvalid,
  insecureEndpoint,
  browserTransportUnsupported,
  requestTimedOut,
  networkUnavailable,
  redirectRejected,
  httpStatusRejected,
  contentTypeRejected,
  responseTooLarge,
  invalidUtf8,
  trustBoundaryUnavailable,
  deliveredToTrustBoundary,
}

class RecommendationCanaryManifestFetchResult {
  const RecommendationCanaryManifestFetchResult({
    required this.state,
    required this.reason,
    this.statusCode,
    this.ingestionResult,
  });

  final RecommendationCanaryManifestFetchState state;
  final String reason;
  final int? statusCode;
  final RecommendationCanaryManifestIngestionResult? ingestionResult;

  bool get deliveredToTrustBoundary =>
      state == RecommendationCanaryManifestFetchState.deliveredToTrustBoundary;

  bool get acceptedForManualReview =>
      deliveredToTrustBoundary &&
      (ingestionResult?.acceptedForManualReview ?? false);

  bool get authorizesCanaryActivation => false;
  bool get authorizesCanaryExpansion => false;
  bool get authorizesCanaryDeactivation => false;
  bool get authorizesFullRollout => false;
}

class V2RecommendationCanaryManifestFetchService {
  V2RecommendationCanaryManifestFetchService({
    V2RecommendationCanaryManifestService? manifestService,
    V2CanaryManifestIngester? manifestIngester,
    this.enabled = false,
    this.endpoint,
    V2CanaryManifestHttpClientFactory? httpClientFactory,
    this.requestTimeout = const Duration(seconds: 5),
    this.maximumResponseBytes = 16 * 1024,
  })  : assert(requestTimeout > Duration.zero),
        assert(maximumResponseBytes > 0),
        _manifestIngester = _resolveManifestIngester(
          manifestService,
          manifestIngester,
        ),
        _httpClientFactory = httpClientFactory ?? _defaultHttpClientFactory;

  final bool enabled;
  final Uri? endpoint;
  final Duration requestTimeout;
  final int maximumResponseBytes;
  final V2CanaryManifestIngester _manifestIngester;
  final V2CanaryManifestHttpClientFactory _httpClientFactory;
  Future<RecommendationCanaryManifestFetchResult>? _pendingFetch;

  Future<RecommendationCanaryManifestFetchResult> fetch() {
    final pending = _pendingFetch;
    if (pending != null) return pending;

    late final Future<RecommendationCanaryManifestFetchResult> result;
    result = _fetchOnce().whenComplete(() {
      if (identical(_pendingFetch, result)) _pendingFetch = null;
    });
    _pendingFetch = result;
    return result;
  }

  Future<RecommendationCanaryManifestFetchResult> _fetchOnce() async {
    if (!enabled) {
      return _result(
        RecommendationCanaryManifestFetchState.disabled,
        'canary_manifest_fetch_disabled',
      );
    }
    if (!supportsSecureCanaryManifestTransport) {
      return _result(
        RecommendationCanaryManifestFetchState.browserTransportUnsupported,
        'canary_manifest_fetch_browser_transport_unsupported',
      );
    }
    final resolvedEndpoint = endpoint;
    if (resolvedEndpoint == null) {
      return _result(
        RecommendationCanaryManifestFetchState.endpointUnconfigured,
        'canary_manifest_fetch_endpoint_unconfigured',
      );
    }
    if (!_hasValidEndpointShape(resolvedEndpoint)) {
      return _result(
        RecommendationCanaryManifestFetchState.endpointInvalid,
        'canary_manifest_fetch_endpoint_invalid',
      );
    }
    if (resolvedEndpoint.scheme.toLowerCase() != 'https') {
      return _result(
        RecommendationCanaryManifestFetchState.insecureEndpoint,
        'canary_manifest_fetch_https_required',
      );
    }

    String rawManifest;
    try {
      rawManifest = await _download(resolvedEndpoint);
    } on TimeoutException {
      return _result(
        RecommendationCanaryManifestFetchState.requestTimedOut,
        'canary_manifest_fetch_timed_out',
      );
    } on _CanaryManifestFetchFailure catch (failure) {
      return _result(
        failure.state,
        failure.reason,
        statusCode: failure.statusCode,
      );
    } catch (_) {
      return _result(
        RecommendationCanaryManifestFetchState.networkUnavailable,
        'canary_manifest_fetch_network_unavailable',
      );
    }

    try {
      final ingestionResult = await _manifestIngester(rawManifest);
      return RecommendationCanaryManifestFetchResult(
        state: RecommendationCanaryManifestFetchState.deliveredToTrustBoundary,
        reason: 'canary_manifest_delivered_to_trust_boundary',
        ingestionResult: ingestionResult,
      );
    } catch (_) {
      return _result(
        RecommendationCanaryManifestFetchState.trustBoundaryUnavailable,
        'canary_manifest_trust_boundary_unavailable',
      );
    }
  }

  Future<String> _download(Uri uri) async {
    final client = _httpClientFactory();
    try {
      return await _downloadWithClient(client, uri).timeout(
        requestTimeout,
        onTimeout: () {
          client.close();
          throw TimeoutException('Canary manifest request timed out.');
        },
      );
    } finally {
      client.close();
    }
  }

  Future<String> _downloadWithClient(http.Client client, Uri uri) async {
    final request = http.Request('GET', uri)
      ..followRedirects = false
      ..maxRedirects = 0
      ..persistentConnection = false
      ..headers['accept'] = 'application/json'
      ..headers['cache-control'] = 'no-store';
    final response = await client.send(request);
    if (response.isRedirect ||
        (response.statusCode >= 300 && response.statusCode < 400)) {
      throw _CanaryManifestFetchFailure(
        RecommendationCanaryManifestFetchState.redirectRejected,
        'canary_manifest_fetch_redirect_rejected',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode != 200) {
      throw _CanaryManifestFetchFailure(
        RecommendationCanaryManifestFetchState.httpStatusRejected,
        'canary_manifest_fetch_http_status_rejected',
        statusCode: response.statusCode,
      );
    }
    if (!_isJsonContentType(response.headers['content-type'])) {
      throw _CanaryManifestFetchFailure(
        RecommendationCanaryManifestFetchState.contentTypeRejected,
        'canary_manifest_fetch_content_type_rejected',
        statusCode: response.statusCode,
      );
    }
    final declaredLength = response.contentLength;
    if (declaredLength != null && declaredLength > maximumResponseBytes) {
      throw _CanaryManifestFetchFailure(
        RecommendationCanaryManifestFetchState.responseTooLarge,
        'canary_manifest_fetch_response_too_large',
        statusCode: response.statusCode,
      );
    }

    final bytes = BytesBuilder(copy: false);
    var receivedBytes = 0;
    await for (final chunk in response.stream) {
      if (chunk.length > maximumResponseBytes - receivedBytes) {
        throw _CanaryManifestFetchFailure(
          RecommendationCanaryManifestFetchState.responseTooLarge,
          'canary_manifest_fetch_response_too_large',
          statusCode: response.statusCode,
        );
      }
      receivedBytes += chunk.length;
      bytes.add(chunk);
    }
    try {
      return utf8.decode(bytes.takeBytes(), allowMalformed: false);
    } on FormatException {
      throw _CanaryManifestFetchFailure(
        RecommendationCanaryManifestFetchState.invalidUtf8,
        'canary_manifest_fetch_invalid_utf8',
        statusCode: response.statusCode,
      );
    }
  }

  RecommendationCanaryManifestFetchResult _result(
    RecommendationCanaryManifestFetchState state,
    String reason, {
    int? statusCode,
  }) {
    return RecommendationCanaryManifestFetchResult(
      state: state,
      reason: reason,
      statusCode: statusCode,
    );
  }

  static bool _hasValidEndpointShape(Uri uri) {
    return uri.hasScheme &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        !uri.hasQuery &&
        !uri.hasFragment;
  }

  static bool _isJsonContentType(String? rawContentType) {
    if (rawContentType == null) return false;
    return rawContentType.split(';').first.trim().toLowerCase() ==
        'application/json';
  }

  static V2CanaryManifestIngester _resolveManifestIngester(
    V2RecommendationCanaryManifestService? manifestService,
    V2CanaryManifestIngester? manifestIngester,
  ) {
    if ((manifestService == null) == (manifestIngester == null)) {
      throw ArgumentError(
        'Provide exactly one manifest service or manifest ingester.',
      );
    }
    return manifestIngester ?? manifestService!.ingest;
  }

  static http.Client _defaultHttpClientFactory() => http.Client();
}

class _CanaryManifestFetchFailure implements Exception {
  const _CanaryManifestFetchFailure(
    this.state,
    this.reason, {
    this.statusCode,
  });

  final RecommendationCanaryManifestFetchState state;
  final String reason;
  final int? statusCode;
}
