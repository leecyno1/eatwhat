import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../bubble/controllers/bubble_controller.dart';
import '../../../core/models/food.dart';
import '../../../core/services/incremental_learning_service.dart';
import '../../../shared/widgets/taste_feedback_slider.dart';
import '../widgets/food_recommendation_loading.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/themes/design_tokens.dart';
import '../../../shared/widgets/ui/rounded_card.dart';

/// 推荐结果页面
class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> with TickerProviderStateMixin {
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
      appBar: AppBar(
        title: const Text('推荐结果'),
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

  /// 构建推荐列表
  Widget _buildRecommendationList(BubbleController controller) {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          _buildSelectedTags(controller),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.recommendations.length,
              itemBuilder: (context, index) {
                final food = controller.recommendations[index];
                return _buildEnhancedFoodCard(food, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建增强的美食卡片
  Widget _buildEnhancedFoodCard(Food food, int index) {
    return RoundedCard(
      padding: const EdgeInsets.all(0),
      child: ClipRRect(
        borderRadius: DesignTokens.bigRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 食物图片
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: DesignTokens.surfaceMuted,
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
                          color: DesignTokens.orange,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: DesignTokens.softShadows(),
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
                color: DesignTokens.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 食物名称
                    Text(
                      food.name ?? '美食',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, color: DesignTokens.ink),
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

                    // 反馈按钮行
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeedbackButton(
                            icon: Icons.thumb_up_outlined,
                            label: '喜欢',
                            color: Colors.green,
                            onTap: () => _showPositiveFeedback(food, index),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFeedbackButton(
                            icon: Icons.thumb_down_outlined,
                            label: '不感兴趣',
                            color: Colors.grey,
                            onTap: () => _showNegativeFeedback(food, index),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

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

  /// 构建反馈按钮
  Widget _buildFeedbackButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示正向反馈（喜欢）
  void _showPositiveFeedback(Food food, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: TasteFeedbackSlider(
            label: '喜欢这个推荐吗？',
            initialValue: 0.6,
            useStarRating: true,
            onChanged: (intensity) {
              _recordPositiveFeedback(food, index, intensity);
            },
          ),
        ),
      ),
    );
  }

  /// 显示负向反馈（不感兴趣）
  void _showNegativeFeedback(Food food, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: TasteFeedbackSlider(
            label: '为什么不喜欢？',
            initialValue: 0.4,
            useStarRating: true,
            onChanged: (intensity) {
              _recordNegativeFeedback(food, index, intensity);
            },
          ),
        ),
      ),
    );
  }

  /// 记录正向反馈
  void _recordPositiveFeedback(Food food, int index, double intensity) {
    final event = TasteFeedbackEvent(
      recipeId: food.id ?? '',
      intensity: intensity,
      isPositive: true,
      recommendationIndex: index,
      tasteVector: _getTasteVectorFromFood(food),
    );

    IncrementalLearningService().recordFeedback(event);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('感谢您的反馈！已记录 "${food.name}" 的正向反馈'),
        duration: const Duration(seconds: 2),
      ),
    );

    debugPrint('✅ 正向反馈已记录: recipeId=${food.id}, intensity=$intensity, index=$index');
  }

  /// 记录负向反馈
  void _recordNegativeFeedback(Food food, int index, double intensity) {
    final event = TasteFeedbackEvent(
      recipeId: food.id ?? '',
      intensity: intensity,
      isPositive: false,
      recommendationIndex: index,
      tasteVector: _getTasteVectorFromFood(food),
    );

    IncrementalLearningService().recordFeedback(event);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('感谢您的反馈！我们会减少 "${food.name}" 类似推荐'),
        duration: const Duration(seconds: 2),
      ),
    );

    debugPrint('✅ 负向反馈已记录: recipeId=${food.id}, intensity=$intensity, index=$index');
  }

  /// 从 Food 模型提取口味向量
  List<double>? _getTasteVectorFromFood(Food food) {
    // 将 Food 的口味属性转换为 46 维向量
    // 这里简化处理，实际项目应该使用更完整的映射
    final vector = List<double>.filled(46, 0.0);

    // 基本口味（0-9）
    final tasteAttributes = food.tasteAttributes ?? [];
    if (tasteAttributes.contains('甜')) vector[0] = 0.5;
    if (tasteAttributes.contains('酸')) vector[1] = 0.5;
    if (tasteAttributes.contains('辣')) vector[3] = 0.5;
    if (tasteAttributes.contains('咸')) vector[4] = 0.5;
    if (tasteAttributes.contains('鲜')) vector[5] = 0.5;
    if (tasteAttributes.contains('清淡')) vector[7] = 0.5;
    if (tasteAttributes.contains('香')) vector[8] = 0.5;

    // 菜系（30-39）
    final cuisineType = food.cuisineType ?? '';
    final cuisineMap = {
      '川菜': 30, '粤菜': 31, '苏菜': 32, '浙菜': 33,
      '闽菜': 34, '湘菜': 35, '徽菜': 36, '鲁菜': 37,
      '西餐': 38, '日韩': 39,
    };
    if (cuisineMap.containsKey(cuisineType)) {
      vector[cuisineMap[cuisineType]!] = 0.5;
    }

    return vector;
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
                  color: DesignTokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 标题
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '获取 ${food.name ?? '美食'}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: DesignTokens.ink),
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
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignTokens.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: DesignTokens.softShadows(),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
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
                            fontSize: 16, fontWeight: FontWeight.w800, color: DesignTokens.ink),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 13, color: DesignTokens.inkMuted),
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

  /// 切换收藏状态
  void _toggleFavorite(Food food) {
    // TODO: 实现收藏功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${food.name} 已添加到收藏'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
