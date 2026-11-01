import 'package:eatwhat_app/v2/core/theme/system_ui_style.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('黑金主题使用浅色状态栏图标', () {
    final style = appSystemUiOverlayStyle(isCream: false);
    expect(style.statusBarIconBrightness, Brightness.light);
    expect(style.statusBarBrightness, Brightness.dark);
    expect(style.systemNavigationBarIconBrightness, Brightness.light);
  });

  test('纸感主题使用深色状态栏图标', () {
    final style = appSystemUiOverlayStyle(isCream: true);
    expect(style.statusBarIconBrightness, Brightness.dark);
    expect(style.statusBarBrightness, Brightness.light);
    expect(style.systemNavigationBarIconBrightness, Brightness.dark);
  });
}
