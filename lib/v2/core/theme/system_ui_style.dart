import 'package:flutter/services.dart';

/// 系统状态栏/导航栏样式跟随深浅主题：黑金主题用浅色图标，纸感主题用深色图标。
SystemUiOverlayStyle appSystemUiOverlayStyle({required bool isCream}) {
  return SystemUiOverlayStyle(
    statusBarColor: const Color(0x00000000),
    statusBarIconBrightness: isCream ? Brightness.dark : Brightness.light,
    statusBarBrightness: isCream ? Brightness.light : Brightness.dark,
    systemNavigationBarColor: const Color(0x00000000),
    systemNavigationBarIconBrightness:
        isCream ? Brightness.dark : Brightness.light,
  );
}
