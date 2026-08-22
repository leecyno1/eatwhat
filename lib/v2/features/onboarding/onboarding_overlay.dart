import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/themes/design_tokens.dart';
import 'onboarding_service.dart';

/// 手势引导步骤配置
class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final String gesturePath; // 手势动画路径

  const OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.gesturePath,
  });
}

/// 新手引导遮罩组件 - 使用 OverlayEntry 实现
class OnboardingOverlay {
  static final List<OnboardingStep> _steps = [
    const OnboardingStep(
      title: '点击选择',
      description: '点击气泡选择你喜欢的口味偏好',
      icon: CupertinoIcons.hand_point_right_fill,
      gesturePath: 'tap',
    ),
    const OnboardingStep(
      title: '长按收藏',
      description: '长按气泡将其添加到收藏夹',
      icon: CupertinoIcons.heart_fill,
      gesturePath: 'long_press',
    ),
    const OnboardingStep(
      title: '上滑喜欢',
      description: '向上滑动表示喜欢这个选择',
      icon: CupertinoIcons.arrow_up_circle_fill,
      gesturePath: 'swipe_up',
    ),
    const OnboardingStep(
      title: '下滑不喜欢',
      description: '向下滑动表示跳过这个选择',
      icon: CupertinoIcons.arrow_down_circle_fill,
      gesturePath: 'swipe_down',
    ),
  ];

  static OverlayEntry? _currentOverlay;

  /// 显示引导遮罩
  static void show(BuildContext context) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    showOn(overlay);
  }

  static void showOn(OverlayState overlay) {
    if (_currentOverlay != null) return;

    _currentOverlay = OverlayEntry(
      builder: (context) => OnboardingWidget(steps: _steps),
    );

    overlay.insert(_currentOverlay!);
  }

  /// 隐藏引导遮罩
  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

/// 新手引导组件
class OnboardingWidget extends StatefulWidget {
  final List<OnboardingStep> steps;

  const OnboardingWidget({
    super.key,
    required this.steps,
  });

  @override
  State<OnboardingWidget> createState() => _OnboardingWidgetState();
}

