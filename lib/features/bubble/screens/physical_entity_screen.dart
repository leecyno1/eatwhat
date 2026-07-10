import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';

import '../controllers/physical_entity_controller.dart';
import '../widgets/physical_entity_widget.dart';
import '../../recommendation/screens/recommendation_screen.dart';
import '../../../shared/widgets/modern_loading_animation.dart';
import '../../../shared/widgets/particle_system.dart';
import '../../../core/utils/performance_optimizer.dart';
import '../../../core/services/growth_engine.dart';
import '../../../core/models/bubble.dart'; // 添加BubbleGesture导入

/// 物理实体界面 - 零重力环境下的形象化实体交互
class PhysicalEntityScreen extends StatefulWidget {
  const PhysicalEntityScreen({super.key});

  @override
  State<PhysicalEntityScreen> createState() => _PhysicalEntityScreenState();
}

class _PhysicalEntityScreenState extends State<PhysicalEntityScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _headerController;
  late AnimationController _containerController;

  late Animation<double> _headerAnimation;
  late Animation<Color?> _backgroundAnimation;
  late Animation<double> _containerAnimation;

  // ✨ 粒子系统管理器
  late ParticleSystemManager _particleManager;

  // 📊 性能监控
  DateTime? _lastFrameTime;

  @override
  void initState() {
    super.initState();

    // ✨ 初始化粒子系统
    _particleManager = ParticleSystemManager(
      maxParticles: 150,
      containerSize: const Size(400, 600),
    );

    // 背景渐变动画
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _backgroundAnimation = ColorTween(
      begin: const Color(0xFF0A0A23), // 深空蓝
      end: const Color(0xFF1A1A2E), // 宇宙紫
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    // 头部动画
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.elasticOut,
    ));

    // 容器动画
    _containerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _containerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _containerController,
      curve: Curves.easeOutBack,
    ));

    _backgroundController.repeat(reverse: true);
    _headerController.forward();
    _containerController.forward();

    // 初始化物理实体控制器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final controller = context.read<PhysicalEntityController>();
        final screenSize = MediaQuery.of(context).size;
        controller.initialize(containerSize: screenSize);

        // 更新粒子系统容器大小
        _particleManager.containerSize = screenSize;

        // 🎯 记录用户行为用于增长分析
        GrowthEngine().recordUserAction(
          userId: 'current_user', // TODO: 从用户服务获取
          action: UserAction.dailyLogin,
        );

        // 🎉 添加欢迎粒子效果
        _addWelcomeEffect();
      } catch (e) {
        debugPrint('PhysicalEntityController initialization error: $e');
      }
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _headerController.dispose();
    _containerController.dispose();
    _particleManager.clear(); // 清理粒子系统
    super.dispose();
  }

  /// 🎉 添加欢迎粒子效果
  void _addWelcomeEffect() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        ParticleEffects.celebrationEffect(
            _particleManager, _particleManager.containerSize);
      }
    });
  }

  /// 📊 记录帧时间用于性能监控
  void _recordFrameTime() {
    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!).inMicroseconds / 1000.0;
      PerformanceOptimizer().recordFrameTime(frameTime);
    }
    _lastFrameTime = now;
  }

  @override
  Widget build(BuildContext context) {
    // 📊 记录帧时间
    _recordFrameTime();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return ParticleSystemWidget(
            manager: _particleManager,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    _backgroundAnimation.value ?? const Color(0xFF0A0A23),
                    const Color(0xFF16213E),
                    const Color(0xFF0F0F23),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              _buildSpaceHeader(),
                              Expanded(
                                child: _buildZeroGravityContainer(),
                              ),
                              _buildMissionControls(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 太空风格头部
  Widget _buildSpaceHeader() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _headerAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(
              children: [
                // 主标题 - 太空风格
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🚀', style: TextStyle(fontSize: 32)),
                          SizedBox(width: 12.w),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF64B5F6),
                                Color(0xFF42A5F5),
                                Color(0xFF2196F3),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              '口味星球',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          const Text('🌌', style: TextStyle(fontSize: 32)),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '在零重力环境中探索您的味蕾偏好',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // 状态面板 - 太空仪表盘风格
                Consumer<PhysicalEntityController>(
                  builder: (context, controller, child) {
                    final status = controller.getSystemStatus();
                    return AnimationConfiguration.staggeredList(
                      position: 0,
                      duration: const Duration(milliseconds: 800),
                      child: SlideAnimation(
                        verticalOffset: -30,
                        child: FadeInAnimation(
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.r),
                              color: Colors.white.withValues(alpha: 0.1),
                              border: Border.all(
                                color: Colors.cyan.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyan.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatusIndicator(
                                  icon: '🌟',
                                  label: '已选实体',
                                  value: '${controller.selectedCount}',
                                  color: const Color(0xFF64B5F6),
                                ),
                                Container(
                                  width: 1.w,
                                  height: 30.h,
                                  color: Colors.cyan.withValues(alpha: 0.3),
                                ),
                                _buildStatusIndicator(
                                  icon: '⚡',
                                  label: '系统能量',
                                  value: status['isSystemAtRest'] ? '低' : '高',
                                  color: status['isSystemAtRest']
                                      ? const Color(0xFF81C784)
                                      : const Color(0xFFFFB74D),
                                ),
                                Container(
                                  width: 1.w,
                                  height: 30.h,
                                  color: Colors.cyan.withValues(alpha: 0.3),
                                ),
                                _buildStatusIndicator(
                                  icon: '🎯',
                                  label: '推荐度',
                                  value: controller.entities.isNotEmpty
                                      ? '${((controller.selectedCount / controller.entities.length) * 100).toInt()}%'
                                      : '0%',
                                  color: const Color(0xFFBA68C8),
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

  Widget _buildStatusIndicator({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: TextStyle(fontSize: 18.sp),
        ),
        SizedBox(height: 4.h),
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
            fontSize: 10.sp,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 零重力容器
  Widget _buildZeroGravityContainer() {
    return Consumer<PhysicalEntityController>(
      builder: (context, controller, child) {
        if (!controller.isInitialized) {
          return const Center(
            child: ModernLoadingAnimation(
              color: Color(0xFF64B5F6),
              message: '正在初始化零重力环境...',
            ),
          );
        }

        return AnimatedBuilder(
          animation: _containerAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _containerAnimation.value,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.r),
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: Colors.cyan.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(23.r),
                  child: Stack(
                    children: [
                      // 星空背景
                      Positioned.fill(
                        child: CustomPaint(
                          painter: SpaceBackgroundPainter(),
                        ),
                      ),

                      // 交互区域 - 禁用物理力
                      Positioned.fill(
                        child: GestureDetector(
                          onTapDown: (details) {
                            HapticFeedback.lightImpact();
                            // 暂时禁用物理力以解决乱窜问题
                            // controller.applyRepulsionForce(
                            //   details.localPosition,
                            //   radius: 80.0,
                            //   strength: 600.0,
                            // );
                          },
                          onPanUpdate: (details) {
                            // 暂时禁用物理力
                            // controller.applyRepulsionForce(
                            //   details.localPosition,
                            //   radius: 60.0,
                            //   strength: 400.0,
                            // );
                          },
                          onDoubleTap: () {
                            HapticFeedback.mediumImpact();
                            // 暂时禁用随机扰动
                            // controller.addRandomDisturbance(strength: 150.0);
                          },
                          child: Stack(
                            children: controller.entities
                                .asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final entity = entry.value;

                              return Positioned(
                                left: entity.position.dx - entity.radius,
                                top: entity.position.dy - entity.radius,
                                child: AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 1000),
                                  child: ScaleAnimation(
                                    scale: 0.8,
                                    child: FadeInAnimation(
                                      child: PhysicalEntityWidget(
                                        entity: entity,
                                        isSelected:
                                            controller.isEntitySelected(entity),
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          controller.toggleEntity(entity);

                                          // ✨ 添加选择粒子效果
                                          ParticleEffects.bubbleSelection(
                                            _particleManager,
                                            entity.position,
                                          );

                                          // 🎯 记录用户行为
                                          GrowthEngine().recordUserAction(
                                            userId: 'current_user',
                                            action: UserAction.bubbleSelection,
                                          );
                                        },
                                        onSwipeUp: () => _handleGesture(
                                          controller,
                                          entity,
                                          BubbleGesture.swipeUp,
                                        ),
                                        onSwipeDown: () => _handleGesture(
                                          controller,
                                          entity,
                                          BubbleGesture.swipeDown,
                                        ),
                                        onSwipeLeft: () => _handleGesture(
                                          controller,
                                          entity,
                                          BubbleGesture.swipeLeft,
                                        ),
                                        onSwipeRight: () => _handleGesture(
                                          controller,
                                          entity,
                                          BubbleGesture.swipeRight,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // 操作提示
                      if (controller.selectedCount == 0)
                        Positioned(
                          bottom: 50.h,
                          left: 0,
                          right: 0,
                          child: AnimationConfiguration.synchronized(
                            duration: const Duration(milliseconds: 1200),
                            child: FadeInAnimation(
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: Center(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24.w,
                                      vertical: 16.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(25.r),
                                      border: Border.all(
                                        color:
                                            Colors.cyan.withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '🌟 探索零重力口味空间',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8.h),
                                        Text(
                                          '点击选择 • 上滑喜欢 • 下滑不喜欢\n双击添加扰动 • 拖拽推动实体',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.8),
                                            fontSize: 12.sp,
                                            height: 1.4,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
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
              ),
            );
          },
        );
      },
    );
  }

  /// 统一手势处理方法
  void _handleGesture(
      PhysicalEntityController controller, entity, BubbleGesture gesture,
      {DragUpdateDetails? details}) {
    switch (gesture) {
      case BubbleGesture.swipeUp:
        HapticFeedback.mediumImpact();
        controller.swipeUpEntity(entity);

        // ❤️ 添加喜欢粒子效果
        ParticleEffects.likeAction(
          _particleManager,
          entity.position,
        );
        break;
      case BubbleGesture.swipeDown:
        HapticFeedback.heavyImpact();
        controller.swipeDownEntity(entity);

        // 💨 添加讨厌消失粒子效果
        ParticleEffects.dislikeAction(
          _particleManager,
          entity.position,
        );
        break;
      case BubbleGesture.swipeLeft:
        HapticFeedback.lightImpact();
        controller.ignoreEntity(entity);
        break;
      case BubbleGesture.swipeRight:
        HapticFeedback.mediumImpact();
        controller.confirmEntity(entity);
        break;
      case BubbleGesture.tap:
        HapticFeedback.lightImpact();
        // controller.selectEntity(entity.id); // 此方法暂不存在，可用其他方法代替

        // 🔥 记录用户行为 - 待实现GrowthEngine单例
        // GrowthEngine.instance.recordUserAction(
        //   userId: 'default_user',
        //   action: UserAction.bubbleSelection,
        // );
        break;
      case BubbleGesture.longPress:
        // 长按处理逻辑
        HapticFeedback.heavyImpact();
        break;
      case BubbleGesture.dragStart:
      case BubbleGesture.dragUpdate:
      case BubbleGesture.dragEnd:
        // 拖拽处理逻辑
        break;
    }
  }

  /// 任务控制面板
  Widget _buildMissionControls() {
    return Consumer<PhysicalEntityController>(
      builder: (context, controller, child) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: AnimationConfiguration.synchronized(
            duration: const Duration(milliseconds: 1000),
            child: SlideAnimation(
              verticalOffset: 50,
              child: FadeInAnimation(
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25.r),
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(
                      color: Colors.cyan.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 主任务按钮
                      SizedBox(
                        width: double.infinity,
                        height: 55.h,
                        child: ElevatedButton(
                          onPressed: controller.selectedCount > 0
                              ? () async {
                                  HapticFeedback.heavyImpact();
                                  await controller.generateRecommendations();
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) =>
                                            const RecommendationScreen(),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: controller.selectedCount > 0
                                ? const Color(0xFF64B5F6)
                                : Colors.grey[700],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor:
                                const Color(0xFF64B5F6).withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.r),
                            ),
                          ),
                          child: controller.isGeneratingRecommendations
                              ? SizedBox(
                                  width: 24.w,
                                  height: 24.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('🚀',
                                        style: TextStyle(fontSize: 20)),
                                    SizedBox(width: 12.w),
                                    Text(
                                      controller.selectedCount > 0
                                          ? '启动美食推荐 (${controller.selectedCount}个偏好)'
                                          : '请先探索并选择您的偏好',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // 控制按钮行
                      Row(
                        children: [
                          // 重置按钮
                          if (controller.selectedCount > 0)
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  controller.clearSelection();
                                },
                                icon: const Icon(
                                  CupertinoIcons.refresh,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                label: Text(
                                  '重新选择',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                          if (controller.selectedCount > 0)
                            SizedBox(width: 16.w),

                          // 物理控制按钮
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                controller.redistributeEntities();
                              },
                              icon: Icon(
                                controller.isPhysicsRunning
                                    ? CupertinoIcons.tornado
                                    : CupertinoIcons.pause_circle,
                                color: Colors.cyan,
                                size: 18,
                              ),
                              label: Text(
                                '重新分布',
                                style: TextStyle(
                                  color: Colors.cyan,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

/// 太空背景画笔
class SpaceBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // 绘制星星
    for (int i = 0; i < 50; i++) {
      final x = (i * 17) % size.width;
      final y = (i * 23) % size.height;
      final radius = (i % 3) + 1.0;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // 绘制星云效果
    final nebulaPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      100,
      nebulaPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      80,
      nebulaPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
