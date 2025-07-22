import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../bubble/controllers/bubble_controller.dart';
import '../../../shared/widgets/modern_loading_animation.dart';
import '../widgets/channel_selector_dialog.dart';

/// 推荐结果页面 - 优化版本
class RecommendationScreenNew extends StatefulWidget {
  const RecommendationScreenNew({super.key});

  @override
  State<RecommendationScreenNew> createState() =>
      _RecommendationScreenNewState();
}

class _RecommendationScreenNewState extends State<RecommendationScreenNew>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('推荐结果'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.orange.shade700,
        actions: [
          Consumer<BubbleController>(
            builder: (context, controller, child) {
              return IconButton(
                onPressed: () => _regenerateRecommendations(controller),
                icon: controller.isGeneratingRecommendations
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: '重新生成',
              );
            },
          ),
        ],
      ),
      body: Consumer<BubbleController>(
        builder: (context, controller, child) {
          if (controller.isGeneratingRecommendations) {
            return _buildLoadingState();
          }

          if (controller.recommendations.isEmpty) {
            return _buildEmptyState(controller);
          }

          return _buildRecommendationList(controller);
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return const Center(
      child: FoodRecommendationLoading(message: 'AI正在为您精心挑选美食...'),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BubbleController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star),
          const SizedBox(height: 24),
          Text(
            '暂时没有找到合适的推荐',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '尝试选择不同的口味组合',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('重新选择'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建推荐列表 - 优化的网格布局
  Widget _buildRecommendationList(BubbleController controller) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.grey.shade50.withOpacity(0.98),
            ],
          ),
        ),
        child: Column(
          children: [
            // 选择的口味标签
            _buildSelectedTags(controller),

            // 推荐列表 - 瀑布流网格布局
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 每行2个卡片
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.7, // 高宽比，显示更多内容
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final food = controller.recommendations[index];
                            return _buildPremiumFoodCard(food, index);
                          },
                          childCount: controller.recommendations.length,
                        ),
                      ),
                    ),
                    const SliverPadding(
                      padding: EdgeInsets.only(bottom: 100), // 为底部操作栏预留空间
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建高级美食卡片 - 玻璃质感和透明效果
  Widget _buildPremiumFoodCard(dynamic food, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + index * 100),
      curve: Curves.easeOutBack,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectFood(food),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              // 玻璃质感渐变背景
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.85),
                  Colors.grey.shade100.withOpacity(0.9),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              // 多层阴影效果
              boxShadow: [
                // 主要阴影
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                // 高光阴影
                BoxShadow(
                  color: Colors.white.withOpacity(0.9),
                  blurRadius: 12,
                  spreadRadius: -4,
                  offset: const Offset(0, -2),
                ),
                // 边缘光晕
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
              // 玻璃边框
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 食物图片区域 - 增大比例
                  Expanded(
                    flex: 4,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        // 图片背景渐变
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.orange.shade50.withOpacity(0.8),
                            Colors.orange.shade100.withOpacity(0.6),
                            Colors.orange.shade200.withOpacity(0.4),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // 美食emoji或图片
                          Center(
                            child: Text(
                              food.emoji ?? '🍽️',
                              style: const TextStyle(fontSize: 56),
                            ),
                          ),

                          // 评分角标 - 玻璃质感
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                // 玻璃质感背景
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.9),
                                    Colors.white.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.orange.shade600,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    (food.score ?? 4.5).toStringAsFixed(1),
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 渐变遮罩 - 增强层次感
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 食物信息区域
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        // 信息区域渐变背景
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.98),
                            Colors.grey.shade50.withOpacity(0.95),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 食物名称
                          Text(
                            food.name ?? '美食',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // 食物描述
                          if (food.description != null)
                            Text(
                              food.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                          const Spacer(),

                          // 选择按钮 - 玻璃质感
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _selectFood(food),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.withOpacity(0.9),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: Colors.orange.withOpacity(0.3),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                '选择',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 选择美食后显示获取渠道
  void _selectFood(dynamic food) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => ChannelSelectorDialog(
        selectedFood: food,
      ),
    );
  }

  /// 构建选择的口味标签
  Widget _buildSelectedTags(BubbleController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.grey.shade50.withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '基于您的口味偏好',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: controller.selectedBubbles.map((bubble) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      bubble.color.withOpacity(0.2),
                      bubble.color.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: bubble.color.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  bubble.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: bubble.color.withOpacity(0.8),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 构建底部操作栏
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.98),
            Colors.grey.shade50.withOpacity(0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('重新选择'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Consumer<BubbleController>(
              builder: (context, controller, child) {
                return ElevatedButton.icon(
                  onPressed: controller.isGeneratingRecommendations
                      ? null
                      : () => _regenerateRecommendations(controller),
                  icon: controller.isGeneratingRecommendations
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(controller.isGeneratingRecommendations
                      ? '生成中...'
                      : '换一批'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 2,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 重新生成推荐
  Future<void> _regenerateRecommendations(BubbleController controller) async {
    await controller.generateRecommendations();

    if (mounted && controller.recommendations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('暂时没有找到新的推荐，请尝试调整口味偏好'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