class _OnboardingWidgetState extends State<OnboardingWidget>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _iconAnimationController;
  late Animation<double> _iconAnimation;
  late AnimationController _handAnimationController;
  late Animation<double> _handAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // 图标动画控制器
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _iconAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _iconAnimationController.forward();

    // 手势动画控制器
    _handAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _handAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _handAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _handAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    _handAnimationController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    HapticFeedback.lightImpact();

    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _iconAnimationController.forward(from: 0.0);
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    HapticFeedback.lightImpact();
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await OnboardingService().markOnboardingAsSeen();
    OnboardingOverlay.hide();
  }

  Offset _getGestureOffset() {
    final step = widget.steps[_currentStep];
    switch (step.gesturePath) {
      case 'swipe_up':
        return Offset(0, -30 * _handAnimation.value);
      case 'swipe_down':
        return Offset(0, 30 * _handAnimation.value);
      default:
        return Offset.zero;
    }
  }

  Widget _buildGestureAnimation() {
    final step = widget.steps[_currentStep];

    return AnimatedBuilder(
      animation: _handAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: _getGestureOffset(),
          child: _buildHandWidget(step),
        );
      },
    );
  }

  Widget _buildHandWidget(OnboardingStep step) {
    const size = 80.0;

    switch (step.gesturePath) {
      case 'tap':
        return _buildTapGesture(size, step);
      case 'long_press':
        return _buildLongPressGesture(size, step);
      case 'swipe_up':
        return _buildSwipeUpGesture(size, step);
      case 'swipe_down':
        return _buildSwipeDownGesture(size, step);
      default:
        return _buildTapGesture(size, step);
    }
  }

  Widget _buildTapGesture(double size, OnboardingStep step) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 点击涟漪效果
          if (_handAnimation.value > 0.5)
            Container(
              width: size * 0.6 * _handAnimation.value,
              height: size * 0.6 * _handAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: DesignTokens.mint
                      .withValues(alpha: 1 - _handAnimation.value),
                  width: 2,
                ),
              ),
            ),
          Icon(
            step.icon,
            size: size * 0.8,
            color: DesignTokens.mint,
          ),
        ],
      ),
    );
  }

  Widget _buildLongPressGesture(double size, OnboardingStep step) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 长按指示器
          AnimatedBuilder(
            animation: _handAnimation,
            builder: (context, child) {
              final isActive = _handAnimation.value > 0.7;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? size * 0.9 : size * 0.7,
                height: isActive ? size * 0.9 : size * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? DesignTokens.pink.withValues(alpha: 0.3)
                      : DesignTokens.mint.withValues(alpha: 0.1),
                  border: Border.all(
                    color: isActive ? DesignTokens.pink : DesignTokens.mint,
                    width: 2,
                  ),
                ),
              );
            },
          ),
          Icon(
            step.icon,
            size: size * 0.6,
            color: DesignTokens.pink,
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeUpGesture(double size, OnboardingStep step) {
    return SizedBox(
      width: size,
      height: size * 1.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 滑动轨迹
          Positioned(
            top: 0,
            child: Container(
              width: 4,
              height: size * 0.6,
              decoration: BoxDecoration(
                color: DesignTokens.mint.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 向上箭头
          Positioned(
            top: _handAnimation.value * 20,
            child: Icon(
              step.icon,
              size: size * 0.6,
              color: DesignTokens.mint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeDownGesture(double size, OnboardingStep step) {
    return SizedBox(
      width: size,
      height: size * 1.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 滑动轨迹
          Positioned(
            bottom: 0,
            child: Container(
              width: 4,
              height: size * 0.6,
              decoration: BoxDecoration(
                color: DesignTokens.orange.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 向下箭头
          Positioned(
            bottom: _handAnimation.value * 20,
            child: Icon(
              step.icon,
              size: size * 0.6,
              color: DesignTokens.orange,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final step = widget.steps[_currentStep];

    // 计算高亮气泡位置（屏幕中央偏上位置模拟气泡）
    final bubbleCenter = Offset(
      screenSize.width / 2,
      screenSize.height * 0.35,
    );
    const bubbleRadius = 60.0;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 半透明黑色遮罩
          CustomPaint(
            size: screenSize,
            painter: _OnboardingMaskPainter(
              highlightCenter: bubbleCenter,
              highlightRadius: bubbleRadius,
            ),
          ),

          // 跳过按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: _skipOnboarding,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '跳过',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // 手势动画区域 - 位于气泡位置
          Positioned(
            left: bubbleCenter.dx - 40,
            top: bubbleCenter.dy - 40,
            child: _buildGestureAnimation(),
          ),

          // 文字说明区域 - 位于气泡下方
          Positioned(
            left: 0,
            right: 0,
            top: bubbleCenter.dy + bubbleRadius + 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题
                AnimatedBuilder(
                  animation: _iconAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _iconAnimation.value,
                      child: Text(
                        step.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // 描述
                Text(
                  step.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 下一步按钮
                GestureDetector(
                  onTap: _goToNextStep,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      color: DesignTokens.mint,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.mint.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _currentStep < widget.steps.length - 1 ? '下一步' : '开始使用',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 底部进度指示器
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.steps.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentStep ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _currentStep
                        ? DesignTokens.mint
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 自定义遮罩画笔 - 实现气泡高亮效果
class _OnboardingMaskPainter extends CustomPainter {
  final Offset highlightCenter;
  final double highlightRadius;

  _OnboardingMaskPainter({
    required this.highlightCenter,
    required this.highlightRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    // 创建路径 - 从外向内挖空圆形区域
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 创建圆形高亮区域路径
    final circlePath = Path()
      ..addOval(Rect.fromCircle(
        center: highlightCenter,
        radius: highlightRadius + 16, // 额外增加一些边距
      ));

    // 使用异或操作挖空圆形区域
    path.addPath(circlePath, Offset.zero);

    // 使用奇偶填充规则实现挖空效果
    path.fillType = PathFillType.evenOdd;

    // 绘制遮罩
    canvas.drawPath(path, paint);

    // 绘制高亮气泡边框
    final borderPaint = Paint()
      ..color = DesignTokens.mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(highlightCenter, highlightRadius + 8, borderPaint);

    // 绘制高亮边框发光效果
    final glowPaint = Paint()
      ..color = DesignTokens.mint.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(highlightCenter, highlightRadius + 8, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _OnboardingMaskPainter oldDelegate) {
    return oldDelegate.highlightCenter != highlightCenter ||
        oldDelegate.highlightRadius != highlightRadius;
  }
}
