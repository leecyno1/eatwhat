import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/bubble_controller.dart';
import '../widgets/bubble_widget.dart';
import '../widgets/optimized_bubble_widget.dart';
import '../../recommendation/screens/recommendation_screen.dart';
import '../../../core/utils/ui_optimizer.dart';
import '../../../core/utils/memory_manager.dart';

/// 气泡主界面
class BubbleScreen extends StatefulWidget {
  const BubbleScreen({Key? key}) : super(key: key);

  @override
  State<BubbleScreen> createState() => _BubbleScreenState();
}

class _BubbleScreenState extends State<BubbleScreen>
    with TickerProviderStateMixin, UIOptimizationMixin, MemoryManagementMixin {
  late AnimationController _backgroundController;
  late Animation<Color?> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    
    // 初始化背景动画
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    
    _backgroundAnimation = ColorTween(
      begin: const Color(0xFFFFF3E0), // 主色调 - 暖黄
      end: const Color(0xFFE3F2FD),   // 辅助色 - 淡蓝
    ).animate(_backgroundController);
    
    _backgroundController.repeat(reverse: true);
    
    // 注册动画控制器到UI优化器
    registerAnimation(_backgroundController);
    
    // 延迟初始化控制器，等待布局完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<BubbleController>();
      final size = MediaQuery.of(context).size;
      controller.initialize(size);
    });
  }

  @override
  void dispose() {
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _backgroundAnimation.value ?? const Color(0xFFFFF3E0), // 主色调 - 暖黄
                  Colors.white, // 中性色
                  const Color(0xFFE3F2FD),   // 辅助色 - 淡蓝
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

  /// 构建头部
  Widget _buildHeader() {
    return Consumer<BubbleController>(
      builder: (context, controller, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                '吃什么',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF8A65), // 主色调 - 暖橙
                ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.selectedCount > 0
                    ? '已选择 ${controller.selectedCount} 个口味'
                    : '点击气泡选择你的口味偏好',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              if (controller.selectedCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '左滑不喜欢，右滑喜欢，点击选择',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// 构建气泡区域
  Widget _buildBubbleArea() {
    return Consumer<BubbleController>(
      builder: (context, controller, child) {
        if (!controller.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return GestureDetector(
          onTapDown: (details) {
            // 在点击位置添加排斥力
            controller.repelBubblesFromPosition(
              details.localPosition,
              strength: 5.0,
            );
          },
          // onPanUpdate 已被移除，拖拽逻辑由BubbleWidget处理
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: controller.bubbles.map((bubble) {
                return Positioned(
                  left: bubble.position.dx - bubble.size / 2,
                  top: bubble.position.dy - bubble.size / 2,
                  child: AnimatedOpacity(
                    opacity: bubble.opacity, // 恢复 AnimatedOpacity
                    duration: const Duration(milliseconds: 300),
                    child: OptimizedBubbleWidget(
                      bubble: bubble,
                      onTap: () {
                        optimizedHapticFeedback(HapticFeedbackType.selectionClick);
                        controller.toggleBubble(bubble);
                      },
                      onGesture: (bubble, gesture, {details}) => controller.handleBubbleGesture(
                        bubble,
                        gesture,
                        dragDetails: details,
                      ),
                      isSelected: bubble.isSelected,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  /// 构建底部控制区域
  Widget _buildBottomControls() {
    return Consumer<BubbleController>(
      builder: (context, controller, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 选中的气泡预览
              if (controller.selectedCount > 0) ...[
                Container(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.selectedBubbles.length,
                    itemBuilder: (context, index) {
                      final bubble = controller.selectedBubbles[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(bubble.name),
                          backgroundColor: bubble.color.withValues(alpha: 0.3),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => controller.deselectBubble(bubble),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // 操作按钮
              Row(
                children: [
                  // 重置按钮
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.selectedCount > 0
                          ? controller.resetSelection
                          : controller.resetAllBubbles,
                      icon: const Icon(Icons.refresh),
                      label: Text(controller.selectedCount > 0 ? '重置选择' : '重置气泡'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // 生成推荐按钮
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: controller.selectedCount > 0 && !controller.isGeneratingRecommendations
                          ? () => _generateRecommendations(controller)
                          : null,
                      icon: controller.isGeneratingRecommendations
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.restaurant),
                      label: Text(
                        controller.isGeneratingRecommendations
                            ? '生成中...'
                            : '生成推荐',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 生成推荐并跳转到推荐页面
  Future<void> _generateRecommendations(BubbleController controller) async {
    await controller.generateRecommendations();
    
    if (mounted && controller.recommendations.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const RecommendationScreen(),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('暂时没有找到合适的推荐，请尝试选择不同的口味组合'),
        ),
      );
    }
  }
}