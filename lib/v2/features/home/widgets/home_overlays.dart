import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class HomeVoiceStageOverlay extends StatelessWidget {
  const HomeVoiceStageOverlay({
    super.key,
    required this.transcript,
  });

  final String transcript;

  @override
  Widget build(BuildContext context) {
    final text = transcript.trim();
    return ColoredBox(
      key: const ValueKey('taste-voice-stage-overlay'),
      color: AppPalette.surface.withValues(alpha: 0.96),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: AppDecorations.card(radius: AppRadii.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppPalette.positiveSurface,
                  borderRadius: AppRadii.small,
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: AppPalette.garden,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('正在听你说', style: AppType.section),
              const SizedBox(height: AppSpacing.xs),
              Text(
                text.isEmpty ? '可以说想吃什么、预算、人数或不想吃的东西。' : text,
                textAlign: TextAlign.center,
                style: AppType.body,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '松手后写回输入框',
                style: AppType.microLabel.copyWith(color: AppPalette.garden),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeGenerationTransitionOverlay extends StatelessWidget {
  const HomeGenerationTransitionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: ColoredBox(
        key: const ValueKey('generation-transition-overlay'),
        color: AppPalette.canvas.withValues(alpha: 0.96),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: AppDecorations.card(radius: AppRadii.lg),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppPalette.garden,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                Text('正在准备推荐', style: AppType.section),
                SizedBox(height: AppSpacing.xs),
                Text(
                  '马上为你整理成一道菜或一顿饭。',
                  textAlign: TextAlign.center,
                  style: AppType.body,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeFirstUseGuideCard extends StatelessWidget {
  const HomeFirstUseGuideCard({
    super.key,
    required this.onDismiss,
  });

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecorations.card(radius: AppRadii.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('选出今天想吃的方向', style: AppType.title),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '点一下或上滑表示喜欢，下滑加入拉黑；拖动食材还能抛进这个口味餐盘。',
            style: AppType.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('home-guide-dismiss-button'),
              onPressed: onDismiss,
              child: const Text('开始选择'),
            ),
          ),
        ],
      ),
    );
  }
}
