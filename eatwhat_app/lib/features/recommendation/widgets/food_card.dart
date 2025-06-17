import 'package:flutter/material.dart';
import '../../../core/models/food.dart';

/// 食物推荐卡片组件
class FoodCard extends StatefulWidget {
  final Food food;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool showFavoriteButton;

  const FoodCard({
    Key? key,
    required this.food,
    this.onTap,
    this.onFavorite,
    this.showFavoriteButton = true,
  });

  @override
  State<FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<FoodCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildCard(),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片区域
            _buildImageSection(),
            
            // 内容区域
            _buildContentSection(),
          ],
        ),
      ),
    );
  }

  /// 构建图片区域
  Widget _buildImageSection() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade200,
            Colors.orange.shade400,
          ],
        ),
      ),
      child: Stack(
        children: [
          // 背景图片或占位符
          if (widget.food.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                widget.food.imageUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
              ),
            )
          else
            _buildImagePlaceholder(),
          
          // 收藏按钮
          if (widget.showFavoriteButton)
            Positioned(
              top: 12,
              right: 12,
              child: _buildFavoriteButton(),
            ),
          
          // 评分标签
          Positioned(
            bottom: 12,
            left: 12,
            child: _buildRatingBadge(),
          ),
        ],
      ),
    );
  }

  /// 构建图片占位符
  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade200,
            Colors.orange.shade400,
          ],
        ),
      ),
      child: Icon(
        Icons.restaurant,
        size: 48,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }

  /// 构建收藏按钮
  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: widget.onFavorite,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          widget.food.isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 20,
          color: widget.food.isFavorite ? Colors.red : Colors.grey.shade600,
        ),
      ),
    );
  }

  /// 构建评分标签
  Widget _buildRatingBadge() {
    if (widget.food.rating <= 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            size: 14,
            color: Colors.amber,
          ),
          const SizedBox(width: 4),
          Text(
            widget.food.rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.food.ratingCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              '(${widget.food.ratingCount})',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 食物名称和价格
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.food.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.food.price != null) ...[
                const SizedBox(width: 8),
                Text(
                  '¥${widget.food.price!.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.orange.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 描述
          if (widget.food.description != null) ...[
            Text(
              widget.food.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          
          // 标签信息
          _buildTags(),
          
          const SizedBox(height: 12),
          
          // 底部信息
          _buildBottomInfo(),
        ],
      ),
    );
  }

  /// 构建标签
  Widget _buildTags() {
    final tags = <String>[];
    
    // 添加菜系
    tags.add(widget.food.cuisineType);
    
    // 添加主要口味特点（最多2个）
    if (widget.food.tasteAttributes.isNotEmpty) {
      tags.addAll(widget.food.tasteAttributes.take(2));
    }
    
    if (tags.isEmpty) return const SizedBox.shrink();
    
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orange.shade200,
              width: 0.5,
            ),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建底部信息
  Widget _buildBottomInfo() {
    final infoItems = <Widget>[];
    
    // 热量信息
    if (widget.food.calories != null) {
      infoItems.add(_buildInfoItem(
        Icons.local_fire_department,
        '${widget.food.calories} 卡',
        Colors.red.shade400,
      ));
    }
    
    // 餐厅信息
    if (widget.food.restaurant != null) {
      infoItems.add(_buildInfoItem(
        Icons.store,
        widget.food.restaurant!,
        Colors.blue.shade400,
      ));
    }
    
    if (infoItems.isEmpty) return const SizedBox.shrink();
    
    return Row(
      children: [
        for (int i = 0; i < infoItems.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: infoItems[i]),
        ],
      ],
    );
  }

  /// 构建信息项
  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
} 