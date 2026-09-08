import 'package:eatwhat_app/core/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('种子账号自动创建且可登录', () async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initialize();

    final result = await AuthService.login(
      usernameOrEmail: '17600806220',
      password: 'Iv19whot@123',
      rememberMe: true,
    );
    expect(result.success, isTrue);
    expect(result.user?.nickname, '管理员');
    expect(result.user?.isMember, isTrue);
    expect(AuthService.isLoggedIn, isTrue);
    await AuthService.logout();
  });

}
