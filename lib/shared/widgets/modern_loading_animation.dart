import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/glassmorphism_theme.dart';

/// 现代化加载动画组件
class ModernLoadingAnimation extends StatefulWidget {
  final double size;
  final Color? color;
  final String? message;
  final double progress;
  final bool showPercentage;

  const ModernLoadingAnimation({
    super.key,
    this.size = 60,
    this.color,
    this.message,
    this.progress = 0.0,
    this.showPercentage = false,
  });

  @override
  State<ModernLoadingAnimation> createState() => _ModernLoadingAnimationState();
}

class _ModernLoadingAnimationState extends State<ModernLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // 脉冲动画
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 旋转动画
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.progress > 0.0) {
      return _buildProgressAnimation();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLoadingAnimation(),
        if (widget.message != null) ...[
          SizedBox(height: 16.h),
          _buildMessageText(),
        ],
      ],
    );
  }

  Widget _buildLoadingAnimation() {
    return Transform.scale(
      scale: 0.8 + (_pulseAnimation.value * 0.2),
      child: Transform.rotate(
        angle: _rotationAnimation.value * 2 * 3.14159,
        child: Container(
          width: widget.size,
          height: widget.size,
          child: GlassmorphismTheme.glassContainer(
            child: Stack(
              children: [
                // 外圈
                _buildOuterRing(),

                // 内圈
                _buildInnerRing(),

                // 中心点
                _buildCenterDot(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOuterRing() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: (widget.color ?? GlassmorphismTheme.primaryGradients.first).withOpacity(0.3),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildInnerRing() {
    return Container(
      width: widget.size * 0.7,
      height: widget.size * 0.7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: (widget.color ?? GlassmorphismTheme.primaryGradients.first).withOpacity(0.6),
          width: 3,
        ),
      ),
    );
  }

  Widget _buildCenterDot() {
    return Center(
      child: Container(
        width: widget.size * 0.2,
        height: widget.size * 0.2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color ?? GlassmorphismTheme.primaryGradients.first,
          boxShadow: [
            BoxShadow(
              color: (widget.color ?? GlassmorphismTheme.primaryGradients.first).withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressAnimation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 进度条
        Container(
          width: 200.w,
          height: 8.h,
          child: GlassmorphismTheme.glassContainer(
            child: Stack(
              children: [
                // 背景
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.r),
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),

                // 进度条
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 200.w * widget.progress,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.r),
                        gradient: LinearGradient(
                          colors: [
                            (widget.color ?? GlassmorphismTheme.primaryGradients.first)
                                .withOpacity(0.8),
                            (widget.color ?? GlassmorphismTheme.primaryGradients.first)
                                .withOpacity(0.6 + (_pulseAnimation.value * 0.2)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // 百分比文本
        if (widget.showPercentage) ...[
          SizedBox(height: 8.h),
          Text(
            '${(widget.progress * 100).toInt()}%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],

        // 消息文本
        if (widget.message != null) ...[
          SizedBox(height: 16.h),
          GlassmorphismTheme.glassContainer(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Text(
              widget.message!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMessageText() {
    return GlassmorphismTheme.glassContainer(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Text(
        widget.message!,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
