import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eatwhat_app/core/services/auth_service.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/services/generation_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('GenerationService 能解析 MiniMax image_urls 数组', () {
    final url = GenerationService.extractMiniMaxImageUrl({
      'data': {
        'image_urls': [
          'https://example.com/generated-dish.jpg',
        ],
      },
      'base_resp': {
        'status_code': 0,
        'status_msg': 'success',
      },
    });

    expect(url, 'https://example.com/generated-dish.jpg');
  });

  group('parseFusionDishes', () {
    test('解析融合菜的步骤（字符串数组）', () {
      final dishes = GenerationService.parseFusionDishes(
        {
          'dishes': [
            {
              'name': '麻辣豆腐牛肉粒盖饭',
              'reason': '麻辣鲜香叠加牛肉的满足感',
              'ingredients': ['牛肉粒', '嫩豆腐'],
              'tags': ['麻辣'],
              'steps': ['牛肉粒滑油至变色。', '下豆腐轻推入味。', '盖在热米饭上。'],
            },
          ],
        },
        ['辣', '下饭'],
      );

      expect(dishes, hasLength(1));
      final dish = dishes.single;
      expect(dish.name, '麻辣豆腐牛肉粒盖饭');
      expect(dish.source, 'ai_fusion');
      expect(dish.steps, ['牛肉粒滑油至变色。', '下豆腐轻推入味。', '盖在热米饭上。']);
      expect(dish.ingredients, ['牛肉粒', '嫩豆腐']);
    });

    test('步骤兼容 {description: ...} 对象数组形态', () {
      final dishes = GenerationService.parseFusionDishes(
        {
          'dishes': [
            {
              'name': '泡椒双脆',
              'reason': '脆上加脆',
              'steps': [
                {'description': '土豆切条泡水。'},
                {'description': '鸡胗打花刀快炒。'},
              ],
            },
          ],
        },
        ['脆'],
      );

      expect(dishes.single.steps, ['土豆切条泡水。', '鸡胗打花刀快炒。']);
    });

    test('空菜名跳过、无理由走默认描述、非数组返回空', () {
      final dishes = GenerationService.parseFusionDishes(
        {
          'dishes': [
            {'name': '  ', 'reason': 'x'},
            {'name': '香辣番茄牛腩炖锅'},
          ],
        },
        ['辣', '番茄'],
      );

      expect(dishes, hasLength(1));
      expect(dishes.single.description, contains('组合成的一道创意菜'));
      expect(GenerationService.parseFusionDishes({'dishes': 'oops'}, ['辣']),
          isEmpty);
    });
  });

  group('AI 代理模式（客户端不持密钥）', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
    });

    tearDown(dotenv.clean);

    RecipeModel recipe() => const RecipeModel(
          id: 'dish-proxy-1',
          name: '番茄炒蛋',
          description: '',
          ingredients: ['番茄', '鸡蛋'],
        );

    Future<HttpServer> fakeUpstream(
      void Function(HttpRequest request) onSeen,
    ) async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        onSeen(request);
        await utf8.decoder.bind(request).join();
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': '{"intro":"代理模式生成的简介"}'},
                },
              ],
            }),
          );
        await request.response.close();
      });
      return server;
    }

    test('无本地密钥但配置了执行代理时，AI 请求走代理路由', () async {
      final seen = <Map<String, dynamic>>[];
      final upstream = await fakeUpstream((request) {
        seen.add({
          'path': request.uri.path,
          'authorization':
              request.headers.value(HttpHeaders.authorizationHeader),
          'proxyToken': request.headers.value('x-execution-proxy-token'),
        });
      });
      addTearDown(() => upstream.close(force: true));

      dotenv.testLoad(
        fileInput:
            'EXECUTION_PROXY_BASE_URL=http://127.0.0.1:${upstream.port}\n'
            'EXECUTION_PROXY_AUTH_TOKEN=proxy-token-1',
      );

      final intro = await GenerationService.instance.generateDishIntroduction(
        recipe(),
      );

      expect(GenerationService.instance.isConfigured, isTrue);
      expect(intro, '代理模式生成的简介');
      expect(seen, hasLength(1));
      expect(seen.single['path'], '/api/v1/ai/chat/completions');
      // 密钥只留在服务端：客户端请求头里不得出现任何 MiniMax 密钥。
      expect(seen.single['authorization'], isNull);
      expect(seen.single['proxyToken'], 'proxy-token-1');
    });

    test('本地会话 JWT 不进入 AI 代理请求', () async {
      String? authorization;
      final upstream = await fakeUpstream((request) {
        authorization = request.headers.value(HttpHeaders.authorizationHeader);
      });
      addTearDown(() => upstream.close(force: true));
      dotenv.testLoad(
        fileInput: 'EXECUTION_PROXY_BASE_URL=http://127.0.0.1:${upstream.port}',
      );
      final registered = await AuthService.register(
        username: 'local_ai_proxy',
        email: 'local-ai@example.com',
        password: 'LocalPass123',
        confirmPassword: 'LocalPass123',
      );
      expect(registered.success, isTrue);
      expect(AuthService.authToken, isNotNull);
      addTearDown(AuthService.logout);

      await GenerationService.instance.generateDishIntroduction(recipe());

      expect(authorization, isNull);
    });

    test('本地有 MiniMax 密钥时直连上游，代理不被使用', () async {
      final direct = <String>[];
      final directUpstream = await fakeUpstream((request) {
        direct.add(request.uri.path);
      });
      addTearDown(() => directUpstream.close(force: true));
      final proxy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => proxy.close(force: true));

      dotenv.testLoad(
        fileInput: 'MINIMAX_API_KEY=local-dev-key\n'
            'MINIMAX_CHAT_API_URL=http://127.0.0.1:${directUpstream.port}\n'
            'EXECUTION_PROXY_BASE_URL=http://127.0.0.1:${proxy.port}\n',
      );

      final intro = await GenerationService.instance.generateDishIntroduction(
        recipe(),
      );

      expect(intro, '代理模式生成的简介');
      expect(direct, ['/chat/completions']);
    });

    test('无密钥也无代理时视为未配置，走本地兜底文案', () async {
      dotenv.testLoad();

      expect(GenerationService.instance.isConfigured, isFalse);

      final intro = await GenerationService.instance.generateDishIntroduction(
        recipe(),
      );

      expect(intro, isNotNull);
      expect(intro, isNot('代理模式生成的简介'));
    });
  });

  group('AI 网络重试分类', () {
    const recipe = RecipeModel(
      id: 'dish-retry-1',
      name: '番茄炒蛋',
      description: '本地兜底简介',
      ingredients: ['番茄', '鸡蛋'],
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      dotenv.testLoad();
    });

    tearDown(dotenv.clean);

    Future<HttpServer> startUpstream(
      Future<void> Function(
        HttpRequest request,
        Map<String, dynamic> body,
        int attempt,
      ) onRequest,
    ) async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var attempt = 0;
      server.listen((request) async {
        attempt += 1;
        try {
          final raw = await utf8.decoder.bind(request).join();
          final body = jsonDecode(raw) as Map<String, dynamic>;
          await onRequest(request, body, attempt);
        } catch (_) {}
      });
      return server;
    }

    Future<void> respond(
      HttpRequest request, {
      int statusCode = HttpStatus.ok,
      String content = '{"intro":"重试后的简介"}',
    }) async {
      request.response
        ..statusCode = statusCode
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'choices': [
              {
                'message': {'content': content},
              },
            ],
          }),
        );
      await request.response.close();
    }

    void configure(HttpServer server, {int timeoutSeconds = 1}) {
      dotenv.testLoad(
        fileInput: 'MINIMAX_API_KEY=test-key\n'
            'MINIMAX_CHAT_API_URL=http://127.0.0.1:${server.port}\n'
            'AI_MAX_RETRIES=3\n'
            'AI_REQUEST_TIMEOUT=$timeoutSeconds\n',
      );
    }

    for (final statusCode in [400, 401, 403]) {
      test('HTTP $statusCode 不盲目重试', () async {
        var requestCount = 0;
        final server = await startUpstream((request, _, attempt) async {
          requestCount = attempt;
          await respond(request, statusCode: statusCode);
        });
        configure(server);

        await GenerationService.instance.generateDishIntroduction(recipe);

        expect(requestCount, 1);
      });
    }

    for (final statusCode in [429, 500, 503]) {
      test('HTTP $statusCode 后重试并采用成功结果', () async {
        var requestCount = 0;
        final server = await startUpstream((request, _, attempt) async {
          requestCount = attempt;
          await respond(
            request,
            statusCode: attempt == 1 ? statusCode : HttpStatus.ok,
          );
        });
        configure(server);

        final intro =
            await GenerationService.instance.generateDishIntroduction(recipe);

        expect(intro, '重试后的简介');
        expect(requestCount, 2);
      });
    }

    test('响应 JSON 无法解析时不重试', () async {
      var requestCount = 0;
      final server = await startUpstream((request, _, attempt) async {
        requestCount = attempt;
        await respond(request, content: 'not-json');
      });
      configure(server);

      await GenerationService.instance.generateDishIntroduction(recipe);

      expect(requestCount, 1);
    });

    test('接收超时后重试并采用成功结果', () async {
      var requestCount = 0;
      final server = await startUpstream((request, _, attempt) async {
        requestCount = attempt;
        if (attempt == 1) {
          await Future<void>.delayed(const Duration(milliseconds: 1500));
        }
        await respond(request);
      });
      configure(server);

      final intro =
          await GenerationService.instance.generateDishIntroduction(recipe);

      expect(intro, '重试后的简介');
      expect(requestCount, 2);
    });

    test('连接中断后重试并采用成功结果', () async {
      var requestCount = 0;
      final server = await startUpstream((request, _, attempt) async {
        requestCount = attempt;
        if (attempt == 1) {
          final socket = await request.response.detachSocket(
            writeHeaders: false,
          );
          socket.destroy();
          return;
        }
        await respond(request);
      });
      configure(server);

      final intro =
          await GenerationService.instance.generateDishIntroduction(recipe);

      expect(intro, '重试后的简介');
      expect(requestCount, 2);
    });

    test('保留 response_format 兼容重试', () async {
      final responseFormats = <bool>[];
      final server = await startUpstream((request, body, attempt) async {
        responseFormats.add(body.containsKey('response_format'));
        await respond(
          request,
          statusCode: attempt == 1 ? HttpStatus.badRequest : HttpStatus.ok,
          content: attempt == 1
              ? '{"error":"unknown parameter response_format"}'
              : '{"intro":"兼容模式简介"}',
        );
      });
      configure(server);

      final intro =
          await GenerationService.instance.generateDishIntroduction(recipe);

      expect(intro, '兼容模式简介');
      expect(responseFormats, [true, false]);
    });

    test('HTTP 400 的无关 invalid 错误不触发兼容重试', () async {
      var requestCount = 0;
      final server = await startUpstream((request, _, attempt) async {
        requestCount = attempt;
        await respond(
          request,
          statusCode: HttpStatus.badRequest,
          content: '{"error":"invalid api key"}',
        );
      });
      configure(server);

      await GenerationService.instance.generateDishIntroduction(recipe);

      expect(requestCount, 1);
    });

    test('含 response_format 的无效 JSON 不触发兼容重试', () async {
      var requestCount = 0;
      final server = await startUpstream((request, _, attempt) async {
        requestCount = attempt;
        await respond(request, content: 'response_format not-json');
      });
      configure(server);

      await GenerationService.instance.generateDishIntroduction(recipe);

      expect(requestCount, 1);
    });

    test('response_format 兼容请求遇到 401 后不再重试', () async {
      var requestCount = 0;
      final server = await startUpstream((request, _, attempt) async {
        requestCount = attempt;
        await respond(
          request,
          statusCode:
              attempt == 1 ? HttpStatus.badRequest : HttpStatus.unauthorized,
          content: attempt == 1
              ? '{"error":"unknown parameter response_format"}'
              : '{"error":"invalid token"}',
        );
      });
      configure(server);

      await GenerationService.instance.generateDishIntroduction(recipe);

      expect(requestCount, 2);
    });

    test('生图请求支持 Dio 取消且不进入重试', () async {
      final imageSeen = Completer<void>();
      var requestCount = 0;
      final server = await startUpstream((request, _, attempt) async {
        requestCount = attempt;
        if (!imageSeen.isCompleted) imageSeen.complete();
        await Future<void>.delayed(const Duration(seconds: 1));
        await respond(request);
      });
      configure(server);
      dotenv.testLoad(
        fileInput: 'MINIMAX_API_KEY=test-key\n'
            'MINIMAX_CHAT_API_URL=http://127.0.0.1:${server.port}\n'
            'AI_MAX_RETRIES=3\n'
            'AI_REQUEST_TIMEOUT=5\n'
            'AI_IMAGE_MODEL_NAME=image-01\n'
            'ENABLE_LIVE_DISH_IMAGE_GENERATION=true\n',
      );
      final cancelToken = CancelToken();
      final pending = (GenerationService.instance as dynamic)
              .generateRecipeImageUrl(recipe, cancelToken: cancelToken)
          as Future<String?>;
      await imageSeen.future.timeout(const Duration(seconds: 1));

      cancelToken.cancel();

      await expectLater(
        pending.timeout(const Duration(milliseconds: 300)),
        throwsA(
          isA<DioException>().having(
            (error) => error.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      expect(requestCount, 1);
    });

    test('图片生成遇到 401 时不重试', () async {
      var requestCount = 0;
      final server = await startUpstream((request, _, attempt) async {
        requestCount = attempt;
        await respond(request, statusCode: HttpStatus.unauthorized);
      });
      configure(server);
      dotenv.testLoad(
        fileInput: 'MINIMAX_API_KEY=test-key\n'
            'MINIMAX_CHAT_API_URL=http://127.0.0.1:${server.port}\n'
            'AI_MAX_RETRIES=3\n'
            'AI_REQUEST_TIMEOUT=1\n'
            'AI_IMAGE_MODEL_NAME=image-01\n'
            'ENABLE_LIVE_DISH_IMAGE_GENERATION=true\n',
      );

      await expectLater(
        GenerationService.instance.generateRecipeImageUrl(recipe),
        throwsA(isA<Exception>()),
      );
      expect(requestCount, 1);
    });
  });

  test('取消推荐会话会中断进行中的增强 HTTP 请求', () async {
    final requestSeen = Completer<void>();
    var requestCount = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      requestCount += 1;
      if (!requestSeen.isCompleted) requestSeen.complete();
      try {
        await utf8.decoder.bind(request).join();
        await Future<void>.delayed(const Duration(seconds: 1));
        request.response
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': '{"dishes":[]}'},
                },
              ],
            }),
          );
        await request.response.close();
      } catch (_) {}
    });
    dotenv.testLoad(
      fileInput: 'EXECUTION_PROXY_BASE_URL=http://127.0.0.1:${server.port}\n'
          'AI_MAX_RETRIES=3',
    );
    addTearDown(dotenv.clean);
    final service = V2Phase2RecommendationService(
      localRecommendationLoader: (_, __, ___) async => const [
        RecipeModel(
          id: 'local_1',
          name: '番茄炒蛋',
          description: '稳定的本地候选。',
          source: 'unified_db',
        ),
      ],
      howToCookRecipeService: V2HowToCookRecipeService(
        searchLoader: (_, __) async => const [],
        completeLoader: (_) async => null,
        assetIndexLoader: () async => '{"items":[]}',
      ),
    );
    const input = TasteInferenceInput(
      likedTagIds: ['spicy'],
      likedTagLabels: ['辣'],
      dislikedTagIds: [],
      dislikedTagLabels: [],
      skippedTagIds: [],
      skippedTagLabels: [],
      freeformRequirement: '',
      historyPreferenceSummary: {},
    );
    final session = await service.startRecommendationSession(input: input);
    await requestSeen.future.timeout(const Duration(seconds: 1));

    session.cancel();

    final enhanced = await session.enhanced.timeout(
      const Duration(milliseconds: 300),
    );
    expect(enhanced.aiSummary, session.local.aiSummary);
    expect(enhanced.resolutionStatus, session.local.resolutionStatus);
    expect(requestCount, 1);
  });

  group('AI fallback 缓存边界', () {
    const recipe = RecipeModel(
      id: 'dish-cache-1',
      name: '番茄炒蛋',
      description: '家常酸甜口',
      ingredients: ['番茄', '鸡蛋'],
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      dotenv.testLoad();
    });

    tearDown(dotenv.clean);

    Future<Set<String>> cacheKeys() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs
          .getKeys()
          .where((key) => key.startsWith('v2_ai_cache:'))
          .toSet();
    }

    Future<HttpServer> startFailingUpstream() async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        await utf8.decoder.bind(request).join();
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      });
      return server;
    }

    String upstreamEnv(HttpServer server) => 'MINIMAX_API_KEY=test-key\n'
        'MINIMAX_CHAT_API_URL=http://127.0.0.1:${server.port}\n'
        'AI_MAX_RETRIES=1\n';

    final operations = <String, Future<Object?> Function(RecipeModel)>{
      '菜品简介': GenerationService.instance.generateDishIntroduction,
      '营养分析': GenerationService.instance.getNutritionAnalysis,
      '饮品搭配': GenerationService.instance.getWinePairing,
      '趣味占卜': (recipe) => GenerationService.instance.getFortune(recipe: recipe),
    };

    for (final entry in operations.entries) {
      test('${entry.key} 未配置或请求失败的 fallback 不写入长期缓存', () async {
        await entry.value(recipe);
        expect(await cacheKeys(), isEmpty);

        SharedPreferences.setMockInitialValues({});
        final server = await startFailingUpstream();
        addTearDown(() => server.close(force: true));
        dotenv.testLoad(fileInput: upstreamEnv(server));

        await entry.value(recipe);
        expect(await cacheKeys(), isEmpty);
      });
    }

    test('营养分析首次失败后重新请求，成功结果仍可缓存', () async {
      var requestCount = 0;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        requestCount++;
        await utf8.decoder.bind(request).join();
        request.response.statusCode =
            requestCount == 1 ? HttpStatus.internalServerError : HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        if (requestCount > 1) {
          request.response.write(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': jsonEncode({
                      'nutrition': {
                        'calories': 777,
                        'protein': 33,
                        'carbs': 22,
                        'fat': 11,
                        'fiber': 5,
                        'sodium': 100,
                        'sugar': 4,
                      },
                      'healthScore': 9,
                      'balanceAdvice': ['AI 恢复后的建议'],
                      'dietaryTags': ['AI 恢复'],
                      'servingSize': '1人份',
                    }),
                  },
                },
              ],
            }),
          );
        }
        await request.response.close();
      });
      dotenv.testLoad(fileInput: upstreamEnv(server));

      await GenerationService.instance.getNutritionAnalysis(recipe);
      final recovered =
          await GenerationService.instance.getNutritionAnalysis(recipe);

      expect(requestCount, 2);
      expect(recovered.healthScore, 9);
      expect(recovered.nutrition.calories, 777);
      expect(await cacheKeys(), isNotEmpty);

      final cached = await GenerationService.instance.getNutritionAnalysis(
        recipe,
      );
      expect(cached.healthScore, 9);
      expect(requestCount, 2);
    });
  });
}
