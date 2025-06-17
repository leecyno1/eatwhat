import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../bubble/controllers/bubble_controller.dart';
import '../widgets/food_card.dart';
import '../widgets/optimized_food_card.dart';
import '../../../core/utils/ui_optimizer.dart';
import '../../../core/utils/memory_manager.dart';

/// 推荐结果页面
class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen>
    with TickerProviderStateMixin, UIOptimizationMixin, MemoryManagementMixin {
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
    
    // 注册动画控制器到UI优化器
    registerAnimation(_slideController);
    
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
          const SizedBox(height: 24),
          Text(
            '正在为您精心挑选美食...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '根据您的口味偏好生成推荐',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
            ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BubbleController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            '暂时没有找到合适的推荐',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '尝试选择不同的口味组合',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
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
          // 选择的口味标签
          _buildSelectedTags(controller),
          
          // 推荐列表
          Expanded(
            child: OptimizedBuilder<List<dynamic>>(
              valueListenable: controller,
              selector: (controller) => controller.recommendations,
              builder: (context, recommendations) => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final food = recommendations[index];
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300 + index * 100),
                  curve: Curves.easeOutBack,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: OptimizedFoodCard(
                    food: food,
                    onTap: () {
                      optimizedHapticFeedback(HapticFeedbackType.mediumImpact);
                      _showFoodDetail(food);
                    },
                    onFavorite: () {
                      optimizedHapticFeedback(HapticFeedbackType.lightImpact);
                      controller.toggleFoodFavorite(food);
                    },
                  ),
            ),
                );
              },
            ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建选择的口味标签
  Widget _buildSelectedTags(BubbleController controller) {
    if (controller.selectedBubbles.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '基于您的口味偏好：',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
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
            ),
                backgroundColor: bubble.color.withValues(alpha: 0.2),
                side: BorderSide(color: bubble.color, width: 1),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
            blurRadius: 8,
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
                  label: Text(
                    controller.isGeneratingRecommendations ? '生成中...' : '换一批',
                  ),
            ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
            ),
                );
              },
            ),
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
          content: Text('暂时没有找到新的推荐，请尝试调整口味选择'),
        ),
      );
    }
  }

  /// 显示食物详情
  void _showFoodDetail(food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFoodDetailSheet(food),
    );
  }

  /// 构建食物详情弹窗
  Widget _buildFoodDetailSheet(food) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              Text(food.name ?? '未知食物', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('类型: ${food.category ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('评分: ${food.rating?.toStringAsFixed(1) ?? 'N/A'}'),
            ], // TODO: Add more food details here (e.g., description, ingredients, image)
          ),
        ); // Correctly close the Container
      }, // Correctly close the builder
    ); // Correctly close the DraggableScrollableSheet and the return statement
  } // Added missing closing brace for _buildFoodDetailSheet method
} // Added missing closing brace for _RecommendationScreenState class
