import 'dart:io';

import 'package:eatwhat_app/core/models/analytics_event.dart';
import 'package:eatwhat_app/core/services/auth_service.dart';
import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_pairing_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_telemetry_context.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/external/platform/meituan_delivery_order_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/services/prebuilt_dish_image_catalog_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_telemetry_service.dart';
import 'package:eatwhat_app/v2/features/result/result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    // The ordering-gate test signs in through the auth sheet, which fires
    // AnalyticsService.identify into MetricsService (Hive-backed). Give the
    // test zone a temp Hive home so opening the box doesn't throw
    // unhandled HiveErrors. Plain Hive.init is used because initFlutter
    // needs path_provider, unavailable in widget tests.
    final dir = await Directory.systemTemp.createTemp('result_phase2_test');
    Hive.init(dir.path);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ResultPage 展示候选切换与营养摘要', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          imageGenerator: (_) async => null,
          nutritionLoader: (_) async => const NutritionAnalysis(
            nutrition: NutritionInfo(
              calories: 320,
              protein: 22,
              carbs: 18,
              fat: 14,
              fiber: 5,
              sodium: 680,
              sugar: 4,
            ),
            healthScore: 8,
            balanceAdvice: ['可以顺手补一份凉拌蔬菜。'],
            dietaryTags: ['高蛋白', '热菜'],
            servingSize: '1人份',
          ),
          recommendations: const [
            RecipeModel(
              id: 'r1',
              name: '番茄肥牛锅',
              description: '热一点，有锅气。',
              ingredients: ['番茄', '肥牛'],
            ),
            RecipeModel(
              id: 'r2',
              name: '香辣干锅鸡',
              description: '辣味更猛，适合夜里。',
              ingredients: ['鸡肉', '辣椒'],
            ),
            RecipeModel(
              id: 'r3',
              name: '麻辣冒菜',
              description: '麻辣直接，重口满足。',
              ingredients: ['牛肉', '蔬菜'],
            ),
          ],
          inferenceInput: const TasteInferenceInput(
            likedTagIds: ['f_spicy'],
            likedTagLabels: ['辣'],
            dislikedTagIds: ['f_sweet'],
            dislikedTagLabels: ['甜'],
            skippedTagIds: ['scene_party'],
            skippedTagLabels: ['聚会'],
            freeformRequirement: '今晚想吃热一点，有锅气',
            historyPreferenceSummary: {'f_spicy': 3},
          ),
          aiReasonsByRecipeId: const {
            'r1': '热口更稳，适合今晚。',
            'r2': '辣味更猛，夜里更带劲。',
          },
          aiSummary: '已经为你收束成三道更像今晚状态的候选。',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byKey(const ValueKey('result-candidate-rail')), findsOneWidget);
    expect(find.byKey(const ValueKey('result-nutrition-card')), findsOneWidget);
    expect(find.text('320 kcal'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('result-candidate-r2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('香辣干锅鸡'), findsWidgets);
    expect(find.text('辣味更猛，夜里更带劲。'), findsWidgets);
  });

  testWidgets('ResultPage 推荐行为漏斗共享同一个推荐批次 ID', (tester) async {
    final telemetryEvents = <_TelemetryEvent>[];
    final telemetry = V2RecommendationTelemetryService(
      sink: (type, properties) async {
        telemetryEvents.add(_TelemetryEvent(type, properties));
      },
    );
    const recommendationContext = RecommendationTelemetryContext(
      recommendationId: 'rec_widget_funnel',
      algorithmVersion: 'hybrid_v3_0',
      primarySource: 'unified_db',
      resolutionStatus: RecommendationResolutionStatus.dbResolved,
      recalledCount: 8,
      finalCount: 2,
      latencyMs: 160,
      diversityScore: 0.75,
      appliedConstraintCount: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          recommendationContext: recommendationContext,
          recommendationTelemetryService: telemetry,
          imageGenerator: (_) async => null,
          nutritionLoader: (_) async => const NutritionAnalysis(
            nutrition: NutritionInfo(
              calories: 320,
              protein: 22,
              carbs: 18,
              fat: 14,
              fiber: 5,
              sodium: 680,
              sugar: 4,
            ),
            healthScore: 8,
            balanceAdvice: [],
            dietaryTags: [],
            servingSize: '1人份',
          ),
          corpusPairingLoader: (_) async => const [],
          pairingLoader: (_) async => const WinePairing(
            name: '冰乌龙',
            reason: '清口解腻。',
            type: 'tea',
            servingTemperature: '冰镇',
            flavor: '清爽',
          ),
          dishIntroLoader: (_, __, ___) async => null,
          recommendations: const [
            RecipeModel(
              id: 'r1',
              name: '番茄肥牛锅',
              description: '热一点，有锅气。',
              ingredients: ['番茄', '肥牛'],
            ),
            RecipeModel(
              id: 'r2',
              name: '香辣干锅鸡',
              description: '辣味更直接。',
              ingredients: ['鸡肉', '辣椒'],
            ),
          ],
          inferenceInput: const TasteInferenceInput(
            likedTagIds: ['f_hot'],
            likedTagLabels: ['热菜'],
            dislikedTagIds: [],
            dislikedTagLabels: [],
            skippedTagIds: [],
            skippedTagLabels: [],
            freeformRequirement: '',
            historyPreferenceSummary: {},
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('result-candidate-r2')));
    await tester.pump();

    await tester.ensureVisible(
      find.byKey(const ValueKey('result-feedback-enjoyed')),
    );
    await tester.tap(find.byKey(const ValueKey('result-feedback-enjoyed')));
    await tester.pump();

    await tester.ensureVisible(find.text('再看看'));
    await tester.tap(find.text('再看看'));
    await tester.pump();

    await tester.ensureVisible(
      find.byKey(const ValueKey('result-execution-delivery')),
    );
    await tester.tap(
      find.byKey(const ValueKey('result-execution-delivery')),
    );
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(
      telemetryEvents.map((event) => event.type),
      containsAllInOrder([
        AnalyticsEventType.recommendationShown,
        AnalyticsEventType.recommendationClicked,
        AnalyticsEventType.tasteFeedbackGiven,
        AnalyticsEventType.recommendationSkipped,
        AnalyticsEventType.recommendationClicked,
        AnalyticsEventType.recommendationExecutionStarted,
      ]),
    );
    expect(
      telemetryEvents
          .map((event) => event.properties['recommendation_id'])
          .toSet(),
      {'rec_widget_funnel'},
    );
    expect(
      telemetryEvents.first.properties['candidate_ids'],
      ['r1', 'r2'],
    );
    expect(
      telemetryEvents.last.properties['execution_path'],
      ExecutionPath.delivery.name,
    );
  });

  testWidgets('ResultPage 在小屏长文案下不应出现溢出异常', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          imageGenerator: (_) async => 'https://invalid.example.com/dish.jpg',
          recommendations: const [
            RecipeModel(
              id: 'r1',
              name: '今天晚上吃点热的超长菜名测试用番茄肥牛锅',
              description: '这是一条非常长的推荐理由，用来验证候选卡片在小屏上不会再出现底部溢出的问题。',
              ingredients: ['番茄', '肥牛'],
            ),
            RecipeModel(
              id: 'r2',
              name: '今天晚上吃点热的超长菜名测试用香辣干锅鸡',
              description: '这也是一条很长的推荐理由，用来验证候选卡片文案被压缩后还能稳定显示。',
              ingredients: ['鸡肉', '辣椒'],
            ),
          ],
          aiReasonsByRecipeId: const {
            'r1': '根据你的口味这是一条非常长的推荐理由，用于测试小屏和长文案布局稳定性。',
            'r2': '另一条很长的推荐理由，用于确保候选卡片不会再出现 BOTTOM OVERFLOWED。',
          },
          inferenceInput: const TasteInferenceInput(
            likedTagIds: ['f_hot'],
            likedTagLabels: ['热'],
            dislikedTagIds: [],
            dislikedTagLabels: [],
            skippedTagIds: [],
            skippedTagLabels: [],
            freeformRequirement: '今晚想吃热一点',
            historyPreferenceSummary: {},
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(tester.takeException(), isNull);
  });

  testWidgets('ResultPage 在无推荐时展示 empty 状态而不是占位菜名', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResultPage(
          recommendations: [],
          fallbackTags: ['热菜'],
        ),
      ),
    );

    await tester.pump();

    expect(find.text('这轮没有收束出合适的菜'), findsOneWidget);
    expect(find.text('本轮未命中'), findsOneWidget);
    expect(find.textContaining('调整口味签名'), findsOneWidget);
    expect(find.text('根据你的口味推荐'), findsNothing);
    expect(
        find.byKey(const ValueKey('result-execution-shortcuts')), findsNothing);
    expect(find.byKey(const ValueKey('result-empty-reselect-button')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('execution-entry-button')), findsNothing);
  });

  testWidgets('ResultPage 在 AI 生成结果时展示正式中文来源语义', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          imageGenerator: (_) async => null,
          recommendations: const [
            RecipeModel(
              id: 'r-ai-1',
              name: '椒麻鸡丝凉面',
              description: '轻一点，但仍然要有味道。',
              ingredients: ['鸡丝', '面条'],
            ),
          ],
          resolutionStatus: RecommendationResolutionStatus.aiResolved,
          primarySource: 'ai',
          aiReasonsByRecipeId: const {
            'r-ai-1': 'AI 根据口味签名生成，它和你的口味表达最贴近。',
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('AI 生成推荐'), findsOneWidget);
    expect(find.text('来源 AI 生成'), findsOneWidget);
    expect(
      find.text('本轮由 AI 根据口味签名直接生成菜品。'),
      findsOneWidget,
    );
  });

  testWidgets('ResultPage 在混合推荐时展示本地召回与 AI 辅助语义', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          imageGenerator: (_) async => null,
          recommendations: const [
            RecipeModel(
              id: 'r-hybrid-1',
              name: '番茄肥牛锅',
              description: '来自本地正式菜谱。',
              ingredients: ['番茄', '肥牛'],
              source: 'unified_db',
            ),
          ],
          recalledCount: 12,
          resolutionStatus: RecommendationResolutionStatus.hybridResolved,
          primarySource: 'hybrid',
          aiReasonsByRecipeId: const {
            'r-hybrid-1': 'AI 认为它最贴合本轮热汤需求。',
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('本地召回 · AI 辅助'), findsOneWidget);
    expect(find.text('来源 本地 + AI'), findsOneWidget);
    expect(
      find.text('本轮先从 12 道本地正式候选中筛选，再由 AI 辅助收束。'),
      findsOneWidget,
    );
  });

  testWidgets('ResultPage 在 AI 降级时明确展示本地可靠推荐', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          imageGenerator: (_) async => null,
          recommendations: const [
            RecipeModel(
              id: 'r-local-1',
              name: '快手番茄蛋',
              description: '网络异常时仍可正常执行。',
              ingredients: ['番茄', '鸡蛋'],
              source: 'unified_db',
            ),
          ],
          recalledCount: 8,
          resolutionStatus: RecommendationResolutionStatus.localFallback,
          primarySource: 'local_fallback',
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('本地可靠推荐'), findsWidgets);
    expect(find.text('来源 本地可靠推荐'), findsOneWidget);
    expect(
      find.text('AI 增强暂时不可用，已从 8 道本地候选中稳定收束。'),
      findsOneWidget,
    );
  });

  testWidgets('ResultPage 展示本轮结构化约束', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          imageGenerator: (_) async => null,
          recommendations: const [
            RecipeModel(
              id: 'r1',
              name: '番茄豆腐面',
              description: '快手、预算友好，适合一人食。',
              ingredients: ['番茄', '豆腐', '面'],
            ),
          ],
          inferenceInput: const TasteInferenceInput(
            likedTagIds: [],
            likedTagLabels: ['家常'],
            dislikedTagIds: [],
            dislikedTagLabels: [],
            skippedTagIds: [],
            skippedTagLabels: [],
            freeformRequirement: '',
            structuredConstraints: TasteStructuredConstraints(
              maxTimeMinutes: 15,
              maxBudgetYuan: 30,
              partySize: 1,
              dietaryRestrictions: ['素食'],
              executionPreference: TasteExecutionPreference.delivery,
              locationPreference: TasteLocationPreference.nearby,
            ),
            historyPreferenceSummary: {},
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('本轮约束：15 分钟内、30 元内、1 人、素食、叫外卖、附近'), findsOneWidget);
  });

  testWidgets('ResultPage 外卖后端未接入时入口直接降级且不弹登录', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          meituanOrderClient: _UnconfiguredMeituanClient(),
          meituanLocationResolver: () async =>
              const GeoPoint(latitude: 39.9042, longitude: 116.4074),
          imageGenerator: (_) async => null,
          recommendations: const [
            RecipeModel(
              id: 'r1',
              name: '椒麻鸡丝凉面',
              description: '适合想省心点外卖的一口。',
              ingredients: ['鸡丝', '面条'],
              tags: ['外卖', '凉面'],
            ),
          ],
          inferenceInput: const TasteInferenceInput(
            likedTagIds: [],
            likedTagLabels: ['家常'],
            dislikedTagIds: [],
            dislikedTagLabels: [],
            skippedTagIds: [],
            skippedTagLabels: [],
            freeformRequirement: '叫外卖',
            structuredConstraints: TasteStructuredConstraints(
              executionPreference: TasteExecutionPreference.delivery,
            ),
            historyPreferenceSummary: {},
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    await tester.tap(find.byKey(const ValueKey('result-execution-delivery')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 降级提示出现，登录弹窗与菜单页都不出现
    expect(find.text('外卖服务暂未接入，先收藏或看看怎么做'), findsOneWidget);
    expect(find.byKey(const ValueKey('eatwhat-auth-sheet')), findsNothing);
    expect(find.text('生成外卖菜单'), findsNothing);
    expect(AuthService.isLoggedIn, isFalse);
  });

  testWidgets('ResultPage 展示三种开吃快捷入口并进入 API 菜单生成页', (tester) async {
    final meituanClient = _FakeMeituanMerchantClient();
    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          meituanOrderClient: meituanClient,
          meituanLocationResolver: () async =>
              const GeoPoint(latitude: 39.9042, longitude: 116.4074),
          imageGenerator: (_) async => null,
          recommendations: const [
            RecipeModel(
              id: 'r1',
              name: '椒麻鸡丝凉面',
              description: '适合想省心点外卖的一口。',
              ingredients: ['鸡丝', '面条'],
              tags: ['外卖', '凉面'],
            ),
          ],
          inferenceInput: const TasteInferenceInput(
            likedTagIds: [],
            likedTagLabels: ['家常'],
            dislikedTagIds: [],
            dislikedTagLabels: [],
            skippedTagIds: [],
            skippedTagLabels: [],
            freeformRequirement: '叫外卖',
            structuredConstraints: TasteStructuredConstraints(
              executionPreference: TasteExecutionPreference.delivery,
            ),
            historyPreferenceSummary: {},
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byKey(const ValueKey('result-execution-shortcuts')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('result-execution-cook')), findsOneWidget);
    expect(find.byKey(const ValueKey('result-execution-delivery')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('result-execution-dine-in')), findsOneWidget);

    // Seed an account so the ordering gate has a user to sign in as.
    await AuthService.register(
      username: 'testfoodie',
      email: 'test@example.com',
      password: 'Test1234',
      confirmPassword: 'Test1234',
    );
    await AuthService.logout();

    await tester.tap(find.byKey(const ValueKey('result-execution-delivery')));
    await tester.pumpAndSettle();

    // The ordering gate now requires an eatwhat account: a signed-out user
    // gets the auth sheet instead of the menu builder. Sign in through the
    // sheet, then the delivery flow resumes.
    expect(find.byKey(const ValueKey('eatwhat-auth-sheet')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('auth-login-username')),
      'testfoodie',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-login-password')),
      'Test1234',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('auth-login-submit')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('auth-login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('生成外卖菜单'), findsOneWidget);
    expect(find.textContaining('锅气食堂'), findsOneWidget);
    expect(meituanClient.lastKeyword, '椒麻鸡丝凉面');
  });

  testWidgets('ResultPage 在服务异常导致空结果时展示正式中文错误语义', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResultPage(
          recommendations: [],
          resolutionStatus: RecommendationResolutionStatus.empty,
          primarySource: 'error',
        ),
      ),
    );

    await tester.pump();

    expect(find.text('推荐服务异常'), findsOneWidget);
    expect(find.text('这轮没有收束出合适的菜'), findsOneWidget);
  });

  testWidgets('ResultPage 在营养接口失败时展示 unavailable 状态而不是继续 loading',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          imageGenerator: (_) async => null,
          nutritionLoader: (_) async => throw Exception('nutrition failed'),
          recommendations: const [
            RecipeModel(
              id: 'r1',
              name: '番茄肥牛锅',
              description: '热一点，有锅气。',
              ingredients: ['番茄', '肥牛'],
            ),
          ],
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byKey(const ValueKey('result-nutrition-card')), findsOneWidget);
    expect(find.text('营养信息暂时不可用'), findsOneWidget);
    expect(find.text('正在整理这道菜的基础营养结构。'), findsNothing);
  });

  testWidgets('ResultPage 优先使用 assets 预制菜图而不是触发在线生图', (tester) async {
    var imageGeneratorCallCount = 0;
    final imageCatalogService = PrebuiltDishImageCatalogService(
      remoteManifestLoader: () async => null,
      assetManifestLoader: () async => '''
{
  "items": [
    {
      "dishId": "r1",
      "dishName": "番茄肥牛锅",
      "aliases": ["番茄肥牛"],
      "heroUrl": "assets/images/prebuilt_dishes/dish-r1_1280.jpg",
      "thumbUrl": "assets/images/prebuilt_dishes/dish-r1_768.jpg",
      "styleTag": "warm_stew",
      "updatedAt": "2026-04-09T12:00:00Z",
      "sourceType": "howtocook_real_local",
      "sourceProject": "HowToCook",
      "sourcePath": "/repo/HowToCook/dishes/meat_dish/番茄肥牛锅/1.jpg",
      "sourceRecipeName": "番茄肥牛锅"
    }
  ]
}
''',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          imageCatalogService: imageCatalogService,
          imageGenerator: (_) async {
            imageGeneratorCallCount += 1;
            return 'https://example.com/should-not-be-used.jpg';
          },
          recommendations: const [
            RecipeModel(
              id: 'r1',
              name: '番茄肥牛锅',
              description: '热一点，有锅气。',
              ingredients: ['番茄', '肥牛'],
            ),
          ],
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(imageGeneratorCallCount, 0);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image.runtimeType.toString() == 'AssetImage',
      ),
      findsWidgets,
    );
    expect(find.text('实拍图'), findsOneWidget);
  });

  testWidgets('ResultPage 对旧预制图显示图库参考图标识', (tester) async {
    final imageCatalogService = PrebuiltDishImageCatalogService(
      remoteManifestLoader: () async => null,
      assetManifestLoader: () async => '''
{
  "items": [
    {
      "dishId": "r1",
      "dishName": "糖醋里脊",
      "aliases": ["糖醋里脊"],
      "heroUrl": "assets/images/prebuilt_dishes/dish-r1_1280.jpg",
      "thumbUrl": "assets/images/prebuilt_dishes/dish-r1_768.jpg",
      "styleTag": "dish",
      "updatedAt": "2026-04-09T12:00:00Z",
      "sourceType": "legacy_prebuilt_asset",
      "sourceProject": "eatwhat_assets",
      "sourcePath": "assets/images/prebuilt_dishes/dish-r1_1280.jpg",
      "sourceRecipeName": "糖醋里脊"
    }
  ]
}
''',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          imageCatalogService: imageCatalogService,
          imageGenerator: (_) async => null,
          recommendations: const [
            RecipeModel(
              id: 'r1',
              name: '糖醋里脊',
              description: '酸甜开胃。',
              ingredients: ['里脊肉', '番茄酱'],
            ),
          ],
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(
        find.byKey(const ValueKey('result-image-source-chip')), findsOneWidget);
    expect(find.text('图库参考图'), findsOneWidget);
  });

  testWidgets('ResultPage 提供查看同源做法入口并可打开菜谱库页', (tester) async {
    final howToCookService = V2HowToCookRecipeService(
      allRecipesLoader: (limit) async => [
        {
          'id': 'htc_1',
          'name': '黄焖鸡',
          'description': '下饭热菜',
          'difficulty': 3,
          'category': '荤菜',
          'subcategory': '家常',
          'cooking_time': 35,
          'servings': 2,
        },
      ],
      assetIndexLoader: () async => '{"items":[]}',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          imageGenerator: (_) async => null,
          howToCookRecipeService: howToCookService,
          recommendations: const [
            RecipeModel(
              id: 'r1',
              name: '黄焖鸡',
              description: '热一点，有锅气。',
              tags: ['荤菜', '家常'],
            ),
          ],
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byKey(const ValueKey('result-open-howtocook-library')),
        findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('result-open-howtocook-library')),
    );
    await tester.tap(
      find.byKey(const ValueKey('result-open-howtocook-library')),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('家常菜谱'), findsOneWidget);
    expect(find.text('荤菜'), findsWidgets);
  });

  testWidgets('ResultPage 在预制图缺失时展示在线生图结果并显示 AI 简介', (tester) async {
    const imageDataUri =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO9jz6sAAAAASUVORK5CYII=';

    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          imageCatalogService: PrebuiltDishImageCatalogService(
            remoteManifestLoader: () async => null,
            assetManifestLoader: () async => '{"items":[]}',
          ),
          imageGenerator: (_) async => imageDataUri,
          dishIntroLoader: (_, __, ___) async =>
              '酸甜先打开胃口，随后肉香慢慢压上来，属于今晚很好入口的一道热菜。',
          recommendations: const [
            RecipeModel(
              id: 'r-sweet-sour',
              name: '糖醋里脊',
              description: '',
              ingredients: ['里脊肉', '番茄酱'],
            ),
          ],
          aiReasonsByRecipeId: const {
            'r-sweet-sour': '酸甜更开胃，今晚吃着不腻。',
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byKey(const ValueKey('result-hero-intro')), findsOneWidget);
    expect(
      find.text('酸甜先打开胃口，随后肉香慢慢压上来，属于今晚很好入口的一道热菜。'),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image.runtimeType.toString() == 'MemoryImage',
      ),
      findsWidgets,
    );
    expect(find.text('AI 生成图'), findsOneWidget);
  });

  testWidgets('ResultPage 生图失败时显示重试入口，重试成功后展示图片', (tester) async {
    const imageDataUri =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO9jz6sAAAAASUVORK5CYII=';
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          imageCatalogService: PrebuiltDishImageCatalogService(
            remoteManifestLoader: () async => null,
            assetManifestLoader: () async => '{"items":[]}',
          ),
          imageGenerator: (_) async {
            calls += 1;
            return calls == 1 ? null : imageDataUri;
          },
          dishIntroLoader: (_, __, ___) async => '外酥里嫩，酸甜清亮，适合想吃得轻松但不寡淡的时候。',
          recommendations: const [
            RecipeModel(
              id: 'r-retry',
              name: '糖醋里脊',
              description: '',
              ingredients: ['里脊肉', '番茄酱'],
            ),
          ],
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byKey(const ValueKey('result-image-retry-button')),
        findsOneWidget);
    expect(find.text('菜图暂未生成'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('result-image-retry-button')),
    );
    await tester.tap(find.byKey(const ValueKey('result-image-retry-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(
        find.byKey(const ValueKey('result-image-retry-button')), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image.runtimeType.toString() == 'MemoryImage',
      ),
      findsWidgets,
    );
  });

  testWidgets('ResultPage 展示来源说明与召回摘要', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          imageGenerator: (_) async => null,
          recommendations: const [
            RecipeModel(
              id: 'r1',
              name: '番茄肥牛锅',
              description: '热一点，有锅气。',
              ingredients: ['番茄', '肥牛'],
            ),
          ],
          recallLabels: const ['辣', '夜宵', '热菜'],
          recalledCount: 3,
          resolutionStatus: RecommendationResolutionStatus.dbResolved,
          primarySource: 'unified_db',
          aiReasonsByRecipeId: const {
            'r1': '热口更稳，适合今晚。',
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(
        find.byKey(const ValueKey('result-explanation-card')), findsOneWidget);
    expect(find.text('本轮先从 3 道 HowToCook 候选里收束出这道菜。'), findsOneWidget);
    expect(find.text('生成信号：辣、夜宵、热菜'), findsOneWidget);
    expect(find.text('来源 HowToCook 菜谱'), findsOneWidget);
  });

  testWidgets('ResultPage 记录吃后轻反馈并更新本轮口味权重', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          imageGenerator: (_) async => null,
          recommendations: const [
            RecipeModel(
              id: 'r-feedback',
              name: '番茄肥牛锅',
              description: '热一点，有锅气。',
              ingredients: ['番茄', '肥牛'],
            ),
          ],
          inferenceInput: const TasteInferenceInput(
            likedTagIds: ['f_hot'],
            likedTagLabels: ['热菜'],
            dislikedTagIds: [],
            dislikedTagLabels: [],
            skippedTagIds: [],
            skippedTagLabels: [],
            freeformRequirement: '想吃热乎的',
            historyPreferenceSummary: {},
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey('result-feedback-band')), findsOneWidget);
    await tester
        .ensureVisible(find.byKey(const ValueKey('result-feedback-enjoyed')));
    await tester.tap(find.byKey(const ValueKey('result-feedback-enjoyed')));
    await tester.pump();

    expect(await V2PreferenceFeedbackService.instance.getTagScore('f_hot'), 1);
    expect(
      await V2PreferenceFeedbackService.instance.getRecentRecipeIds(),
      contains('r-feedback'),
    );

    await tester.tap(find.byKey(const ValueKey('result-feedback-not-for-me')));
    await tester.pump();

    expect(await V2PreferenceFeedbackService.instance.getTagScore('f_hot'), 0);
  });

  testWidgets('ResultPage 优先展示菜库搭配而不是临时生成饮品', (tester) async {
    var generatedPairingCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          imageGenerator: (_) async => null,
          nutritionLoader: (_) async => const NutritionAnalysis(
            nutrition: NutritionInfo(
              calories: 360,
              protein: 20,
              carbs: 30,
              fat: 12,
              fiber: 4,
              sodium: 600,
              sugar: 5,
            ),
            healthScore: 7,
            balanceAdvice: [],
            dietaryTags: [],
            servingSize: '1人份',
          ),
          dishIntroLoader: (_, __, ___) async => null,
          corpusPairingLoader: (_) async => const [
            RecipePairingModel(
              id: 'p1',
              dishId: '1',
              type: 'drink',
              name: '冰镇乌龙茶',
              description: '清口解腻，压住锅底油香。',
              strength: 0.9,
              source: 'rule',
            ),
            RecipePairingModel(
              id: 'p2',
              dishId: '1',
              type: 'side',
              name: '凉拌黄瓜',
              description: '补一点脆感。',
              strength: 0.8,
              source: 'rule',
            ),
          ],
          pairingLoader: (_) async {
            generatedPairingCalled = true;
            return const WinePairing(
              name: '临时饮品',
              reason: '不应该被展示。',
              type: 'tea',
              servingTemperature: '冰镇',
              flavor: '清爽',
            );
          },
          recommendations: const [
            RecipeModel(
              id: '1',
              name: '番茄肥牛锅',
              description: '热一点，有锅气。',
              ingredients: ['番茄', '肥牛'],
              source: 'unified_db',
            ),
          ],
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('冰镇乌龙茶'), findsOneWidget);
    expect(find.text('凉拌黄瓜'), findsOneWidget);
    expect(find.text('临时饮品'), findsNothing);
    expect(generatedPairingCalled, isFalse);
  });

  testWidgets('ResultPage 在菜库无搭配时回到原有饮品和配菜链路', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          imageGenerator: (_) async => null,
          nutritionLoader: (_) async => const NutritionAnalysis(
            nutrition: NutritionInfo(
              calories: 360,
              protein: 20,
              carbs: 30,
              fat: 12,
              fiber: 4,
              sodium: 600,
              sugar: 5,
            ),
            healthScore: 7,
            balanceAdvice: [],
            dietaryTags: [],
            servingSize: '1人份',
          ),
          dishIntroLoader: (_, __, ___) async => null,
          corpusPairingLoader: (_) async => const [],
          pairingLoader: (_) async => const WinePairing(
            name: '青柠苏打',
            reason: '清爽解腻。',
            type: 'sparkling',
            servingTemperature: '冰镇',
            flavor: '清爽',
          ),
          recommendations: const [
            RecipeModel(
              id: '1',
              name: '番茄肥牛锅',
              description: '热一点，有锅气。',
              ingredients: ['番茄', '肥牛'],
              source: 'unified_db',
            ),
          ],
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('青柠苏打'), findsOneWidget);
    expect(find.text('凉拌黄瓜'), findsOneWidget);
  });

  testWidgets('ResultPage 切换候选时不会短暂沿用上一道菜的搭配内容', (tester) async {
    Future<WinePairing> pairingLoader(RecipeModel recipe) async {
      if (recipe.id == 'r1') {
        return const WinePairing(
          name: '冷泡茉莉',
          reason: '第一道菜的饮品搭配。',
          type: 'tea',
          servingTemperature: '冰镇',
          flavor: '清香',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return const WinePairing(
        name: '青柠苏打',
        reason: '第二道菜的饮品搭配。',
        type: 'sparkling',
        servingTemperature: '冰镇',
        flavor: '清爽',
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          imageGenerator: (_) async => null,
          pairingLoader: pairingLoader,
          recommendations: const [
            RecipeModel(
              id: 'r1',
              name: '番茄肥牛锅',
              description: '热一点，有锅气。',
              ingredients: ['番茄', '肥牛'],
            ),
            RecipeModel(
              id: 'r2',
              name: '香辣干锅鸡',
              description: '辣味更猛，适合夜里。',
              ingredients: ['鸡肉', '辣椒'],
            ),
          ],
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('冷泡茉莉'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('result-candidate-r2')));
    await tester.pump();

    expect(find.text('冷泡茉莉'), findsNothing);
    expect(find.textContaining('正在结合这道菜的口味结构补全饮品和配菜'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('青柠苏打'), findsOneWidget);
  });
}

class _UnconfiguredMeituanClient extends MeituanDeliveryOrderClient {
  // Simulates the production state where EXECUTION_PROXY_BASE_URL is
  // missing: entry points must degrade instead of ordering.
  @override
  bool get isConfigured => false;
}

class _FakeMeituanMerchantClient extends MeituanDeliveryOrderClient {
  String? lastKeyword;

  // The real getter reads EnvConfig's proxy base URL, which is absent in
  // tests — ordering-gate tests need the backend marked as configured.
  @override
  bool get isConfigured => true;

  @override
  Future<MeituanMerchantSearchResult> searchMerchantResults({
    required String keyword,
    required GeoPoint location,
    int limit = 10,
  }) async {
    lastKeyword = keyword;
    return const MeituanMerchantSearchResult(
      hasNextPage: false,
      merchants: [
        MeituanDeliveryMerchant(
          merchantId: 'merchant-1',
          merchantName: '锅气食堂',
          deliveryTimeMinutes: 28,
          minimumPrice: 20,
        ),
      ],
    );
  }
}

class _TelemetryEvent {
  const _TelemetryEvent(this.type, this.properties);

  final AnalyticsEventType type;
  final Map<String, dynamic> properties;
}
