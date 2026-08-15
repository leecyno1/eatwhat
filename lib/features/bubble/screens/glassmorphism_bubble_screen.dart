import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/bubble_controller.dart';
import '../../recommendation/screens/recommendation_screen.dart';
import '../widgets/glassmorphism_bubble_widget.dart';
import '../../../shared/widgets/modern_loading_animation.dart';
import '../../../core/theme/glassmorphism_theme.dart';

/// Glassmorphism风格气泡主界面
class GlassmorphismBubbleScreen extends StatefulWidget {
  const GlassmorphismBubbleScreen({super.key});

  @override
  State<GlassmorphismBubbleScreen> createState() => _GlassmorphismBubbleScreenState();
}

class _GlassmorphismBubbleScreenState extends State<GlassmorphismBubbleScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _particleController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _particleAnimation;

  bool _showParticles = true;
  bool _enableHapticFeedback = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // 延迟初始化控制器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<BubbleController>();
      final size = MediaQuery.of(context).size;
      controller.initialize(screenSize: size);
    });
  }

  void _initializeAnimations() {
    // 背景动画
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    // 粒子动画
    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeInOut,
    ));

    _backgroundController.repeat(reverse: true);
    _particleController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 动画背景
          _buildAnimatedBackground(),

          // 粒子效果
          if (_showParticles) _buildParticleEffect(),

          // 主内容
          _buildMainContent(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return GlassmorphismTheme.animatedGradientBackground(
          gradientSets: [
            GlassmorphismTheme.primaryGradients,
            GlassmorphismTheme.secondaryGradients,
            GlassmorphismTheme.accentGradients,
            GlassmorphismTheme.warmGradients,
          ],
          duration: const Duration(seconds: 15),
          child: Container(),
        );
      },
    );
  }

  Widget _buildParticleEffect() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particleAnimation.value),
          child: Container(),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildBubbleArea(),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<BubbleController>(
      builder: (context, controller, child) {
        return GlassmorphismTheme.floatingCard(
          margin: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // 标题
              Text(
                '吃什么',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),

              // 状态文本
              Text(
                controller.selectedCount > 0
                    ? '已选择 ${controller.selectedCount} 个口味'
                    : '点击气泡选择你的口味偏好',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),

              if (controller.selectedCount > 0) ...[
                SizedBox(height: 8.h),
                Text(
                  '左滑不喜欢，右滑喜欢，点击选择',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBubbleArea() {
    return Consumer<BubbleController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(
            child: ModernLoadingAnimation(),
          );
        }

        if (!controller.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Stack(
          children: [
            // 气泡网格
            _buildBubbleGrid(controller),

            // 选择指示器
            if (controller.selectedCount > 0) _buildSelectionIndicator(controller),
          ],
        );
      },
    );
  }

  Widget _buildBubbleGrid(BubbleController controller) {
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
      ),
      itemCount: controller.bubbles.length,
      itemBuilder: (context, index) {
        final bubble = controller.bubbles[index];
        final isSelected = controller.selectedBubbles.contains(bubble);

        return GlassmorphismBubbleWidget(
          bubble: bubble,
          isSelected: isSelected,
          gradientIndex: index,
          enableHapticFeedback: _enableHapticFeedback,
          onTap: () {
            controller.toggleBubble(bubble);
            if (_enableHapticFeedback) {
              HapticFeedback.lightImpact();
            }
          },
          onSwipeLeft: () {
            controller.markBubbleAsDisliked(bubble);
            if (_enableHapticFeedback) {
              HapticFeedback.mediumImpact();
            }
          },
          onSwipeRight: () {
            controller.markBubbleAsLiked(bubble);
            if (_enableHapticFeedback) {
              HapticFeedback.mediumImpact();
            }
          },
        );
      },
    );
  }

  Widget _buildSelectionIndicator(BubbleController controller) {
    return Positioned(
      top: 20.h,
      right: 20.w,
      child: GlassmorphismTheme.glassContainer(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              '${controller.selectedCount}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Consumer<BubbleController>(
      builder: (context, controller, child) {
        return GlassmorphismTheme.floatingCard(
          margin: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // 控制按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 重置按钮
                  _buildControlButton(
                    icon: Icons.refresh,
                    label: '重置',
                    onTap: () {
                      controller.resetSelection();
                      if (_enableHapticFeedback) {
                        HapticFeedback.mediumImpact();
                      }
                    },
                  ),

                  // 推荐按钮
                  _buildControlButton(
                    icon: Icons.restaurant,
                    label: '推荐',
                    isPrimary: true,
                    onTap: controller.selectedCount > 0
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RecommendationScreen(),
                              ),
                            );
                            if (_enableHapticFeedback) {
                              HapticFeedback.heavyImpact();
                            }
                          }
                        : null,
                  ),

                  // 设置按钮
                  _buildControlButton(
                    icon: Icons.settings,
                    label: '设置',
                    onTap: () {
                      _showSettingsDialog();
                    },
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // 功能开关
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildToggleButton(
                    icon: Icons.auto_awesome,
                    label: '粒子效果',
                    value: _showParticles,
                    onChanged: (value) {
                      setState(() {
                        _showParticles = value;
                      });
                    },
                  ),
                  _buildToggleButton(
                    icon: Icons.vibration,
                    label: '触觉反馈',
                    value: _enableHapticFeedback,
                    onChanged: (value) {
                      setState(() {
                        _enableHapticFeedback = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphismTheme.glassContainer(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : Colors.white.withOpacity(0.8),
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : Colors.white.withOpacity(0.8),
                fontSize: 12.sp,
                fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: GlassmorphismTheme.glassContainer(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: value ? Colors.white : Colors.white.withOpacity(0.6),
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: value ? Colors.white : Colors.white.withOpacity(0.6),
                fontSize: 12.sp,
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              width: 32.w,
              height: 16.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: value ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
              ),
              child: AnimatedAlign(
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 12.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => GlassmorphismTheme.glassContainer(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '设置',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),

            // 设置选项
            _buildSettingItem(
              icon: Icons.auto_awesome,
              title: '粒子效果',
              subtitle: '显示背景粒子动画',
              value: _showParticles,
              onChanged: (value) {
                setState(() {
                  _showParticles = value;
                });
              },
            ),

            SizedBox(height: 12.h),

            _buildSettingItem(
              icon: Icons.vibration,
              title: '触觉反馈',
              subtitle: '交互时提供触觉反馈',
              value: _enableHapticFeedback,
              onChanged: (value) {
                setState(() {
                  _enableHapticFeedback = value;
                });
              },
            ),

            SizedBox(height: 20.h),

            // 关闭按钮
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: GlassmorphismTheme.glassContainer(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                child: Text(
                  '关闭',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.8),
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40.w,
            height: 20.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              color: value ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
            ),
            child: AnimatedAlign(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 16.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 粒子效果绘制器
class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // 绘制多个粒子
    for (int i = 0; i < 20; i++) {
      final x = (i * 37) % size.width;
      final y = (i * 73 + animationValue * 100) % size.height;

      canvas.drawCircle(
        Offset(x, y),
        2 + (i % 3) * 1.0,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
