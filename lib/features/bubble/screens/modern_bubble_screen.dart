import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:provider/provider.dart';

import '../controllers/bubble_controller.dart';
import '../widgets/modern_bubble_widget.dart';
import '../../recommendation/screens/recommendation_screen.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../shared/widgets/modern_loading_animation.dart';

/// 现代化气泡界面 - iPhone风格设计
class ModernBubbleScreen extends StatefulWidget {
  const ModernBubbleScreen({super.key});

  @override
  State<ModernBubbleScreen> createState() => _ModernBubbleScreenState();
}

class _ModernBubbleScreenState extends State<ModernBubbleScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;
  late Animation<Color?> _backgroundAnimation;

  @override
  void initState() {
    super.initState();

    // 背景渐变动画
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _backgroundAnimation = ColorTween(
      begin: const Color(0xFFF8F9FA),
      end: const Color(0xFFE8F4FD),
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    // 头部动画
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.elasticOut,
    ));

    _backgroundController.repeat(reverse: true);
    _headerController.forward();

    // 初始化气泡控制器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final controller = context.read<BubbleController>();
        controller.initialize(screenSize: MediaQuery.of(context).size);
      } catch (e) {
        debugPrint('BubbleController initialization error: $e');
      }
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _backgroundAnimation.value ?? const Color(0xFFF8F9FA),
                  const Color(0xFFFFFFFF),
                  const Color(0xFFF0F8FF),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildModernHeader(),
                  Expanded(
                    child: _buildBubbleArea(),
                  ),
                  _buildBottomControls(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 现代化头部设计
  Widget _buildModernHeader() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _headerAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: Column(
              children: [
                // 主标题
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Column(
                    children: [
                      Text(
                        '🍽️ 今天吃什么',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          background: Paint()
                            ..shader = const LinearGradient(
                              colors: ModernTheme.primaryGradient,
                            ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '选择您的口味偏好，我们为您推荐美食',
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // 选择状态指示器
                Consumer<BubbleController>(
                  builder: (context, controller, child) {
                    return AnimationConfiguration.staggeredList(
                      position: 0,
                      duration: const Duration(milliseconds: 600),
                      child: SlideAnimation(
                        verticalOffset: -50,
                        child: FadeInAnimation(
                          child: GlassmorphicContainer(
                            width: double.infinity,
                            height: 60.h,
                            borderRadius: 20.r,
                            blur: 20,
                            alignment: Alignment.center,
                            border: 2,
                            linearGradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.2),
                                Colors.white.withValues(alpha: 0.1),
                              ],
                            ),
                            borderGradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.3),
                                Colors.white.withValues(alpha: 0.1),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatusItem(
                                  icon: CupertinoIcons.hand_raised,
                                  label: '已选择',
                                  value: '${controller.selectedCount}',
                                  color: ModernTheme.accentColor,
                                ),
                                Container(
                                  width: 1.w,
                                  height: 30.h,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                _buildStatusItem(
                                  icon: CupertinoIcons.sparkles,
                                  label: '可选择',
                                  value: '${controller.bubbles.length}',
                                  color: ModernTheme.primaryColor,
                                ),
                                Container(
                                  width: 1.w,
                                  height: 30.h,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                _buildStatusItem(
                                  icon: CupertinoIcons.heart_fill,
                                  label: '推荐度',
                                  value:
                                      '${controller.bubbles.isNotEmpty ? ((controller.selectedCount / controller.bubbles.length) * 100).toInt() : 0}%',
                                  color: ModernTheme.warningColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 18.sp,
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 现代化气泡区域
  Widget _buildBubbleArea() {
    return Consumer<BubbleController>(
      builder: (context, controller, child) {
        if (!controller.isInitialized) {
          return const Center(
            child: ModernLoadingAnimation(
              color: ModernTheme.primaryColor,
              message: '正在准备您的专属口味气泡...',
            ),
          );
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          child: AnimationLimiter(
            child: Stack(
              children: [
                // 背景装饰
                Positioned.fill(
                  child: CustomPaint(
                    painter: BubbleBackgroundPainter(),
                  ),
                ),

                // 手势检测区域
                GestureDetector(
                  onTapDown: (details) {
                    HapticFeedback.lightImpact();
                    controller.repelBubblesFromPosition(
                      details.localPosition,
                      80.0,
                    );
                  },
                  onPanUpdate: (details) {
                    controller.repelBubblesFromPosition(
                      details.localPosition,
                      60.0,
                    );
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Stack(
                      children: controller.bubbles.asMap().entries.map((entry) {
                        final index = entry.key;
                        final bubble = entry.value;

                        return Positioned(
                          left: bubble.position.dx - bubble.size / 2,
                          top: bubble.position.dy - bubble.size / 2,
                          child: AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 800),
                            child: ScaleAnimation(
                              scale: 0.8,
                              child: FadeInAnimation(
                                child: ModernBubbleWidget(
                                  bubble: bubble,
                                  isSelected: controller.isBubbleSelected(bubble),
                                  gradientIndex: index,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    controller.toggleBubble(bubble);
                                  },
                                  onSwipeUp: () {
                                    HapticFeedback.mediumImpact();
                                    controller.likeBubbleByName(bubble.name);
                                  },
                                  onSwipeDown: () {
                                    HapticFeedback.heavyImpact();
                                    controller.dislikeBubbleByName(bubble.name);
                                  },
                                  onSwipeLeft: () {
                                    HapticFeedback.lightImpact();
                                    controller.ignoreBubbleByName(bubble.name);
                                  },
                                  onSwipeRight: () {
                                    HapticFeedback.mediumImpact();
                                    controller.confirmBubbleByName(bubble.name);
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // 提示文字
                if (controller.selectedCount == 0)
                  Positioned(
                    bottom: 100.h,
                    left: 0,
                    right: 0,
                    child: AnimationConfiguration.synchronized(
                      duration: const Duration(milliseconds: 1000),
                      child: FadeInAnimation(
                        child: SlideAnimation(
                          verticalOffset: 30,
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                '🫧 点击气泡选择您的偏好\n👆 上滑喜欢 👇 下滑不喜欢',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
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

  /// 现代化底部控制区域
  Widget _buildBottomControls() {
    return Consumer<BubbleController>(
      builder: (context, controller, child) {
        return Container(
          margin: EdgeInsets.all(20.w),
          child: AnimationConfiguration.synchronized(
            duration: const Duration(milliseconds: 800),
            child: SlideAnimation(
              verticalOffset: 50,
              child: FadeInAnimation(
                child: GlassmorphicContainer(
                  width: double.infinity,
                  height: 120.h,
                  borderRadius: 24.r,
                  blur: 20,
                  alignment: Alignment.center,
                  border: 2,
                  linearGradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                  ),
                  borderGradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.4),
                      Colors.white.withValues(alpha: 0.2),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      children: [
                        // 生成推荐按钮
                        SizedBox(
                          width: double.infinity,
                          height: 50.h,
                          child: ElevatedButton(
                            onPressed: controller.selectedCount > 0
                                ? () async {
                                    HapticFeedback.heavyImpact();
                                    await controller.generateRecommendations();
                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (context) => const RecommendationScreen(),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: controller.selectedCount > 0
                                  ? ModernTheme.primaryColor
                                  : Colors.grey[300],
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: ModernTheme.primaryColor.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                            child: controller.isGeneratingRecommendations
                                ? SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(CupertinoIcons.sparkles),
                                      SizedBox(width: 8.w),
                                      Text(
                                        controller.selectedCount > 0
                                            ? '为我推荐美食 (${controller.selectedCount}个偏好)'
                                            : '请先选择您的偏好',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        SizedBox(height: 8.h),

                        // 重置按钮
                        if (controller.selectedCount > 0)
                          TextButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              controller.clearSelection();
                            },
                            child: Text(
                              '重新选择',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 背景装饰画笔
class BubbleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // 绘制装饰圆圈
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      80,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      60,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.6, size.height * 0.2),
      40,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
