@TestOn('browser')
library;

import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_manifest_fetch_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_manifest_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('Web 构建在创建可能携带同源凭据的客户端前失败关闭', () async {
    var clients = 0;
    var ingestions = 0;
    final service = V2RecommendationCanaryManifestFetchService(
      enabled: true,
      endpoint: Uri.parse('https://config.example.com/v1/canary.json'),
      manifestIngester: (rawManifest) async {
        ingestions += 1;
        return const RecommendationCanaryManifestIngestionResult(
          state: RecommendationCanaryManifestIngestionState.malformed,
          reason: 'must_not_ingest',
        );
      },
      httpClientFactory: () {
        clients += 1;
        return _NeverUsedClient();
      },
    );

    final result = await service.fetch();

    expect(
      result.state,
      RecommendationCanaryManifestFetchState.browserTransportUnsupported,
    );
    expect(clients, 0);
    expect(ingestions, 0);
    expect(result.authorizesCanaryActivation, isFalse);
    expect(result.authorizesCanaryExpansion, isFalse);
    expect(result.authorizesCanaryDeactivation, isFalse);
    expect(result.authorizesFullRollout, isFalse);
  });
}

class _NeverUsedClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw StateError('Browser client must not be used.');
  }
}
