#!/usr/bin/env dart
// bin/meituan_cdp_login.dart
//
// 使用 Chrome CDP 自动化登录美团开放平台的脚本
// 运行方式: dart bin/meituan_cdp_login.dart <username> <password>

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:eatwhat_app/core/services/chrome_cdp_service.dart';
import 'package:eatwhat_app/core/services/meituan_auth_service.dart';

void main(List<String> args) async {
  if (args.length < 2) {
    print('用法: dart bin/meituan_cdp_login.dart <用户名> <密码>');
    print('示例: dart bin/meituan_cdp_login.dart 13800138000 mypassword');
    exit(1);
  }

  final username = args[0];
  final password = args[1];

  print('========================================');
  print('美团开放平台 CDP 自动化登录');
  print('========================================');
  print('');

  // 检查 Chrome CDP 连接
  print('1. 检查 Chrome CDP 连接...');
  final cdp = ChromeCdpService();

  try {
    final tabs = await cdp.listTabs();
    print('   ✓ Chrome 已连接，当前打开的标签页:');
    for (final tab in tabs.take(5)) {
      print('     - ${tab.title}: ${tab.url}');
    }
    if (tabs.length > 5) {
      print('     ... 还有 ${tabs.length - 5} 个标签页');
    }
    print('');
  } catch (e) {
    print('   ✗ 无法连接到 Chrome CDP');
    print('   请确保 Chrome 以远程调试模式运行:');
    print('   /Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome --remote-debugging-port=9222');
    exit(1);
  }

  // 执行登录
  print('2. 准备登录美团开放平台...');
  print('   用户名: ${username.substring(0, 3)}***');
  print('');

  final authService = MeituanAuthService(cdpService: cdp);

  try {
    print('3. 开始自动化登录...');
    print('   (请勿操作键盘和鼠标，自动化脚本正在执行)');
    print('');

    final tokens = await authService.loginWithCdp(
      username: username,
      password: password,
    );

    print('');
    print('========================================');
    print('✓ 登录成功!');
    print('========================================');
    print('');
    print('认证信息:');
    print('  - Access Token: ${tokens.accessToken?.substring(0, 20) ?? "无"}...');
    print('  - Token 类型: ${tokens.tokenType ?? "无"}');
    print('  - 有效期至: ${tokens.expiresAt ?? "无"}');
    print('  - Cookie 数量: ${tokens.cookies.length}');
    print('');

    if (tokens.accessToken != null) {
      print('4. 保存认证信息...');
      // 认证信息已由 MeituanAuthService 自动保存
      print('   ✓ 认证信息已保存到安全存储');
    }

    print('');
    print('========================================');
    print('后续步骤:');
    print('1. 现在可以使用美团开放平台 API 了');
    print('2. 确保在 .env 中配置了必要的 API 参数');
    print('========================================');
  } on Exception catch (e) {
    print('');
    print('========================================');
    print('✗ 登录失败');
    print('========================================');
    print('错误: $e');
    print('');
    print('常见问题:');
    print('1. 检查用户名和密码是否正确');
    print('2. 检查 Chrome 是否以远程调试模式运行');
    print('3. 检查是否有验证码或双因素认证');
    print('');
    exit(1);
  } finally {
    cdp.dispose();
  }
}
