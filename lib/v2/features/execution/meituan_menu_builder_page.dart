import 'package:eatwhat_app/v2/core/external/platform/meituan_delivery_order_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_exceptions.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/services/v2_location_service.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/auth/auth_sheet.dart';
import 'package:eatwhat_app/v2/features/execution/meituan_order_page.dart';
import 'package:eatwhat_app/v2/features/execution/widgets/execution_widgets.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MeituanMenuBuilderPage extends StatefulWidget {
  const MeituanMenuBuilderPage({
    super.key,
    required this.intent,
    this.client,
    this.locationResolver,
    this.paymentLauncher,
  });

  final ExecutionIntent intent;
  final MeituanDeliveryOrderClient? client;
  final Future<GeoPoint> Function()? locationResolver;
  final MeituanPaymentLauncher? paymentLauncher;

  @override
  State<MeituanMenuBuilderPage> createState() => _MeituanMenuBuilderPageState();
}

class _MeituanMenuBuilderPageState extends State<MeituanMenuBuilderPage> {
  late final MeituanDeliveryOrderClient _client;
  late Future<MeituanMerchantSearchResult> _future;
  GeoPoint? _location;

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? MeituanDeliveryOrderClient();
    _future = _search();
  }

  Future<MeituanMerchantSearchResult> _search() async {
    final location = await (widget.locationResolver ??
        V2LocationService.instance.getCurrentLocationOrFallback)();
    _location = location;
    return _client.searchMerchantResults(
      keyword: widget.intent.recipe.name,
      location: location,
    );
  }

  Future<void> _authorizeMeituanService() async {
    try {
      final authorizationUri = await _client.createOAuthAuthorizationUri();
      final launched = await launchUrl(
        authorizationUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('暂时无法打开美团服务授权页')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFrom(error))),
      );
    }
  }

  String _messageFrom(Object error) {
    if (error is PlatformApiException) {
      return error.message;
    }
    return error.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), '').trim();
  }

  void _refresh() {
    setState(() => _future = _search());
  }

  Widget _oauthRequiredState() {
    return ExecutionUnavailableState(
      title: '首次点单需要绑定美团配送服务',
      description: '你仍然使用“吃什么”账号。这里只做一次美团交易授权，之后由吃什么后端保存并自动续期，不需要重复登录或重新注册。',
      actionLabel: '一次授权，继续点单',
      onAction: _authorizeMeituanService,
    );
  }

  Widget _eatWhatLoginRequiredState() {
    return ExecutionUnavailableState(
      title: '先登录吃什么，再继续点单',
      description: '下单账号属于“吃什么”。登录后，服务端才能为你的账号安全保存美团交易授权和订单信息。',
      actionLabel: '登录吃什么',
      onAction: () async {
        // In-place auth sheet instead of a full-page route jump, so signing
        // in resumes the merchant search right where the user left off.
        final signedIn = await showEatWhatAuthSheet(
          context,
          reason: '登录后才能使用美团下单',
        );
        if (signedIn && mounted) {
          _refresh();
        }
      },
    );
  }

  Future<void> _openMerchant(MeituanDeliveryMerchant merchant) async {
    final location = _location;
    if (location == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MeituanOrderPage(
          intent: widget.intent,
          match: DeliveryMatchResult(
            platform: 'meituan',
            providerDisplayName: '美团外卖',
            merchantId: merchant.merchantId,
            merchantName: merchant.merchantName,
            dishName: widget.intent.recipe.name,
            url: '',
            source: 'meituan_open_api',
            price: merchant.minimumPrice == null
                ? null
                : Money(amount: merchant.minimumPrice!),
            deliveryTimeMinutes: merchant.deliveryTimeMinutes,
          ),
          client: _client,
          locationResolver: () async => location,
          paymentLauncher: widget.paymentLauncher,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Defense in depth: entry points already degrade when the proxy is
    // missing, but any path that lands here anyway gets a clear state page
    // instead of a raw network error from the search future.
    if (!_client.isConfigured) {
      return ExecutionUnavailableState(
        title: '外卖服务暂未接入',
        description: '美团点餐正在联调中。可以先收藏这道菜，或看看怎么做。',
      );
    }
    return ExecutionAsyncScaffold<MeituanMerchantSearchResult>(
      title: '生成外卖菜单',
      accent: AppPalette.chili,
      future: _future,
      onRefresh: _refresh,
      builder: (context, result) {
        if (result.merchants.isEmpty) {
          return const ExecutionUnavailableState(
            title: '美团暂未返回可点餐门店',
            description: '这里不会跳网页。请确认消费者点餐 API、OAuth 和门店搜索权限已经开通。',
          );
        }
        return ListView(
          key: const ValueKey('meituan-merchant-menu'),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: AppDecorations.card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('匹配到的门店', style: AppType.microLabel),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${widget.intent.recipe.name} · ${result.merchants.length} 家可选',
                    style: AppType.title,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '选择门店后，继续读取真实菜品、规格、价格和库存。',
                    style: AppType.body.copyWith(color: AppPalette.inkSoft),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            for (final merchant in result.merchants) ...[
              _MerchantCard(
                merchant: merchant,
                onTap: () => _openMerchant(merchant),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
      errorBuilder: (context, error) {
        if (error is PlatformApiException &&
            error.code == 'meituan_oauth_required') {
          return _oauthRequiredState();
        }
        if (error is PlatformApiException &&
            (error.code == 'eatwhat_user_required' ||
                error.code == 'unauthorized')) {
          return _eatWhatLoginRequiredState();
        }
        final message = _messageFrom(error);
        return ExecutionUnavailableState(
          title: error is PlatformApiException &&
                  error.code == 'meituan_permission_denied'
              ? '吃什么的美团接口仍在审核中'
              : '暂时无法读取美团门店',
          description: message,
          actionLabel: '重试',
          onAction: _refresh,
        );
      },
    );
  }
}

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({required this.merchant, required this.onTap});

  final MeituanDeliveryMerchant merchant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(merchant.merchantName, style: AppType.section),
              ),
              if (merchant.rating != null)
                Text(
                  '评分 ${merchant.rating!.toStringAsFixed(1)}',
                  style: AppType.label.copyWith(color: AppPalette.inkSoft),
                ),
            ],
          ),
          if (merchant.address.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              merchant.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppType.body.copyWith(
                color: AppPalette.ink.withValues(alpha: 0.58),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (merchant.deliveryTimeMinutes != null)
                _MerchantMeta('${merchant.deliveryTimeMinutes} 分钟'),
              if (merchant.minimumPrice != null)
                _MerchantMeta(
                    '¥${merchant.minimumPrice!.toStringAsFixed(0)} 起送'),
              if (merchant.shippingFee != null)
                _MerchantMeta(
                    '配送 ¥${merchant.shippingFee!.toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: ValueKey('meituan-merchant-${merchant.merchantId}'),
              onPressed: onTap,
              icon: const Icon(Icons.restaurant_menu_rounded),
              label: const Text('选择门店并生成菜单'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantMeta extends StatelessWidget {
  const _MerchantMeta(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: AppRadii.capsule,
        color: AppPalette.surfaceMuted,
      ),
      child: Text(label, style: AppType.microLabel),
    );
  }
}
