class PlatformApiNotConfiguredException implements Exception {
  PlatformApiNotConfiguredException(this.platform, {String? message})
      : message = message ?? '平台开放 API 未配置（缺少 baseUrl/appKey/appSecret/token）';

  final String platform;
  final String message;

  @override
  String toString() => 'PlatformApiNotConfiguredException($platform): $message';
}

class PlatformApiException implements Exception {
  PlatformApiException(
    this.platform,
    this.message, {
    this.statusCode,
    this.code,
    this.details = const {},
  });

  final String platform;
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic> details;

  @override
  String toString() =>
      'PlatformApiException($platform, code=$code, statusCode=$statusCode): '
      '$message';
}
