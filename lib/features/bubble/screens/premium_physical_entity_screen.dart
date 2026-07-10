import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../controllers/physical_entity_controller.dart';
import '../widgets/text_physical_entity_widget.dart';
import '../../recommendation/screens/recommendation_screen.dart';
import '../../../shared/widgets/modern_loading_animation.dart';

/// 高级物理实体界面 - 商业化白色透明设计
class PremiumPhysicalEntityScreen extends StatefulWidget {
  const PremiumPhysicalEntityScreen({super.key});

  @override
  State<PremiumPhysicalEntityScreen> createState() => _PremiumPhysicalEntityScreenState();
}

class _PremiumPhysicalEntityScreenState extends State<PremiumPhysicalEntityScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _headerController;
  late AnimationController _particleController;

  late Animation<double> _headerAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _particleAnimation;

  // 背景粒子系统
  final List<BackgroundParticle> _particles = [];
  late DateTime _lastUpdateTime;

  @override
  void initState() {
    super.initState();
    _lastUpdateTime = DateTime.now();

    // 背景动画
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_backgroundController);

    // 头部动画
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));

    // 粒子动画
    _particleController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_particleController);

    // 初始化背景粒子
    _initializeParticles();

    // 启动动画
    _backgroundController.repeat();
    _headerController.forward();
    _particleController.repeat();

    // 初始化控制器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<PhysicalEntityController>();
      controller.initializeEntities(context);
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _headerController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < 30; i++) {
      _particles.add(BackgroundParticle(
        position: Offset(
          random.nextDouble() * 400,
          random.nextDouble() * 800,
        ),
        velocity: Offset(
          (random.nextDouble() - 0.5) * 20,
          (random.nextDouble() - 0.5) * 20,
        ),
        size: 2 + random.nextDouble() * 4,
        opacity: 0.1 + random.nextDouble() * 0.3,
      ));
    }
  }

  void _updateParticles() {
    final now = DateTime.now();
    final deltaTime = now.difference(_lastUpdateTime).inMilliseconds / 1000.0;
    _lastUpdateTime = now;

    for (final particle in _particles) {
      particle.update(deltaTime, const Size(400, 800));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: Stack(
          children: [
            // 背景粒子层
            _buildBackgroundParticles(),

            // 主要内容
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  _buildHeader(),
                  SizedBox(height: 8.h),
                  Expanded(
                    child: _buildEntityContainer(),
                  ),
                  _buildSelectedKeywords(),
                  _buildBottomControls(),
                  SizedBox(height: 15.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20.sp,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.settings,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          onPressed: () => _showSettings(),
        ),
        SizedBox(width: 16.w),
      ],
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      child: Column(
        children: [
          Text(
            '🍽️ 吃什么',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          // 移除说明文字
        ],
      ),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _headerAnimation.value)),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildEntityContainer() {
    return Consumer<PhysicalEntityController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(
            child: ModernLoadingAnimation(),
          );
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: GlassmorphicContainer(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 24.r,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              border: 0,
              borderGradient: const LinearGradient(
                colors: [Colors.transparent, Colors.transparent],
              ),
              blur: 30.0,
              child: Stack(
                children: [
                  // 物理实体
                  ...controller.entities.map((entity) {
                    return Positioned(
                      left: entity.position.dx - entity.radius,
                      top: entity.position.dy - entity.radius,
                      child: _buildInteractiveEntity(entity, controller),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedKeywords() {
    return Consumer<PhysicalEntityController>(
      builder: (context, controller, child) {
        final likedKeywords = controller.likedEntities.map((e) => e.name).toList();
        final dislikedKeywords = controller.dislikedEntities.map((e) => e.name).toList();

        if (likedKeywords.isEmpty && dislikedKeywords.isEmpty) {
          return const SizedBox();
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 80.h,
            borderRadius: 12.r,
            linearGradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            border: 0,
            borderGradient: const LinearGradient(
              colors: [Colors.transparent, Colors.transparent],
            ),
            blur: 20.0,
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (likedKeywords.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.thumb_up,
                          color: Colors.green,
                          size: 14.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '喜欢:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Wrap(
                            spacing: 6.w,
                            runSpacing: 4.h,
                            children: likedKeywords.map((keyword) {
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  keyword,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (likedKeywords.isNotEmpty && dislikedKeywords.isNotEmpty)
                    SizedBox(height: 8.h),
                  if (dislikedKeywords.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.thumb_down,
                          color: Colors.red,
                          size: 14.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '不喜欢:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Wrap(
                            spacing: 6.w,
                            runSpacing: 4.h,
                            children: dislikedKeywords.map((keyword) {
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  keyword,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 50.h,
        borderRadius: 16.r,
        linearGradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        border: 0,
        borderGradient: const LinearGradient(
          colors: [Colors.transparent, Colors.transparent],
        ),
        blur: 20.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              icon: Icons.refresh,
              label: '重新开始',
              onTap: _resetEntities,
            ),
            _buildControlButton(
              icon: Icons.favorite,
              label: '获取推荐',
              onTap: _getRecommendations,
              isPrimary: true,
            ),
            _buildControlButton(
              icon: Icons.share,
              label: '分享',
              onTap: _sharePreferences,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color:
              isPrimary ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isPrimary
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16.sp,
            ),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundParticles() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        _updateParticles();
        return CustomPaint(
          size: Size.infinite,
          painter: ParticlePainter(_particles),
        );
      },
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF667eea),
          Color(0xFF764ba2),
          Color(0xFFf093fb),
          Color(0xFFf5576c),
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ),
    );
  }

  Widget _buildInteractiveEntity(entity, PhysicalEntityController controller) {
    return GestureDetector(
      onTap: () => _handleEntityTap(entity, controller),
      onLongPress: () => _handleEntityLongPress(entity),
      onPanStart: (details) => _handlePanStart(entity, details, controller),
      onPanUpdate: (details) => _handlePanUpdate(entity, details, controller),
      onPanEnd: (details) => _handlePanEnd(entity, details, controller),
      child: TextPhysicalEntityWidget(
        entity: entity,
        isSelected: entity.isSelected,
        isLiked: controller.likedEntities.any((e) => e.id == entity.id),
        isDisliked: controller.dislikedEntities.any((e) => e.id == entity.id),
        scale: 1.0,
        onTap: () => _handleEntityTap(entity, controller),
        onLongPress: () => _handleEntityLongPress(entity),
      ),
    );
  }

  void _handleEntityTap(entity, PhysicalEntityController controller) {
    HapticFeedback.mediumImpact();
    controller.toggleEntitySelection(entity.id);

    // 添加选择反馈动画
    _addSelectionFeedback(entity);
  }

  void _handleEntityLongPress(entity) {
    HapticFeedback.heavyImpact();
    _showEntityDetails(entity);
  }

  // 处理拖拽开始
  void _handlePanStart(entity, DragStartDetails details, PhysicalEntityController controller) {
    HapticFeedback.selectionClick();
    controller.pausePhysics(); // 暂停物理引擎
  }

  // 处理拖拽更新
  void _handlePanUpdate(entity, DragUpdateDetails details, PhysicalEntityController controller) {
    // 将全局坐标转换为容器内的本地坐标
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPosition = renderBox.globalToLocal(details.globalPosition);
      controller.updateEntityPosition(entity.id, localPosition);
    }
  }

  // 处理拖拽结束
  void _handlePanEnd(entity, DragEndDetails details, PhysicalEntityController controller) {
    // 根据滑动方向给实体添加速度
    final velocity = details.velocity.pixelsPerSecond;
    controller.applyVelocityToEntity(entity.id, velocity);

    // 检测滑动手势方向
    if (velocity.dx.abs() > velocity.dy.abs()) {
      // 水平滑动
      if (velocity.dx > 100) {
        _handleSwipeRight(entity, controller);
      } else if (velocity.dx < -100) {
        _handleSwipeLeft(entity, controller);
      }
    } else {
      // 垂直滑动
      if (velocity.dy > 100) {
        _handleSwipeDown(entity, controller);
      } else if (velocity.dy < -100) {
        _handleSwipeUp(entity, controller);
      }
    }

    // 暂时禁用物理引擎恢复以解决乱窜问题
    // controller.resumePhysics(); // 恢复物理引擎
  }

  // 滑动手势处理
  void _handleSwipeUp(entity, PhysicalEntityController controller) {
    HapticFeedback.lightImpact();
    controller.likeEntity(entity.id);
    _showFeedbackMessage('👍 喜欢 ${entity.name}');
  }

  void _handleSwipeDown(entity, PhysicalEntityController controller) {
    HapticFeedback.lightImpact();
    controller.dislikeEntity(entity.id);
    _showFeedbackMessage('👎 不喜欢 ${entity.name}');
  }

  void _handleSwipeLeft(entity, PhysicalEntityController controller) {
    HapticFeedback.lightImpact();
    controller.skipEntity(entity.id);
    _showFeedbackMessage('⏭️ 跳过 ${entity.name}');
  }

  void _handleSwipeRight(entity, PhysicalEntityController controller) {
    HapticFeedback.lightImpact();
    controller.favoriteEntity(entity.id);
    _showFeedbackMessage('⭐ 收藏 ${entity.name}');
  }

  void _addSelectionFeedback(entity) {
    // TODO: 添加选择动画效果
  }

  void _showFeedbackMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1500),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.only(
          bottom: 100.h,
          left: 20.w,
          right: 20.w,
        ),
      ),
    );
  }

  void _showEntityDetails(entity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEntityDetailsSheet(entity),
    );
  }

  Widget _buildEntityDetailsSheet(entity) {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 300.h,
        borderRadius: 24.r,
        linearGradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.8),
          ],
        ),
        border: 0,
        borderGradient: const LinearGradient(
          colors: [Colors.transparent, Colors.transparent],
        ),
        blur: 30.0,
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                entity.emoji,
                style: TextStyle(fontSize: 60.sp),
              ),
              SizedBox(height: 16.h),
              Text(
                entity.name,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                entity.description,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        '关闭',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16.sp,
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
    );
  }

  void _resetEntities() {
    final controller = context.read<PhysicalEntityController>();
    controller.resetEntities();
  }

  void _getRecommendations() {
    final controller = context.read<PhysicalEntityController>();
    final selectedEntities = controller.getSelectedEntities();

    if (selectedEntities.isEmpty) {
      _showMessage('请先选择一些口味偏好');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecommendationScreen(),
      ),
    );
  }

  void _sharePreferences() {
    final controller = context.read<PhysicalEntityController>();
    final selectedEntities = controller.getSelectedEntities();

    if (selectedEntities.isEmpty) {
      _showMessage('请先选择一些口味偏好');
      return;
    }

    // TODO: 实现分享功能
    _showMessage('分享功能开发中...');
  }

  void _showSettings() {
    // TODO: 显示设置页面
    _showMessage('设置功能开发中...');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}

// 背景粒子类
class BackgroundParticle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;

  BackgroundParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
  });

  void update(double deltaTime, Size containerSize) {
    position = Offset(
      position.dx + velocity.dx * deltaTime,
      position.dy + velocity.dy * deltaTime,
    );

    // 边界反弹
    if (position.dx < 0 || position.dx > containerSize.width) {
      velocity = Offset(-velocity.dx, velocity.dy);
    }
    if (position.dy < 0 || position.dy > containerSize.height) {
      velocity = Offset(velocity.dx, -velocity.dy);
    }

    position = Offset(
      position.dx.clamp(0, containerSize.width),
      position.dy.clamp(0, containerSize.height),
    );
  }
}

// 粒子绘制器
class ParticlePainter extends CustomPainter {
  final List<BackgroundParticle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      canvas.drawCircle(
        particle.position,
        particle.size,
        paint..color = Colors.white.withValues(alpha: particle.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
