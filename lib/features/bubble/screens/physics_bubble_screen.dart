import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/bubble.dart';
import '../../../core/utils/bubble_physics.dart';
import '../widgets/enhanced_bubble_widget.dart';
import '../controllers/bubble_controller.dart';

/// 支持物理引擎的气泡主界面
class PhysicsBubbleScreen extends StatefulWidget {
  const PhysicsBubbleScreen({Key? key}) : super(key: key);

  @override
  State<PhysicsBubbleScreen> createState() => _PhysicsBubbleScreenState();
}

class _PhysicsBubbleScreenState extends State<PhysicsBubbleScreen>
    with TickerProviderStateMixin {
  late BubblePhysics _physics;
  late Timer _physicsTimer;
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  
  Size? _screenSize;
  final double _padding = 20.0; // 屏幕边距
  
  @override
  void initState() {
    super.initState();
    
    // 背景动画控制器
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundController);
    
    _backgroundController.repeat();
    
    // 延迟初始化物理引擎
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePhysics();
    });
  }

  void _initializePhysics() {
    final size = MediaQuery.of(context).size;
    _screenSize = Size(
      size.width - _padding * 2, 
      size.height - _padding * 2 - kToolbarHeight - 100, // 减去AppBar和底部空间
    );
    
    _physics = BubblePhysics(screenSize: _screenSize!);
    
    // 初始化气泡控制器
    final controller = context.read<BubbleController>();
    controller.initializeBubbles();
    
    // 随机分布气泡位置
    _physics.randomDistributeBubbles(controller.bubbles);
    
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
        controller.notifyListeners(); // 通知UI更新
      }
    });
  }

  @override
  void dispose() {
    _physicsTimer.cancel();
    _backgroundController.dispose();
    super.dispose();
  }

  void _handleBubbleTap(Bubble bubble) {
    final controller = context.read<BubbleController>();
    controller.toggleBubble(bubble);
    
    // 添加爆炸效果
    _physics.addExplosion(bubble.position, controller.bubbles, 5.0);
  }

  void _handleBubbleDrag(Bubble bubble, DragUpdateDetails details) {
    // 更新气泡位置
    bubble.position = Offset(
      (bubble.position.dx + details.delta.dx).clamp(
        bubble.size / 2 + _padding,
        _screenSize!.width - bubble.size / 2 + _padding,
      ),
      (bubble.position.dy + details.delta.dy).clamp(
        bubble.size / 2 + _padding,
        _screenSize!.height - bubble.size / 2 + _padding,
      ),
    );
    
    // 应用手势力
    _physics.applyGestureForce(bubble, details.delta);
  }

  void _handleBubbleLongPress(Bubble bubble) {
    // 长按添加吸引效果
    final controller = context.read<BubbleController>();
    _physics.addAttraction(bubble.position, controller.bubbles, 3.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text(
          '吃什么 - 物理气泡',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              final controller = context.read<BubbleController>();
              controller.clearSelection();
              if (_screenSize != null) {
                _physics.randomDistributeBubbles(controller.bubbles);
              }
            },
          ),
        ],
      ),
      body: Consumer<BubbleController>(
        builder: (context, controller, child) {
          if (!controller.isInitialized || _screenSize == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            );
          }

          return Column(
            children: [
              // 选中气泡状态栏
              _buildSelectedBubblesBar(controller),
              
              // 主气泡交互区域
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(_padding),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
                      colors: [
                        Colors.blue.shade900.withOpacity(0.3),
                        Colors.purple.shade900.withOpacity(0.2),
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        // 动态背景
                        _buildAnimatedBackground(),
                        
                        // 气泡层
                        ...controller.bubbles.map((bubble) {
                          return EnhancedBubbleWidget(
                            bubble: bubble,
                            onTap: () => _handleBubbleTap(bubble),
                            onLongPress: () => _handleBubbleLongPress(bubble),
                            onPanUpdate: (details) => _handleBubbleDrag(bubble, details),
                          );
                        }).toList(),
                        
                        // 边界指示器
                        _buildBoundaryIndicators(),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 底部控制栏
              _buildBottomControls(controller),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelectedBubblesBar(BubbleController controller) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '已选择: ${controller.selectedBubbles.length} 个偏好',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: controller.selectedBubbles.isEmpty
                ? const Text(
                    '点击气泡选择你的偏好，长按可产生吸引效果',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.selectedBubbles.length,
                    itemBuilder: (context, index) {
                      final bubble = controller.selectedBubbles[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              bubble.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              bubble.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: BackgroundParticlesPainter(
            animationValue: _backgroundAnimation.value,
          ),
        );
      },
    );
  }

  Widget _buildBoundaryIndicators() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.blue.withOpacity(0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Widget _buildBottomControls(BubbleController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: controller.selectedBubbles.isEmpty
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '基于${controller.selectedBubbles.length}个偏好生成推荐中...',
                          ),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu),
                  SizedBox(width: 8),
                  Text(
                    '生成推荐',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              controller.clearSelection();
              if (_screenSize != null) {
                _physics.circularDistributeBubbles(
                  controller.bubbles,
                  Offset(_screenSize!.width / 2, _screenSize!.height / 2),
                  100,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

/// 背景粒子绘制器
class BackgroundParticlesPainter extends CustomPainter {
  final double animationValue;

  BackgroundParticlesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // 绘制漂浮的背景粒子
    for (int i = 0; i < 20; i++) {
      final x = (i * 37.0 + animationValue * 50) % size.width;
      final y = (i * 43.0 + animationValue * 30) % size.height;
      final radius = 2.0 + (animationValue * 3) % 2.0;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(BackgroundParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
} 