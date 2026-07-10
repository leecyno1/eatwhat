import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:glassmorphism/glassmorphism.dart';

import '../../../core/models/food.dart';
import '../../../core/services/unified_food_data_service.dart';
import '../../../core/services/user_preference_manager.dart'
    show UserActionType;

/// 增强食物推荐卡片 - Phase 1 UI优化
/// 支持玻璃态效果、动画、推荐原因显示等
class EnhancedFoodCard extends StatefulWidget {
  final Food food;
  final VoidCallback? onTap;
  final String? recommendationReason;
  final bool showRecommendationReason;
  final bool compactMode;

  const EnhancedFoodCard({
    super.key,
    required this.food,
    this.onTap,
    this.recommendationReason,
    this.showRecommendationReason = false,
    this.compactMode = false,
  });

  @override
  State<EnhancedFoodCard> createState() => _EnhancedFoodCardState();
}

class _EnhancedFoodCardState extends State<EnhancedFoodCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isFavorite = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _isFavorite = widget.food.isFavorite;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: widget.compactMode ? 8.0 : 12.0,
            vertical: 6.0,
          ),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: widget.compactMode ? 120 : 160,
            borderRadius: 16,
            blur: 10,
            alignment: Alignment.bottomCenter,
            border: 2,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            child: _buildCardContent(context),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: 100.ms)
        .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildCardContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // 食物图片
          _buildFoodImage(),

          const SizedBox(width: 12),

          // 食物信息
          Expanded(
            child: _buildFoodInfo(context),
          ),

          // 操作按钮
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildFoodImage() {
    return Hero(
      tag: 'food-${widget.food.id}',
      child: Container(
        width: widget.compactMode ? 60 : 80,
        height: widget.compactMode ? 60 : 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child:
              widget.food.imageUrl != null && widget.food.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.food.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Icon(
        Icons.restaurant,
        color: Theme.of(context).primaryColor,
        size: widget.compactMode ? 24 : 32,
      ),
    );
  }

  Widget _buildFoodInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 菜名和标签
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.food.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!widget.compactMode) ...[
              const SizedBox(height: 4),
              Text(
                widget.food.description ?? '美味可口，值得一试',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            _buildTags(context),
          ],
        ),

        // 评分和其他信息
        _buildMetadata(context),
      ],
    );
  }

  Widget _buildTags(BuildContext context) {
    final visibleTags =
        (widget.food.tasteAttributes ?? const <String>[]).take(3).toList();
    if (visibleTags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: visibleTags.map((tag) => _buildTag(context, tag)).toList(),
    );
  }

  Widget _buildTag(BuildContext context, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getTagColor(tag).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getTagColor(tag).withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        tag,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getTagColor(tag),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case '辣':
      case '麻辣':
      case '香辣':
        return Colors.red;
      case '甜':
      case '酸甜':
        return Colors.pink;
      case '清淡':
      case '鲜':
        return Colors.green;
      case '香':
      case '浓郁':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMetadata(BuildContext context) {
    return Row(
      children: [
        // 评分
        Icon(
          Icons.star,
          size: 14,
          color: Colors.amber,
        ),
        const SizedBox(width: 2),
        Text(
          '${widget.food.rating.toStringAsFixed(1)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),

        if (!widget.compactMode) ...[
          const SizedBox(width: 8),
          Container(
            width: 2,
            height: 2,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.food.cuisineType ?? '其他',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
        ],

        // 推荐原因
        if (widget.showRecommendationReason &&
            widget.recommendationReason != null) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.recommendationReason!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 收藏按钮
        GestureDetector(
          onTap: _toggleFavorite,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isFavorite
                  ? Colors.red.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: _isFavorite ? Colors.red : Colors.grey,
            ),
          ),
        )
            .animate(target: _isFavorite ? 1.0 : 0.0)
            .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.2, 1.2))
            .then()
            .scale(begin: const Offset(1.2, 1.2), end: const Offset(1.0, 1.0)),

        if (!widget.compactMode) ...[
          const SizedBox(height: 8),
          // 菜谱按钮
          GestureDetector(
            onTap: _viewRecipe,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.menu_book_outlined,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _toggleFavorite() async {
    // 添加触觉反馈
    // HapticFeedback.lightImpact();

    setState(() {
      _isFavorite = !_isFavorite;
    });

    // 调用统一服务处理收藏
    try {
      final unifiedService = UnifiedFoodDataService();
      await unifiedService.toggleFoodFavorite(widget.food.id);
      await unifiedService.recordUserAction(
        widget.food.id,
        UserActionType.favorite,
      );
    } catch (e) {
      debugPrint('切换收藏状态失败: $e');
      // 恢复状态
      setState(() {
        _isFavorite = !_isFavorite;
      });
    }
  }

  Future<void> _viewRecipe() async {
    try {
      final unifiedService = UnifiedFoodDataService();

      // 记录查看行为
      await unifiedService.recordUserAction(
        widget.food.id,
        UserActionType.view,
      );

      // 获取详细菜谱信息
      final recipe = await unifiedService.getRecipeByFoodId(widget.food.id);

      if (recipe != null && mounted) {
        // 这里可以导航到菜谱详情页
        // Navigator.of(context).push(...);
        debugPrint('查看菜谱: ${recipe.name}');
      }
    } catch (e) {
      debugPrint('查看菜谱失败: $e');
    }
  }
}
