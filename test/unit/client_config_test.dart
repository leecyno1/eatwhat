import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eatwhat_app/app/app_dependencies.dart';
import 'package:eatwhat_app/v2/core/config/client_config.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/ports/ai_gateway.dart';
import 'package:eatwhat_app/v2/core/services/dish_enhancement_service.dart';
import 'package:eatwhat_app/v2/core/services/generation_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_ai_cache_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(dotenv.clean);

  group('ClientConfig.fromEnvConfig', () {
    test('reads AI-chain values and allows local HTTP in debug', () {
      dotenv.testLoad(fileInput: _representativeEnv);

      final config = ClientConfig.fromEnvConfig(
        // Explicitly exercise the debug branch rather than the test build mode.
        // ignore: avoid_redundant_argument_values
        isRelease: false,
      );

      expect(config.minimaxChatApiUrl, 'http://127.0.0.1:4100');
      expect(config.minimaxApiKey, 'dev-minimax-key');
      expect(config.minimaxChatModel, 'chat-model-dev');
      expect(config.executionProxyBaseUrl, 'http://127.0.0.1:4200');
      expect(config.executionProxyAuthToken, 'proxy-token-dev');
      expect(config.hasUsableExecutionProxy, isTrue);
      expect(config.aiImageModelName, 'image-model-dev');
      expect(config.minimaxImageModel, 'minimax-image-dev');
      expect(config.minimaxApiUrl, 'http://127.0.0.1:4300/images');
      expect(config.aiRequestTimeoutSeconds, 17);
      expect(config.aiMaxRetries, 4);
      expect(config.aiTemperature, 0.31);
      expect(config.enableLiveDishImageGeneration, isTrue);
    });

    test('release blanks the direct key and rejects an HTTP proxy', () {
      dotenv.testLoad(fileInput: _representativeEnv);

      final config = ClientConfig.fromEnvConfig(isRelease: true);

      expect(config.minimaxApiKey, isEmpty);
      expect(config.executionProxyBaseUrl, 'http://127.0.0.1:4200');
      expect(config.hasUsableExecutionProxy, isFalse);
    });
  });

  test('AppDependencies.standard keeps its original proxy after dotenv reload',
      () async {
    final requestsA = <String>[];
    final requestsB = <String>[];
    final upstreamA = await _startChatUpstream('简介来自代理 A', requestsA);
    final upstreamB = await _startChatUpstream('简介来自代理 B', requestsB);
    addTearDown(() => upstreamA.close(force: true));
    addTearDown(() => upstreamB.close(force: true));
    dotenv.testLoad(fileInput: _proxyEnv(upstreamA));

    final dependencies = AppDependencies.standard();
    dotenv.testLoad(fileInput: _proxyEnv(upstreamB));
    final intro = await dependencies.generationService.generateDishIntroduction(
      const RecipeModel(
        id: 'fixed-proxy-recipe',
        name: '固定代理菜',
        description: '',
        ingredients: ['番茄'],
      ),
    );

    expect(intro, '简介来自代理 A');
    expect(requestsA, ['/api/v1/ai/chat/completions']);
    expect(requestsB, isEmpty);
  });

  test('default GenerationService.instance follows dotenv reloads', () async {
    final requestsA = <String>[];
    final requestsB = <String>[];
    final upstreamA = await _startChatUpstream('动态简介 A', requestsA);
    final upstreamB = await _startChatUpstream('动态简介 B', requestsB);
    addTearDown(() => upstreamA.close(force: true));
    addTearDown(() => upstreamB.close(force: true));

    dotenv.testLoad(fileInput: _proxyEnv(upstreamA));
    final introA = await GenerationService.instance.generateDishIntroduction(
      const RecipeModel(
        id: 'dynamic-proxy-recipe-a',
        name: '动态代理菜 A',
        description: '',
        ingredients: ['番茄'],
      ),
    );
    dotenv.testLoad(fileInput: _proxyEnv(upstreamB));
    final introB = await GenerationService.instance.generateDishIntroduction(
      const RecipeModel(
        id: 'dynamic-proxy-recipe-b',
        name: '动态代理菜 B',
        description: '',
        ingredients: ['鸡蛋'],
      ),
    );

    expect(introA, '动态简介 A');
    expect(introB, '动态简介 B');
    expect(requestsA, hasLength(1));
    expect(requestsB, hasLength(1));
  });

  group('DishEnhancementService with AiGateway', () {
    test('injected image-generation flag stays fixed after dotenv reload',
        () async {
      dotenv.testLoad(
        fileInput: 'ENABLE_LIVE_DISH_IMAGE_GENERATION=true',
      );
      final gateway = _FakeAiGateway();
      final service = DishEnhancementService(
        transport: gateway,
        cache: V2AiCacheService.instance,
        config: _testConfig(),
      );
      dotenv.testLoad(
        fileInput: 'ENABLE_LIVE_DISH_IMAGE_GENERATION=false',
      );

      final url = await service.generateRecipeImageUrl(
        const RecipeModel(
          id: 'fixed-image-flag-recipe',
          name: '固定生图开关菜',
          description: '',
          ingredients: ['番茄'],
        ),
      );

      expect(url, 'https://example.com/fake-dish.jpg');
      expect(gateway.imageCalls, 1);
    });

    test('disabled image generation returns null without calling the gateway',
        () async {
      final gateway = _FakeAiGateway();
      final service = DishEnhancementService(
        transport: gateway,
        cache: V2AiCacheService.instance,
        config: _testConfig(enableLiveDishImageGeneration: false),
      );

      final url = await service.generateRecipeImageUrl(
        const RecipeModel(
          id: 'disabled-image-flag-recipe',
          name: '关闭生图菜',
          description: '',
          ingredients: ['鸡蛋'],
        ),
      );

      expect(url, isNull);
      expect(gateway.imageCalls, 0);
    });
  });
}

