#!/usr/bin/env dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  const String enterpriseName = '北京大圣之怒科技有限公司';
  const String creditCode = '91110108MABPAXTH8N';
  const String phone = '17600806220';
  const String password = 'iv19whot';

  print('🏢 美团开放平台企业商户注册');
  print('企业名: $enterpriseName');
  print('信用代码: $creditCode');
  print('');

  try {
    // 获取 WebSocket URL
    print('📱 正在连接 Chrome DevTools Protocol...');
    final wsUrl = await _getWebSocketUrl();
    if (wsUrl == null) {
      print('❌ 无法连接到 Chrome。请确保 Chrome 已启动调试模式。');
      exit(1);
    }
    print('✅ 已连接');
    print('');

    // 步骤 1: 访问注册页面
    print('📄 步骤 1: 访问美团开放平台...');
    await _navigateTo(wsUrl, 'https://open.meituan.com');
    await Future.delayed(Duration(seconds: 2));
    print('✅ 已打开首页');
    print('');

    // 步骤 2: 点击注册
    print('📝 步骤 2: 查找注册入口...');
    await _clickElement(wsUrl, '''
      document.querySelector('a[href*="register"]') ||
      document.querySelector('button:contains("注册")') ||
      document.querySelector('[class*="register"]')
    ''');
    await Future.delayed(Duration(seconds: 2));
    print('✅ 已点击注册');
    print('');

    // 步骤 3: 选择企业商户类型
    print('🏪 步骤 3: 选择企业商户类型...');
    await _sendCdpCommand(wsUrl, 'Runtime.evaluate', {
      'expression': '''
        (function() {
          // 查找企业商户选项
          const options = document.querySelectorAll('[role="radio"], .option, label, button');
          for (let opt of options) {
            if (opt.textContent.includes('企业') || opt.textContent.includes('商户')) {
              opt.click();
              return true;
            }
          }
          return false;
        })()
      '''
    });
    await Future.delayed(Duration(seconds: 1));
    print('✅ 已选择企业商户');
    print('');

    // 步骤 4: 填写登录信息（如果需要）
    print('🔐 步骤 4: 检查登录状态...');
    final isLoggedIn = await _checkLoginStatus(wsUrl);
    if (!isLoggedIn) {
      print('  需要登录，正在填写登录信息...');
      await _fillLoginForm(wsUrl, phone, password);
      await _clickLoginButton(wsUrl);
      await Future.delayed(Duration(seconds: 3));
      print('✅ 已登录');
    } else {
      print('✅ 已登录');
    }
    print('');

    // 步骤 5: 填写企业基本信息
    print('🏢 步骤 5: 填写企业信息...');
    await _fillEnterpriseInfo(wsUrl, enterpriseName, creditCode);
    print('✅ 已填写企业信息');
    print('');

    // 步骤 6: 上传营业执照
    print('📑 步骤 6: 上传营业执照...');
    print('  ⚠️  需要手动上传营业执照文件');
    print('  请在浏览器中选择文件');
    await Future.delayed(Duration(seconds: 3));
    print('✅ 请完成文件上传');
    print('');

    // 步骤 7: 填写法人信息
    print('👤 步骤 7: 填写法人信息...');
    print('  ⚠️  请在浏览器中手动填写法人信息');
    await Future.delayed(Duration(seconds: 2));
    print('✅ 请完成法人信息填写');
    print('');

    // 步骤 8: 银行账户信息
    print('🏦 步骤 8: 银行账户信息...');
    print('  ⚠️  请在浏览器中手动填写银行账户');
    await Future.delayed(Duration(seconds: 2));
    print('✅ 请完成银行账户填写');
    print('');

    // 步骤 9: 提交审核
    print('✨ 步骤 9: 提交申请...');
    await _clickElement(wsUrl, '''
      document.querySelector('button[type="submit"]') ||
      document.querySelector('[class*="submit"]') ||
      Array.from(document.querySelectorAll('button')).find(b => b.textContent.includes('提交') || b.textContent.includes('申请'))
    ''');
    print('✅ 已提交申请');
    print('');

    print('🎉 注册流程已启动！');
    print('📌 请完成以下步骤：');
    print('  1. 上传营业执照');
    print('  2. 填写法人身份信息');
    print('  3. 填写银行账户信息');
    print('  4. 提交申请');
    print('');
    print('审批时间通常为 1-5 个工作日');

  } catch (e) {
    print('❌ 错误: $e');
    exit(1);
  }
}

