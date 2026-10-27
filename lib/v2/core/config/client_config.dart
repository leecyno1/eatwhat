import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:flutter/foundation.dart';

class ClientConfig {
  const ClientConfig({
    required this.minimaxChatApiUrl,
    required this.minimaxApiKey,
    required this.minimaxChatModel,
    required this.executionProxyBaseUrl,
    required this.executionProxyAuthToken,
    required this.hasUsableExecutionProxy,
    required this.aiImageModelName,
    required this.minimaxImageModel,
    required this.minimaxApiUrl,
    required this.aiRequestTimeoutSeconds,
    required this.aiMaxRetries,
    required this.aiTemperature,
    required this.enableLiveDishImageGeneration,
  });

  factory ClientConfig.fromEnvConfig({bool isRelease = kReleaseMode}) {
    final executionProxyBaseUrl = EnvConfig.executionProxyBaseUrl;
    return ClientConfig(
      minimaxChatApiUrl: EnvConfig.minimaxChatApiUrl,
      minimaxApiKey: isRelease ? '' : EnvConfig.minimaxApiKey,
      minimaxChatModel: EnvConfig.minimaxChatModel,
      executionProxyBaseUrl: executionProxyBaseUrl,
      executionProxyAuthToken: EnvConfig.executionProxyAuthToken,
      hasUsableExecutionProxy: executionProxyBaseUrl.trim().isNotEmpty &&
          EnvConfig.backendUrlIssue(
                executionProxyBaseUrl,
                requireHttps: isRelease,
              ) ==
              null,
      aiImageModelName: EnvConfig.aiImageModelName,
      minimaxImageModel: EnvConfig.minimaxImageModel,
      minimaxApiUrl: EnvConfig.minimaxApiUrl,
      aiRequestTimeoutSeconds: EnvConfig.aiRequestTimeoutSeconds,
      aiMaxRetries: EnvConfig.aiMaxRetries,
      aiTemperature: EnvConfig.aiTemperature,
      enableLiveDishImageGeneration: EnvConfig.enableLiveDishImageGeneration,
    );
  }

  final String minimaxChatApiUrl;
  final String minimaxApiKey;
  final String minimaxChatModel;
  final String executionProxyBaseUrl;
  final String executionProxyAuthToken;
  final bool hasUsableExecutionProxy;
  final String aiImageModelName;
  final String minimaxImageModel;
  final String minimaxApiUrl;
  final int aiRequestTimeoutSeconds;
  final int aiMaxRetries;
  final double aiTemperature;
  final bool enableLiveDishImageGeneration;
}
