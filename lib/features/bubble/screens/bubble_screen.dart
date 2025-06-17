import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/bubble.dart';
import '../../../core/utils/bubble_physics.dart';
import '../widgets/bubble_widget.dart';
import '../controllers/bubble_controller.dart';
import '../../recommendation/screens/recommendation_screen.dart';

/// 气泡主界面
class BubbleScreen extends StatefulWidget {
  const BubbleScreen({super.key});

  @override
  State<BubbleScreen> createState() => _BubbleScreenState();
}

class _BubbleScreenState extends State<BubbleScreen>
    with TickerProviderStateMixin {
  late BubblePhysics _physics;
  late Timer _physicsTimer;
  late AnimationController _backgroundController;
  late Animation<Color?> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _backgroundAnimation = ColorTween(
      begin: const Color(0xFF1A1A2E),
      end: const Color(0xFF16213E),
    ).animate(_backgroundController);

    _backgroundController.repeat(reverse: true);

    // 在下一帧初始化物理引擎
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePhysics();
      _startPhysicsLoop();
    });
  }

  void _initializePhysics() {
    final size = MediaQuery.of(context).size;
    _physics = BubblePhysics(screenSize: size);
    
    // 初始化气泡位置
    final controller = context.read<BubbleController>();
    _physics.randomDistributeBubbles(controller.bubbles);
  }

  void _startPhysicsLoop() {
    _physicsTimer = Timer.periodic(
      const Duration(milliseconds: 16), // 60 FPS
      (timer) {
        final controller = context.read<BubbleController>();
        _physics.updateBubbles(controller.bubbles, 0.016);
        
        // 触发重建
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _physicsTimer.cancel();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  _backgroundAnimation.value ?? const Color(0xFF1A1A2E),
                  const Color(0xFF0F0F23),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            '《吃什么》',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '滑动气泡表达你的喜好',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          _buildGestureGuide(),
        ],
      ),
    );
  }

  Widget _buildGestureGuide() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGestureItem('👍', '上滑', '喜欢', Colors.green),
          const SizedBox(width: 16),
          _buildGestureItem('👎', '下滑', '不喜欢', Colors.red),
          const SizedBox(width: 16),
          _buildGestureItem('👈', '左滑', '忽略', Colors.grey),
          const SizedBox(width: 16),
          _buildGestureItem('👆', '点击', '选择', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildGestureItem(String emoji, String gesture, String meaning, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 2),
        Text(
          gesture,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          meaning,
          style: TextStyle(
            fontSize: 8,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildBubbleArea() {
    return Consumer<BubbleController>(
      builder: (context, controller, child) {
        return Stack(
          children: [
            // 背景粒子效果
            _buildBackgroundParticles(),
            
            // 气泡
            ...controller.bubbles.map((bubble) => BubbleWidget(
              key: ValueKey(bubble.id),
              bubble: bubble,
              onGesture: _handleBubbleGesture,
            )),
            
            // 选中气泡的连线效果
            if (controller.selectedBubbles.isNotEmpty)
              _buildConnectionLines(controller.selectedBubbles),
          ],
        );
      },
    );
  }

  Widget _buildBackgroundParticles() {
    return CustomPaint(
      painter: _BackgroundParticlesPainter(),
      size: Size.infinite,
    );
  }

  Widget _buildConnectionLines(List<Bubble> selectedBubbles) {
    return CustomPaint(
      painter: _ConnectionLinesPainter(selectedBubbles),
      size: Size.infinite,
    );
  }

  Widget _buildBottomControls() {
    return Consumer<BubbleController>(
      builder: (context, controller, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 选中的气泡数量显示
              if (controller.selectedBubbles.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '已选择 ${controller.selectedBubbles.length} 个偏好',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // 控制按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: Icons.refresh,
                    label: '重新分布',
                    onPressed: () => _redistributeBubbles(),
                  ),
                  _buildControlButton(
                    icon: Icons.clear_all,
                    label: '清除选择',
                    onPressed: controller.selectedBubbles.isNotEmpty
                        ? () => controller.resetSelection()
                        : null,
                  ),
                  _buildControlButton(
                    icon: Icons.restaurant,
                    label: '推荐美食',
                    onPressed: controller.selectedBubbles.isNotEmpty
                        ? () => _generateRecommendations()
                        : null,
                    isPrimary: true,
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
    required VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary 
            ? Colors.orange 
            : Colors.white.withValues(alpha: 0.1),
        foregroundColor: isPrimary ? Colors.white : Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: isPrimary ? 8 : 2,
      ),
    );
  }

  void _handleBubbleGesture(
    Bubble bubble,
    BubbleGesture gesture,
    Offset position,
    double velocity,
  ) {
    final controller = context.read<BubbleController>();
    
    switch (gesture) {
      case BubbleGesture.tap:
        controller.toggleBubbleSelection(bubble);
        break;
      case BubbleGesture.swipeUp:
        controller.likeBubble(bubble);
        _addExplosionEffect(position);
        break;
      case BubbleGesture.swipeDown:
        controller.dislikeBubble(bubble);
        _addExplosionEffect(position);
        break;
      case BubbleGesture.swipeLeft:
        controller.ignoreBubble(bubble);
        break;
      case BubbleGesture.longPress:
        _showBubbleDetails(bubble);
        break;
      default:
        break;
    }
  }

  void _addExplosionEffect(Offset position) {
    final controller = context.read<BubbleController>();
    controller.repelBubblesFromPosition(position, 5.0);
  }

  void _redistributeBubbles() {
    final controller = context.read<BubbleController>();
    controller.resetAllBubbles();
  }

  void _generateRecommendations() {
    final controller = context.read<BubbleController>();
    controller.generateRecommendations();
    
    // 导航到推荐页面
    Navigator.pushNamed(context, '/recommendations');
  }

  void _showBubbleDetails(Bubble bubble) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bubble.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('类型: ${BubbleFactory.getNameByType(bubble.type)}'),
            if (bubble.description != null)
              Text('描述: ${bubble.description}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
      floatingActionButton: Consumer<BubbleController>(
        builder: (context, controller, child) {
          if (controller.selectedBubbles.isEmpty) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton.extended(
            onPressed: () async {
              await controller.generateRecommendations();
              if (context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RecommendationScreen(),
                  ),
                );
              }
            },
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.restaurant_menu, color: Colors.white),
            label: Text(
              '获取推荐 (${controller.selectedBubbles.length})',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}

/// 背景粒子绘制器
class _BackgroundParticlesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // 绘制一些背景粒子
    for (int i = 0; i < 20; i++) {
      final x = (i * 37) % size.width;
      final y = (i * 73) % size.height;
      canvas.drawCircle(Offset(x, y), 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 连接线绘制器
class _ConnectionLinesPainter extends CustomPainter {
  final List<Bubble> selectedBubbles;

  _ConnectionLinesPainter(this.selectedBubbles);

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedBubbles.length < 2) return;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 绘制选中气泡之间的连线
    for (int i = 0; i < selectedBubbles.length - 1; i++) {
      for (int j = i + 1; j < selectedBubbles.length; j++) {
        canvas.drawLine(
          selectedBubbles[i].position,
          selectedBubbles[j].position,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 