import 'package:dio/dio.dart';
import 'package:eatwhat_app/v2/core/external/platform/signing/request_signer.dart';

class OpenPlatformClient {
  final Dio _dio;
  final String baseUrl;
  final String appKey;
  final String appSecret;
  final String accessToken;
  final RequestSigner signer;

  OpenPlatformClient({
    required Dio dio,
    required this.baseUrl,
    required this.appKey,
    required this.appSecret,
    required this.accessToken,
    required this.signer,
  }) : _dio = dio;

  bool get isConfigured =>
      baseUrl.isNotEmpty &&
      appKey.isNotEmpty &&
      appSecret.isNotEmpty &&
      accessToken.isNotEmpty;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, String> queryParameters = const {},
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final params = <String, String>{
      ...queryParameters,
      'appKey': appKey,
      'timestamp': ts.toString(),
    };
    final signature = signer.sign(
      method: 'GET',
      path: path,
      params: params,
      secret: appSecret,
      timestampSeconds: ts,
    );

    final signedParams = <String, String>{
      ...params,
      'sign': signature,
    };

    return _dio.get(
      '$baseUrl$path',
      queryParameters: signedParams,
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      ),
    );
  }
}
