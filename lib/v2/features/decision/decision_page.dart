import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_router.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/features/home/widgets/floating_editorial_background.dart';
import 'package:eatwhat_app/v2/features/result/result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class DecisionPage extends StatefulWidget {
  const DecisionPage({
    super.key,
    this.input,
    this.selectedTagLabels = const [],
    this.selectedTagIds = const [],
    this.customRequirement,
    this.localRecommendationLoader,
    this.recommendationRefiner,
    this.aiRecommendationLoader,
    this.recommendationFlowService,
    this.autoNavigateToResult = true,
  });

  final TasteInferenceInput? input;
  final List<String> selectedTagLabels;
  final List<String> selectedTagIds;
  final String? customRequirement;
  final LocalRecommendationLoader? localRecommendationLoader;
  final RecommendationRefiner? recommendationRefiner;
  final AiRecommendationLoader? aiRecommendationLoader;
  final V2Phase2RecommendationService? recommendationFlowService;
  final bool autoNavigateToResult;

  TasteInferenceInput get resolvedInput {
    if (input != null) {
      return input!;
    }
    return TasteInferenceInput(
      likedTagIds: selectedTagIds,
      likedTagLabels: selectedTagLabels,
      dislikedTagIds: const [],
      dislikedTagLabels: const [],
      skippedTagIds: const [],
      skippedTagLabels: const [],
      freeformRequirement: customRequirement ?? '',
      historyPreferenceSummary: const {},
    );
  }

  @override
  State<DecisionPage> createState() => _DecisionPageState();
}

