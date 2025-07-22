import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

/// 加载动画类型枚举
enum LoadingAnimationType {
  bubbles,
  wave,
  pulse,
  rotation,
  morphing,
  particles,
}

/// 现代化加载动画组件
class ModernLoadingAnimation extends StatelessWidget {
  final LoadingAnimationType type;
  final Color color;
  final double size;
  final String? message;
  final bool showMessage;

  const ModernLoadingAnimation({
    super.key,
    this.type = LoadingAnimationType.bubbles,
    this.color = Colors.blue,
    this.size = 50,
    this.message,
    this.showMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: _buildLoadingAnimation(),
          ),
          if (showMessage) ...[
            const SizedBox(height: 16),
            Text(
              message ?? '加载中...',
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(duration: 800.ms)
                .then(delay: 200.ms)
                .fadeOut(duration: 800.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    switch (type) {
      case LoadingAnimationType.bubbles:
        return _BubbleLoadingAnimation(color: color);
      case LoadingAnimationType.wave:
        return _WaveLoadingAnimation(color: color);
      case LoadingAnimationType.pulse:
        return _PulseLoadingAnimation(color: color);
      case LoadingAnimationType.rotation:
        return _RotationLoadingAnimation(color: color);
      case LoadingAnimationType.morphing:
        return _MorphingLoadingAnimation(color: color);
      case LoadingAnimationType.particles:
        return _ParticleLoadingAnimation(color: color);
    }
  }
}

/// 气泡加载动画
class _BubbleLoadingAnimation extends StatelessWidget {
  final Color color;

  const _BubbleLoadingAnimation({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .scaleY(
              begin: 0.5,
              end: 1.5,
              duration: 600.ms,
              delay: Duration(milliseconds: index * 200),
              curve: Curves.easeInOut,
            )
            .then()
            .scaleY(
              begin: 1.5,
              end: 0.5,
              duration: 600.ms,
              curve: Curves.easeInOut,
            );
      }),
    );
  }
}

/// 波浪加载动画
class _WaveLoadingAnimation extends StatelessWidget {
  final Color color;

  const _WaveLoadingAnimation({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        return Container(
          width: 4,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .scaleY(
              begin: 0.3,
              end: 1.0,
              duration: 800.ms,
              delay: Duration(milliseconds: index * 100),
              curve: Curves.easeInOut,
            )
            .then()
            .scaleY(
              begin: 1.0,
              end: 0.3,
              duration: 800.ms,
              curve: Curves.easeInOut,
            );
      }),
    );
  }
}

/// 脉冲加载动画
class _PulseLoadingAnimation extends StatelessWidget {
  final Color color;

  const _PulseLoadingAnimation({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: List.generate(3, (index) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3 - index * 0.1),
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.5, 1.5),
              duration: 1200.ms,
              delay: Duration(milliseconds: index * 400),
              curve: Curves.easeOut,
            )
            .fadeOut(
              begin: 0.8,
              duration: 1200.ms,
              delay: Duration(milliseconds: index * 400),
            );
      }),
    );
  }
}

/// 旋转加载动画
class _RotationLoadingAnimation extends StatelessWidget {
  final Color color;

  const _RotationLoadingAnimation({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 外圈
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 3,
            ),
          ),
        ),
        // 旋转弧
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 1000.ms),
      ],
    );
  }
}

/// 形变加载动画
class _MorphingLoadingAnimation extends StatelessWidget {
  final Color color;

  const _MorphingLoadingAnimation({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .custom(
          duration: 2000.ms,
          builder: (context, value, child) {
            double borderRadius;
            if (value < 0.25) {
              // 圆形到方形
              borderRadius = 20 * (1 - value * 4);
            } else if (value < 0.5) {
              // 方形到菱形
              borderRadius = 0;
            } else if (value < 0.75) {
              // 菱形到方形
              borderRadius = 0;
            } else {
              // 方形到圆形
              borderRadius = 20 * ((value - 0.75) * 4);
            }

            return Transform.rotate(
              angle: value * 2 * math.pi,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
            );
          },
        );
  }
}

/// 粒子加载动画
class _ParticleLoadingAnimation extends StatelessWidget {
  final Color color;

  const _ParticleLoadingAnimation({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: List.generate(8, (index) {
        final angle = (index * math.pi * 2) / 8;
        final x = math.cos(angle) * 15;
        final y = math.sin(angle) * 15;

        return Transform.translate(
          offset: Offset(x, y),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .scale(
              begin: const Offset(0.3, 0.3),
              end: const Offset(1.0, 1.0),
              duration: 800.ms,
              delay: Duration(milliseconds: index * 100),
              curve: Curves.easeOut,
            )
            .then()
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(0.3, 0.3),
              duration: 800.ms,
              curve: Curves.easeIn,
            );
      }),
    );
  }
}

/// 食物推荐专用加载动画
class FoodRecommendationLoading extends StatelessWidget {
  final String? message;

  const FoodRecommendationLoading({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 餐具动画
        Stack(
          alignment: Alignment.center,
          children: [
            // 盘子
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                ),
              ),
            ),
            // 叉子
            Transform.rotate(
              angle: -math.pi / 4,
              child: Icon(
                Icons.restaurant,
                size: 30,
                color: Colors.grey[600],
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .rotate(
                  begin: 0,
                  end: 1,
                  duration: 2000.ms,
                ),
          ],
        )
            .animate(onPlay: (controller) => controller.repeat())
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.1, 1.1),
              duration: 1500.ms,
              curve: Curves.easeInOut,
            )
            .then()
            .scale(
              begin: const Offset(1.1, 1.1),
              end: const Offset(0.9, 0.9),
              duration: 1500.ms,
              curve: Curves.easeInOut,
            ),
        
        const SizedBox(height: 16),
        
        Text(
          message ?? 'AI正在为您精心挑选美食...',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        )
            .animate(onPlay: (controller) => controller.repeat())
            .fadeIn(duration: 1000.ms)
            .then(delay: 500.ms)
            .fadeOut(duration: 1000.ms),
      ],
    );
  }
}

/// 全屏加载遮罩
class FullScreenLoadingOverlay extends StatelessWidget {
  final LoadingAnimationType type;
  final Color backgroundColor;
  final Color loadingColor;
  final String? message;
  final bool isVisible;

  const FullScreenLoadingOverlay({
    super.key,
    this.type = LoadingAnimationType.bubbles,
    this.backgroundColor = Colors.black54,
    this.loadingColor = Colors.white,
    this.message,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: isVisible
          ? Container(
              color: backgroundColor,
              child: ModernLoadingAnimation(
                type: type,
                color: loadingColor,
                message: message,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// 按钮加载状态
class LoadingButton extends StatelessWidget {
  final String text;
  final String loadingText;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final LoadingAnimationType loadingType;

  const LoadingButton({
    super.key,
    required this.text,
    this.loadingText = '请稍候...',
    required this.isLoading,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.loadingType = LoadingAnimationType.bubbles,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: ModernLoadingAnimation(
                      type: loadingType,
                      color: textColor ?? Colors.white,
                      size: 16,
                      showMessage: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(loadingText),
                ],
              )
            : Text(text),
      ),
    );
  }
} 