class PlatformApiNotConfiguredException implements Exception {
  final String platform;
  final String message;

  PlatformApiNotConfiguredException(this.platform, {String? message})
      : message = message ?? '平台开放 API 未配置（缺少 baseUrl/appKey/appSecret/token）';

  @override
  String toString() => 'PlatformApiNotConfiguredException($platform): $message';
}

class PlatformApiException implements Exception {
  final String platform;
  final String message;
  final int? statusCode;

  PlatformApiException(
    this.platform,
    this.message, {
    this.statusCode,
  });

  @override
  String toString() =>
      'PlatformApiException($platform, statusCode=$statusCode): $message';
}
