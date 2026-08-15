import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/v2/core/external/platform/execution_proxy_platform_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';

class JdDeliveryProvider extends ExecutionProxyPlatformProvider {
  JdDeliveryProvider({super.client})
      : super(
          platform: 'jd_delivery',
          displayName: '京东外卖（秒送）',
          deliveryMatchPath: EnvConfig.jdDeliveryMatchPath,
          capabilities: const ProviderCapabilityMatrix(
            supportsDishSearch: true,
            supportsPrefillCart: true,
          ),
        );
}
