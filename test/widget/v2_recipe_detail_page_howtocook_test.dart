import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';
import 'package:eatwhat_app/v2/features/details/recipe_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  String? clipboardText;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message);
      if (key == 'assets/images/howtocook_gallery/test.jpg') {
        return ByteData(1);
      }
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          final data = Map<String, dynamic>.from(call.arguments as Map);
          clipboardText = data['text']?.toString();
          return null;
        case 'Clipboard.getData':
          return {'text': clipboardText ?? ''};
      }
      return null;
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    clipboardText = null;
  });

  testWidgets('RecipeDetailPage 优先展示统一库里的 HowToCook 原菜谱', (tester) async {
    final service = V2HowToCookRecipeService(
      searchLoader: (query, limit) async => [
        {
          'id': 'htc_1',
          'name': '黄焖鸡',
          'description': '一道十分下饭的美食',
          'difficulty': 3,
          'category': '荤菜',
          'cooking_time': 35,
          'servings': 2,
        },
      ],
      completeLoader: (recipeId) async => {
        'id': 'htc_1',
        'name': '黄焖鸡',
        'description': '一道十分下饭的美食',
        'difficulty': 3,
        'category': '荤菜',
        'cooking_time': 35,
        'servings': 2,
        'ingredients': [
          {'name': '鸡腿', 'amount': '2', 'unit': '只'},
          {'name': '香菇', 'amount': '5', 'unit': '朵'},
        ],
        'steps': [
          {'description': '鸡腿洗净剁块。'},
          {'description': '焖煮 15 分钟后加入青椒。'},
        ],
      },
      assetIndexLoader: () async => '{"items":[]}',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RecipeDetailPage(
          recipe: const RecipeModel(
            id: '19',
            name: '黄焖鸡',
            description: '统一库原始描述',
            ingredients: ['鸡腿 1只', '土豆 1个'],
            steps: ['鸡腿洗净切块。', '土豆下锅焖到软糯。'],
            source: 'howtocook',
          ),
          howToCookRecipeService: service,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('统一库原始描述'), findsOneWidget);
    expect(find.text('鸡腿 1只'), findsOneWidget);
    expect(find.text('鸡腿洗净切块。'), findsOneWidget);
    expect(find.text('HowToCook 原菜谱'), findsOneWidget);
    expect(find.text('食材 2'), findsOneWidget);
    expect(find.text('步骤 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('recipe-cook-brief-section')),
        findsOneWidget);
    expect(find.text('照着做'), findsOneWidget);
    expect(find.text('备料 2'), findsOneWidget);
    expect(find.text('2 步'), findsOneWidget);
    expect(find.text('生成菜谱'), findsNothing);
    expect(find.text('生成图片'), findsNothing);
    expect(find.text('一道十分下饭的美食'), findsNothing);
    expect(find.text('鸡腿 2只'), findsNothing);
  });

  testWidgets('RecipeDetailPage 可从照着做摘要进入做菜模式', (tester) async {
    final service = V2HowToCookRecipeService(
      assetIndexLoader: () async => '{"items":[]}',
      searchLoader: (query, limit) async => const [],
      completeLoader: (recipeId) async => null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RecipeDetailPage(
          recipe: const RecipeModel(
            id: 'cook-brief',
            name: '番茄肥牛锅',
            description: '热乎乎的一锅。',
            ingredients: ['番茄 2个', '肥牛 200g'],
            steps: ['番茄炒出沙。', '加水煮 8 分钟后下肥牛。'],
            source: 'howtocook',
          ),
          howToCookRecipeService: service,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('计时 8 分钟'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('recipe-cooking-mode-panel')), findsNothing);

    await tester.ensureVisible(
        find.byKey(const ValueKey('recipe-brief-start-cooking-button')));
    await tester.pump();
    await tester
        .tap(find.byKey(const ValueKey('recipe-brief-start-cooking-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('recipe-cooking-mode-panel')),
        findsOneWidget);
    expect(find.text('做菜模式'), findsOneWidget);
  });

  testWidgets('RecipeDetailPage 能渲染 HowToCook 本地图片资产', (tester) async {
    final service = V2HowToCookRecipeService(
      searchLoader: (query, limit) async => [
        {
          'id': 'htc_1',
          'name': '黄焖鸡',
          'description': '一道十分下饭的美食',
          'difficulty': 3,
          'category': '荤菜',
        },
      ],
      completeLoader: (recipeId) async => {
        'id': 'htc_1',
        'name': '黄焖鸡',
        'description': '一道十分下饭的美食',
        'difficulty': 3,
        'category': '荤菜',
        'ingredients': [
          {'name': '鸡腿', 'amount': '2', 'unit': '只'},
        ],
        'steps': [
          {'description': '鸡腿洗净剁块。'},
        ],
      },
      assetIndexLoader: () async => '''
        {
          "items": [
            {
              "recipeId": "htc_1",
              "name": "黄焖鸡",
              "assetImageUrls": ["assets/images/howtocook_gallery/test.jpg"]
            }
          ]
        }
      ''',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RecipeDetailPage(
          recipe: const RecipeModel(
            id: '19',
            name: '黄焖鸡',
            description: '统一库简化描述',
          ),
          howToCookRecipeService: service,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.image(const AssetImage('assets/images/howtocook_gallery/test.jpg')),
      findsOneWidget,
    );
  });

  testWidgets('RecipeDetailPage 展示相似做法列表', (tester) async {
    final service = V2HowToCookRecipeService(
      searchLoader: (query, limit) async => [
        {
          'id': 'htc_1',
          'name': '黄焖鸡',
          'description': '一道十分下饭的美食',
          'difficulty': 3,
          'category': '荤菜',
          'subcategory': '家常',
        },
      ],
      completeLoader: (recipeId) async => {
        'id': 'htc_1',
        'name': '黄焖鸡',
        'description': '一道十分下饭的美食',
        'difficulty': 3,
        'category': '荤菜',
        'subcategory': '家常',
        'ingredients': [
          {'name': '鸡腿', 'amount': '2', 'unit': '只'},
        ],
        'steps': [
          {'description': '鸡腿洗净剁块。'},
        ],
      },
      allRecipesLoader: (limit) async => [
        {
          'id': 'htc_1',
          'name': '黄焖鸡',
          'description': '一道十分下饭的美食',
          'difficulty': 3,
          'category': '荤菜',
          'subcategory': '家常',
        },
        {
          'id': 'htc_2',
          'name': '可乐鸡翅',
          'description': '甜咸下饭',
          'difficulty': 2,
          'category': '荤菜',
          'subcategory': '家常',
        },
      ],
      assetIndexLoader: () async => '{"items":[]}',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RecipeDetailPage(
          recipe: const RecipeModel(
            id: '19',
            name: '黄焖鸡',
            description: '统一库简化描述',
            tags: ['荤菜', '家常'],
          ),
          howToCookRecipeService: service,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('相似做法'), findsOneWidget);
    expect(find.text('可乐鸡翅'), findsOneWidget);
  });

  testWidgets('RecipeDetailPage 支持份量缩放与替换建议', (tester) async {
    final service = V2HowToCookRecipeService(
      searchLoader: (query, limit) async => [
        {
          'id': 'htc_1',
          'name': '黄焖鸡',
          'description': '一道十分下饭的美食',
          'difficulty': 3,
          'category': '荤菜',
          'subcategory': '家常',
          'servings': 2,
        },
      ],
      completeLoader: (recipeId) async => {
        'id': 'htc_1',
        'name': '黄焖鸡',
        'description': '一道十分下饭的美食',
        'difficulty': 3,
        'category': '荤菜',
        'subcategory': '家常',
        'servings': 2,
        'ingredients': [
          {'name': '鸡腿', 'amount': '2', 'unit': '只'},
          {'name': '香菇', 'amount': '4', 'unit': '朵'},
        ],
        'steps': [
          {'description': '鸡腿洗净剁块。'},
        ],
      },
      assetIndexLoader: () async => '{"items":[]}',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RecipeDetailPage(
          recipe: const RecipeModel(
            id: '19',
            name: '黄焖鸡',
            description: '统一库简化描述',
            tags: ['荤菜', '家常'],
          ),
          howToCookRecipeService: service,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('2 人份'), findsOneWidget);
    expect(find.text('鸡腿 2只'), findsOneWidget);

    await tester
        .ensureVisible(find.byKey(const ValueKey('recipe-servings-increase')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('recipe-servings-increase')));
    await tester.pump();

    expect(find.text('3 人份'), findsOneWidget);
    expect(find.text('鸡腿 3只'), findsOneWidget);
    expect(find.text('替换建议'), findsOneWidget);
    expect(find.textContaining('鸡腿可换成鸡翅根'), findsOneWidget);
  });

  testWidgets('RecipeDetailPage 支持步骤勾选并展示烹饪进度', (tester) async {
    final service = V2HowToCookRecipeService(
      searchLoader: (query, limit) async => [
        {
          'id': 'htc_1',
          'name': '番茄肥牛锅',
          'description': '热乎乎的一锅。',
          'difficulty': 2,
          'category': '荤菜',
        },
      ],
      completeLoader: (recipeId) async => {
        'id': 'htc_1',
        'name': '番茄肥牛锅',
        'description': '热乎乎的一锅。',
        'difficulty': 2,
        'category': '荤菜',
        'ingredients': [
          {'name': '番茄', 'amount': '2', 'unit': '个'},
          {'name': '肥牛', 'amount': '200', 'unit': 'g'},
        ],
        'steps': [
          {'description': '番茄炒出沙。'},
          {'description': '加入热水煮 8 分钟。'},
        ],
      },
      assetIndexLoader: () async => '{"items":[]}',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RecipeDetailPage(
          recipe: const RecipeModel(
            id: '19',
            name: '番茄肥牛锅',
            description: '统一库简化描述',
          ),
          howToCookRecipeService: service,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('完成 0/2'), findsOneWidget);
    expect(find.text('约 8 分钟'), findsOneWidget);

    await tester
        .ensureVisible(find.byKey(const ValueKey('recipe-step-toggle-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('recipe-step-toggle-0')));
    await tester.pump();

    expect(find.text('完成 1/2'), findsOneWidget);
  });

  testWidgets('RecipeDetailPage 做菜模式会优先展示执行提示', (tester) async {
    final service = V2HowToCookRecipeService(
      searchLoader: (query, limit) async => [
        {
          'id': 'htc_1',
          'name': '番茄肥牛锅',
          'description': '热乎乎的一锅。',
          'difficulty': 2,
          'category': '荤菜',
        },
      ],
      completeLoader: (recipeId) async => {
        'id': 'htc_1',
        'name': '番茄肥牛锅',
        'description': '热乎乎的一锅。',
        'difficulty': 2,
        'category': '荤菜',
        'ingredients': [
          {'name': '番茄', 'amount': '2', 'unit': '个'},
          {'name': '肥牛', 'amount': '200', 'unit': 'g'},
        ],
        'steps': [
          {'description': '番茄炒出沙。'},
          {'description': '加入热水煮 8 分钟。'},
        ],
      },
      assetIndexLoader: () async => '{"items":[]}',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RecipeDetailPage(
          recipe: const RecipeModel(
            id: '19',
            name: '番茄肥牛锅',
            description: '统一库简化描述',
          ),
          howToCookRecipeService: service,
          startInCookingMode: true,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('做菜模式'), findsOneWidget);
    expect(find.textContaining('先备料'), findsOneWidget);
    expect(find.text('完成 0/2'), findsOneWidget);
    expect(find.byKey(const ValueKey('recipe-cooking-mode-panel')),
        findsOneWidget);
  });

  testWidgets('RecipeDetailPage 做菜完成后会写回自制路径与口味偏好', (tester) async {
    final service = V2HowToCookRecipeService(
      searchLoader: (query, limit) async => [
        {
          'id': 'htc_1',
          'name': '番茄肥牛锅',
          'description': '热乎乎的一锅。',
          'difficulty': 2,
          'category': '荤菜',
        },
      ],
      completeLoader: (recipeId) async => {
        'id': 'htc_1',
        'name': '番茄肥牛锅',
        'description': '热乎乎的一锅。',
        'difficulty': 2,
        'category': '荤菜',
        'ingredients': [
          {'name': '番茄', 'amount': '2', 'unit': '个'},
          {'name': '肥牛', 'amount': '200', 'unit': 'g'},
        ],
        'steps': [
          {'description': '番茄炒出沙。'},
          {'description': '加入热水煮 8 分钟。'},
        ],
      },
      assetIndexLoader: () async => '{"items":[]}',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RecipeDetailPage(
          recipe: const RecipeModel(
            id: '19',
            name: '番茄肥牛锅',
            description: '统一库简化描述',
            tags: ['热菜'],
          ),
          howToCookRecipeService: service,
          startInCookingMode: true,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('recipe-cooking-complete-button')),
        findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('recipe-cooking-complete-button')));
    await tester.pumpAndSettle();

    expect(find.text('已记住这次自制完成'), findsOneWidget);
    expect(
      await V2PreferenceFeedbackService.instance.getRecentRecipeIds(),
      contains('19'),
    );
    expect(
      await V2PreferenceFeedbackService.instance.getExecutionPathScore(
        ExecutionPath.cook,
      ),
      2,
    );
    expect(await V2PreferenceFeedbackService.instance.getTagScore('热菜'), 2);
  });

  testWidgets('RecipeDetailPage 的步骤计时器可启动并显示倒计时', (tester) async {
    final service = V2HowToCookRecipeService(
      searchLoader: (query, limit) async => [
        {
          'id': 'htc_1',
          'name': '番茄肥牛锅',
          'description': '热乎乎的一锅。',
          'difficulty': 2,
          'category': '荤菜',
        },
      ],
      completeLoader: (recipeId) async => {
        'id': 'htc_1',
        'name': '番茄肥牛锅',
        'description': '热乎乎的一锅。',
        'difficulty': 2,
        'category': '荤菜',
        'ingredients': [
          {'name': '番茄', 'amount': '2', 'unit': '个'},
          {'name': '肥牛', 'amount': '200', 'unit': 'g'},
        ],
        'steps': [
          {'description': '番茄炒出沙。'},
          {'description': '加入热水煮 8 分钟。'},
        ],
      },
      assetIndexLoader: () async => '{"items":[]}',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RecipeDetailPage(
          recipe: const RecipeModel(
            id: '19',
            name: '番茄肥牛锅',
            description: '统一库简化描述',
          ),
          howToCookRecipeService: service,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester
        .ensureVisible(find.byKey(const ValueKey('recipe-step-timer-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('recipe-step-timer-1')));
    await tester.pumpAndSettle();

    expect(find.text('8 分钟'), findsOneWidget);
    expect(find.text('开始计时'), findsOneWidget);

    await tester.tap(find.text('开始计时'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('剩余'), findsOneWidget);
  });

  testWidgets('RecipeDetailPage 可打开购物清单并复制食材', (tester) async {
    final service = V2HowToCookRecipeService(
      searchLoader: (query, limit) async => [
        {
          'id': 'htc_1',
          'name': '番茄肥牛锅',
          'description': '热乎乎的一锅。',
          'difficulty': 2,
          'category': '荤菜',
          'servings': 2,
        },
      ],
      completeLoader: (recipeId) async => {
        'id': 'htc_1',
        'name': '番茄肥牛锅',
        'description': '热乎乎的一锅。',
        'difficulty': 2,
        'category': '荤菜',
        'servings': 2,
        'ingredients': [
          {'name': '番茄', 'amount': '2', 'unit': '个'},
          {'name': '肥牛', 'amount': '200', 'unit': 'g'},
        ],
        'steps': [
          {'description': '番茄炒出沙。'},
        ],
      },
      assetIndexLoader: () async => '{"items":[]}',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RecipeDetailPage(
          recipe: const RecipeModel(
            id: '19',
            name: '番茄肥牛锅',
            description: '统一库简化描述',
          ),
          howToCookRecipeService: service,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.ensureVisible(
        find.byKey(const ValueKey('recipe-shopping-list-button')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('recipe-shopping-list-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('购物清单'), findsWidgets);
    expect(find.text('番茄 2个'), findsWidgets);
    expect(find.text('肥牛 200g'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('recipe-shopping-list-copy')));
    await tester.pump();

    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    expect(clipboard?.text, contains('番茄 2个'));
    expect(clipboard?.text, contains('肥牛 200g'));
  });

  testWidgets('RecipeDetailPage 会恢复购物清单勾选状态', (tester) async {
    final service = V2HowToCookRecipeService(
      searchLoader: (query, limit) async => [
        {
          'id': 'htc_1',
          'name': '番茄肥牛锅',
          'description': '热乎乎的一锅。',
          'difficulty': 2,
          'category': '荤菜',
          'servings': 2,
        },
      ],
      completeLoader: (recipeId) async => {
        'id': 'htc_1',
        'name': '番茄肥牛锅',
        'description': '热乎乎的一锅。',
        'difficulty': 2,
        'category': '荤菜',
        'servings': 2,
        'ingredients': [
          {'name': '番茄', 'amount': '2', 'unit': '个'},
          {'name': '肥牛', 'amount': '200', 'unit': 'g'},
        ],
        'steps': [
          {'description': '番茄炒出沙。'},
        ],
      },
      assetIndexLoader: () async => '{"items":[]}',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RecipeDetailPage(
          recipe: const RecipeModel(
            id: '19',
            name: '番茄肥牛锅',
            description: '统一库简化描述',
          ),
          howToCookRecipeService: service,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(
        find.byKey(const ValueKey('recipe-shopping-list-button')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('recipe-shopping-list-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const ValueKey('recipe-shopping-item-0')));
    await tester.pump();
    expect(find.text('已买 1/2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(
        find.byKey(const ValueKey('recipe-shopping-list-button')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('recipe-shopping-list-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('已买 1/2'), findsOneWidget);
  });

  testWidgets('RecipeDetailPage 会恢复已勾选的烹饪进度', (tester) async {
    final service = V2HowToCookRecipeService(
      searchLoader: (query, limit) async => [
        {
          'id': 'htc_1',
          'name': '番茄肥牛锅',
          'description': '热乎乎的一锅。',
          'difficulty': 2,
          'category': '荤菜',
        },
      ],
      completeLoader: (recipeId) async => {
        'id': 'htc_1',
        'name': '番茄肥牛锅',
        'description': '热乎乎的一锅。',
        'difficulty': 2,
        'category': '荤菜',
        'ingredients': [
          {'name': '番茄', 'amount': '2', 'unit': '个'},
          {'name': '肥牛', 'amount': '200', 'unit': 'g'},
        ],
        'steps': [
          {'description': '番茄炒出沙。'},
          {'description': '加入热水煮 8 分钟。'},
        ],
      },
      assetIndexLoader: () async => '{"items":[]}',
    );

    Widget page() {
      return MaterialApp(
        home: RecipeDetailPage(
          recipe: const RecipeModel(
            id: '19',
            name: '番茄肥牛锅',
            description: '统一库简化描述',
          ),
          howToCookRecipeService: service,
        ),
      );
    }

    await tester.pumpWidget(page());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester
        .ensureVisible(find.byKey(const ValueKey('recipe-step-toggle-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('recipe-step-toggle-0')));
    await tester.pump();

    expect(find.text('完成 1/2'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(page());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('完成 1/2'), findsOneWidget);
  });
}
