import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/bubble_controller.dart';
import '../../recommendation/screens/recommendation_screen.dart';
import '../widgets/modern_bubble_widget.dart';
import '../../../shared/widgets/modern_loading_animation.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/themes/design_tokens.dart';
import '../../../shared/widgets/ui/greeting_header.dart';
import '../../../shared/widgets/ui/stat_pill.dart';
import '../../../shared/widgets/ui/primary_cta_button.dart';
import '../../../shared/widgets/preference_saved_toast.dart';
import '../../../core/utils/analytics_helper.dart';

/// 气泡主界面
class BubbleScreen extends StatefulWidget {
  const BubbleScreen({super.key});

  @override
  State<BubbleScreen> createState() => _BubbleScreenState();
}

class _BubbleScreenState extends State<BubbleScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<Color?> _backgroundAnimation;
  bool _useEnhancedBubbles = true; // 控制是否使用增强气泡

  @override
  void initState() {
    super.initState();

    // 埋点：记录气泡页面进入
    AnalyticsHelper.logPageEnter('bubble_screen');

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

      // 设置偏好保存回调
      controller.onPreferenceSaved = (bool isLike) {
        if (mounted) {
          ToastManager.showPreferenceSavedToast(context, isLike);
        }
      };
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBubbleArea()),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Consumer<BubbleController>(
      builder: (context, controller, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GreetingHeader(title: 'Hi, Chef 👋', subtitle: '选择你的今日口味'),
              Row(
                children: [
                  Expanded(
                    child: StatPill(
                      icon: Icons.bubble_chart_rounded,
                      value: '${controller.bubbles.length}',
                      label: '口味',
                      color: DesignTokens.mint,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatPill(
                      icon: Icons.favorite_rounded,
                      value: '${controller.selectedCount}',
                      label: '已选',
                      color: DesignTokens.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatPill(
                      icon: Icons.timer_rounded,
                      value: '今日',
                      label: '推荐',
                      color: DesignTokens.pink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('增强气泡', style: DesignTokens.caption),
                  Switch.adaptive(
                    value: _useEnhancedBubbles,
                    activeColor: DesignTokens.mint,
                    onChanged: (v) => setState(() => _useEnhancedBubbles = v),
                  )
                ],
              )
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
            child: ModernLoadingAnimation(size: 60, color: Colors.orange, message: '气泡加载中...'),
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
                        onTap: () {
                          HapticFeedback.selectionClick();
                          controller.toggleBubble(bubble);
                        },
                        onLongPress: () {
                          // 可扩展：显示气泡详情
                        },
                        onSwipeUp: () {
                          controller.likeBubbleByName(bubble.name);
                        },
                        onSwipeDown: () {
                          controller.dislikeBubbleByName(bubble.name);
                        },
                        onSwipeLeft: () {
                          controller.ignoreBubbleByName(bubble.name);
                        },
                        onSwipeRight: () {
                          controller.confirmBubbleByName(bubble.name);
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
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.selectedCount > 0
                          ? controller.resetSelection
                          : controller.resetAllBubbles,
                      icon: const Icon(Icons.refresh),
                      label: Text(controller.selectedCount > 0 ? '重置选择' : '重置气泡'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: DesignTokens.pillRadius,
                        boxShadow: DesignTokens.softShadows(),
                      ),
                      child: PrimaryCtaButton(
                        label: controller.isGeneratingRecommendations ? '生成中…' : '生成推荐',
                        icon: Icons.auto_awesome_rounded,
                        onPressed:
                            controller.selectedCount > 0 && !controller.isGeneratingRecommendations
                                ? () => _generateRecommendations(controller)
                                : null,
                      ),
                    ),
                  ),
                ],
              )
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