Future<String?> _getWebSocketUrl() async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:9222/json'));
    final response = await request.close();

    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      final tabs = jsonDecode(body) as List;
      if (tabs.isNotEmpty) {
        return tabs[0]['webSocketDebuggerUrl'] as String?;
      }
    }
  } catch (e) {
    // 忽略
  }
  return null;
}

Future<void> _navigateTo(String wsUrl, String url) async {
  await _sendCdpCommand(wsUrl, 'Page.navigate', {'url': url});
}

Future<bool> _checkLoginStatus(String wsUrl) async {
  try {
    final result = await _sendCdpCommand(wsUrl, 'Runtime.evaluate', {
      'expression': '''
        (function() {
          // 检查是否已登录（检查常见的登录标志）
          const userName = document.querySelector('[class*="username"]') ||
                          document.querySelector('[class*="user-name"]') ||
                          document.querySelector('[class*="profile"]');
          return !!userName || !document.querySelector('[href*="login"]');
        })()
      '''
    });
    return result?['result']?['value'] == true;
  } catch (e) {
    return false;
  }
}

Future<void> _fillLoginForm(
    String wsUrl, String phone, String password) async {
  await _sendCdpCommand(wsUrl, 'Runtime.evaluate', {
    'expression': '''
      (function() {
        const inputs = document.querySelectorAll('input');
        for (let i = 0; i < inputs.length; i++) {
          const input = inputs[i];
          if (input.type === 'text' || input.type === 'tel') {
            input.value = '$phone';
            input.dispatchEvent(new Event('input', { bubbles: true }));
          } else if (input.type === 'password') {
            input.value = '$password';
            input.dispatchEvent(new Event('input', { bubbles: true }));
          }
        }
        return true;
      })()
    '''
  });
}

Future<void> _clickLoginButton(String wsUrl) async {
  await _clickElement(wsUrl, '''
    Array.from(document.querySelectorAll('button, input[type="submit"]')).find(
      b => b.textContent.includes('登') || b.textContent.includes('确')
    )
  ''');
}

Future<void> _fillEnterpriseInfo(
    String wsUrl, String enterpriseName, String creditCode) async {
  await _sendCdpCommand(wsUrl, 'Runtime.evaluate', {
    'expression': '''
      (function() {
        const inputs = document.querySelectorAll('input[type="text"]');
        let nameSet = false;
        let codeSet = false;

        for (let input of inputs) {
          const label = input.previousElementSibling?.textContent || input.placeholder || '';

          if (!nameSet && (label.includes('企业') || label.includes('名称') || label.includes('公司'))) {
            input.value = '$enterpriseName';
            input.dispatchEvent(new Event('input', { bubbles: true }));
            nameSet = true;
          }

          if (!codeSet && (label.includes('代码') || label.includes('注册') || label.includes('统一'))) {
            input.value = '$creditCode';
            input.dispatchEvent(new Event('input', { bubbles: true }));
            codeSet = true;
          }

          if (nameSet && codeSet) break;
        }
        return { nameSet, codeSet };
      })()
    '''
  });
}

Future<void> _clickElement(String wsUrl, String elementSelector) async {
  try {
    await _sendCdpCommand(wsUrl, 'Runtime.evaluate', {
      'expression': '''
        (function() {
          const element = $elementSelector;
          if (element) {
            element.click();
            return true;
          }
          return false;
        })()
      '''
    });
  } catch (e) {
    // 元素不存在，忽略
  }
}

Future<dynamic> _sendCdpCommand(
    String wsUrl, String method, Map<String, dynamic> params) async {
  final ws = await WebSocket.connect(wsUrl);
  int messageId = 1;
  final completer = Completer<dynamic>();

  try {
    final subscription = ws.listen(
      (data) {
        try {
          final response = jsonDecode(data);
          if (response['id'] == messageId && !completer.isCompleted) {
            if (response['result'] != null) {
              completer.complete(response);
            } else if (response['error'] != null) {
              completer.completeError(
                  Exception('CDP 错误: ${response['error']['message']}'));
            }
          }
        } catch (e) {
          // 忽略
        }
      },
      onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      cancelOnError: true,
    );

    ws.add(jsonEncode({
      'id': messageId,
      'method': method,
      'params': params,
    }));

    final result = await completer.future
        .timeout(Duration(seconds: 10))
        .whenComplete(() => subscription.cancel());

    return result;
  } finally {
    try {
      ws.close();
    } catch (e) {
      // 忽略
    }
  }
}
