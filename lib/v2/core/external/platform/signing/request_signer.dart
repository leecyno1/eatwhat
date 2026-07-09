abstract class RequestSigner {
  String sign({
    required String method,
    required String path,
    required Map<String, String> params,
    required String secret,
    required int timestampSeconds,
  });
}
