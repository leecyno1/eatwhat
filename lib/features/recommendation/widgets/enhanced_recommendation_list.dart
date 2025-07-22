import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/food.dart';
import 'enhanced_food_card.dart';

/// 增强推荐列表组件 - Phase 1 UI优化
/// 支持瀑布流布局、分类显示、动画效果
class EnhancedRecommendationList extends StatefulWidget {
  final List<Food> foods;
  final ScrollController? scrollController;
  final Function(Food)? onFoodTap;
  final Function(String)? onCategoryTap;
  final bool showCategoryHeaders;
  final bool isLoading;
  final bool compactMode;

  const EnhancedRecommendationList({
    super.key,
    required this.foods,
    this.scrollController,
    this.onFoodTap,
    this.onCategoryTap,
    this.showCategoryHeaders = true,
    this.isLoading = false,
    this.compactMode = false,
  });

  @override
  State<EnhancedRecommendationList> createState() => _EnhancedRecommendationListState();
}

class _EnhancedRecommendationListState extends State<EnhancedRecommendationList>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  Map<String, List<Food>> _categorizedFoods = {};
  String _selectedCategory = '全部';

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    if (widget.isLoading) {
      _loadingController.repeat();
    }
    
    _categorizeFoods();
  }

  @override
  void didUpdateWidget(EnhancedRecommendationList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.foods != widget.foods) {
      _categorizeFoods();
    }
    
    if (oldWidget.isLoading != widget.isLoading) {
      if (widget.isLoading) {
        _loadingController.repeat();
      } else {
        _loadingController.stop();
      }
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  void _categorizeFoods() {
    _categorizedFoods.clear();
    _categorizedFoods['全部'] = widget.foods;
    
    // 按菜系分类
    final cuisineGroups = <String, List<Food>>{};
    for (final food in widget.foods) {
      cuisineGroups.putIfAbsent(food.cuisineType, () => []).add(food);
    }
    _categorizedFoods.addAll(cuisineGroups);
    
    // 按口味分类
    final tasteGroups = <String, List<Food>>{};
    for (final food in widget.foods) {
      for (final taste in food.tasteAttributes) {
        if (['辣', '甜', '清淡', '香'].contains(taste)) {
          tasteGroups.putIfAbsent(taste, () => []).add(food);
        }
      }
    }
    _categorizedFoods.addAll(tasteGroups);
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }
    
    if (widget.foods.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        if (widget.showCategoryHeaders) ...[
          _buildCategoryTabs(),
          const SizedBox(height: 16),
        ],
        
        Expanded(
          child: _buildRecommendationGrid(),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    final categories = _categorizedFoods.keys.toList();
    
    return Container(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
              widget.onCategoryTap?.call(category);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                category,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationGrid() {
    final currentFoods = _categorizedFoods[_selectedCategory] ?? [];
    
    if (currentFoods.isEmpty) {
      return _buildEmptyState();
    }

    return AnimationLimiter(
      child: ListView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: currentFoods.length,
        itemBuilder: (context, index) {
          final food = currentFoods[index];
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: EnhancedFoodCard(
                  food: food,
                  onTap: () => widget.onFoodTap?.call(food),
                  recommendationReason: _generateRecommendationReason(food),
                  showRecommendationReason: true,
                  compactMode: widget.compactMode,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // 加载中的分类标签动画
        Container(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: _buildShimmerBox(
                  width: 60 + (index * 10).toDouble(),
                  height: 32,
                  borderRadius: 20,
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 加载中的卡片动画
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: _buildShimmerBox(
                  width: double.infinity,
                  height: widget.compactMode ? 120 : 160,
                  borderRadius: 16,
                ),
              ).animate(delay: Duration(milliseconds: index * 100))
               .shimmer(duration: 1500.ms);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.5),
            Theme.of(context).colorScheme.surface,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.easeOut)
              .then()
              .shake(hz: 2, duration: 1000.ms),
          
          const SizedBox(height: 16),
          
          Text(
            '暂无推荐',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '尝试选择不同的口味偏好\n或者浏览其他分类',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          
          const SizedBox(height: 24),
          
          ElevatedButton.icon(
            onPressed: () {
              // 重新生成推荐
              setState(() {
                _selectedCategory = '全部';
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('换个口味'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 300.ms)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  String? _generateRecommendationReason(Food food) {
    // 根据食物特征生成推荐理由
    if (food.rating >= 4.5) {
      return '高分推荐';
    }
    
    if (food.tasteAttributes.contains('辣')) {
      return '符合辣味偏好';
    }
    
    if (food.tasteAttributes.contains('清淡')) {
      return '清爽口感';
    }
    
    if (food.cuisineType.contains('川菜')) {
      return '经典川菜';
    }
    
    if (food.preparationTime?.contains('30') == true) {
      return '快手菜';
    }
    
    return null;
  }
}

/// 推荐统计信息组件
class RecommendationStats extends StatelessWidget {
  final int totalCount;
  final Map<String, int> categoryStats;
  final double averageRating;

  const RecommendationStats({
    super.key,
    required this.totalCount,
    required this.categoryStats,
    required this.averageRating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '推荐统计',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(context, '总数', '$totalCount', Icons.restaurant),
              _buildStatItem(context, '平均评分', averageRating.toStringAsFixed(1), Icons.star),
              _buildStatItem(context, '菜系', '${categoryStats.length}', Icons.category),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}