import 'package:eatwhat_app/v2/core/external/platform/execution_proxy_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_exceptions.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/external/platform/providers/dianping_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/providers/eleme_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/providers/jd_delivery_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/providers/meituan_provider.dart';
import 'package:eatwhat_app/v2/core/services/v2_execution_fallback_link_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_location_service.dart';

class V2ExecutionService {
  V2ExecutionService({
    List<PlatformProvider>? providers,
    Future<GeoPoint> Function()? locationResolver,
    Future<Map<String, bool>?> Function()? providerHealthResolver,
    V2ExecutionFallbackLinkService? fallbackLinkService,
  })  : _providers = providers ??
            [
              MeituanProvider(),
              ElemeProvider(),
              JdDeliveryProvider(),
              DianpingProvider(),
            ],
        _locationResolver = locationResolver ??
            V2LocationService.instance.getCurrentLocationOrFallback,
        _providerHealthResolver =
            providerHealthResolver ?? _loadProxyProviderHealth,
        _fallbackLinkService =
            fallbackLinkService ?? const V2ExecutionFallbackLinkService();

  static final V2ExecutionService instance = V2ExecutionService();

  final List<PlatformProvider> _providers;
  final Future<GeoPoint> Function() _locationResolver;
  final Future<Map<String, bool>?> Function() _providerHealthResolver;
  final V2ExecutionFallbackLinkService _fallbackLinkService;

  List<PlatformProvider> get providers => List.unmodifiable(_providers);

  Future<List<ProviderAvailability>> getProviderSnapshot({
    ExecutionPath path = ExecutionPath.delivery,
  }) async {
    final remoteHealth = await _providerHealthResolver();
    return _providers
        .map(
          (provider) => _buildAvailability(
            provider,
            remoteConfigured: remoteHealth?[_healthKey(provider, path)],
          ),
        )
        .toList();
  }

  ProviderAvailability _buildAvailability(
    PlatformProvider provider, {
    bool? remoteConfigured,
  }) {
    if (!provider.isConfigured) {
      return ProviderAvailability(
        platform: provider.platform,
        displayName: provider.displayName,
        capabilities: provider.capabilities,
        isConfigured: false,
        reason: '未配置执行层代理服务或平台凭据',
      );
    }

    if (remoteConfigured == false) {
      return ProviderAvailability(
        platform: provider.platform,
        displayName: provider.displayName,
        capabilities: provider.capabilities,
        isConfigured: false,
        reason: '${provider.displayName}生产适配器未配置',
      );
    }

    if (!provider.capabilities.hasAnyCapability) {
      return ProviderAvailability(
        platform: provider.platform,
        displayName: provider.displayName,
        capabilities: provider.capabilities,
        reason: '已配置基础凭据，但菜品级检索/预填购物车/商家详情能力尚未接入',
      );
    }

    return ProviderAvailability(
      platform: provider.platform,
      displayName: provider.displayName,
      capabilities: provider.capabilities,
    );
  }

  String _healthKey(PlatformProvider provider, ExecutionPath path) {
    if (provider.platform == 'dianping' && path == ExecutionPath.dineIn) {
      return 'dianping_dine_in';
    }
    return provider.platform;
  }

  static Future<Map<String, bool>?> _loadProxyProviderHealth() async {
    final client = ExecutionProxyClient();
    if (!client.isConfigured) return null;
    try {
      return await client.getProviderHealth();
    } catch (_) {
      return null;
    }
  }

  Future<DeliveryExecutionSnapshot> matchDelivery({
    required ExecutionIntent intent,
    int limit = 10,
  }) async {
    final providerStates = await getProviderSnapshot();
    final providerStateMap = {
      for (final state in providerStates) state.platform: state,
    };
    final availableProviders = _providers.where((provider) {
      return providerStateMap[provider.platform]?.isConfigured == true &&
          provider.capabilities.supportsDishSearch;
    }).toList();

    if (availableProviders.isEmpty) {
      return DeliveryExecutionSnapshot(
        status: ExecutionAvailabilityStatus.partial,
        providerStates: providerStates,
        matches: _fallbackLinkService.buildDeliveryFallbacks(intent: intent),
        message: '当前没有可用的外卖商品检索能力，已提供平台搜索入口',
      );
    }

    final location = await _locationResolver();
    final matches = <DeliveryMatchResult>[];
    var hasProviderError = false;
    final attempts = await Future.wait(
      availableProviders.map(
        (provider) => _loadDeliveryMatches(
          provider: provider,
          intent: intent,
          location: location,
          limit: limit,
        ),
      ),
    );
    for (final attempt in attempts) {
      matches.addAll(attempt.matches);
      if (attempt.reason != null) {
        hasProviderError = true;
        final provider = attempt.provider;
        providerStateMap[provider.platform] = ProviderAvailability(
          platform: provider.platform,
          displayName: provider.displayName,
          capabilities: provider.capabilities,
          isConfigured: attempt.isConfigured,
          reason: attempt.reason,
        );
      }
    }

    if (matches.isEmpty) {
      final fallbackMatches =
          _fallbackLinkService.buildDeliveryFallbacks(intent: intent);
      return DeliveryExecutionSnapshot(
        status: ExecutionAvailabilityStatus.partial,
        providerStates: providerStateMap.values.toList(),
        matches: fallbackMatches,
        message: hasProviderError ? '外卖代理调用失败，已提供搜索入口' : '未找到可展示的外卖候选，已提供搜索入口',
      );
    }

    matches.sort(_compareDeliveryMatches);
    return DeliveryExecutionSnapshot(
      status: ExecutionAvailabilityStatus.available,
      providerStates: providerStateMap.values.toList(),
      matches: matches.take(limit).toList(),
    );
  }

