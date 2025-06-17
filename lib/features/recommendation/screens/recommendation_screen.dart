import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/recommendation_controller.dart';
import '../widgets/food_card_widget.dart';
import '../widgets/recommendation_stats_widget.dart';
import '../widgets/empty_recommendation_widget.dart';

/// 推荐结果界面
class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F0F23),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<RecommendationController>(
            builder: (context, controller, child) {
              return CustomScrollView(
                slivers: [
                  // 应用栏
                  _buildSliverAppBar(context, controller),
                  
                  // 统计信息
                  if (controller.recommendations.isNotEmpty)
                    _buildStatsSection(controller),
                  
                  // 推荐内容
                  _buildRecommendationContent(controller),

                  // 操作按钮
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildActionButtons(context, controller),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context, RecommendationController controller) {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.menu_book),
          label: const Text('制作菜谱'),
          onPressed: () {
            // TODO: 获取当前选中的菜品名称
            final String foodName = controller.recommendations.isNotEmpty ? controller.recommendations.first.name : "美食";
            controller.openRecipe(foodName);
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50), 
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.delivery_dining),
          label: const Text('点外卖'),
          onPressed: () {
            // TODO: 获取当前选中的菜品名称
            final String foodName = controller.recommendations.isNotEmpty ? controller.recommendations.first.name : "美食";
            // 弹出选择外卖平台的对话框
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('选择外卖平台'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.storefront), // 可以替换为美团的图标
                        title: const Text('美团外卖'),
                        onTap: () {
                          Navigator.of(context).pop();
                          controller.openFoodDelivery(foodName, platform: 'meituan');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.electric_moped), // 可以替换为饿了么的图标
                        title: const Text('饿了么'),
                        onTap: () {
                          Navigator.of(context).pop();
                          controller.openFoodDelivery(foodName, platform: 'eleme');
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.restaurant),
          label: const Text('附近餐厅'),
          onPressed: () {
            // TODO: 获取当前选中的菜品名称
            final String foodName = controller.recommendations.isNotEmpty ? controller.recommendations.first.name : "美食";
            controller.openNearbyRestaurants(foodName);
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  /// 构建应用栏
  Widget _buildSliverAppBar(BuildContext context, RecommendationController controller) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: const Text(
            '为你推荐',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.purple.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (controller.recommendations.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _refreshRecommendations(context, controller),
          ),
      ],
    );
  }

  /// 构建统计信息区域
  Widget _buildStatsSection(RecommendationController controller) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: RecommendationStatsWidget(
              stats: controller.getRecommendationStats(),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建推荐内容区域
  Widget _buildRecommendationContent(RecommendationController controller) {
    if (controller.isLoading) {
      return _buildLoadingState();
    }

    if (controller.errorMessage != null) {
      return _buildErrorState(controller.errorMessage!);
    }

    if (controller.recommendations.isEmpty) {
      return SliverToBoxAdapter(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: const EmptyRecommendationWidget(),
          ),
        ),
      );
    }

    return _buildRecommendationList(controller);
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return SliverToBoxAdapter(
      child: Container(
        height: 400,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                strokeWidth: 3,
              ),
              SizedBox(height: 24),
              Text(
                '正在为你精心挑选...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(String errorMessage) {
    return SliverToBoxAdapter(
      child: Container(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _refreshRecommendations(context, 
                  Provider.of<RecommendationController>(context, listen: false)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建推荐列表
  Widget _buildRecommendationList(RecommendationController controller) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final food = controller.recommendations[index];
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, 0.5 + (index * 0.1)),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  (index * 0.1).clamp(0.0, 0.8),
                  ((index * 0.1) + 0.2).clamp(0.2, 1.0),
                  curve: Curves.easeOutCubic,
                ),
              )),
              child: FadeTransition(
                opacity: Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (index * 0.1).clamp(0.0, 0.8),
                    ((index * 0.1) + 0.3).clamp(0.3, 1.0),
                    curve: Curves.easeIn,
                  ),
                )),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: FoodCardWidget(
                    food: food,
                    onLike: (foodId) => context.read<BubbleController>().toggleFoodFavorite(foodId),
                    onDislike: (foodId) => context.read<BubbleController>().toggleFoodFavorite(foodId),
                    onTap: () => _navigateToFoodDetail(context, food),
                  ),
                ),
              ),
            );
          },
          childCount: controller.recommendations.length,
        ),
      ),
    );
  }

  /// 刷新推荐
  void _refreshRecommendations(BuildContext context, RecommendationController controller) {
    // 这里应该获取当前选中的气泡
    // 暂时使用空列表，实际应用中需要从气泡控制器获取
    context.read<BubbleController>().generateRecommendations();
    
    _animationController.reset();
    _animationController.forward();
  }

  /// 导航到食物详情
  void _navigateToFoodDetail(BuildContext context, dynamic food) {
    Navigator.pushNamed(
      context,
      '/food-detail',
      arguments: food,
    );
  }
}