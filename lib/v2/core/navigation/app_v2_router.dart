import 'package:eatwhat_app/features/auth/screens/login_screen.dart';
import 'package:eatwhat_app/features/auth/screens/register_screen.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_telemetry_context.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/external/platform/meituan_delivery_order_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';
import 'package:eatwhat_app/v2/features/decision/decision_page.dart';
import 'package:eatwhat_app/v2/features/details/howtocook_library_page.dart';
import 'package:eatwhat_app/v2/features/details/recipe_detail_page.dart';
import 'package:eatwhat_app/v2/features/execution/execution_home_page.dart';
import 'package:eatwhat_app/v2/features/execution/meituan_menu_builder_page.dart';
import 'package:eatwhat_app/v2/features/execution/meituan_order_page.dart';
import 'package:eatwhat_app/v2/features/favorites/favorites_page.dart';
import 'package:eatwhat_app/v2/features/home/home_page.dart';
import 'package:eatwhat_app/v2/features/result/result_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppV2Routes {
  const AppV2Routes._();

  static const String home = '/';
  static const String decision = '/decision';
  static const String result = '/result';
  static const String recipeDetail = '/recipe-detail';
  static const String execution = '/execution';
  static const String executionDelivery = '/execution-delivery';
  static const String executionDineIn = '/execution-dine-in';
  static const String decisionDemo = '/decision-demo';
  static const String resultDemo = '/result-demo';
  static const String favorites = '/favorites';
  static const String howtocookLibrary = '/howtocook';
  static const String executionDemo = '/execution-demo';
  static const String deliveryDemo = '/delivery-demo';
  static const String orderDemo = '/order-demo';
  static const String login = '/login';
  static const String register = '/register';
}

class AppV2DecisionRouteData {
  const AppV2DecisionRouteData({
    required this.input,
    this.recommendationFlowService,
    this.autoNavigateToResult = true,
  });

  final TasteInferenceInput input;
  final V2Phase2RecommendationService? recommendationFlowService;
  final bool autoNavigateToResult;
}

class AppV2ResultRouteData {
  const AppV2ResultRouteData({
    required this.recommendations,
    required this.inferenceInput,
    this.fallbackTags = const [],
    this.recallLabels = const [],
    this.recalledCount = 0,
    this.aiReasonsByRecipeId = const {},
    this.aiSummary,
    this.resolutionStatus,
    this.primarySource,
    this.recommendationContext,
  });

  final List<RecipeModel> recommendations;
  final TasteInferenceInput inferenceInput;
  final List<String> fallbackTags;
  final List<String> recallLabels;
  final int recalledCount;
  final Map<String, String> aiReasonsByRecipeId;
  final String? aiSummary;
  final RecommendationResolutionStatus? resolutionStatus;
  final String? primarySource;
  final RecommendationTelemetryContext? recommendationContext;
}

class AppV2RecipeDetailRouteData {
  const AppV2RecipeDetailRouteData({
    required this.recipe,
    this.howToCookRecipeService,
    this.startInCookingMode = false,
  });

  final RecipeModel recipe;
  final V2HowToCookRecipeService? howToCookRecipeService;
  final bool startInCookingMode;
}

class AppV2HowToCookLibraryRouteData {
  const AppV2HowToCookLibraryRouteData({
    this.service,
    this.initialCategory = '',
    this.initialQuery = '',
  });

  final V2HowToCookRecipeService? service;
  final String initialCategory;
  final String initialQuery;
}

class AppV2ExecutionRouteData {
  const AppV2ExecutionRouteData({
    required this.intent,
  });

  final ExecutionIntent intent;
}

class AppV2DeliveryExecutionRouteData {
  const AppV2DeliveryExecutionRouteData({
    required this.intent,
    this.snapshot,
    this.meituanOrderClient,
    this.locationResolver,
  });

  final ExecutionIntent intent;
  final DeliveryExecutionSnapshot? snapshot;
  final MeituanDeliveryOrderClient? meituanOrderClient;
  final Future<GeoPoint> Function()? locationResolver;
}

class AppV2DineInExecutionRouteData {
  const AppV2DineInExecutionRouteData({
    required this.intent,
    this.snapshot,
  });

  final ExecutionIntent intent;
  final DineInExecutionSnapshot? snapshot;
}

class AppV2Router {
  const AppV2Router._();

