import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'core/services/cold_start_service.dart';
import 'core/theme/fluid_theme.dart';
import 'features/onboarding/cold_start_questionnaire_page.dart';
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
    final coldStartService = ColdStartService();

    // 检查是否已完成冷启动问卷
    final questionnaireCompleted =
        await coldStartService.isQuestionnaireCompleted();
    debugPrint('AppV2: 冷启动问卷状态 = $questionnaireCompleted');

    if (mounted) {
      // 如果需要显示问卷，延迟显示以确保界面准备好
      if (!questionnaireCompleted) {
        // 问卷将在 build 方法中通过 Overlay 显示
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showQuestionnaireOverlay();
        });
      } else {
        // 检查是否需要显示 onboarding
        await _checkOnboardingStatus();
      }
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

  void _showQuestionnaireOverlay() {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showQuestionnaireOverlay();
      });
      return;
    }

    navigator.push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: ColdStartQuestionnairePage(
              onCompleted: () {
                debugPrint('问卷完成，进入主界面');
                _onQuestionnaireCompleted();
              },
              onSkipped: () {
                debugPrint('问卷跳过，进入主界面');
                _onQuestionnaireCompleted();
              },
            ),
          );
        },
      ),
    );
  }

  void _onQuestionnaireCompleted() {
    final navigator = _navigatorKey.currentState;
    if (navigator?.canPop() ?? false) {
      navigator!.pop();
    }

    // 问卷关闭后，再检查是否需要显示 onboarding，避免新引导被问卷页挡住。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkOnboardingStatus();
      }
    });
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
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
