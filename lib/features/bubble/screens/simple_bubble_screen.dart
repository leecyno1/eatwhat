import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/bubble.dart';
import '../widgets/simple_bubble_widget.dart';
import '../controllers/bubble_controller.dart';

/// 简化的气泡主界面
class SimpleBubbleScreen extends StatefulWidget {
  const SimpleBubbleScreen({Key? key}) : super(key: key);

  @override
  State<SimpleBubbleScreen> createState() => _SimpleBubbleScreenState();
}

class _SimpleBubbleScreenState extends State<SimpleBubbleScreen> {
  @override
  void initState() {
    super.initState();
    
    // 初始化气泡控制器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<BubbleController>();
      final size = MediaQuery.of(context).size;
      controller.initialize(size);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF0F0F23),
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
            '点击气泡选择你的偏好',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleArea() {
    return Consumer<BubbleController>(
      builder: (context, controller, child) {
        if (!controller.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          );
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: controller.bubbles.map((bubble) {
              return Positioned(
                left: bubble.position.dx - bubble.size / 2,
                top: bubble.position.dy - bubble.size / 2,
                child: SimpleBubbleWidget(
                  bubble: bubble,
                  onTap: () => controller.toggleBubble(bubble),
                ),
              );
            }).toList(),
          ),
        );
      },
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
                    color: Colors.white.withOpacity(0.1),
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
            : Colors.white.withOpacity(0.1),
        foregroundColor: isPrimary ? Colors.white : Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: isPrimary ? 8 : 2,
      ),
    );
  }

  void _generateRecommendations() async {
    final controller = context.read<BubbleController>();
    await controller.generateRecommendations();
    
    if (mounted) {
      Navigator.pushNamed(context, '/recommendations');
    }
  }
} 