  static String initialLocationForBootstrap(String bootstrap) {
    switch (bootstrap.trim().toLowerCase()) {
      case 'decision_demo':
        return AppV2Routes.decisionDemo;
      case 'result_demo':
        return AppV2Routes.resultDemo;
      case 'execution_demo':
        return AppV2Routes.executionDemo;
      case 'delivery_demo':
        return AppV2Routes.deliveryDemo;
      case 'order_demo':
        return AppV2Routes.orderDemo;
      case 'home':
      default:
        return AppV2Routes.home;
    }
  }

  static GoRouter createRouter({
    required GlobalKey<NavigatorState> navigatorKey,
    String debugBootstrap = 'home',
    bool debugMode = false,
  }) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: debugMode
          ? initialLocationForBootstrap(debugBootstrap)
          : AppV2Routes.home,
      routes: [
        GoRoute(
          path: AppV2Routes.home,
          name: 'v2_home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: AppV2Routes.login,
          name: 'v2_login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppV2Routes.register,
          name: 'v2_register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppV2Routes.decision,
          name: 'v2_decision',
          builder: (context, state) {
            final data = state.extra;
            if (data is! AppV2DecisionRouteData) {
              return const HomePage();
            }
            return DecisionPage(
              input: data.input,
              recommendationFlowService: data.recommendationFlowService,
              autoNavigateToResult: data.autoNavigateToResult,
            );
          },
        ),
        GoRoute(
          path: AppV2Routes.result,
          name: 'v2_result',
          builder: (context, state) {
            final data = state.extra;
            if (data is! AppV2ResultRouteData) {
              return const HomePage();
            }
            return ResultPage(
              recommendations: data.recommendations,
              inferenceInput: data.inferenceInput,
              fallbackTags: data.fallbackTags,
              recallLabels: data.recallLabels,
              recalledCount: data.recalledCount,
              aiReasonsByRecipeId: data.aiReasonsByRecipeId,
              aiSummary: data.aiSummary,
              resolutionStatus: data.resolutionStatus,
              primarySource: data.primarySource,
              recommendationContext: data.recommendationContext,
            );
          },
        ),
        GoRoute(
          path: AppV2Routes.recipeDetail,
          name: 'v2_recipe_detail',
          builder: (context, state) {
            final data = state.extra;
            if (data is! AppV2RecipeDetailRouteData) {
              return const HomePage();
            }
            return RecipeDetailPage(
              recipe: data.recipe,
              howToCookRecipeService: data.howToCookRecipeService,
              startInCookingMode: data.startInCookingMode,
            );
          },
        ),
        GoRoute(
          path: AppV2Routes.execution,
          name: 'v2_execution',
          builder: (context, state) {
            final data = state.extra;
            if (data is! AppV2ExecutionRouteData) {
              return const HomePage();
            }
            return ExecutionHomePage(intent: data.intent);
          },
        ),
        GoRoute(
          path: AppV2Routes.executionDelivery,
          name: 'v2_execution_delivery',
          builder: (context, state) {
            final data = state.extra;
            if (data is! AppV2DeliveryExecutionRouteData) {
              return const HomePage();
            }
            return MeituanMenuBuilderPage(
              intent: data.intent,
              client: data.meituanOrderClient,
              locationResolver: data.locationResolver,
            );
          },
        ),
        GoRoute(
          path: AppV2Routes.executionDineIn,
          name: 'v2_execution_dine_in',
          builder: (context, state) {
            final data = state.extra;
            if (data is! AppV2DineInExecutionRouteData) {
              return const HomePage();
            }
            return DineInExecutionPage(
              intent: data.intent,
              snapshot: data.snapshot,
            );
          },
        ),
        GoRoute(
          path: AppV2Routes.decisionDemo,
          name: 'v2_decision_demo',
          builder: (context, state) =>
              const DecisionPage(input: demoInferenceInput),
        ),
        GoRoute(
          path: AppV2Routes.resultDemo,
          name: 'v2_result_demo',
          builder: (context, state) => const ResultPage(
            recommendations: demoRecipes,
            inferenceInput: demoInferenceInput,
            aiReasonsByRecipeId: {
              '1': '麻辣、热菜和下饭诉求最集中，适合现在直接定一道稳的主菜。',
              '3': '想吃厚重满足感时，红烧肉是更偏暖、更有收口感的选择。',
              '6': '如果你想要香辣但不想太重，宫保鸡丁会更灵活一些。',
            },
            aiSummary: '这组是基于你当前口味信号收束出的正式候选，优先展示有图且易决策的家常热菜。',
            recalledCount: 8,
            recallLabels: ['麻辣', '热菜', '下饭', '夜宵'],
            primarySource: 'unified_db',
          ),
        ),
        GoRoute(
          path: AppV2Routes.favorites,
          name: 'v2_favorites',
          builder: (context, state) => const FavoritesPageV2(),
        ),
        GoRoute(
          path: AppV2Routes.howtocookLibrary,
          name: 'v2_howtocook_library',
          builder: (context, state) {
            final data = state.extra;
            if (data is AppV2HowToCookLibraryRouteData) {
              return HowToCookLibraryPage(
                service: data.service,
                initialCategory: data.initialCategory,
                initialQuery: data.initialQuery,
              );
            }
            return const HowToCookLibraryPage();
          },
        ),
        GoRoute(
          path: AppV2Routes.executionDemo,
          name: 'v2_execution_demo',
          builder: (context, state) => const ExecutionHomePage(
            intent: demoExecutionIntent,
          ),
        ),
        GoRoute(
          path: AppV2Routes.deliveryDemo,
          name: 'v2_delivery_demo',
          builder: (context, state) => MeituanMenuBuilderPage(
            intent: demoExecutionIntent.copyWith(
              preferredPath: ExecutionPath.delivery,
            ),
            client: _DemoMeituanDeliveryOrderClient(),
            locationResolver: _demoLocationResolver,
            paymentLauncher: (_) async => true,
          ),
        ),
        GoRoute(
          path: AppV2Routes.orderDemo,
          name: 'v2_order_demo',
          builder: (context, state) => MeituanOrderPage(
            intent: demoExecutionIntent.copyWith(
              preferredPath: ExecutionPath.delivery,
            ),
            match: const DeliveryMatchResult(
              platform: 'meituan',
              providerDisplayName: '美团外卖',
              merchantId: 'demo-guoqi-canteen',
              merchantName: '锅气食堂（福田店）',
              dishName: '麻婆豆腐',
              url: '',
              source: 'meituan_open_api_demo',
              price: Money(amount: 20),
              deliveryTimeMinutes: 32,
            ),
            client: _DemoMeituanDeliveryOrderClient(),
            locationResolver: _demoLocationResolver,
            paymentLauncher: (_) async => true,
          ),
        ),
      ],
    );
  }
}

