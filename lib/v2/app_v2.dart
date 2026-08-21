import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/fluid_theme.dart';
import 'features/onboarding/onboarding_overlay.dart';
import 'features/onboarding/onboarding_service.dart';

class AppV2 extends StatefulWidget {
  const AppV2({super.key});

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
    );
    _checkInitialStatus();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  Future<void> _checkInitialStatus() async {
    if (EnvConfig.debugMode) {
      return;
    }

    // The cold-start questionnaire is retired: it duplicated what the home
    // stage already does better — the physical pot collects preferences
    // directly from taps, grabs, and blocks, so first-run users land straight
    // on the stage (with the gesture guide card) instead of a form flow.
    if (mounted) {
      await _checkOnboardingStatus();
    }
  }

  Future<void> _checkOnboardingStatus() async {
    final shouldShow = await OnboardingService().shouldShowOnboarding();
    if (mounted) {
      if (shouldShow) {
        final overlay = _navigatorKey.currentState?.overlay;
        if (overlay != null) {
          OnboardingOverlay.showOn(overlay);
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'EatWhat V2',
          theme: FluidTheme.lightTheme,
          darkTheme: FluidTheme.darkTheme,
          themeMode: ThemeMode.dark,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
