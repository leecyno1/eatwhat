import 'dart:io';

import 'package:eatwhat_app/core/models/analytics_event.dart';
import 'package:eatwhat_app/core/services/auth_service.dart';
import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_telemetry_context.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/external/platform/meituan_delivery_order_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/services/prebuilt_dish_image_catalog_service.dart';
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

    // 缩略图点选切换：菜名换到下一道
    await tester.tap(find.byKey(const ValueKey('result-candidate-r3')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('麻辣冒菜'), findsWidgets);
    expect(find.text('就吃这个'), findsOneWidget);
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

    // 点缩略图切换候选（事件同步发出）
    await tester.tap(find.byKey(const ValueKey('result-candidate-r2')));
    await tester.pump(const Duration(milliseconds: 300));

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
    expect(find.text('外卖服务接入中，请先在美团开放平台注册商家'), findsOneWidget);
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

  testWidgets('ResultPage 点「就吃这个」默认直达做菜页，不再弹重复的三选一页',
      (tester) async {
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
              steps: ['番茄炒出沙。', '加入热水煮 8 分钟。'],
            ),
          ],
          // 不带 executionPreference → 无首选渠道，应回退到「菜谱直出」。
          inferenceInput: const TasteInferenceInput(
            likedTagIds: [],
            likedTagLabels: ['家常'],
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
    await tester.pump(const Duration(milliseconds: 900));

    // 主 CTA 仍是明确的「就吃这个」。
    expect(
      find.byKey(const ValueKey('execution-entry-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('execution-entry-button')));
    await tester.pumpAndSettle();

    // 一键直达做菜（菜谱直出）页，而不是重复的三选一「开吃方式」页。
    expect(
      find.byKey(const ValueKey('recipe-cooking-page-view')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('execution-home-page')), findsNothing);
    expect(find.text('开吃方式'), findsNothing);
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
  Future<MeituanOAuthStatus> getOAuthStatus() async =>
      const MeituanOAuthStatus(connected: true, requiresUserAuthorization: false);

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
