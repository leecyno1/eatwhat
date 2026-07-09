import 'package:eatwhat_app/v2/core/external/platform/platform_exceptions.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/external/platform/providers/dianping_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/providers/eleme_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/providers/meituan_provider.dart';
import 'package:eatwhat_app/v2/core/services/v2_execution_fallback_link_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_location_service.dart';

class V2ExecutionService {
  V2ExecutionService({
    List<PlatformProvider>? providers,
    Future<GeoPoint> Function()? locationResolver,
    V2ExecutionFallbackLinkService? fallbackLinkService,
  })  : _providers = providers ??
            [
              DianpingProvider(),
              MeituanProvider(),
              ElemeProvider(),
            ],
        _locationResolver = locationResolver ??
            V2LocationService.instance.getCurrentLocationOrFallback,
        _fallbackLinkService =
            fallbackLinkService ?? const V2ExecutionFallbackLinkService();

  static final V2ExecutionService instance = V2ExecutionService();

  final List<PlatformProvider> _providers;
  final Future<GeoPoint> Function() _locationResolver;
  final V2ExecutionFallbackLinkService _fallbackLinkService;

  List<PlatformProvider> get providers => List.unmodifiable(_providers);

  Future<List<ProviderAvailability>> getProviderSnapshot() async {
    return _providers.map(_buildAvailability).toList();
  }

  ProviderAvailability _buildAvailability(PlatformProvider provider) {
    if (!provider.isConfigured) {
      return ProviderAvailability(
        platform: provider.platform,
        displayName: provider.displayName,
        capabilities: provider.capabilities,
        isConfigured: false,
        reason: '未配置执行层代理服务或平台凭据',
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

  Future<DeliveryExecutionSnapshot> matchDelivery({
    required ExecutionIntent intent,
    int limit = 10,
  }) async {
    final providerStates = await getProviderSnapshot();
    final providerStateMap = {
      for (final state in providerStates) state.platform: state,
    };
    final availableProviders = _providers.where((provider) {
      return provider.isConfigured && provider.capabilities.supportsDishSearch;
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
    for (final provider in availableProviders) {
      try {
        matches.addAll(
          await provider.searchDishCandidates(
            intent: intent,
            location: location,
            limit: limit,
          ),
        );
      } on PlatformApiException catch (error) {
        hasProviderError = true;
        providerStateMap[provider.platform] = ProviderAvailability(
          platform: provider.platform,
          displayName: provider.displayName,
          capabilities: provider.capabilities,
          isConfigured: provider.isConfigured,
          reason: error.message,
        );
      } on PlatformApiNotConfiguredException catch (error) {
        hasProviderError = true;
        providerStateMap[provider.platform] = ProviderAvailability(
          platform: provider.platform,
          displayName: provider.displayName,
          capabilities: provider.capabilities,
          isConfigured: false,
          reason: error.message,
        );
      } catch (_) {
        hasProviderError = true;
        providerStateMap[provider.platform] = ProviderAvailability(
          platform: provider.platform,
          displayName: provider.displayName,
          capabilities: provider.capabilities,
          isConfigured: provider.isConfigured,
          reason: '代理服务暂时不可用',
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

    return DeliveryExecutionSnapshot(
      status: ExecutionAvailabilityStatus.available,
      providerStates: providerStateMap.values.toList(),
      matches: matches,
    );
  }

  Future<DineInExecutionSnapshot> matchDineIn({
    required ExecutionIntent intent,
    int limit = 10,
  }) async {
    final providerStates = await getProviderSnapshot();
    final availableProviders = _providers.where((provider) {
      return provider.isConfigured &&
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
