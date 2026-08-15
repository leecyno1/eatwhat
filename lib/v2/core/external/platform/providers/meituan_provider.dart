import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/v2/core/external/platform/execution_proxy_platform_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';

class MeituanProvider extends ExecutionProxyPlatformProvider {
  MeituanProvider({super.client})
      : super(
          platform: 'meituan',
          displayName: '美团外卖',
          deliveryMatchPath: EnvConfig.meituanDeliveryMatchPath,
          capabilities: const ProviderCapabilityMatrix(
            supportsDishSearch: true,
            supportsMerchantSearch: true,
          ),
        );
}
