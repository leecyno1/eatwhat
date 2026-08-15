#!/usr/bin/env dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    print('用法: dart bin/meituan_login_standalone.dart <手机号> <密码>');
    print('例如: dart bin/meituan_login_standalone.dart 17600806220 password123');
    exit(1);
  }

  final phone = args[0];
  final password = args[1];

  print('🔐 美团开放平台自动登录');
  print('手机号: $phone');
  print('密码: ' + ('*' * password.length));
  print('');

  try {
    // 获取 WebSocket URL
    print('📱 正在连接 Chrome DevTools Protocol...');
    final wsUrl = await _getWebSocketUrl();
    if (wsUrl == null) {
      print('❌ 无法连接到 Chrome。请确保 Chrome 已启动调试模式：');
      print('   open -a "Google Chrome" --args --remote-debugging-port=9222');
      exit(1);
    }
    print('✅ 已连接到 Chrome');
    print('');

    // 获取第一个标签页
    print('📄 获取标签页...');
    final pageId = await _getFirstTabId();
    print('✅ 标签页 ID: $pageId');
    print('');

    // 导航到美团开放平台
    print('🌐 导航到美团开放平台...');
    final url = 'https://open.meituan.com/user/login';
    await _navigateTo(wsUrl, url);
    print('✅ 已打开: $url');
    await Future.delayed(Duration(seconds: 3));
    print('');

    // 查找并填写登录表单
    print('🔍 查找和填写登录表单...');
    await _fillAndSubmitLoginForm(wsUrl, phone, password);
    print('✅ 已提交登录');
    print('');

    // 等待登录完成
    print('⏳ 等待登录完成...');
    await Future.delayed(Duration(seconds: 5));

    // 检查页面状态
    print('📊 检查登录状态...');
    final currentUrl = await _getCurrentUrl(wsUrl);
    print('✅ 当前页面: $currentUrl');
    print('');

    print('✨ 登录脚本执行完成！');
    print('📌 请在浏览器中完成任何需要的验证步骤。');

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
    // 连接失败
  }
  return null;
}

Future<String> _getFirstTabId() async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:9222/json'));
    final response = await request.close();

    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      final tabs = jsonDecode(body) as List;
      if (tabs.isNotEmpty) {
        return tabs[0]['id'] as String;
      }
    }
  } catch (e) {
    // 忽略
  }
  throw Exception('无法获取标签页');
}

Future<void> _navigateTo(String wsUrl, String url) async {
  await _sendCdpCommand(wsUrl, 'Page.navigate', {'url': url});
}

Future<void> _fillAndSubmitLoginForm(
    String wsUrl, String phone, String password) async {
  // 填写手机号
  await _sendCdpCommand(wsUrl, 'Runtime.evaluate', {
    'expression': '''
      (function() {
        const inputs = document.querySelectorAll('input[type="text"], input[type="tel"]');
        for (let input of inputs) {
          if (input.offsetParent !== null) {
            input.value = '$phone';
            input.dispatchEvent(new Event('input', { bubbles: true }));
            input.dispatchEvent(new Event('change', { bubbles: true }));
            break;
          }
        }
        return true;
      })()
    '''
  });

  await Future.delayed(Duration(milliseconds: 500));

  // 填写密码
  await _sendCdpCommand(wsUrl, 'Runtime.evaluate', {
    'expression': '''
      (function() {
        const inputs = document.querySelectorAll('input[type="password"]');
        if (inputs.length > 0) {
          inputs[0].value = '$password';
          inputs[0].dispatchEvent(new Event('input', { bubbles: true }));
          inputs[0].dispatchEvent(new Event('change', { bubbles: true }));
          return true;
        }
        return false;
      })()
    '''
  });

  await Future.delayed(Duration(milliseconds: 500));

  // 点击登录按钮
  await _sendCdpCommand(wsUrl, 'Runtime.evaluate', {
    'expression': '''
      (function() {
        const buttons = document.querySelectorAll('button, input[type="submit"], a, span');
        for (let btn of buttons) {
          const text = btn.textContent || btn.innerText || '';
          if (text.includes('登') || text.includes('确') || text.includes('提')) {
            btn.click();
            return true;
          }
        }
        return false;
      })()
    '''
  });
}

Future<String?> _getCurrentUrl(String wsUrl) async {
  try {
    final result = await _sendCdpCommand(
        wsUrl, 'Runtime.evaluate', {'expression': 'window.location.href'});
    return result?['result']?['value'] as String?;
  } catch (e) {
    return null;
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
          if (response['id'] == messageId) {
            if (response['result'] != null) {
              completer.complete(response);
            } else if (response['error'] != null) {
              completer.completeError(
                  Exception('CDP 错误: ${response['error']['message']}'));
            }
          }
        } catch (e) {
          // 忽略解析错误
        }
      },
      onError: (e) => completer.completeError(e),
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
      // 忽略关闭错误
    }
  }
}
