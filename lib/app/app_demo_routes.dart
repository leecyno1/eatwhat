import 'package:eatwhat_app/app/app_dependencies.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/external/platform/meituan_delivery_order_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_routes.dart';
import 'package:eatwhat_app/v2/features/decision/decision_page.dart';
import 'package:eatwhat_app/v2/features/details/recipe_detail_page.dart';
import 'package:eatwhat_app/v2/features/execution/execution_home_page.dart';
import 'package:eatwhat_app/v2/features/execution/meituan_menu_builder_page.dart';
import 'package:eatwhat_app/v2/features/execution/meituan_order_page.dart';
import 'package:eatwhat_app/v2/features/result/result_page.dart';
import 'package:go_router/go_router.dart';

List<GoRoute> buildAppV2DemoRoutes(AppDependencies dependencies) {
  return [
    GoRoute(
      path: AppV2Routes.decisionDemo,
      name: 'v2_decision_demo',
      builder: (context, state) => DecisionPage(
        input: demoInferenceInput,
        recommendationFlowService: dependencies.recommendationFlowService,
      ),
    ),
    GoRoute(
      path: AppV2Routes.recipeDetailDemo,
      name: 'v2_recipe_detail_demo',
      builder: (context, state) => RecipeDetailPage(
        recipe: demoRecipes.first,
        generationService: dependencies.generationService,
        howToCookRecipeService: dependencies.howToCookRecipeService,
      ),
    ),
    GoRoute(
      path: AppV2Routes.resultDemo,
      name: 'v2_result_demo',
      builder: (context, state) => ResultPage(
        recommendations: demoRecipes,
        inferenceInput: demoInferenceInput,
        aiReasonsByRecipeId: const {
          '1': '麻辣、热菜和下饭诉求最集中，适合现在直接定一道稳的主菜。',
          '3': '想吃厚重满足感时，红烧肉是更偏暖、更有收口感的选择。',
          '6': '如果你想要香辣但不想太重，宫保鸡丁会更灵活一些。',
        },
        aiSummary: '这组是基于你当前口味信号收束出的正式候选，优先展示有图且易决策的家常热菜。',
        recalledCount: 8,
        recallLabels: const ['麻辣', '热菜', '下饭', '夜宵'],
        primarySource: 'unified_db',
        generationService: dependencies.generationService,
        howToCookRecipeService: dependencies.howToCookRecipeService,
      ),
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
  ];
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
              boxPrice: 1,
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