  Future<_DeliveryProviderAttempt> _loadDeliveryMatches({
    required PlatformProvider provider,
    required ExecutionIntent intent,
    required GeoPoint location,
    required int limit,
  }) async {
    try {
      return _DeliveryProviderAttempt(
        provider: provider,
        matches: await provider.searchDishCandidates(
          intent: intent,
          location: location,
          limit: limit,
        ),
        isConfigured: provider.isConfigured,
      );
    } on PlatformApiNotConfiguredException catch (error) {
      return _DeliveryProviderAttempt(
        provider: provider,
        isConfigured: false,
        reason: error.message,
      );
    } on PlatformApiException catch (error) {
      return _DeliveryProviderAttempt(
        provider: provider,
        isConfigured: provider.isConfigured,
        reason: error.message,
      );
    } catch (_) {
      return _DeliveryProviderAttempt(
        provider: provider,
        isConfigured: provider.isConfigured,
        reason: '代理服务暂时不可用',
      );
    }
  }

  int _compareDeliveryMatches(
    DeliveryMatchResult left,
    DeliveryMatchResult right,
  ) {
    if (left.supportsPrefillCart != right.supportsPrefillCart) {
      return left.supportsPrefillCart ? -1 : 1;
    }
    final deliveryComparison = (left.deliveryTimeMinutes ?? 999)
        .compareTo(right.deliveryTimeMinutes ?? 999);
    if (deliveryComparison != 0) return deliveryComparison;
    return (left.price?.amount ?? double.infinity)
        .compareTo(right.price?.amount ?? double.infinity);
  }

  Future<DineInExecutionSnapshot> matchDineIn({
    required ExecutionIntent intent,
    int limit = 10,
  }) async {
    final providerStates = await getProviderSnapshot(
      path: ExecutionPath.dineIn,
    );
    final providerStateMap = {
      for (final state in providerStates) state.platform: state,
    };
    final availableProviders = _providers.where((provider) {
      return providerStateMap[provider.platform]?.isConfigured == true &&
          provider.capabilities.supportsMerchantSearch;
    }).toList();

    final location = await _locationResolver();

    if (availableProviders.isEmpty) {
      return DineInExecutionSnapshot(
        status: ExecutionAvailabilityStatus.partial,
        providerStates: providerStates,
        matches: _fallbackLinkService.buildDineInFallbacks(
          intent: intent,
          location: location,
        ),
      );
    }

    final matches = <DineInMatchResult>[];
    for (final provider in availableProviders) {
      try {
        matches.addAll(
          await provider.searchMerchantCandidates(
            intent: intent,
            location: location,
            limit: limit,
          ),
        );
      } catch (_) {
        // 显式能力状态已由 providerStates 呈现，这里不再 silently fallback。
      }
    }

    return DineInExecutionSnapshot(
      status: matches.isEmpty
          ? ExecutionAvailabilityStatus.partial
          : ExecutionAvailabilityStatus.available,
      providerStates: providerStates,
      matches: matches.isEmpty
          ? _fallbackLinkService.buildDineInFallbacks(
              intent: intent,
              location: location,
            )
          : matches,
    );
  }
}

class _DeliveryProviderAttempt {
  const _DeliveryProviderAttempt({
    required this.provider,
    required this.isConfigured,
    this.matches = const [],
    this.reason,
  });

  final PlatformProvider provider;
  final bool isConfigured;
  final List<DeliveryMatchResult> matches;
  final String? reason;
}
