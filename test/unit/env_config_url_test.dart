import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('backendUrlIssue', () {
    test('空值、相对路径与非法协议均判为不可用', () {
      expect(EnvConfig.backendUrlIssue(''), isNotNull);
      expect(EnvConfig.backendUrlIssue('   '), isNotNull);
      expect(EnvConfig.backendUrlIssue('api.eatwhat.app'), isNotNull);
      expect(EnvConfig.backendUrlIssue('/api/v1'), isNotNull);
      expect(EnvConfig.backendUrlIssue('ftp://api.eatwhat.app'), isNotNull);
    });

    test('默认（开发）构建允许本地 HTTP', () {
      expect(
        EnvConfig.backendUrlIssue('http://127.0.0.1:8787'),
        isNull,
      );
      expect(
        EnvConfig.backendUrlIssue('http://154.194.253.179/eatwhat'),
        isNull,
      );
    });

    test('发布语义拒绝 HTTP，HTTPS 通过', () {
      expect(
        EnvConfig.backendUrlIssue(
          'http://api.eatwhat.app',
          requireHttps: true,
        ),
        contains('HTTPS'),
      );
      expect(
        EnvConfig.backendUrlIssue(
          'https://api.eatwhat.app',
          requireHttps: true,
        ),
        isNull,
      );
      expect(
        EnvConfig.backendUrlIssue(
          'https://api.eatwhat.app/eatwhat/',
          requireHttps: true,
        ),
        isNull,
      );
    });
  });

  group('executionProxyConfigIssue', () {
    tearDown(dotenv.clean);

    test('未配置不算错误，但不可用', () {
      dotenv.testLoad();

      expect(EnvConfig.executionProxyConfigIssue, isNull);
      expect(EnvConfig.hasUsableExecutionProxy, isFalse);
    });

    test('开发构建下本地 HTTP 代理可用', () {
      dotenv.testLoad(
        fileInput: 'EXECUTION_PROXY_BASE_URL=http://127.0.0.1:8787',
      );

      expect(EnvConfig.executionProxyConfigIssue, isNull);
      expect(EnvConfig.hasUsableExecutionProxy, isTrue);
    });

    test('协议非法时标记配置问题', () {
      dotenv.testLoad(
        fileInput: 'EXECUTION_PROXY_BASE_URL=ftp://api.eatwhat.app',
      );

      expect(EnvConfig.executionProxyConfigIssue, isNotNull);
      expect(EnvConfig.hasUsableExecutionProxy, isFalse);
    });
  });

  group('releaseConfigIssues', () {
    tearDown(dotenv.clean);

    test('开发构建不产生发布配置问题', () {
      dotenv.testLoad(
        fileInput: 'EXECUTION_PROXY_BASE_URL=http://api.eatwhat.app',
      );

      expect(EnvConfig.releaseConfigIssues(), isEmpty);
    });

    test('标记明文后端与发布包内的密钥，但不回显密钥值', () {
      dotenv.testLoad(fileInput: '''
EXECUTION_PROXY_BASE_URL=http://api.eatwhat.app
EATWHAT_AUTH_BASE_URL=http://api.eatwhat.app
MEMBERSHIP_SIGNING_SEED=super-secret-seed
MINIMAX_API_KEY=super-secret-key
''');

      final issues = EnvConfig.releaseConfigIssues(isRelease: true);

      expect(issues, hasLength(4));
      expect(issues.join('\n'), contains('HTTPS'));
      expect(issues.join('\n'), contains('MEMBERSHIP_SIGNING_SEED'));
      expect(issues.join('\n'), contains('MINIMAX_API_KEY'));
      expect(issues.join('\n'), isNot(contains('super-secret')));
    });
  });
}
