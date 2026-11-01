import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app_dependencies.dart';
import 'core/config/env_config.dart';
import 'core/services/auth_service.dart';
import 'core/utils/analytics_helper.dart';
import 'v2/app_v2.dart';
import 'v2/core/theme/app_theme_controller.dart';
import 'v2/core/theme/system_ui_style.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // 初始化埋点
  AnalyticsHelper.logAppLaunch(
    version: '1.0.0',
    platform: defaultTargetPlatform.toString(),
  );

  await EnvConfig.init();
  await AuthService.initialize();
  await AppThemeController.loadStored();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI overlay follows the theme so dark pages keep readable icons.
  void applySystemUiOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      appSystemUiOverlayStyle(isCream: AppThemeController.isCream),
    );
  }

  applySystemUiOverlay();
  AppThemeController.mode.addListener(applySystemUiOverlay);

  runApp(
    ProviderScope(
      child: AppV2(
        dependencies: AppDependencies.standard(),
      ),
    ),
  );
}
