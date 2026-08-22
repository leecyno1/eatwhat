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
      color: AppPalette.night.withValues(alpha: 0.96),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: AppDecorations.nightCard(radius: AppRadii.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppPalette.nightElevated,
                  borderRadius: AppRadii.small,
                ),
                child: Icon(
                  Icons.mic_rounded,
                  color: AppPalette.leaf,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('正在听你说', style: AppTypeNight.section),
              const SizedBox(height: AppSpacing.xs),
              Text(
                text.isEmpty ? '可以说想吃什么、预算、人数或不想吃的东西。' : text,
                textAlign: TextAlign.center,
                style: AppTypeNight.body,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '松手后写回输入框',
                style: AppTypeNight.microLabel.copyWith(color: AppPalette.leaf),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Generation transition as a gold-steamed kitchen beat: a breathing pot
/// mark ringed by a rotating gold arc, staged copy that reads like a chef
/// at work. Replaces the bare spinner so waiting feels authored, not idle.
class HomeGenerationTransitionOverlay extends StatefulWidget {
  const HomeGenerationTransitionOverlay({super.key});

  @override
  State<HomeGenerationTransitionOverlay> createState() =>
      _HomeGenerationTransitionOverlayState();
}

class _HomeGenerationTransitionOverlayState
    extends State<HomeGenerationTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _lineIndex = 0;

  static const _lines = [
    '主厨正在看今天的锅气',
    '正在替你过一遍菜库',
    '快收束成一口了',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _controller.addListener(() {
      final next = (_controller.value * _lines.length).floor() % _lines.length;
      if (next != _lineIndex) {
        setState(() => _lineIndex = next);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: ColoredBox(
        key: const ValueKey('generation-transition-overlay'),
        color: GoldPalette.nightDeep.withValues(alpha: 0.97),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final breathe =
                      1 + 0.06 * (1 - (_controller.value * 2 - 1).abs());
                  return Transform.scale(
                    scale: breathe,
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: GoldPalette.goldHairline,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 88,
                            height: 88,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.6,
                              strokeCap: StrokeCap.round,
                              valueColor: const AlwaysStoppedAnimation(
                                GoldPalette.gold,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.dinner_dining_rounded,
                            size: 30,
                            color: GoldPalette.gold,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                '正在为你点菜',
                style: TextStyle(
                  color: GoldPalette.creamText,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AnimatedSwitcher(
                duration: AppMotion.fast,
                child: Text(
                  _lines[_lineIndex],
                  key: ValueKey(_lineIndex),
                  style: const TextStyle(
                    color: GoldPalette.goldSoft,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
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
      decoration: AppDecorations.nightCard(radius: AppRadii.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('选出今天想吃的方向', style: AppTypeNight.title),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '点一下收下；按住抓起，拖到顶部收下、底部拉黑；摇一摇翻一翻锅。',
            style: AppTypeNight.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('home-guide-dismiss-button'),
              onPressed: onDismiss,
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.leaf,
                foregroundColor: AppPalette.night,
              ),
              child: const Text('开始选择'),
            ),
          ),
        ],
      ),
    );
  }
}
