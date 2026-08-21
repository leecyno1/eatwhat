import 'dart:async';

import 'package:eatwhat_app/core/services/auth_service.dart';
import 'package:eatwhat_app/v2/core/external/platform/meituan_delivery_order_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_router.dart';
import 'package:eatwhat_app/v2/core/services/v2_execution_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_telemetry_service.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/details/howtocook_library_page.dart';
import 'package:eatwhat_app/v2/features/details/recipe_detail_page.dart';
import 'package:eatwhat_app/v2/features/execution/controllers/execution_completion_controller.dart'
    as execution_completion;
import 'package:eatwhat_app/v2/features/auth/auth_sheet.dart';
import 'package:eatwhat_app/v2/features/execution/meituan_menu_builder_page.dart';
import 'package:eatwhat_app/v2/features/execution/meituan_order_page.dart';
import 'package:eatwhat_app/v2/features/execution/widgets/execution_completion_feedback_panel.dart';
import 'package:eatwhat_app/v2/features/execution/widgets/execution_widgets.dart';
import 'package:eatwhat_app/v2/features/home/widgets/floating_editorial_background.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ExecutionHomePage extends StatefulWidget {
  const ExecutionHomePage({
    super.key,
    required this.intent,
  });

  final ExecutionIntent intent;

  @override
  State<ExecutionHomePage> createState() => _ExecutionHomePageState();
}

class _ExecutionHomePageState extends State<ExecutionHomePage> {
  static final V2PreferenceFeedbackService _feedback =
      V2PreferenceFeedbackService.instance;
  static final V2RecommendationTelemetryService _recommendationTelemetry =
      V2RecommendationTelemetryService.instance;

  ExecutionPath _learnedPreferredPath = ExecutionPath.any;

  @override
  void initState() {
    super.initState();
    _loadLearnedPreferredPath();
  }

  Future<void> _loadLearnedPreferredPath() async {
    if (widget.intent.preferredPath != ExecutionPath.any) return;
    final preferredPath = await _feedback.getPreferredExecutionPath();
    if (!mounted) return;
    setState(() {
      _learnedPreferredPath = preferredPath;
    });
  }

