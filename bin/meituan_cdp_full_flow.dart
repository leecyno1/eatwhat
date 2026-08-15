#!/usr/bin/env dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  const String phone = '17600806220';
  const String password = 'iv19whot';

  print('🔐 美团开放平台 CDP 自动化流程');
  print('手机号: $phone');
  print('密码: ' + ('*' * password.length));
  print('');

  try {
    // 获取 WebSocket URL
    print('📱 连接 Chrome DevTools Protocol...');
    final wsUrl = await _getWebSocketUrl();
    if (wsUrl == null) {
      print('❌ 无法连接到 Chrome');
      exit(1);
    }
    print('✅ 已连接到 Chrome');
    print('   WebSocket: $wsUrl');
    print('');

    // 导航到登录页
    print('🌐 导航到美团开放平台登录页...');
    await _navigateTo(wsUrl, 'https://open.meituan.com/user/login');
    await Future.delayed(Duration(seconds: 3));
    print('✅ 已打开登录页');
    print('');

    // 填写登录信息
    print('🔍 查找登录表单...');
    await _fillPhoneField(wsUrl, phone);
    await Future.delayed(Duration(milliseconds: 500));
    print('✅ 已填写手机号');

    await _fillPasswordField(wsUrl, password);
    await Future.delayed(Duration(milliseconds: 500));
    print('✅ 已填写密码');
    print('');

    // 点击登录
    print('🔐 点击登录按钮...');
    await _clickLoginButton(wsUrl);
    await Future.delayed(Duration(seconds: 3));
    print('✅ 已提交登录');
    print('');

    // 检查是否需要验证
    print('⏳ 等待登录验证...');
    await Future.delayed(Duration(seconds: 3));
    final currentUrl = await _getCurrentUrl(wsUrl);
    print('   当前URL: $currentUrl');
    print('');

    // 导航到注册流程文档
    print('📖 导航到注册流程文档...');
    await _navigateTo(wsUrl, 'https://open.meituan.com/docs/introduce/guide');
    await Future.delayed(Duration(seconds: 2));
    print('✅ 已打开文档');
    print('');

    // 提取文档内容
    print('📄 提取注册流程信息...');
    final content = await _extractContent(wsUrl);
    if (content != null && content.isNotEmpty) {
      print('✅ 成功读取文档');
      print('');
      print('===== 注册流程详情 ====');
      print(content);
      print('====================');
    } else {
      print('⚠️ 无法读取文档内容');
    }
    print('');

    // 截图
    print('📸 截图当前页面...');
    final screenshotData = await _captureScreenshot(wsUrl);
    if (screenshotData != null) {
      final file = File('meituan_guide.png');
      file.writeAsBytesSync(base64Decode(screenshotData));
      print('✅ 已保存截图: meituan_guide.png');
    }
    print('');

    print('✨ 流程完成！');

  } catch (e) {
    print('❌ 错误: $e');
    exit(1);
  }
}

Future<String?> _getWebSocketUrl() async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:9222/json'))
        .timeout(Duration(seconds: 5));
    final response = await request.close().timeout(Duration(seconds: 5));

    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      final tabs = jsonDecode(body) as List;
      if (tabs.isNotEmpty) {
        return tabs[0]['webSocketDebuggerUrl'] as String?;
      }
    }
  } catch (e) {
    print('   连接错误: $e');
  }
  return null;
}

Future<void> _navigateTo(String wsUrl, String url) async {
  final ws = await WebSocket.connect(wsUrl).timeout(Duration(seconds: 10));
  int msgId = 1;

  ws.add(jsonEncode({
    'id': msgId,
    'method': 'Page.navigate',
    'params': {'url': url}
  }));

  await Future.delayed(Duration(milliseconds: 500));
  ws.close();
}

Future<void> _fillPhoneField(String wsUrl, String phone) async {
  await _evaluateJs(wsUrl, '''
    (function() {
      const inputs = document.querySelectorAll('input');
      for (let input of inputs) {
        if (input.type === 'tel' || input.type === 'text' || input.placeholder?.includes('手机')) {
          input.focus();
          input.value = '$phone';
          input.dispatchEvent(new Event('input', { bubbles: true }));
          input.dispatchEvent(new Event('change', { bubbles: true }));
          input.dispatchEvent(new Event('blur', { bubbles: true }));
          return true;
        }
      }
      return false;
    })()
  ''');
}

