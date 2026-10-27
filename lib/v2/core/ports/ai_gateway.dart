import 'package:dio/dio.dart';

abstract interface class AiGateway {
  bool get isConfigured;

  Future<Map<String, dynamic>> chatJson({
    required String system,
    required String user,
    double? temperature,
    CancelToken? cancelToken,
  });

  Future<String?> generateImage({
    required String prompt,
    CancelToken? cancelToken,
  });
}
