import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnvConfig.validateConfig', () {
    tearDown(dotenv.clean);

    test('配置 MINIMAX_API_KEY 后通过', () async {
      dotenv.testLoad(fileInput: 'MINIMAX_API_KEY=sk-test-minimax-key');

      expect(EnvConfig.validateConfig(), isTrue);
    });

    test('缺少 MINIMAX_API_KEY 时不通过', () async {
      dotenv.testLoad(fileInput: 'UNRELATED_VAR=1');

      expect(EnvConfig.validateConfig(), isFalse);
    });

    test('已弃用的 SiliconFlow key 不再满足必需校验', () async {
      dotenv.testLoad(fileInput: '''
SILICONFLOW_API_KEY=sk-legacy-siliconflow
SILICONFLOW_API_URL=https://api.siliconflow.cn/v1
''');

      expect(EnvConfig.validateConfig(), isFalse);
    });
  });

  group('EnvConfig.validateApiKeySecurity', () {
    tearDown(dotenv.clean);

    test('校验 MiniMax key 而非 SiliconFlow key', () async {
      dotenv.testLoad(fileInput: 'MINIMAX_API_KEY=sk-valid-minimax-key-123456');

      expect(EnvConfig.validateApiKeySecurity(), isTrue);
    });

    test('占位符 key 不通过', () async {
      dotenv.testLoad(fileInput: 'MINIMAX_API_KEY=your_api_key_here');

      expect(EnvConfig.validateApiKeySecurity(), isFalse);
    });

    test('空 key 不通过', () async {
      dotenv.testLoad(fileInput: 'UNRELATED_VAR=1');

      expect(EnvConfig.validateApiKeySecurity(), isFalse);
    });
  });
}