const _representativeEnv = 'MINIMAX_CHAT_API_URL=http://127.0.0.1:4100\n'
    'MINIMAX_API_KEY=dev-minimax-key\n'
    'MINIMAX_CHAT_MODEL=chat-model-dev\n'
    'EXECUTION_PROXY_BASE_URL=http://127.0.0.1:4200\n'
    'EXECUTION_PROXY_AUTH_TOKEN=proxy-token-dev\n'
    'AI_IMAGE_MODEL_NAME=image-model-dev\n'
    'MINIMAX_IMAGE_MODEL=minimax-image-dev\n'
    'MINIMAX_API_URL=http://127.0.0.1:4300/images\n'
    'AI_REQUEST_TIMEOUT=17\n'
    'AI_MAX_RETRIES=4\n'
    'AI_TEMPERATURE=0.31\n'
    'ENABLE_LIVE_DISH_IMAGE_GENERATION=true\n';

String _proxyEnv(HttpServer server) =>
    'EXECUTION_PROXY_BASE_URL=http://127.0.0.1:${server.port}\n'
    'EXECUTION_PROXY_AUTH_TOKEN=proxy-token\n'
    'AI_MAX_RETRIES=1\n';

Future<HttpServer> _startChatUpstream(
  String intro,
  List<String> requests,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    requests.add(request.uri.path);
    await utf8.decoder.bind(request).join();
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': jsonEncode({'intro': intro}),
              },
            },
          ],
        }),
      );
    await request.response.close();
  });
  return server;
}

ClientConfig _testConfig({bool enableLiveDishImageGeneration = true}) {
  return ClientConfig(
    minimaxChatApiUrl: 'https://api.minimaxi.com/v1',
    minimaxApiKey: 'test-key',
    minimaxChatModel: 'test-chat-model',
    executionProxyBaseUrl: '',
    executionProxyAuthToken: '',
    hasUsableExecutionProxy: false,
    aiImageModelName: 'test-image-model',
    minimaxImageModel: 'image-01',
    minimaxApiUrl: 'https://api.minimax.io/v1/image_generation',
    aiRequestTimeoutSeconds: 30,
    aiMaxRetries: 1,
    aiTemperature: 0.7,
    enableLiveDishImageGeneration: enableLiveDishImageGeneration,
  );
}

class _FakeAiGateway implements AiGateway {
  int imageCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<Map<String, dynamic>> chatJson({
    required String system,
    required String user,
    double? temperature,
    CancelToken? cancelToken,
  }) async {
    return const {'intro': 'fake gateway intro'};
  }

  @override
  Future<String?> generateImage({
    required String prompt,
    CancelToken? cancelToken,
  }) async {
    imageCalls += 1;
    return 'https://example.com/fake-dish.jpg';
  }
}
