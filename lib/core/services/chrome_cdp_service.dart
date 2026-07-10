import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Chrome DevTools Protocol (CDP) WebSocket消息
class CdpMessage {
  final int id;
  final String method;
  final Map<String, dynamic>? params;
  final dynamic result;
  final String? error;

  CdpMessage({
    required this.id,
    required this.method,
    this.params,
    this.result,
    this.error,
  });

  factory CdpMessage.fromJson(Map<String, dynamic> json) {
    return CdpMessage(
      id: json['id'] as int,
      method: json['method'] as String? ?? '',
      params: json['params'] as Map<String, dynamic>?,
      result: json['result'],
      error: json['error']?.toString(),
    );
  }
}

/// Chrome标签页信息
class ChromeTab {
  final String id;
  final String title;
  final String url;
  final String webSocketUrl;

  ChromeTab({
    required this.id,
    required this.title,
    required this.url,
    required this.webSocketUrl,
  });

  factory ChromeTab.fromJson(Map<String, dynamic> json) {
    return ChromeTab(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      webSocketUrl: json['webSocketDebuggerUrl'] as String,
    );
  }
}

/// Chrome CDP服务 - 通过WebSocket连接Chrome浏览器
class ChromeCdpService {
  ChromeCdpService({this.host = 'localhost', this.port = 9222});

  final String host;
  final int port;
  WebSocket? _socket;
  final _messageCompleters = <int, Completer<CdpMessage>>{};
  int _messageId = 0;
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  bool _isConnected = false;

  /// 是否已连接
  bool get isConnected => _isConnected;

  /// 连接状态变更流
  Stream<bool> get connectionStatus => _eventController.stream
      .where((e) => e['type'] == 'connection')
      .map((e) => e['connected'] as bool);

