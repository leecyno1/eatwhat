import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/models/bubble.dart';
import '../../../core/utils/bubble_physics.dart';
import '../controllers/bubble_controller.dart';
import '../../recommendation/controllers/recommendation_controller.dart';

/// 魔幻风格的气泡主界面
class MagicBubbleScreen extends StatefulWidget {
  const MagicBubbleScreen({Key? key}) : super(key: key);

  @override
  State<MagicBubbleScreen> createState() => _MagicBubbleScreenState();
}

class _MagicBubbleScreenState extends State<MagicBubbleScreen>
    with TickerProviderStateMixin {
  late BubblePhysics _physics;
  late Timer _physicsTimer;
  late AnimationController _backgroundController;
  late AnimationController _titleController;
  late AnimationController _particleController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _titleAnimation;
  late Animation<double> _particleAnimation;
  
  Size? _screenSize;
  final double _padding = 25.0;
  
  @override
  void initState() {
    super.initState();
    
    // 背景动画控制器 - 慢速循环
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    
    // 标题动画控制器
    _titleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // 粒子动画控制器
    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    );
    
    _titleAnimation = CurvedAnimation(
      parent: _titleController,
      curve: Curves.elasticOut,
    );
    
    _particleAnimation = CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    );
    
    // 启动动画
    _backgroundController.repeat(reverse: true);
    _titleController.forward();
    _particleController.repeat();
    
    // 延迟初始化物理引擎
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePhysics();
    });
  }

  void _initializePhysics() {
    final size = MediaQuery.of(context).size;
    _screenSize = Size(
      size.width - _padding * 2, 
      size.height - _padding * 2 - kToolbarHeight - 120,
    );
    
    _physics = BubblePhysics(screenSize: _screenSize!);
    
    // 初始化气泡控制器
    final controller = context.read<BubbleController>();
    controller.initializeBubbles();
    
    // 魔法圆形分布气泡
    _physics.circularDistributeBubbles(
      controller.bubbles,
      Offset(_screenSize!.width / 2, _screenSize!.height / 2),
      min(_screenSize!.width, _screenSize!.height) * 0.3,
    );
    
    // 启动物理更新循环
    _startPhysicsLoop();
  }

  void _startPhysicsLoop() {
    const frameRate = 60;
    const frameDuration = Duration(milliseconds: 1000 ~/ frameRate);
    
    _physicsTimer = Timer.periodic(frameDuration, (timer) {
      final controller = context.read<BubbleController>();
      if (controller.bubbles.isNotEmpty && mounted) {
        _physics.updateBubbles(controller.bubbles, 1.0 / frameRate);
        controller.notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _physicsTimer.cancel();
    _backgroundController.dispose();
    _titleController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  /// 生成推荐
  Future<void> _generateRecommendations(BuildContext context, BubbleController controller) async {
    final recommendationController = context.read<RecommendationController>();
    
    // 显示加载状态
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🔮'),
            const SizedBox(width: 8),
            Text('基于${controller.selectedBubbles.length}个魔法偏好生成推荐中...'),
            const SizedBox(width: 8),
            const Text('✨'),
          ],
        ),
        backgroundColor: Colors.amber.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );

    // 生成推荐
    await recommendationController.generateRecommendations(controller.selectedBubbles);
    
    // 导航到推荐页面
    if (mounted) {
      Navigator.of(context).pushNamed('/recommendation');
    }
  }

  void _handleBubbleTap(Bubble bubble) {
    final controller = context.read<BubbleController>();
    controller.toggleBubble(bubble);
    
    // 魔法爆炸效果
    _physics.addExplosion(bubble.position, controller.bubbles, 8.0);
    
    // 触觉反馈
    HapticFeedback.mediumImpact();
  }

  void _handleBubbleDrag(Bubble bubble, DragUpdateDetails details) {
    // 限制在屏幕边界内
    bubble.position = Offset(
      (bubble.position.dx + details.delta.dx).clamp(
        bubble.size / 2,
        _screenSize!.width - bubble.size / 2,
      ),
      (bubble.position.dy + details.delta.dy).clamp(
        bubble.size / 2,
        _screenSize!.height - bubble.size / 2,
      ),
    );
    
    // 应用魔法手势力
    _physics.applyGestureForce(bubble, details.delta * 2);
  }

  void _handleBubbleLongPress(Bubble bubble) {
    // 魔法吸引效果
    final controller = context.read<BubbleController>();
    _physics.addAttraction(bubble.position, controller.bubbles, 5.0);
    
    // 强触觉反馈
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF1a1a2e),  // 深紫色
              Color(0xFF16213e),  // 深蓝色  
              Color(0xFF0f0f23),  // 深黑色
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<BubbleController>(
            builder: (context, controller, child) {
              return Column(
                children: [
                  // 魔法标题区域
                  _buildMagicHeader(controller),
                  
                  // 主要气泡交互区域
                  Expanded(
                    child: _buildMagicBubbleArea(controller),
                  ),
                  
                  // 魔法控制面板
                  _buildMagicControlPanel(controller),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMagicHeader(BubbleController controller) {
    return AnimatedBuilder(
      animation: _titleAnimation,
      builder: (context, child) {
        return Container(
          height: 120,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 魔法标题
              Transform.scale(
                scale: _titleAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.8),
                        Colors.amber.withOpacity(0.9),
                        Colors.yellow.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Text(
                    '🔮 吃什么 ✨',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 魔法提示文字
              Opacity(
                opacity: _titleAnimation.value,
                child: Text(
                  controller.selectedBubbles.isEmpty 
                      ? '✨ 点击气泡选择你的口味偏好 ✨'
                      : '🌟 已选择 ${controller.selectedBubbles.length} 个魔法偏好 🌟',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMagicBubbleArea(BubbleController controller) {
    if (!controller.isInitialized || _screenSize == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.amber,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              '🔮 魔法气泡生成中... ✨',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.purple.withOpacity(0.2),
            Colors.blue.withOpacity(0.15),
            Colors.indigo.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: Colors.cyan.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // 动态魔法背景
            _buildMagicBackground(),
            
            // 气泡层
            ...controller.bubbles.map((bubble) {
              return _buildMagicBubble(bubble);
            }).toList(),
            
            // 魔法光效边框
            _buildMagicBorder(),
          ],
        ),
      ),
    );
  }

  Widget _buildMagicBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_backgroundAnimation, _particleAnimation]),
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: MagicBackgroundPainter(
            backgroundValue: _backgroundAnimation.value,
            particleValue: _particleAnimation.value,
          ),
        );
      },
    );
  }

  Widget _buildMagicBubble(Bubble bubble) {
    return Transform.translate(
      offset: Offset(
        bubble.position.dx - bubble.size / 2,
        bubble.position.dy - bubble.size / 2,
      ),
      child: MagicBubbleWidget(
        bubble: bubble,
        onTap: () => _handleBubbleTap(bubble),
        onLongPress: () => _handleBubbleLongPress(bubble),
        onPanUpdate: (details) => _handleBubbleDrag(bubble, details),
      ),
    );
  }

  Widget _buildMagicBorder() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.cyan.withOpacity(0.3 + 0.2 * _backgroundAnimation.value),
              width: 2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMagicControlPanel(BubbleController controller) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.7),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        children: [
          // 重置魔法按钮
          Expanded(
            flex: 1,
            child: _buildMagicButton(
              icon: Icons.refresh_rounded,
              label: '重置气泡',
              color: Colors.purple,
              onPressed: () {
                controller.clearSelection();
                if (_screenSize != null) {
                  _physics.circularDistributeBubbles(
                    controller.bubbles,
                    Offset(_screenSize!.width / 2, _screenSize!.height / 2),
                    min(_screenSize!.width, _screenSize!.height) * 0.3,
                  );
                }
                HapticFeedback.lightImpact();
              },
            ),
          ),
          
          const SizedBox(width: 15),
          
          // 生成推荐魔法按钮
          Expanded(
            flex: 2,
            child: _buildMagicButton(
              icon: Icons.auto_awesome_rounded,
              label: '生成推荐',
              color: controller.selectedBubbles.isEmpty ? Colors.grey : Colors.amber,
              isEnabled: controller.selectedBubbles.isNotEmpty,
              onPressed: controller.selectedBubbles.isEmpty
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      _generateRecommendations(context, controller);
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    bool isEnabled = true,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? color : Colors.grey.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: isEnabled ? 8 : 2,
          shadowColor: isEnabled ? color.withOpacity(0.5) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 魔法气泡组件
class MagicBubbleWidget extends StatefulWidget {
  final Bubble bubble;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(DragUpdateDetails)? onPanUpdate;

  const MagicBubbleWidget({
    Key? key,
    required this.bubble,
    this.onTap,
    this.onLongPress,
    this.onPanUpdate,
  }) : super(key: key);

  @override
  State<MagicBubbleWidget> createState() => _MagicBubbleWidgetState();
}

class _MagicBubbleWidgetState extends State<MagicBubbleWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.2).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.elasticOut),
    );
    
    if (widget.bubble.isSelected) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MagicBubbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.bubble.isSelected != oldWidget.bubble.isSelected) {
      if (widget.bubble.isSelected) {
        _glowController.repeat(reverse: true);
        _rotationController.forward().then((_) => _rotationController.reverse());
      } else {
        _glowController.reset();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Color _getBubbleColor() {
    switch (widget.bubble.type) {
      case BubbleType.taste:
        return Colors.pink;
      case BubbleType.cuisine:
        return Colors.orange;
      case BubbleType.ingredient:
        return Colors.green;
      case BubbleType.context:
        return Colors.blue;
      case BubbleType.nutrition:
        return Colors.purple;
      case BubbleType.temperature:
        return Colors.red;
      case BubbleType.spiciness:
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onPanUpdate: widget.onPanUpdate,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _glowAnimation,
          _rotationAnimation,
        ]),
        builder: (context, child) {
          final color = _getBubbleColor();
          final glowIntensity = widget.bubble.isSelected ? _glowAnimation.value : 0.0;
          
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                width: widget.bubble.size,
                height: widget.bubble.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withOpacity(0.9 + 0.1 * glowIntensity),
                      color.withOpacity(0.7 + 0.2 * glowIntensity),
                      color.withOpacity(0.4 + 0.3 * glowIntensity),
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3 + 0.4 * glowIntensity),
                      blurRadius: 8 + 15 * glowIntensity,
                      spreadRadius: 2 + 6 * glowIntensity,
                    ),
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4 + 0.4 * glowIntensity),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.bubble.emoji,
                        style: TextStyle(
                          fontSize: widget.bubble.size * 0.4,
                        ),
                      ),
                      if (widget.bubble.size > 45)
                        Text(
                          widget.bubble.text,
                          style: TextStyle(
                            fontSize: widget.bubble.size * 0.14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 魔法背景绘制器
class MagicBackgroundPainter extends CustomPainter {
  final double backgroundValue;
  final double particleValue;

  MagicBackgroundPainter({
    required this.backgroundValue,
    required this.particleValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制魔法粒子
    final particlePaint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final x = (i * 47.0 + particleValue * 60) % size.width;
      final y = (i * 31.0 + particleValue * 40) % size.height;
      final radius = 1.0 + (particleValue * 2 + i * 0.1) % 2.0;
      
      // 不同颜色的魔法粒子
      if (i % 3 == 0) {
        particlePaint.color = Colors.cyan.withOpacity(0.3);
      } else if (i % 3 == 1) {
        particlePaint.color = Colors.purple.withOpacity(0.2);
      } else {
        particlePaint.color = Colors.amber.withOpacity(0.25);
      }
      
      canvas.drawCircle(Offset(x, y), radius, particlePaint);
    }
    
    // 绘制魔法光环
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.cyan.withOpacity(0.1 + 0.1 * backgroundValue);
      
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.4 * (0.8 + 0.2 * backgroundValue);
    
    canvas.drawCircle(center, radius, glowPaint);
  }

  @override
  bool shouldRepaint(MagicBackgroundPainter oldDelegate) {
    return oldDelegate.backgroundValue != backgroundValue ||
           oldDelegate.particleValue != particleValue;
  }
} 