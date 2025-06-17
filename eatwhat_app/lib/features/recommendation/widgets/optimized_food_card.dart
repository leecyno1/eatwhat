import 'package:flutter/material.dart';
import '../../../core/models/food.dart';
import '../../../core/utils/performance_optimizer.dart';

/// 优化的食物卡片组件
class OptimizedFoodCard extends StatefulWidget {
  final Food food;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool showAnimation;
  final double? width;
  final double? height;
  
  const OptimizedFoodCard({
    Key? key,
    required this.food,
    this.onTap,
    this.onFavoriteToggle,
    this.showAnimation = true,
    this.width,
    this.height,
  }) : super(key: key);
  
  @override
  State<OptimizedFoodCard> createState() => _OptimizedFoodCardState();
}

class _OptimizedFoodCardState extends State<OptimizedFoodCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  // 性能优化组件
  late final PerformanceOptimizer.DebouncedNotifier _debouncedNotifier;
  late final PerformanceOptimizer.FrameRateLimiter _animationLimiter;
  
  // 缓存的样式和颜色
  late final BoxDecoration _cardDecoration;
  late final TextStyle _titleStyle;
  late final TextStyle _descriptionStyle;
  late final Color _favoriteColor;
  
  bool _isPressed = false;
  bool _isHovered = false;
  
  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // 创建动画
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // 初始化性能优化组件
    _debouncedNotifier = PerformanceOptimizer.DebouncedNotifier(
      delay: const Duration(milliseconds: 16), // 60 FPS
    );
    
    _animationLimiter = PerformanceOptimizer.FrameRateLimiter(
      minInterval: const Duration(milliseconds: 16),
    );
    
    // 缓存样式
    _initializeStyles();
  }
  
  void _initializeStyles() {
    _cardDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
    
    _titleStyle = const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
    
    _descriptionStyle = TextStyle(
      fontSize: 14,
      color: Colors.grey[600],
      height: 1.4,
    );
    
    _favoriteColor = widget.food.isFavorite ? Colors.red : Colors.grey[400]!;
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _debouncedNotifier.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    if (!widget.showAnimation) return;
    
    setState(() {
      _isPressed = true;
    });
    
    if (_animationLimiter.shouldUpdate()) {
      _animationController.forward();
    }
  }
  
  void _handleTapUp(TapUpDetails details) {
    if (!widget.showAnimation) return;
    
    setState(() {
      _isPressed = false;
    });
    
    if (_animationLimiter.shouldUpdate()) {
      _animationController.reverse();
    }
  }
  
  void _handleTapCancel() {
    if (!widget.showAnimation) return;
    
    setState(() {
      _isPressed = false;
    });
    
    if (_animationLimiter.shouldUpdate()) {
      _animationController.reverse();
    }
  }
  
  void _handleTap() {
    _debouncedNotifier.notify(() {
      widget.onTap?.call();
    });
  }
  
  void _handleFavoriteToggle() {
    _debouncedNotifier.notify(() {
      widget.onFavoriteToggle?.call();
    });
  }
  
  void _handleHover(bool isHovered) {
    if (_isHovered != isHovered) {
      setState(() {
        _isHovered = isHovered;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return PerformanceOptimizer.OptimizedBuilder(
      builder: (context) => _buildCard(),
      shouldRebuild: (oldWidget, newWidget) {
        // 只有在关键属性变化时才重建
        if (oldWidget is! OptimizedFoodCard || newWidget is! OptimizedFoodCard) {
          return true;
        }
        
        return oldWidget.food.id != newWidget.food.id ||
               oldWidget.food.isFavorite != newWidget.food.isFavorite ||
               oldWidget.showAnimation != newWidget.showAnimation;
      },
    );
  }
  
  Widget _buildCard() {
    Widget card = Container(
      width: widget.width ?? 280,
      height: widget.height ?? 200,
      decoration: _cardDecoration.copyWith(
        color: _isHovered ? Colors.grey[50] : Colors.white,
      ),
      child: _buildCardContent(),
    );
    
    // 应用动画（如果启用）
    if (widget.showAnimation) {
      card = AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: child,
            ),
          );
        },
        child: card,
      );
    }
    
    // 添加手势检测
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTap: _handleTap,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: card,
      ),
    );
  }
  
  Widget _buildCardContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和收藏按钮
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.food.name,
                  style: _titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildFavoriteButton(),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 描述
          if (widget.food.description.isNotEmpty)
            Expanded(
              child: Text(
                widget.food.description,
                style: _descriptionStyle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          
          const SizedBox(height: 12),
          
          // 标签
          _buildTags(),
        ],
      ),
    );
  }
  
  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: _handleFavoriteToggle,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(
          widget.food.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: _favoriteColor,
          size: 24,
        ),
      ),
    );
  }
  
  Widget _buildTags() {
    List<String> _getTags() {
      final tags = <String>[];
      // Check if tasteAttributes is not null and not empty before adding
      if (widget.food.tasteAttributes != null && widget.food.tasteAttributes!.isNotEmpty) {
      // Add all taste attributes as tags
      tags.addAll(widget.food.tasteAttributes!);
      }
      // Add cuisine type if available
      if (widget.food.cuisineType != null && widget.food.cuisineType!.isNotEmpty) {
      tags.add(widget.food.cuisineType!);
      }
      // Add scenarios if available and not empty
      if (widget.food.scenarios != null && widget.food.scenarios!.isNotEmpty) {
      tags.addAll(widget.food.scenarios!);
      }
      // Add ingredients if available and not empty (maybe only first few or specific ones)
      // For simplicity, let's add the first ingredient if available
      if (widget.food.ingredients != null && widget.food.ingredients!.isNotEmpty) {
      // tags.add(widget.food.ingredients!.first); // Example: add first ingredient
      }
      return tags.take(3).toList(); // Limit to 3 tags
    }
    
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: tags.map((tag) => _buildTag(tag)).toList(),
    );
  }
  
  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 轻量级食物卡片（用于列表场景）
class LightweightFoodCard extends StatelessWidget {
  final Food food;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  
  const LightweightFoodCard({
    Key? key,
    required this.food,
    this.onTap,
    this.onFavoriteToggle,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          food.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: food.description?.isNotEmpty == true
            ? Text(
                food.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: IconButton(
          icon: Icon(
            food.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: food.isFavorite ? Colors.red : Colors.grey[400],
          ),
          onPressed: onFavoriteToggle,
        ),
        onTap: onTap,
      ),
    );
  }
}

/// 食物卡片网格组件
class OptimizedFoodGrid extends StatelessWidget {
  final List<Food> foods;
  final Function(Food)? onFoodTap;
  final Function(Food)? onFavoriteToggle;
  final bool showAnimation;
  final int crossAxisCount;
  final double childAspectRatio;
  
  const OptimizedFoodGrid({
    Key? key,
    required this.foods,
    this.onFoodTap,
    this.onFavoriteToggle,
    this.showAnimation = true,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.4,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: foods.length,
      itemBuilder: (context, index) {
        final food = foods[index];
        return OptimizedFoodCard(
          food: food,
          showAnimation: showAnimation,
          onTap: () => onFoodTap?.call(food),
          onFavoriteToggle: () => onFavoriteToggle?.call(food),
        );
      },
    );
  }
}