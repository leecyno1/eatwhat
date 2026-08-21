import 'package:eatwhat_app/core/services/auth_service.dart';
import 'package:eatwhat_app/v2/features/auth/auth_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget host() {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              key: const ValueKey('open-auth'),
              onPressed: () => showEatWhatAuthSheet(context),
              child: const Text('打开登录'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('注册即自动登录并返回 true', (tester) async {
    var signedIn = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                key: const ValueKey('open-auth'),
                onPressed: () async {
                  signedIn = await showEatWhatAuthSheet(
                    context,
                    reason: '登录后才能使用美团下单',
                  );
                },
                child: const Text('打开登录'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-auth')));
    await settle(tester);

    // 弹窗与下单提示条出现
    expect(find.byKey(const ValueKey('eatwhat-auth-sheet')), findsOneWidget);
    expect(find.text('登录后才能使用美团下单'), findsOneWidget);

    // 切到注册 tab
    await tester.tap(find.text('注册'));
    await settle(tester);

    await tester.enterText(
      find.byKey(const ValueKey('auth-register-username')),
      '美食家小王',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-register-email')),
      'wang@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-register-password')),
      'Eat123456',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-register-confirm')),
      'Eat123456',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('auth-register-submit')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('auth-register-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // sheet 关闭且登录态就绪
    expect(find.byKey(const ValueKey('eatwhat-auth-sheet')), findsNothing);
    expect(signedIn, isTrue);
    expect(AuthService.isLoggedIn, isTrue);
    expect(AuthService.currentUser?.username, '美食家小王');
    expect(AuthService.currentUser?.isMember, isFalse);

    await AuthService.logout();
  });

  testWidgets('登录已有账号成功', (tester) async {
    // 先注册一个账号（离线注册即落库）
    await AuthService.register(
      username: '老食客',
      email: 'fan@example.com',
      password: 'Eat123456',
      confirmPassword: 'Eat123456',
    );
    await AuthService.logout();

    await tester.pumpWidget(host());
    await tester.tap(find.byKey(const ValueKey('open-auth')));
    await settle(tester);

    await tester.enterText(
      find.byKey(const ValueKey('auth-login-username')),
      '老食客',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-login-password')),
      'Eat123456',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('auth-login-submit')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('auth-login-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(AuthService.isLoggedIn, isTrue);
    expect(AuthService.currentUser?.nickname, '老食客');

    await AuthService.logout();
  });

  testWidgets('错误密码显示行内错误且不登录', (tester) async {
    await AuthService.register(
      username: '老食客',
      email: 'fan@example.com',
      password: 'Eat123456',
      confirmPassword: 'Eat123456',
    );
    await AuthService.logout();

    await tester.pumpWidget(host());
    await tester.tap(find.byKey(const ValueKey('open-auth')));
    await settle(tester);

    await tester.enterText(
      find.byKey(const ValueKey('auth-login-username')),
      '老食客',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-login-password')),
      'wrong-pass',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('auth-login-submit')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('auth-login-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(AuthService.isLoggedIn, isFalse);
    expect(find.byKey(const ValueKey('eatwhat-auth-sheet')), findsOneWidget);

    await AuthService.logout();
  });

  test('User 模型会员字段默认与序列化兼容', () {
    final json = {
      'id': '1',
      'username': 'u',
      'email': 'u@example.com',
      'nickname': 'n',
      'passwordHash': 'h',
      'avatar': null,
      'createdAt': '2026-08-21T00:00:00.000',
      'updatedAt': null,
      'lastLoginAt': '2026-08-21T00:00:00.000',
      'userPreference': {
        'userId': '1',
      },
    };
    // 旧数据（无会员字段）解析为标准账号
    final legacy = User.fromJson(json);
    expect(legacy.isMember, isFalse);
    expect(legacy.memberSince, isNull);

    // 会员字段完整回环
    final member = legacy.copyWith(
      isMember: true,
      memberSince: DateTime(2026, 8, 21),
    );
    final restored = User.fromJson(member.toJson());
    expect(restored.isMember, isTrue);
    expect(restored.memberSince, DateTime(2026, 8, 21));
  });
}
