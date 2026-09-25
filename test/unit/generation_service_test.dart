import 'dart:convert';
import 'dart:io';

import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/services/generation_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
}