Future<void> _fillPasswordField(String wsUrl, String password) async {
  await _evaluateJs(wsUrl, '''
    (function() {
      const inputs = document.querySelectorAll('input[type="password"]');
      if (inputs.length > 0) {
        inputs[0].focus();
        inputs[0].value = '$password';
        inputs[0].dispatchEvent(new Event('input', { bubbles: true }));
        inputs[0].dispatchEvent(new Event('change', { bubbles: true }));
        inputs[0].dispatchEvent(new Event('blur', { bubbles: true }));
        return true;
      }
      return false;
    })()
  ''');
}

Future<void> _clickLoginButton(String wsUrl) async {
  await _evaluateJs(wsUrl, '''
    (function() {
      // 尝试找到登录按钮
      const buttons = document.querySelectorAll('button, input[type="submit"], a');
      for (let btn of buttons) {
        const text = (btn.textContent || btn.innerText || btn.value || '').trim();
        if (text.includes('登') && text.includes('录')) {
          btn.click();
          return true;
        }
      }
      return false;
    })()
  ''');
}

Future<String?> _getCurrentUrl(String wsUrl) async {
  try {
    final result = await _evaluateJs(wsUrl, 'window.location.href');
    return result as String?;
  } catch (e) {
    return null;
  }
}

Future<String?> _extractContent(String wsUrl) async {
  try {
    final result = await _evaluateJs(wsUrl, '''
      (function() {
        // 提取主要内容
        const main = document.querySelector('main') ||
                    document.querySelector('[role="main"]') ||
                    document.querySelector('.content') ||
                    document.querySelector('article') ||
                    document.body;

        if (main) {
          // 提取所有文本内容
          let text = '';
          const headings = main.querySelectorAll('h1, h2, h3, h4, h5, h6, p, li, div');

          for (let el of headings) {
            const content = (el.textContent || '').trim();
            if (content && content.length > 0 && content.length < 500) {
              text += content + '\n';
            }
          }

          return text.substring(0, 2000); // 限制长度
        }
        return null;
      })()
    ''');
    return result as String?;
  } catch (e) {
    return null;
  }
}

Future<String?> _captureScreenshot(String wsUrl) async {
  try {
    final ws = await WebSocket.connect(wsUrl).timeout(Duration(seconds: 10));
    int msgId = 1;
    final completer = Completer<String?>();

    final subscription = ws.listen(
      (data) {
        try {
          final response = jsonDecode(data);
          if (response['id'] == msgId && response['result']?['data'] != null) {
            completer.complete(response['result']['data'] as String?);
          }
        } catch (e) {}
      },
      onError: (e) => completer.completeError(e),
      cancelOnError: true,
    );

    ws.add(jsonEncode({
      'id': msgId,
      'method': 'Page.captureScreenshot',
      'params': {}
    }));

    final result = await completer.future
        .timeout(Duration(seconds: 10))
        .whenComplete(() => subscription.cancel());
    ws.close();
    return result;
  } catch (e) {
    return null;
  }
}

Future<dynamic> _evaluateJs(String wsUrl, String expression) async {
  try {
    final ws = await WebSocket.connect(wsUrl).timeout(Duration(seconds: 10));
    int msgId = 1;
    final completer = Completer<dynamic>();

    final subscription = ws.listen(
      (data) {
        try {
          final response = jsonDecode(data);
          if (response['id'] == msgId && !completer.isCompleted) {
            if (response['result']?['value'] != null) {
              completer.complete(response['result']['value']);
            } else if (response['result'] != null) {
              completer.complete(response['result']);
            } else if (response['error'] != null) {
              completer.completeError(Exception(response['error']['message']));
            }
          }
        } catch (e) {}
      },
      onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      cancelOnError: true,
    );

    ws.add(jsonEncode({
      'id': msgId,
      'method': 'Runtime.evaluate',
      'params': {
        'expression': expression,
        'returnByValue': true
      }
    }));

    final result = await completer.future
        .timeout(Duration(seconds: 10))
        .whenComplete(() => subscription.cancel());
    ws.close();
    return result;
  } catch (e) {
    throw Exception('JavaScript 执行失败: $e');
  }
}
