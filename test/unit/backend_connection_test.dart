import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

/// 验证 app 端的后端地址配置指向 179 服务器，且认证/代理 URL 拼接正确。
void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '''
EATWHAT_AUTH_BASE_URL=http://154.194.253.179
EXECUTION_PROXY_BASE_URL=http://154.194.253.179/eatwhat
''');
  });

  test('认证与代理地址指向 179 服务器', () {
    expect(EnvConfig.eatWhatAuthBaseUrl, 'http://154.194.253.179');
    expect(
      EnvConfig.executionProxyBaseUrl,
      'http://154.194.253.179/eatwhat',
    );
  });

  test('认证端点 URL 拼接正确（去尾斜杠）', () {
    final base = EnvConfig.eatWhatAuthBaseUrl;
    final register = '${base.replaceAll(RegExp(r'/+\$'), '')}/api/v1/auth/register';
    expect(register, 'http://154.194.253.179/api/v1/auth/register');
  });
}
