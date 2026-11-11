import 'package:eatwhat_app/app/app_dependencies.dart';
import 'package:eatwhat_app/app/app_router.dart';
import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme_controller.dart';
import 'core/theme/fluid_theme.dart';

class AppV2 extends StatefulWidget {
  const AppV2({super.key, this.dependencies});

  final AppDependencies? dependencies;

  @override
  State<AppV2> createState() => _AppV2State();
}

class _AppV2State extends State<AppV2> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppV2Router.createRouter(
      navigatorKey: _navigatorKey,
      debugMode: EnvConfig.debugMode,
      debugBootstrap: EnvConfig.v2DebugBootstrap,
      dependencies: widget.dependencies,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ValueListenableBuilder<AppThemeMode>(
          valueListenable: AppThemeController.mode,
          builder: (context, theme, _) {
            return MaterialApp.router(
              title: 'EatWhat V2',
              theme: FluidTheme.lightTheme,
              darkTheme: FluidTheme.darkTheme,
              themeMode: AppThemeController.isCream
                  ? ThemeMode.light
                  : ThemeMode.dark,
              routerConfig: _router,
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}
