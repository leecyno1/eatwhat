import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/bubble_controller.dart';
import '../../recommendation/screens/recommendation_screen.dart';
import '../../../shared/widgets/modern_bubble_widget.dart';
import '../../../shared/widgets/modern_loading_animation.dart';

/// 气泡主界面
class BubbleScreen extends StatefulWidget {
  const BubbleScreen({super.key});

  @override
  State<BubbleScreen> createState() => _BubbleScreenState();
}

class _BubbleScreenState extends State<BubbleScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<Color?> _backgroundAnimation;
  bool _useEnhancedBubbles = true; // 控制是否使用增强气泡

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
      end: const Color(0xFFE3F2FD), // 辅助色 - 淡蓝
    ).animate(_backgroundController);

    _backgroundController.repeat(reverse: true);

    // 延迟初始化控制器，等待布局完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<BubbleController>();
      final size = MediaQuery.of(context).size;
      controller.initialize(screenSize: size);
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
                  _backgroundAnimation.value ??
                      const Color(0xFFFFF3E0), // 主色调 - 暖黄
                  Colors.white, // 中性色
                  const Color(0xFFE3F2FD), // 辅助色 - 淡蓝
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
              const SizedBox(height: 16),
              // 液态玻璃效果切换按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '液态玻璃效果:',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: _useEnhancedBubbles,
                    onChanged: (value) {
                      setState(() {
                        _useEnhancedBubbles = value;
                      });
                    },
                    activeColor: const Color(0xFFFF8A65),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _useEnhancedBubbles ? '开启' : '关闭',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _useEnhancedBubbles
                              ? const Color(0xFFFF8A65)
                              : Colors.grey,
                          fontWeight: FontWeight.w500,
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

  /// 构建气泡区域
  Widget _buildBubbleArea() {
    return Consumer<BubbleController>(
      builder: (context, controller, child) {
        if (!controller.isInitialized) {
          return const Center(
            child: ModernLoadingAnimation(
              type: LoadingAnimationType.bubbles,
              color: Colors.orange,
              message: '气泡加载中...'
            ),
          );
        }

        return GestureDetector(
          onTapDown: (details) {
            controller.repelBubblesFromPosition(
              details.localPosition,
              50.0,
            );
          },
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: controller.bubbles.map((bubble) {
                return Positioned(
                  left: bubble.position.dx - bubble.size / 2,
                  top: bubble.position.dy - bubble.size / 2,
                  child: AnimatedOpacity(
                    opacity: bubble.opacity,
                    duration: const Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.toggleBubble(bubble);
                      },
                      child: ModernBubbleWidget(
                        bubble: bubble,
                        isSelected: controller.isBubbleSelected(bubble),
                        isHighlighted: false,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          controller.toggleBubble(bubble);
                        },
                        onLongPress: (name) {
                          // 可扩展：显示气泡详情
                        },
                        onSwipeUp: (name) {
                          controller.likeBubbleByName(name);
                        },
                        onSwipeDown: (name) {
                          controller.dislikeBubbleByName(name);
                        },
                        onSwipeLeft: (name) {
                          controller.ignoreBubbleByName(name);
                        },
                        onSwipeRight: (name) {
                          controller.confirmBubbleByName(name);
                        },
                      ),
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
                SizedBox(
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
                      label: Text(
                          controller.selectedCount > 0 ? '重置选择' : '重置气泡'),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 生成推荐按钮
                  Expanded(
                    flex: 2,
                    child: LoadingButton(
                      text: '生成推荐',
                      loadingText: '生成中...',
                      isLoading: controller.isGeneratingRecommendations,
                      onPressed: controller.selectedCount > 0 &&
                              !controller.isGeneratingRecommendations
                          ? () => _generateRecommendations(controller)
                          : null,
                      backgroundColor: Colors.orange,
                      textColor: Colors.white,
                      loadingType: LoadingAnimationType.bubbles,
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