class _DecisionPageState extends State<DecisionPage>
    with SingleTickerProviderStateMixin {
  static const Duration _recommendationWaitTimeout = Duration(seconds: 12);
  late Timer _timer;
  late final AnimationController _inferenceController;
  late final V2Phase2RecommendationService _recommendationFlowService;

  List<RecipeModel> _recommendations = [];
  Map<String, String> _aiReasonsByRecipeId = {};
  String? _aiSummary;
  RecommendationResolutionStatus _resolutionStatus =
      RecommendationResolutionStatus.empty;
  String _primarySource = 'empty';
  bool _aiLoading = true;
  bool _isFinished = false;
  int _currentIndex = 0;
  int _cycleCount = 0;
  int _speed = 50;
  int _recallCount = 0;
  int _finalCount = 0;
  String? _refinedSummary;
  List<String> _recallLabels = const [];
  _DecisionStage _stage = _DecisionStage.recall;

  TasteInferenceInput get _input => widget.resolvedInput;

  List<String> get _displaySignals {
    final signals = [
      ..._input.likedTagLabels,
      if (_input.freeformRequirement.trim().isNotEmpty)
        _input.freeformRequirement.trim(),
    ];
    return signals.isEmpty ? ['今天这一口'] : signals;
  }

  @override
  void initState() {
    super.initState();
    _recommendationFlowService = widget.recommendationFlowService ??
        V2Phase2RecommendationService(
          localRecommendationLoader: widget.localRecommendationLoader,
          recommendationRefiner: widget.recommendationRefiner,
          aiRecommendationLoader: widget.aiRecommendationLoader,
        );
    _inferenceController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _startSlotMachine();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    try {
      if (mounted) {
        setState(() {
          _stage = _DecisionStage.recall;
        });
      }
      final bundle = await _recommendationFlowService
          .buildRecommendations(
            input: _input,
          )
          .timeout(
            _recommendationWaitTimeout,
            onTimeout: () => Phase2RecommendationBundle(
              recallLabels: _input.primarySignals,
              recalledCount: 0,
              finalRecommendations: const [],
              aiReasonsByRecipeId: const {},
              aiSummary: '这轮没有命中合适的菜品。',
              isEstimated: true,
              resolutionStatus: RecommendationResolutionStatus.empty,
              primarySource: 'empty',
            ),
          );

      if (!mounted) return;
      setState(() {
        _recommendations = bundle.finalRecommendations;
        _aiLoading = false;
        _aiReasonsByRecipeId = bundle.aiReasonsByRecipeId;
        _aiSummary = bundle.aiSummary;
        _refinedSummary = bundle.aiSummary;
        _resolutionStatus = bundle.resolutionStatus;
        _primarySource = bundle.primarySource;
        _recallCount = bundle.recalledCount;
        _recallLabels = bundle.recallLabels;
        _finalCount = bundle.finalRecommendations.length;
        _stage = _DecisionStage.finalized;
      });
    } catch (e) {
      debugPrint('AI Error: $e');
      if (!mounted) return;
      setState(() {
        _recommendations = const [];
        _aiLoading = false;
        _aiSummary = '这轮没有命中合适的菜品。';
        _resolutionStatus = RecommendationResolutionStatus.empty;
        _primarySource = 'error';
        _recallLabels = const [];
        _recallCount = 0;
        _finalCount = _recommendations.length;
        _stage = _DecisionStage.finalized;
      });
    }
  }

  String _buildLiveStatusText() {
    switch (_stage) {
      case _DecisionStage.recall:
        return '正在让 AI 生成候选菜品';
      case _DecisionStage.rerank:
        return '正在补全图片和做法信息';
      case _DecisionStage.finalized:
        return '正在确认本轮正式推荐结果';
    }
  }

  void _startSlotMachine() {
    _timer = Timer.periodic(Duration(milliseconds: _speed), (timer) {
      final signals = _displaySignals;
      setState(() {
        _currentIndex = (_currentIndex + 1) % signals.length;
        _cycleCount++;
      });

      HapticFeedback.lightImpact();

      if (_cycleCount > 18 && !_aiLoading) {
        _speed += 10;
        _timer.cancel();
        if (_speed > 240) {
          _finish();
        } else {
          _startSlotMachine();
        }
      }
    });
  }

  void _finish() {
    _isFinished = true;
    HapticFeedback.heavyImpact();

    if (!widget.autoNavigateToResult) {
      if (mounted) {
        setState(() {});
      }
      return;
    }

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final resultData = AppV2ResultRouteData(
        recommendations: _recommendations,
        inferenceInput: _input,
        fallbackTags: _input.primarySignals,
        aiReasonsByRecipeId: _aiReasonsByRecipeId,
        aiSummary: _aiSummary,
        resolutionStatus: _resolutionStatus,
        primarySource: _primarySource,
        recallLabels: _recallLabels,
        recalledCount: _recallCount,
      );
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        context.replace(AppV2Routes.result, extra: resultData);
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultPage(
            recommendations: resultData.recommendations,
            inferenceInput: resultData.inferenceInput,
            fallbackTags: resultData.fallbackTags,
            aiReasonsByRecipeId: resultData.aiReasonsByRecipeId,
            aiSummary: resultData.aiSummary,
            resolutionStatus: resultData.resolutionStatus,
            primarySource: resultData.primarySource,
            recallLabels: resultData.recallLabels,
            recalledCount: resultData.recalledCount,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _inferenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLabel =
        _displaySignals[_currentIndex % _displaySignals.length];
    final stageItems = [
      (
        label: 'AI 生成 ${_recallCount > 0 ? _recallCount : '...'} 道候选',
        stage: _DecisionStage.recall,
      ),
      (
        label:
            '资料补全 ${_finalCount > 0 ? _finalCount : (_recallCount > 0 ? _recallCount : '...')} 道正式结果',
        stage: _DecisionStage.rerank,
      ),
      (
        label: _stage == _DecisionStage.finalized ? '正式结果已完成收束' : '正式结果收束中',
        stage: _DecisionStage.finalized,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Stack(
        children: [
          const FloatingEditorialBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        child: const Text(
                          '口味收束台',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.56),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _aiLoading
                                    ? AppColors.sunsetOrange
                                    : AppColors.freshLime,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _aiLoading ? '口味推理中' : '口味推理完成',
                              style: TextStyle(
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.64),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      key: const ValueKey('decision-stage-shell'),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.82),
                          width: 1.1,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.66),
                            Colors.white.withValues(alpha: 0.34),
                          ],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: const SizedBox.expand(),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(22, 20, 22, 22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '正在组合你的口味签名',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '喜欢、不要、略过，再加上你补充的一句话，正在交给 AI 生成 3-5 个候选菜品。',
                                    style: TextStyle(
                                      color: AppColors.textPrimary
                                          .withValues(alpha: 0.58),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Expanded(
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _InferenceHalo(
                                            controller: _inferenceController,
                                          ),
                                          const SizedBox(height: 22),
                                          Text(
                                            currentLabel,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 42,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.textPrimary,
                                              height: 1.0,
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 10,
                                            alignment: WrapAlignment.center,
                                            children: [
                                              for (final item in stageItems)
                                                _DecisionStageChip(
                                                  label: item.label,
                                                  isActive: _stage.index >=
                                                      item.stage.index,
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _refinedSummary
                                                        ?.trim()
                                                        .isNotEmpty ==
                                                    true
                                                ? _refinedSummary!.trim()
                                                : '喜欢、不要、略过，再加上你补充的一句话，正在交给 AI 生成 3-5 个候选菜品。',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppColors.textPrimary
                                                  .withValues(alpha: 0.62),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            _buildLiveStatusText(),
                                            style: TextStyle(
                                              color: AppColors.textPrimary
                                                  .withValues(alpha: 0.54),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_isFinished)
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        '候选菜品已经准备好',
                                        style: TextStyle(
                                          color: AppColors.freshLime,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _DecisionStage {
  recall,
  rerank,
  finalized,
}

class _DecisionStageChip extends StatelessWidget {
  const _DecisionStageChip({
    required this.label,
    required this.isActive,
  });

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final activeColor =
        isActive ? AppColors.sunsetOrange : AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.sunsetOrange.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive
              ? AppColors.sunsetOrange.withValues(alpha: 0.34)
              : Colors.white.withValues(alpha: 0.48),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: activeColor.withValues(alpha: isActive ? 0.94 : 0.62),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InferenceHalo extends StatelessWidget {
  const _InferenceHalo({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SizedBox(
          width: 116,
          height: 116,
          child: CustomPaint(
            painter: _InferenceHaloPainter(progress: controller.value),
          ),
        );
      },
    );
  }
}

class _InferenceHaloPainter extends CustomPainter {
  const _InferenceHaloPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x66F46B40);

    final glowPaint = Paint()
      ..color = const Color(0x33F46B40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    final innerOrbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x44FFFFFF);
    canvas
      ..drawCircle(center, 30, glowPaint)
      ..drawCircle(center, 44, orbitPaint)
      ..drawCircle(center, 30, innerOrbitPaint);

    for (final offset in [0.0, 0.34, 0.67]) {
      final angle = (progress + offset) * 2 * 3.1415926;
      final dot = Offset(
        center.dx + 44 * sin(angle),
        center.dy + 44 * cos(angle),
      );
      canvas.drawCircle(
        dot,
        4.4,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _InferenceHaloPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
