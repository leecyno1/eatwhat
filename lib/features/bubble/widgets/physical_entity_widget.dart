import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../../../core/models/physical_entity.dart';
import '../../../core/utils/performance_optimizer.dart';

/// 物理实体组件 - 显示具有物理属性的实体替代气泡
/// 性能优化：
/// - RepaintBoundary 减少重绘区域
/// - 帧渲染监控接入
class PhysicalEntityWidget extends StatefulWidget {
  final PhysicalEntity entity;
  final bool isSelected;
  // 是否启用动态环境/空闲动画（性能开关）
  final bool enableDynamicAnimations;
  final VoidCallback? onTap;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onLongPress;

  const PhysicalEntityWidget({
    super.key,
    required this.entity,
    this.isSelected = false,
    this.enableDynamicAnimations = true,
    this.onTap,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onLongPress,
  });

  @override
  State<PhysicalEntityWidget> createState() => _PhysicalEntityWidgetState();
}

class _PhysicalEntityWidgetState extends State<PhysicalEntityWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _dragController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _dragAnimation;

  Offset? _panStart;
  Offset _dragOffset = Offset.zero;
  bool _isPanning = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    // 缩放动画 - 点击反馈
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // 发光动画 - 选中状态
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // 脉冲动画 - 高亮状态
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 拖拽动画 - 平滑移动到目标位置
    _dragController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _dragAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _dragController,
      curve: Curves.easeOutBack,
    ));

    // 暂时禁用所有重复动画以解决乱窜问题
    /*
    if (widget.isSelected) {
      _glowController.repeat(reverse: true);
    }

    if (widget.entity.isHighlighted) {
      _pulseController.repeat(reverse: true);
    }
    */

    // 注册到性能优化器
    PerformanceOptimizer().registerAnimatedWidget();
  }

  @override
  void didUpdateWidget(PhysicalEntityWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 选中状态变化
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _glowController.repeat(reverse: true);
      } else {
        _glowController.stop();
        _glowController.reset();
      }
    }

    // 高亮状态变化
    if (widget.entity.isHighlighted != oldWidget.entity.isHighlighted) {
      if (widget.entity.isHighlighted) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    _dragController.dispose();
    // 从性能优化器注销
    PerformanceOptimizer().unregisterAnimatedWidget();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge(
            [_scaleAnimation, _glowAnimation, _pulseAnimation, _dragAnimation]),
        builder: (context, child) {
          return Transform.translate(
          offset: _isDragging ? _dragOffset : _dragAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: 0.0,
              child: Opacity(
                opacity: widget.entity.opacity,
                child: GestureDetector(
                  onTapDown: (_) {
                    _scaleController.forward();
                    HapticFeedback.lightImpact();
                  },
                  onTapUp: (_) {
                    _scaleController.reverse();
                    widget.onTap?.call();
                  },
                  onTapCancel: () {
                    _scaleController.reverse();
                  },
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    widget.onLongPress?.call();
                  },
                  onPanStart: (details) {
                    _panStart = details.localPosition;
                    _isPanning = true;
                    _isDragging = true;
                    _dragOffset = Offset.zero;
                  },
                  onPanUpdate: (details) {
                    if (_isDragging && _panStart != null) {
                      setState(() {
                        _dragOffset = details.localPosition - _panStart!;
                      });
                    }
                  },
                  onPanEnd: (details) {
                    if (_panStart == null || !_isPanning) return;

                    _isPanning = false;
                    _isDragging = false;
                    final velocity = details.velocity.pixelsPerSecond;
                    const threshold = 100.0;

                    if (velocity.dx.abs() > velocity.dy.abs()) {
                      // 水平滑动
                      if (velocity.dx > threshold) {
                        _animateToTarget(Offset(200, 0), () {
                          HapticFeedback.lightImpact();
                          widget.onSwipeRight?.call();
                        });
                      } else if (velocity.dx < -threshold) {
                        _animateToTarget(Offset(-200, 0), () {
                          HapticFeedback.lightImpact();
                          widget.onSwipeLeft?.call();
                        });
                      } else {
                        _resetPosition();
                      }
                    } else {
                      // 垂直滑动 - 优化喜欢/不喜欢的交互
                      if (velocity.dy < -threshold) {
                        // 上滑 = 喜欢，移动到顶部
                        _animateToTopAndLike();
                      } else if (velocity.dy > threshold) {
                        // 下滑 = 不喜欢，移动到底部并消失
                        _animateToBottomAndDislike();
                      } else {
                        _resetPosition();
                      }
                    }

                    _panStart = null;
                  },
                  onPanCancel: () {
                    _isPanning = false;
                    _isDragging = false;
                    _panStart = null;
                    _resetPosition();
                  },
                  child: SizedBox(
                    width: widget.entity.radius * 2,
                    height: widget.entity.radius * 2,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 选中状态的玻璃质感外发光效果
                        if (widget.isSelected)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  // 外层柔和光晕
                                  BoxShadow(
                                    color: widget.entity.primaryColor
                                        .withValues(alpha: 0.2),
                                    blurRadius: 35.0,
                                    spreadRadius: 12.0,
                                  ),
                                  // 中层彩色光环
                                  BoxShadow(
                                    color: widget.entity.secondaryColor
                                        .withValues(alpha: 0.25),
                                    blurRadius: 20.0,
                                    spreadRadius: 6.0,
                                  ),
                                  // 内层白色光晕 - 玻璃反射
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    blurRadius: 15.0,
                                    spreadRadius: 3.0,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // 主实体容器 - 玻璃质感圆形
                        Container(
                          width: widget.entity.radius * 2,
                          height: widget.entity.radius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // 玻璃质感渐变 - 增加透明度
                            gradient: RadialGradient(
                              center: const Alignment(-0.3, -0.3), // 偏移高光位置
                              colors: [
                                Colors.white.withValues(alpha: 0.3), // 顶部高光
                                widget.entity.primaryColor
                                    .withValues(alpha: 0.2), // 主色透明
                                widget.entity.secondaryColor
                                    .withValues(alpha: 0.15), // 辅色更透明
                                widget.entity.primaryColor
                                    .withValues(alpha: 0.1), // 边缘极透明
                              ],
                              stops: const [0.0, 0.3, 0.7, 1.0],
                            ),
                            // 柔和的阴影效果
                            boxShadow: [
                              // 主阴影 - 减弱
                              BoxShadow(
                                color: widget.entity.primaryColor
                                    .withValues(alpha: 0.15),
                                blurRadius: widget.isSelected ? 25 : 15,
                                spreadRadius: widget.isSelected ? 2 : 1,
                                offset: const Offset(0, 8),
                              ),
                              // 内部发光 - 玻璃质感
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: -4,
                                offset: const Offset(-3, -6),
                              ),
                              // 底部微弱阴影
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              // 玻璃边缘效果 - 非常微弱的边界
                              border: Border.all(
                                color: widget.isSelected
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : Colors.white.withValues(alpha: 0.2),
                                width: widget.isSelected ? 2 : 1,
                              ),
                              // 内部玻璃高光
                              gradient: RadialGradient(
                                center: const Alignment(-0.4, -0.4),
                                radius: 0.6,
                                colors: [
                                  Colors.white.withValues(alpha: 0.2),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: _buildEntityContent(),
                          ),
                        ),

                        // 物理属性指示器 (调试用，可选) - 移除选中状态指示器
                        if (widget.entity.kineticEnergy > 100)
                          Positioned(
                            bottom: -8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '⚡',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
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
    ),
    );
  }

  /// 动画移动到目标位置
  void _animateToTarget(Offset target, VoidCallback onComplete) {
    _dragAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(
      parent: _dragController,
      curve: Curves.easeOutCubic,
    ));

    _dragController.reset();
    _dragController.forward().then((_) {
      onComplete();
      _resetPosition();
    });
  }

  /// 重置位置
  void _resetPosition() {
    _dragAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _dragController,
      curve: Curves.easeOutBack,
    ));

    _dragController.reset();
    _dragController.forward().then((_) {
      setState(() {
        _dragOffset = Offset.zero;
      });
    });
  }

  /// 上滑到顶部表示喜欢
  void _animateToTopAndLike() {
    _dragAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: const Offset(0, -400), // 移动到屏幕顶部外
    ).animate(CurvedAnimation(
      parent: _dragController,
      curve: Curves.easeInOut,
    ));

    _dragController.reset();
    _dragController.forward().then((_) {
      HapticFeedback.mediumImpact();
      widget.onSwipeUp?.call(); // 触发喜欢回调
      // 气泡会在控制器中被处理，这里不需要重置位置
    });
  }

  /// 下滑到底部表示不喜欢并缓慢消失
  void _animateToBottomAndDislike() {
    // 先移动到底部
    _dragAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: const Offset(0, 400), // 移动到屏幕底部外
    ).animate(CurvedAnimation(
      parent: _dragController,
      curve: Curves.easeInOut,
    ));

    _dragController.reset();
    _dragController.forward().then((_) {
      // 开始淡出动画
      _startFadeOutAnimation();
    });
  }

  /// 开始淡出动画
  void _startFadeOutAnimation() {
    // 使用现有的发光控制器来做淡出效果
    _glowController.reset();
    _glowController.animateTo(1.0).then((_) {
      HapticFeedback.heavyImpact();
      widget.onSwipeDown?.call(); // 触发不喜欢回调
      // 气泡会在控制器中被移除
    });
  }

  /// 构建实体内容 - 玻璃质感版本
  Widget _buildEntityContent() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 主要表情符号或图标 - 增加发光效果
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                // 为emoji添加微弱的背景光晕
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                widget.entity.emoji,
                style: TextStyle(
                  fontSize: widget.entity.radius * 0.4,
                  shadows: [
                    // 为emoji添加柔和阴影
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                    // 白色高光
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      offset: const Offset(0, -1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 如果有额外图标，显示在角落
          if (widget.entity.icon != null)
            Flexible(
              child: Text(
                widget.entity.icon!,
                style: TextStyle(
                  fontSize: widget.entity.radius * 0.15,
                  color: Colors.white.withValues(alpha: 0.8),
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

          // 实体名称 - 增强对比度
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                // 为文字添加半透明背景增加可读性
                color: Colors.black.withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: AutoSizeText(
                widget.entity.name,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  shadows: [
                    // 强化文字阴影增加可读性
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.7),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                    // 微弱白色边缘光
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      offset: const Offset(0, -0.5),
                      blurRadius: 1,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                minFontSize: 8,
              ),
            ),
          ),

          // 类型指示器 - 玻璃质感小点
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.4),
                  _getTypeColor(widget.entity.type).withValues(alpha: 0.8),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      _getTypeColor(widget.entity.type).withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 根据实体类型获取指示颜色
  Color _getTypeColor(PhysicalEntityType type) {
    switch (type) {
      case PhysicalEntityType.taste:
        return Colors.red;
      case PhysicalEntityType.cuisine:
        return Colors.blue;
      case PhysicalEntityType.ingredient:
        return Colors.green;
      case PhysicalEntityType.scenario:
        return Colors.orange;
      case PhysicalEntityType.nutrition:
        return Colors.purple;
    }
  }
}
