import 'dart:async';

import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_telemetry_context.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_router.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_telemetry_service.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
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
    this.recommendationTelemetryService,
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
  final V2RecommendationTelemetryService? recommendationTelemetryService;
  final bool autoNavigateToResult;

  TasteInferenceInput get resolvedInput {
    if (input != null) return input!;
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

class _DecisionPageState extends State<DecisionPage> {
  late final V2Phase2RecommendationService _recommendationFlowService;
  late final V2RecommendationTelemetryService _recommendationTelemetryService;

  List<RecipeModel> _recommendations = const [];
  Map<String, String> _aiReasonsByRecipeId = const {};
  String? _aiSummary;
  RecommendationResolutionStatus _resolutionStatus =
      RecommendationResolutionStatus.empty;
  String _primarySource = 'empty';
  bool _aiLoading = true;
  bool _isFinished = false;
  int _recallCount = 0;
  int _finalCount = 0;
  String? _refinedSummary;
  List<String> _recallLabels = const [];
  RecommendationTelemetryContext? _recommendationContext;
  _DecisionStage _stage = _DecisionStage.recall;
  Timer? _resultNavigationTimer;

  TasteInferenceInput get _input => widget.resolvedInput;

  List<String> get _displaySignals {
    final signals = <String>[
      ..._input.likedTagLabels,
      if (_input.freeformRequirement.trim().isNotEmpty)
        _input.freeformRequirement.trim(),
    ];
    return signals.isEmpty ? const ['今天这一口'] : signals;
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
    _recommendationTelemetryService = widget.recommendationTelemetryService ??
        V2RecommendationTelemetryService.instance;
    _fetchRecommendations();
  }

  @override
  void dispose() {
    _resultNavigationTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRecommendations() async {
    // Stage 1: the local bundle (hybrid scoring, no LLM call) is sub-second —
    // navigate immediately so the user never stares at a spinner. Stage 2
    // runs the MiniMax refine in the background and hands the finished
    // bundle to the already-open result page.
    final fullBundleFuture =
        _recommendationFlowService.buildRecommendations(input: _input);
    // Surface the AI's finished summary in the finalize window: when the
    // background refine lands before navigation, the stage copy swaps in.
    unawaited(
      fullBundleFuture.then((bundle) {
        if (!mounted) return;
        final summary = bundle.aiSummary?.trim();
        if (summary == null || summary.isEmpty) return;
        setState(() => _refinedSummary = summary);
      }).catchError((_) {}),
    );

    try {
      final bundle = await _recommendationFlowService
          .buildRecommendations(
            input: _input,
            skipAiEnhancement: true,
          )
          .timeout(
            const Duration(seconds: 3),
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
      final recommendationContext = RecommendationTelemetryContext(
        recommendationId: _recommendationTelemetryService
            .createRecommendationId(algorithmVersion: bundle.algorithmVersion),
        algorithmVersion: bundle.algorithmVersion,
        primarySource: bundle.primarySource,
        resolutionStatus: bundle.resolutionStatus,
        recalledCount: bundle.recalledCount,
        finalCount: bundle.finalRecommendations.length,
        latencyMs: bundle.latency.inMilliseconds,
        diversityScore: bundle.diversityScore,
        appliedConstraintCount: bundle.appliedConstraints.length,
        fallbackReason: bundle.fallbackReason,
      );
      setState(() {
        _recommendations = bundle.finalRecommendations;
        _aiReasonsByRecipeId = bundle.aiReasonsByRecipeId;
        _aiSummary = bundle.aiSummary;
        // The local copy only fills the stage copy when the AI words have
        // not landed yet — if the background refine already finished (fast
        // mocks), its summary must not be overwritten by the local one.
        _refinedSummary ??= bundle.aiSummary;
        _resolutionStatus = bundle.resolutionStatus;
        _primarySource = bundle.primarySource;
        _recallCount = bundle.recalledCount;
        _recallLabels = bundle.recallLabels;
        _recommendationContext = recommendationContext;
        _finalCount = bundle.finalRecommendations.length;
        _stage = _DecisionStage.rerank;
      });
      _finish();
    } catch (error) {
      debugPrint('AI Error: $error');
      if (!mounted) return;
      final recommendationContext = RecommendationTelemetryContext(
        recommendationId:
            _recommendationTelemetryService.createRecommendationId(
          algorithmVersion: V2Phase2RecommendationService.algorithmVersion,
        ),
        algorithmVersion: V2Phase2RecommendationService.algorithmVersion,
        primarySource: 'error',
        resolutionStatus: RecommendationResolutionStatus.empty,
        recalledCount: 0,
        finalCount: 0,
        latencyMs: 0,
        diversityScore: 0,
        appliedConstraintCount: _input.structuredConstraints.labels.length +
            _input.dislikedTagLabels.length,
        fallbackReason: 'recommendation_error',
      );
      setState(() {
        _recommendations = const [];
        _aiReasonsByRecipeId = const {};
        _aiSummary = '这轮没有命中合适的菜品。';
        _refinedSummary = _aiSummary;
        _resolutionStatus = RecommendationResolutionStatus.empty;
        _primarySource = 'error';
        _recallLabels = const [];
        _recallCount = 0;
        _finalCount = 0;
        _recommendationContext = recommendationContext;
        _stage = _DecisionStage.rerank;
      });
      _finish();
    }
  }

  String _buildLiveStatusText() {
    return switch (_stage) {
      _DecisionStage.recall => '正在从本地菜谱库召回候选',
      _DecisionStage.rerank => '正在进行智能收束与资料补全',
      _DecisionStage.finalized => '正在确认本轮正式推荐结果',
    };
  }

  Future<Phase2RecommendationBundle>? _aiEnhancement;

  void _finish({Future<Phase2RecommendationBundle>? aiEnhancement}) {
    if (_isFinished) return;
    setState(() {
      _aiLoading = false;
      _isFinished = true;
      _stage = _DecisionStage.finalized;
      _aiEnhancement = aiEnhancement;
    });
    HapticFeedback.mediumImpact();

    if (!widget.autoNavigateToResult) return;
    _resultNavigationTimer?.cancel();
    _resultNavigationTimer = Timer(AppMotion.standard, _openResult);
  }

  void _openResult() {
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
      recommendationContext: _recommendationContext,
      aiEnhancement: _aiEnhancement,
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
          recommendationContext: resultData.recommendationContext,
          aiEnhancement: resultData.aiEnhancement,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final transitionDuration = reduceMotion ? Duration.zero : AppMotion.fast;
    final stageItems = <({String label, _DecisionStage stage})>[
      (
        label: '本地召回 ${_recallCount > 0 ? _recallCount : '...'} 道候选',
        stage: _DecisionStage.recall,
      ),
      (
        label:
            '智能收束 ${_finalCount > 0 ? _finalCount : (_recallCount > 0 ? _recallCount : '...')} 道正式结果',
        stage: _DecisionStage.rerank,
      ),
      (
        label: _stage == _DecisionStage.finalized ? '正式结果已完成收束' : '正式结果收束中',
        stage: _DecisionStage.finalized,
      ),
    ];

    return Scaffold(
      backgroundColor: AppPalette.night,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('口味收束台', style: AppTypeNight.microLabel),
                  const Spacer(),
                  _DecisionStatusBadge(
                    isLoading: _aiLoading,
                    duration: transitionDuration,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Container(
                  key: const ValueKey('decision-stage-shell'),
                  width: double.infinity,
                  decoration: AppDecorations.nightCard(radius: AppRadii.lg),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: transitionDuration,
                          curve: AppMotion.enter,
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _isFinished
                                ? AppPalette.nightElevated
                                : AppPalette.nightSurface,
                            borderRadius: AppRadii.small,
                            border: Border.all(
                              color: _isFinished
                                  ? AppPalette.leaf.withValues(alpha: 0.5)
                                  : AppPalette.nightDivider,
                            ),
                          ),
                          child: Icon(
                            _isFinished
                                ? Icons.check_rounded
                                : Icons.restaurant_menu_rounded,
                            color: _isFinished
                                ? AppPalette.leaf
                                : AppPalette.moonMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          '正在组合你的口味签名',
                          style: AppTypeNight.title,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _refinedSummary?.trim().isNotEmpty == true
                              ? _refinedSummary!.trim()
                              : '根据你的偏好和补充要求，先从可靠菜谱中筛选，再收束成一组可直接选择的结果。',
                          style: AppTypeNight.body,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final signal in _displaySignals.take(4))
                              _DecisionSignalChip(label: signal),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Divider(
                          height: 1,
                          color: AppPalette.nightDivider,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (var index = 0;
                            index < stageItems.length;
                            index++) ...[
                          _DecisionStageRow(
                            label: stageItems[index].label,
                            state: _stateFor(stageItems[index].stage),
                            duration: transitionDuration,
                          ),
                          if (index != stageItems.length - 1)
                            const SizedBox(height: AppSpacing.xs),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        AnimatedSwitcher(
                          duration: transitionDuration,
                          switchInCurve: AppMotion.enter,
                          switchOutCurve: AppMotion.enter,
                          child: Text(
                            _buildLiveStatusText(),
                            key: ValueKey(_stage),
                            style: AppTypeNight.label.copyWith(
                              color: _isFinished
                                  ? AppPalette.leaf
                                  : AppPalette.moonMuted,
                            ),
                          ),
                        ),
                        if (_isFinished) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '候选菜品已经准备好',
                            style: AppTypeNight.label.copyWith(
                              color: AppPalette.leaf,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _DecisionStageState _stateFor(_DecisionStage stage) {
    if (_stage.index > stage.index || _isFinished) {
      return _DecisionStageState.complete;
    }
    if (_stage == stage) return _DecisionStageState.active;
    return _DecisionStageState.pending;
  }
}

enum _DecisionStage { recall, rerank, finalized }

enum _DecisionStageState { pending, active, complete }

class _DecisionStatusBadge extends StatelessWidget {
  const _DecisionStatusBadge({
    required this.isLoading,
    required this.duration,
  });

  final bool isLoading;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: AppMotion.enter,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppPalette.nightElevated,
        borderRadius: AppRadii.capsule,
        border: Border.all(color: AppPalette.nightDivider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: duration,
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isLoading ? AppPalette.yolk : AppPalette.leaf,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isLoading ? '口味推理中' : '口味推理完成',
            style: AppTypeNight.microLabel.copyWith(
              color: isLoading ? AppPalette.yolk : AppPalette.leaf,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionSignalChip extends StatelessWidget {
  const _DecisionSignalChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppPalette.nightElevated,
        borderRadius: AppRadii.capsule,
        border: Border.all(color: AppPalette.nightDivider),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypeNight.label,
      ),
    );
  }
}

class _DecisionStageRow extends StatelessWidget {
  const _DecisionStageRow({
    required this.label,
    required this.state,
    required this.duration,
  });

  final String label;
  final _DecisionStageState state;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final isComplete = state == _DecisionStageState.complete;
    final isActive = state == _DecisionStageState.active;
    final foreground =
        isComplete || isActive ? AppPalette.moonlight : AppPalette.moonMuted;
    final surface = isComplete
        ? AppPalette.nightElevated
        : isActive
            ? AppPalette.nightSurface
            : AppPalette.night;

    return AnimatedContainer(
      duration: duration,
      curve: AppMotion.enter,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadii.small,
        border: Border.all(
          color: isComplete
              ? AppPalette.leaf.withValues(alpha: 0.42)
              : AppPalette.nightDivider,
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: duration,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isComplete
                  ? AppPalette.leaf
                  : isActive
                      ? AppPalette.moonlight
                      : AppPalette.nightElevated,
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Icon(
              isComplete
                  ? Icons.check_rounded
                  : isActive
                      ? Icons.more_horiz_rounded
                      : Icons.remove_rounded,
              size: 17,
              color: isComplete || isActive
                  ? AppPalette.night
                  : AppPalette.moonMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypeNight.label.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
