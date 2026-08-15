import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/v2/core/external/platform/execution_proxy_platform_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';

class ElemeProvider extends ExecutionProxyPlatformProvider {
  ElemeProvider({super.client})
      : super(
          platform: 'eleme',
          displayName: '饿了么',
          deliveryMatchPath: EnvConfig.elemeDeliveryMatchPath,
          capabilities: const ProviderCapabilityMatrix(
            supportsDishSearch: true,
            supportsPrefillCart: true,
          ),
        );
}