Future<GeoPoint> _demoLocationResolver() async {
  return const GeoPoint(latitude: 22.5431, longitude: 114.0579);
}

class _DemoMeituanDeliveryOrderClient extends MeituanDeliveryOrderClient {
  // The demo route serves reviewable merchants without any backend — from
  // the page's perspective the ordering service is fully wired up.
  @override
  bool get isConfigured => true;

  @override
  Future<MeituanMerchantSearchResult> searchMerchantResults({
    required String keyword,
    required GeoPoint location,
    int limit = 10,
  }) async {
    return const MeituanMerchantSearchResult(
      hasNextPage: false,
      merchants: [
        MeituanDeliveryMerchant(
          merchantId: 'demo-guoqi-canteen',
          merchantName: '锅气食堂（福田店）',
          address: '福华路 88 号 · 美团专送',
          rating: 4.8,
          deliveryTimeMinutes: 32,
          shippingFee: 3,
          minimumPrice: 20,
        ),
        MeituanDeliveryMerchant(
          merchantId: 'demo-home-kitchen',
          merchantName: '家常小馆（中心区店）',
          address: '金田路 126 号 · 品牌专送',
          rating: 4.7,
          deliveryTimeMinutes: 38,
          shippingFee: 2,
          minimumPrice: 18,
        ),
      ],
    );
  }

