import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/v2/core/external/platform/execution_proxy_platform_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';

class DianpingProvider extends ExecutionProxyPlatformProvider {
  DianpingProvider({super.client})
      : super(
          platform: 'dianping',
          displayName: '大众点评',
          deliveryMatchPath: EnvConfig.dianpingDeliveryMatchPath,
          dineInMatchPath: EnvConfig.dianpingDineInMatchPath,
          capabilities: const ProviderCapabilityMatrix(
            supportsDishSearch: true,
            supportsMerchantSearch: true,
            supportsPrefillCart: true,
            supportsMerchantDetail: true,
            supportsReservation: true,
            supportsNavigation: true,
          ),
        );
}