  Future<void> _openRecipeDetail(BuildContext context) async {
    unawaited(_feedback.recordExecutionPathChosen(ExecutionPath.cook));
    _recordExecutionStarted(ExecutionPath.cook);
    final routeData = AppV2RecipeDetailRouteData(
      recipe: widget.intent.recipe,
      startInCookingMode: true,
    );
    if (GoRouter.maybeOf(context) != null) {
      await context.push(AppV2Routes.recipeDetail, extra: routeData);
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeDetailPage(
          recipe: widget.intent.recipe,
          startInCookingMode: true,
        ),
      ),
    );
  }

  Future<void> _openHowToCookLibrary(BuildContext context) async {
    const routeData = AppV2HowToCookLibraryRouteData();
    if (GoRouter.maybeOf(context) != null) {
      await context.push(AppV2Routes.howtocookLibrary, extra: routeData);
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const HowToCookLibraryPage(),
      ),
    );
  }

  Future<void> _openDelivery(BuildContext context) async {
    unawaited(_feedback.recordExecutionPathChosen(ExecutionPath.delivery));
    _recordExecutionStarted(ExecutionPath.delivery);

    // Degrade before the login gate when the ordering backend isn't wired
    // up — a snackbar beats signing the user in only to hit a technical
    // error in the menu builder.
    if (!MeituanDeliveryOrderClient().isConfigured) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('外卖服务暂未接入，先收藏或看看怎么做')),
        );
      }
      return;
    }

    // Ordering gate: Meituan orders belong to an eatwhat account, so a
    // signed-out user gets the login/register sheet first and only moves
    // on into the delivery flow after signing in.
    if (!AuthService.isLoggedIn) {
      final signedIn = await showEatWhatAuthSheet(
        context,
        reason: '登录后才能使用美团下单',
      );
      if (!signedIn || !context.mounted) return;
    }

    final intent = widget.intent.copyWith(
      preferredPath: ExecutionPath.delivery,
    );
    final routeData = AppV2DeliveryExecutionRouteData(intent: intent);
    if (GoRouter.maybeOf(context) != null) {
      await context.push(AppV2Routes.executionDelivery, extra: routeData);
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MeituanMenuBuilderPage(intent: intent),
      ),
    );
  }

  Future<void> _openDineIn(BuildContext context) async {
    unawaited(_feedback.recordExecutionPathChosen(ExecutionPath.dineIn));
    _recordExecutionStarted(ExecutionPath.dineIn);
    final intent = widget.intent.copyWith(
      preferredPath: ExecutionPath.dineIn,
    );
    final routeData = AppV2DineInExecutionRouteData(intent: intent);
    if (GoRouter.maybeOf(context) != null) {
      await context.push(AppV2Routes.executionDineIn, extra: routeData);
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DineInExecutionPage(intent: intent),
      ),
    );
  }

  void _recordExecutionStarted(ExecutionPath path) {
    final recommendationContext = widget.intent.recommendationContext;
    if (recommendationContext == null) return;
    unawaited(
      _recommendationTelemetry.recordExecutionStarted(
        context: recommendationContext,
        recipeId: widget.intent.recipe.id,
        position: widget.intent.recommendationPosition ?? 0,
        executionPath: path.name,
      ),
    );
  }

  ExecutionPath get _preferredPath {
    if (widget.intent.preferredPath != ExecutionPath.any) {
      return widget.intent.preferredPath;
    }
    return _learnedPreferredPath;
  }

  @override
  Widget build(BuildContext context) {
    final recommendedPath = switch (_preferredPath) {
      ExecutionPath.cook => '自己做',
      ExecutionPath.delivery => '叫外卖',
      ExecutionPath.dineIn => '去堂食',
      ExecutionPath.any => '',
    };
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Stack(
        children: [
          const FloatingEditorialBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ExecutionCapsule(
                        label: '开吃方式',
                        background: AppPalette.rice.withValues(alpha: 0.72),
                        foreground: AppColors.textPrimary,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      key: const ValueKey('execution-home-page'),
                      decoration: AppDecorations.card(radius: AppRadii.lg),
                      child: ClipRRect(
                        borderRadius: AppRadii.panel,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              Text(
                                '这道 ${widget.intent.recipe.name}，你想怎么完成？',
                                style: AppType.display.copyWith(
                                  fontSize: 28,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '想动手就看步骤，想省心就找外卖，想出门就看看附近有什么同款。',
                                style: AppType.body.copyWith(
                                  color: AppPalette.ink.withValues(alpha: 0.64),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  if (widget.intent.locationPreference ==
                                      ExecutionLocationPreference.nearby)
                                    ExecutionCapsule(
                                      label: '附近优先',
                                      background: AppPalette.rice
                                          .withValues(alpha: 0.56),
                                      foreground: AppColors.textPrimary,
                                    ),
                                  for (final pairing
                                      in widget.intent.pairings.take(3))
                                    ExecutionCapsule(
                                      label:
                                          '${pairing.category} · ${pairing.title}',
                                      background: AppPalette.rice
                                          .withValues(alpha: 0.5),
                                      foreground: AppColors.textPrimary,
                                    ),
                                ],
                              ),
                              if (widget.intent.sourceTags.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    for (final tag
                                        in widget.intent.sourceTags.take(6))
                                      ExecutionCapsule(
                                        label: tag,
                                        background: AppPalette.rice
                                            .withValues(alpha: 0.42),
                                        foreground: AppColors.textPrimary,
                                      ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 22),
                              SizedBox(
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 124,
                                      child: ExecutionPathCard(
                                        title: '自己做',
                                        subtitle: '看食材、步骤和小技巧，按自己的节奏把这道菜做出来。',
                                        accent: AppPalette.chili,
                                        icon: Icons.soup_kitchen_rounded,
                                        isRecommended: recommendedPath == '自己做',
                                        onTap: () => _openRecipeDetail(context),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        key: const ValueKey(
                                          'execution-open-howtocook-library',
                                        ),
                                        onPressed: () =>
                                            _openHowToCookLibrary(context),
                                        icon: const Icon(
                                          Icons.menu_book_rounded,
                                          size: 18,
                                        ),
                                        label: const Text('看看更多可做菜谱'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 124,
                                child: ExecutionPathCard(
                                  title: '叫外卖',
                                  subtitle: '找附近能送到的同款或相近菜品，少纠结，直接下单。',
                                  accent: AppPalette.herb,
                                  icon: Icons.delivery_dining_rounded,
                                  isRecommended: recommendedPath == '叫外卖',
                                  onTap: () => _openDelivery(context),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 124,
                                child: ExecutionPathCard(
                                  title: '去堂食',
                                  subtitle: '看看附近哪家店做得稳，再按距离、评分和人均来决定。',
                                  accent: AppPalette.grape,
                                  icon: Icons.storefront_rounded,
                                  isRecommended: recommendedPath == '去堂食',
                                  onTap: () => _openDineIn(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveryExecutionPage extends StatefulWidget {
  const DeliveryExecutionPage({
    super.key,
    required this.intent,
    this.snapshot,
  });

  final ExecutionIntent intent;
  final DeliveryExecutionSnapshot? snapshot;

  @override
  State<DeliveryExecutionPage> createState() => _DeliveryExecutionPageState();
}

class _DeliveryExecutionPageState extends State<DeliveryExecutionPage> {
  final V2ExecutionService _service = V2ExecutionService.instance;
  late Future<DeliveryExecutionSnapshot> _future;
  DateTime? _lastRequestedAt;

  @override
  void initState() {
    super.initState();
    _lastRequestedAt = DateTime.now();
    _future = widget.snapshot == null
        ? _service.matchDelivery(intent: widget.intent)
        : Future<DeliveryExecutionSnapshot>.value(widget.snapshot!);
  }

  void _refresh() {
    if (widget.snapshot != null) return;
    setState(() {
      _lastRequestedAt = DateTime.now();
      _future = _service.matchDelivery(intent: widget.intent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ExecutionAsyncScaffold<DeliveryExecutionSnapshot>(
      title: '叫外卖',
      accent: AppPalette.herb,
      future: _future,
      onRefresh: widget.snapshot == null ? _refresh : null,
      builder: (context, snapshot) {
        if (snapshot.status == ExecutionAvailabilityStatus.unavailable) {
          return ExecutionStatusLayout(
            providerStates: snapshot.providerStates,
            diagnostics: ExecutionProxyPanel(
              snapshot: snapshot,
              requestedAt: _lastRequestedAt,
            ),
            child: ExecutionUnavailableState(
              title: '外卖暂时找不到',
              description: snapshot.providerStates
                  .map((state) =>
                      '${state.displayName}：${state.reason ?? '当前不可用'}')
                  .join('\n'),
            ),
          );
        }

        if (snapshot.matches.isEmpty) {
          return ExecutionStatusLayout(
            providerStates: snapshot.providerStates,
            diagnostics: ExecutionProxyPanel(
              snapshot: snapshot,
              requestedAt: _lastRequestedAt,
            ),
            child: const ExecutionUnavailableState(
              title: '暂时没有匹配到外卖候选',
              description: '附近还没有返回合适的同款菜品，可以刷新一次或换个做法。',
            ),
          );
        }

        return ExecutionStatusLayout(
          providerStates: snapshot.providerStates,
          diagnostics: ExecutionProxyPanel(
            snapshot: snapshot,
            requestedAt: _lastRequestedAt,
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  itemBuilder: (context, index) {
                    final match = snapshot.matches[index];
                    return ExecutionResultCard(
                      title: match.merchantName,
                      subtitle:
                          '${match.dishName} · ${match.providerDisplayName}',
                      accent: AppPalette.herb,
                      note: match.note,
                      metadata: [
                        if (match.price != null)
                          '¥${match.price!.amount.toStringAsFixed(0)}',
                        if (match.deliveryTimeMinutes != null)
                          '${match.deliveryTimeMinutes} 分钟送达',
                        if (_usesMeituanOrderingFlow(match))
                          'EatWhat 内选菜'
                        else
                          match.supportsPrefillCart ? '支持快速下单' : '平台内继续选择',
                      ],
                      actionLabel: !_canOpenDeliveryMatch(match)
                          ? '暂不可跳转'
                          : _deliveryActionLabel(match),
                      onTap: !_canOpenDeliveryMatch(match)
                          ? null
                          : () => _openDeliveryMatch(match),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: snapshot.matches.length,
                ),
              ),
              Padding(
                key: const ValueKey('execution-completion-feedback'),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: ExecutionCompletionFeedbackPanel(
                  intent: widget.intent,
                  platform: 'delivery',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openDeliveryMatch(DeliveryMatchResult match) async {
    if (_usesMeituanOrderingFlow(match)) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MeituanOrderPage(
            intent: widget.intent,
            match: match,
          ),
        ),
      );
      return;
    }
    final urls = [match.url, if (match.fallbackUrl != null) match.fallbackUrl!];
    for (final rawUrl in urls) {
      final uri = Uri.tryParse(rawUrl);
      if (uri == null) continue;
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${match.providerDisplayName}暂时无法打开')),
    );
  }

  String _deliveryActionLabel(DeliveryMatchResult match) {
    if (_usesMeituanOrderingFlow(match)) return '选菜并下单';
    final provider = _providerActionName(
      platform: match.platform,
      displayName: match.providerDisplayName,
    );
    if (match.supportsPrefillCart) return '去$provider下单';
    if (match.source == 'deep_link_fallback') return '去$provider搜索';
    return '打开$provider';
  }

  bool _canOpenDeliveryMatch(DeliveryMatchResult match) {
    return _usesMeituanOrderingFlow(match) || match.url.trim().isNotEmpty;
  }

  bool _usesMeituanOrderingFlow(DeliveryMatchResult match) {
    return match.platform == 'meituan' &&
        match.source == 'meituan_open_api' &&
        match.merchantId.trim().isNotEmpty;
  }
}

class DineInExecutionPage extends StatefulWidget {
  const DineInExecutionPage({
    super.key,
    required this.intent,
    this.snapshot,
  });

  final ExecutionIntent intent;
  final DineInExecutionSnapshot? snapshot;

  @override
  State<DineInExecutionPage> createState() => _DineInExecutionPageState();
}

class _DineInExecutionPageState extends State<DineInExecutionPage> {
  final V2ExecutionService _service = V2ExecutionService.instance;
  late Future<DineInExecutionSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.snapshot == null
        ? _service.matchDineIn(intent: widget.intent)
        : Future<DineInExecutionSnapshot>.value(widget.snapshot!);
  }

  @override
  Widget build(BuildContext context) {
    return ExecutionAsyncScaffold<DineInExecutionSnapshot>(
      title: '去堂食',
      accent: AppPalette.grape,
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.status == ExecutionAvailabilityStatus.unavailable) {
          return ExecutionStatusLayout(
            providerStates: snapshot.providerStates,
            child: ExecutionUnavailableState(
              title: '附近店铺暂时找不到',
              description: snapshot.providerStates
                  .map((state) =>
                      '${state.displayName}：${state.reason ?? '当前不可用'}')
                  .join('\n'),
            ),
          );
        }

        if (snapshot.matches.isEmpty) {
          return ExecutionStatusLayout(
            providerStates: snapshot.providerStates,
            child: const ExecutionUnavailableState(
              title: '暂时没有匹配到堂食候选',
              description: '附近还没有返回合适店铺，可以稍后再试或先看看做法。',
            ),
          );
        }

        return ExecutionStatusLayout(
          providerStates: snapshot.providerStates,
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  itemBuilder: (context, index) {
                    final match = snapshot.matches[index];
                    return ExecutionResultCard(
                      title: match.merchantName,
                      subtitle:
                          '${match.matchedDishName} · ${match.providerDisplayName}',
                      accent: AppPalette.grape,
                      note: match.note,
                      metadata: [
                        if (match.rating != null)
                          '评分 ${match.rating!.toStringAsFixed(1)}',
                        if (match.pricePerPerson != null)
                          '¥${match.pricePerPerson!.amount.toStringAsFixed(0)}/人',
                        if (match.distanceMeters != null)
                          '${match.distanceMeters!.toStringAsFixed(0)}m',
                        if (match.supportsMerchantDetail) '支持详情',
                        if (match.supportsReservation) '支持预约',
                        if (match.supportsNavigation) '支持导航',
                      ],
                      actionLabel: match.url.trim().isEmpty
                          ? '暂不可跳转'
                          : _dineInActionLabel(match),
                      onTap: match.url.trim().isEmpty
                          ? null
                          : () => _openExternalLink(match.url),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: snapshot.matches.length,
                ),
              ),
              Padding(
                key: const ValueKey('execution-completion-feedback'),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: ExecutionCompletionFeedbackPanel(
                  intent: widget.intent,
                  platform: 'dine_in',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openExternalLink(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _dineInActionLabel(DineInMatchResult match) {
    final provider = _providerActionName(
      platform: match.platform,
      displayName: match.providerDisplayName,
    );
    return '打开$provider';
  }
}

String _providerActionName({
  required String platform,
  required String displayName,
}) {
  final normalizedDisplayName = displayName.trim();
  if (normalizedDisplayName.isNotEmpty) return normalizedDisplayName;
  return switch (platform.trim().toLowerCase()) {
    'meituan' => '美团外卖',
    'eleme' => '饿了么',
    'dianping' => '大众点评',
    'jd' || 'jd_delivery' => '京东外卖（秒送）',
    'apple_maps' => 'Apple 地图',
    _ => '平台',
  };
}

@visibleForTesting
ExecutionPath executionPathForPlatform(String platform) {
  return execution_completion.executionPathForPlatform(platform);
}