  @override
  Future<MeituanProductSearchResult> searchProducts({
    required String merchantId,
    required GeoPoint location,
    String keyword = '',
  }) async {
    return const MeituanProductSearchResult(
      merchantName: '锅气食堂（福田店）',
      products: [
        MeituanDeliveryProduct(
          productId: 'demo-mapotofu',
          name: '麻婆豆腐',
          categoryName: '招牌热菜',
          description: '嫩豆腐、牛肉末和豆瓣酱，麻辣下饭。',
          monthlySales: 866,
          attributes: [
            MeituanDeliveryAttribute(
              name: '辣度',
              values: [
                MeituanDeliveryAttributeValue(id: 1, label: '微辣'),
                MeituanDeliveryAttributeValue(id: 2, label: '中辣'),
              ],
            ),
          ],
          skus: [
            MeituanDeliverySku(
              skuId: 'demo-mapotofu-standard',
              price: 26,
              specification: '标准份',
              stock: -1,
              boxPrice: 1,
            ),
          ],
        ),
        MeituanDeliveryProduct(
          productId: 'demo-rice',
          name: '东北米饭',
          categoryName: '主食',
          description: '粒粒分明，适合拌麻婆豆腐汤汁。',
          attributes: [],
          skus: [
            MeituanDeliverySku(
              skuId: 'demo-rice-standard',
              price: 3,
              specification: '一碗',
              stock: -1,
            ),
          ],
        ),
        MeituanDeliveryProduct(
          productId: 'demo-cucumber',
          name: '凉拌黄瓜',
          categoryName: '清爽小菜',
          description: '蒜香清爽，平衡麻辣口感。',
          attributes: [],
          skus: [
            MeituanDeliverySku(
              skuId: 'demo-cucumber-standard',
              price: 9,
              specification: '一份',
              stock: -1,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<MeituanOrderPreview> previewOrder(
    MeituanDeliveryOrderRequest request,
  ) async {
    return const MeituanOrderPreview(
      previewToken: 'demo-preview-token',
      total: 33,
      shippingFee: 3,
      boxFee: 1,
      merchantName: '锅气食堂（福田店）',
    );
  }

  @override
  Future<MeituanSubmittedOrder> submitOrder(
    MeituanDeliveryOrderRequest request, {
    required String previewToken,
    String? verifyCode,
    String? paymentSuccessUrl,
    String? paymentFailureUrl,
  }) async {
    return const MeituanSubmittedOrder(
      status: 'payment_required',
      orderId: 'demo-order',
      paymentUrl: 'https://example.com/demo-payment',
      requiresVerification: false,
    );
  }
}

const TasteInferenceInput demoInferenceInput = TasteInferenceInput(
  likedTagIds: ['f_spicy', 'scene_night', 'style_home'],
  likedTagLabels: ['麻辣', '夜宵', '家常'],
  dislikedTagIds: ['f_sweet'],
  dislikedTagLabels: ['太甜'],
  skippedTagIds: ['scene_party'],
  skippedTagLabels: ['聚会'],
  freeformRequirement: '今晚想吃一口热的、香的、最好很下饭',
  historyPreferenceSummary: {
    'f_spicy': 4,
    'scene_night': 2,
    'style_home': 3,
  },
);

const List<RecipeModel> demoRecipes = [
  RecipeModel(
    id: '1',
    name: '麻婆豆腐',
    description: '豆腐嫩、肉末香，麻辣会先抬起来，后劲是很稳的下饭感。',
    ingredients: ['豆腐', '牛肉末', '豆瓣酱'],
    source: 'unified_db',
  ),
  RecipeModel(
    id: '3',
    name: '红烧肉',
    description: '酱香和油脂感更厚，适合想吃得更满足、更有压轴感的时候。',
    ingredients: ['五花肉', '冰糖', '生抽'],
    source: 'unified_db',
  ),
  RecipeModel(
    id: '6',
    name: '宫保鸡丁',
    description: '辣度更灵活，鸡肉和花生的香气会更跳，节奏更轻快。',
    ingredients: ['鸡胸肉', '花生米', '干辣椒'],
    source: 'unified_db',
  ),
];

const ExecutionIntent demoExecutionIntent = ExecutionIntent(
  recipe: RecipeModel(
    id: '1',
    name: '麻婆豆腐',
    description: '豆腐嫩、肉末香，麻辣会先抬起来，后劲是很稳的下饭感。',
    ingredients: ['豆腐', '牛肉末', '豆瓣酱'],
    source: 'unified_db',
  ),
  pairings: [
    PairingSelection(
      category: '主食',
      title: '米饭',
      subtitle: '吸住麻辣汤汁，收口最稳。',
    ),
  ],
  sourceTags: ['麻辣', '热菜', '下饭'],
);
