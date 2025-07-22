import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../bubble/controllers/bubble_controller.dart';
import '../widgets/food_card.dart';
import '../../../shared/widgets/modern_loading_animation.dart';
import '../../../shared/widgets/page_transitions.dart';

/// 推荐结果页面
class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen>
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
      child: FoodRecommendationLoading(
        message: 'AI正在为您精心挑选美食...'
      ),
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

  /// 构建推荐列表
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

            // 推荐列表 - 优化为瀑布流布局
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 每行显示2个
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75, // 调整高宽比显示更多照片
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final food = controller.recommendations[index];
                            return _buildEnhancedFoodCard(food, index);
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

  /// 构建增强的美食卡片
  Widget _buildEnhancedFoodCard(dynamic food, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 8,
            spreadRadius: -2,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 食物图片
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.orange.shade100.withOpacity(0.5),
                      Colors.orange.shade200.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // 美食图片占位或实际图片
                    Center(
                      child: Text(
                        food.emoji ?? '🍽️',
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                    // 评分角标
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              (food.score ?? 4.5).toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
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
            
            // 食物信息
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
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
                    // 食物名称
                    Text(
                      food.name ?? '美食',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // 食物描述或标签
                    if (food.description != null)
                      Text(
                        food.description!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const Spacer(),
                    
                    // 操作按钮
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _selectFood(food),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.withOpacity(0.8),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '选择',
                          style: TextStyle(
                            fontSize: 12,
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
    );
  }

  /// 选择美食后的处理
  void _selectFood(dynamic food) {
    // TODO: 实现选择美食后弹出获取渠道页面
    _showFoodChannelsDialog(food);
  }

  /// 显示美食获取渠道对话框
  void _showFoodChannelsDialog(dynamic food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // 拖拽指示器
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 标题
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '获取 ${food.name ?? '美食'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // 渠道选项
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildChannelOption(
                      icon: Icons.restaurant,
                      title: '查看菜谱',
                      subtitle: '学习制作方法，在家烹饪',
                      color: Colors.green,
                      onTap: () => _openRecipeChannel(food),
                    ),
                    _buildChannelOption(
                      icon: Icons.delivery_dining,
                      title: '外卖订购',
                      subtitle: '快速配送到家',
                      color: Colors.blue,
                      onTap: () => _openDeliveryChannel(food),
                    ),
                    _buildChannelOption(
                      icon: Icons.location_on,
                      title: '附近餐厅',
                      subtitle: '大众点评推荐餐厅',
                      color: Colors.orange,
                      onTap: () => _openRestaurantChannel(food),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建渠道选项
  Widget _buildChannelOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 打开菜谱渠道
  void _openRecipeChannel(dynamic food) {
    Navigator.pop(context); // 关闭底部弹窗
    // TODO: 导航到菜谱详情页面
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在查找${food.name}的菜谱...')),
    );
  }

  /// 打开外卖渠道
  void _openDeliveryChannel(dynamic food) {
    Navigator.pop(context); // 关闭底部弹窗
    // TODO: 集成外卖API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在搜索${food.name}的外卖...')),
    );
  }

  /// 打开餐厅渠道
  void _openRestaurantChannel(dynamic food) {
    Navigator.pop(context); // 关闭底部弹窗
    // TODO: 集成大众点评API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在查找附近提供${food.name}的餐厅...')),
    );
  }
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.recommendations.length,
              itemBuilder: (context, index) {
                final food = controller.recommendations[index];
                return ListItemTransition(
                  index: index,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300 + index * 100),
                    curve: Curves.easeOutBack,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: FoodCard(
                      food: food,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _showFoodDetail(food);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建选择的口味标签
  Widget _buildSelectedTags(BubbleController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '基于您的口味偏好',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: controller.selectedBubbles.map((bubble) {
              return Chip(
                label: Text(
                  bubble.name,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: bubble.color.withValues(alpha: 0.2),
                side: BorderSide(color: bubble.color, width: 1),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('重新选择'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Consumer<BubbleController>(
              builder: (context, controller, child) {
                return LoadingButton(
                  text: '换一批',
                  loadingText: '生成中...',
                  isLoading: controller.isGeneratingRecommendations,
                  onPressed: controller.isGeneratingRecommendations
                      ? null
                      : () => _regenerateRecommendations(controller),
                  backgroundColor: Colors.orange,
                  textColor: Colors.white,
                  loadingType: LoadingAnimationType.bubbles,
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
        ),
      );
    }
  }

  /// 显示食物详情
  void _showFoodDetail(dynamic food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // 拖拽指示器
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 食物详情内容
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name ?? '未知美食',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        if (food.description != null) ...[
                          Text(
                            food.description!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 其他食物信息可以在这里添加
                        Text(
                          '推荐理由',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '基于您选择的口味偏好，这道美食非常适合您的口味！',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
