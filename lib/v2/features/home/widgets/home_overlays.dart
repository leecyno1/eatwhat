import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class HomeVoiceStageOverlay extends StatefulWidget {
  const HomeVoiceStageOverlay({
    super.key,
    required this.transcript,
  });

  final String transcript;

  @override
  State<HomeVoiceStageOverlay> createState() => _HomeVoiceStageOverlayState();
}

class _HomeVoiceStageOverlayState extends State<HomeVoiceStageOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transcript = widget.transcript.trim();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = Curves.easeInOut.transform(_controller.value);
        return Container(
          key: const ValueKey('taste-voice-stage-overlay'),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 0.92,
              colors: [
                Colors.white.withValues(alpha: 0.18 + pulse * 0.08),
                const Color(0xFFF8D6C9).withValues(alpha: 0.16),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 150 + pulse * 16,
                      height: 150 + pulse * 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF46B40)
                              .withValues(alpha: 0.16 + pulse * 0.14),
                        ),
                      ),
                    ),
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.94),
                            const Color(0xFFF46B40)
                                .withValues(alpha: 0.18 + pulse * 0.08),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF46B40)
                                .withValues(alpha: 0.16 + pulse * 0.12),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.mic_rounded,
                          size: 24,
                          color: Color(0xFFF46B40),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            final height = 8 +
                                ((pulse + index * 0.17) % 1) *
                                    (index.isEven ? 18 : 12);
                            return Container(
                              margin:
                                  EdgeInsets.only(right: index == 4 ? 0 : 4),
                              width: 4,
                              height: height,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: const Color(0xFFF46B40)
                                    .withValues(alpha: 0.9 - index * 0.08),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  '正在采集你的口味描述',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.56),
                    ),
                  ),
                  child: Text(
                    transcript.isEmpty ? '继续说，比如想吃热的、带锅气、别太甜。' : transcript,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.74),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return AbsorbPointer(
          child: Container(
            key: const ValueKey('generation-transition-overlay'),
            color: const Color(0x18FFF6F2),
            child: Center(
              child: Opacity(
                opacity: fade.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFF46B40).withValues(alpha: 0.22),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFF46B40)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '正在整理口味',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '正在交给 AI 生成菜单，随后补全图片和做法。',
                      style: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.58),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xE6FFFFFF),
              Color(0xD9FFF4EE),
              Color(0xD9FFE0D2),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.84),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x331A120E),
              blurRadius: 32,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '第一次使用，先这样玩',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '上滑表示喜欢，下滑表示不要，左右表示先略过。补一句今天想吃的，会和你滑出来的口味签名一起进入 AI 推理。',
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.74),
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onDismiss,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF45B33),
                  foregroundColor: Colors.white,
                ),
                child: const Text('知道了'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeFavoritesButton extends StatelessWidget {
  const HomeFavoritesButton({
    super.key,
    required this.onTap,
    this.compact = false,
  });

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 9 : 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xE6F45B33),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33F45B33),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 18,
              ),
              if (!compact) ...[
                const SizedBox(width: 8),
                const Text(
                  '偏爱档案',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