  /// 获取所有打开的标签页
  Future<List<ChromeTab>> listTabs() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('http://$host:$port/json'),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      final List<dynamic> json = jsonDecode(body);
      return json
          .where((tab) => tab['type'] == 'page')
          .map((tab) => ChromeTab.fromJson(tab))
          .toList();
    } catch (e) {
      debugPrint('[ChromeCdpService] 获取标签页失败: $e');
      return [];
    }
  }

  /// 连接到指定标签页的WebSocket
  Future<void> connectToTab(ChromeTab tab) async {
    await connect(tab.webSocketUrl);
  }

  /// 连接到WebSocket URL
  Future<void> connect(String url) async {
    if (_isConnected) {
      await disconnect();
    }

    try {
      _socket = await WebSocket.connect(url);
      _socket!.listen(
        _handleMessage,
        onError: (error) {
          debugPrint('[ChromeCdpService] WebSocket错误: $error');
          _isConnected = false;
          _eventController.add({'type': 'connection', 'connected': false});
        },
        onDone: () {
          debugPrint('[ChromeCdpService] WebSocket连接关闭');
          _isConnected = false;
          _eventController.add({'type': 'connection', 'connected': false});
        },
      );
      _isConnected = true;
      _eventController.add({'type': 'connection', 'connected': true});
    } catch (e) {
      debugPrint('[ChromeCdpService] 连接失败: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.close();
      _socket = null;
    }
    _isConnected = false;
    _messageCompleters.clear();
  }

  /// 发送CDP命令并等待响应
  Future<CdpMessage> sendCommand(String method, [Map<String, dynamic>? params]) async {
    if (_socket == null || !_isConnected) {
      throw StateError('未连接到Chrome CDP');
    }

    final id = ++_messageId;
    final message = {
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    };

    final completer = Completer<CdpMessage>();
    _messageCompleters[id] = completer;

    _socket!.add(jsonEncode(message));

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _messageCompleters.remove(id);
        throw TimeoutException('CDP命令超时: $method');
      },
    );
  }

  /// 处理收到的消息
  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;

      // 事件消息
      if (json.containsKey('method')) {
        _eventController.add(json);
        return;
      }

      // 响应消息
      if (json.containsKey('id')) {
        final id = json['id'] as int;
        final completer = _messageCompleters.remove(id);
        if (completer != null) {
          completer.complete(CdpMessage.fromJson(json));
        }
      }
    } catch (e) {
      debugPrint('[ChromeCdpService] 解析消息失败: $e');
    }
  }

  // ==================== 常用CDP命令 ====================

  /// 打开新标签页
  Future<ChromeTab> newTab(String url) async {
    final result = await sendCommand('Target.createTarget', {
      'url': url,
    });
    final targetId = result.result['targetId'] as String;

    // 获取新创建标签页的信息
    final tabs = await listTabs();
    return tabs.firstWhere(
      (tab) => tab.id == targetId,
      orElse: () => ChromeTab(
        id: targetId,
        title: '',
        url: url,
        webSocketUrl: 'ws://$host:$port/devtools/page/$targetId',
      ),
    );
  }

  /// 导航到指定URL
  Future<void> navigate(String url) async {
    await sendCommand('Page.navigate', {'url': url});
  }

  /// 等待页面加载
  Future<void> waitForLoad(double timeoutSeconds) async {
    await sendCommand('Page.enable');
    await sendCommand('Runtime.enable');

    // 等待 load 事件
    final completer = Completer<void>();
    final subscription = _eventController.stream.listen((event) {
      if (event['method'] == 'Page.loadEventFired') {
        completer.complete();
      }
    });

    try {
      await completer.future.timeout(
        Duration(seconds: timeoutSeconds.toInt()),
        onTimeout: () {},
      );
    } finally {
      subscription.cancel();
    }
  }

  /// 执行JavaScript
  Future<dynamic> evaluate(String expression, {bool returnByValue = true}) async {
    final result = await sendCommand('Runtime.evaluate', {
      'expression': expression,
      'returnByValue': returnByValue,
    });
    return result.result?['result']?['value'];
  }

  /// 获取所有Cookie
  Future<List<Map<String, dynamic>>> getCookies() async {
    final result = await sendCommand('Network.getAllCookies');
    return (result.result?['cookies'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  /// 获取指定域名的Cookie
  Future<List<Map<String, dynamic>>> getCookiesForUrls(List<String> urls) async {
    final result = await sendCommand('Network.getCookies', {
      'urls': urls,
    });
    return (result.result?['cookies'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  /// 设置Cookie
  Future<void> setCookie(Map<String, dynamic> cookie) async {
    await sendCommand('Network.setCookie', cookie);
  }

  /// 点击元素
  Future<void> clickElement(String selector) async {
    await evaluate('''
      document.querySelector('$selector')?.click();
    ''');
  }

  /// 填写表单
  Future<void> fillInput(String selector, String value) async {
    await evaluate('''
      (function() {
        const el = document.querySelector('$selector');
        if (el) {
          el.value = '$value';
          el.dispatchEvent(new Event('input', { bubbles: true }));
          el.dispatchEvent(new Event('change', { bubbles: true }));
        }
      })();
    ''');
  }

  /// 获取元素文本
  Future<String?> getElementText(String selector) async {
    final result = await evaluate('''
      document.querySelector('$selector')?.innerText;
    ''');
    return result?.toString();
  }

  /// 截图
  Future<List<int>> takeScreenshot() async {
    final result = await sendCommand('Page.captureScreenshot');
    final data = result.result?['data'];
    if (data != null) {
      return base64Decode(data as String);
    }
    return [];
  }

  /// 滚动到元素可见
  Future<void> scrollIntoView(String selector) async {
    await evaluate('''
      document.querySelector('$selector')?.scrollIntoView({ behavior: 'smooth', block: 'center' });
    ''');
  }

  /// 等待元素出现
  Future<bool> waitForSelector(String selector, {double timeoutSeconds = 10}) async {
    final start = DateTime.now();
    while ((DateTime.now().difference(start).inSeconds) < timeoutSeconds) {
      final exists = await evaluate('''
        document.querySelector('$selector') !== null;
      ''');
      if (exists == true) return true;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  /// 事件流订阅
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  /// 关闭标签页
  Future<void> closeTab(String targetId) async {
    await sendCommand('Target.closeTarget', {
      'targetId': targetId,
    });
  }

  /// 注入脚本
  Future<void> addScriptToEvaluateOnNewDocument(String script) async {
    await sendCommand('Page.addScriptToEvaluateOnNewDocument', {
      'source': script,
    });
  }

  /// 清除所有事件监听并关闭
  void dispose() {
    disconnect();
    _eventController.close();
  }
}
