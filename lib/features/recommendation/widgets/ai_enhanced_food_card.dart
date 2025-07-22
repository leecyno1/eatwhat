import 'package:flutter/material.dart';
import '../../../core/models/food.dart';
import '../../../shared/widgets/ai_generated_loading_animation.dart';

/// AI增强的食物卡片组件
/// 集成现代动画和交互效果
class AIEnhancedFoodCard extends StatefulWidget {
  final Food food;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final double width;
  final double height;

  const AIEnhancedFoodCard({
    super.key,
    required this.food,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.width = 280,
    this.height = 320,
  });

  @override
  State<AIEnhancedFoodCard> createState() => _AIEnhancedFoodCardState();
}

class _AIEnhancedFoodCardState extends State<AIEnhancedFoodCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _favoriteController;
  late AnimationController _imageController;
  
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _favoriteScaleAnimation;
  late Animation<Color?> _favoriteColorAnimation;
  late Animation<double> _imageScaleAnimation;
  late Animation<double> _overlayOpacityAnimation;

  bool _isHovered = false;
  bool _isImageLoading = true;

  @override
  void initState() {
    super.initState();
    
    // 悬停动画控制器
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 收藏动画控制器
    _favoriteController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // 图片动画控制器
    _imageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // 设置动画
    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 12.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));

    _favoriteScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _favoriteController,
      curve: Curves.elasticOut,
    ));

    _favoriteColorAnimation = ColorTween(
      begin: Colors.grey[400],
      end: Colors.red,
    ).animate(CurvedAnimation(
      parent: _favoriteController,
      curve: Curves.easeInOut,
    ));

    _imageScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));

    _overlayOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    // 模拟图片加载
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _isImageLoading = false);
        _imageController.forward();
      }
    });

    // 如果已经是收藏状态，直接设置动画
    if (widget.isFavorite) {
      _favoriteController.forward();
    }
  }

  @override
  void didUpdateWidget(AIEnhancedFoodCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite != oldWidget.isFavorite) {
      if (widget.isFavorite) {
        _favoriteController.forward();
      } else {
        _favoriteController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _favoriteController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  void _onHoverStart() {
    setState(() => _isHovered = true);
    _hoverController.forward();
  }

  void _onHoverEnd() {
    setState(() => _isHovered = false);
    _hoverController.reverse();
  }

  void _onFavoritePressed() {
    if (widget.isFavorite) {
      _favoriteController.reverse();
    } else {
      _favoriteController.forward();
    }
    widget.onFavorite?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AIButtonAnimation(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => _onHoverStart(),
        onExit: (_) => _onHoverEnd(),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _hoverController,
            _favoriteController,
            _imageController,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      blurRadius: _elevationAnimation.value,
                      spreadRadius: _elevationAnimation.value / 4,
                      offset: Offset(0, _elevationAnimation.value / 2),
                    ),
                  ],
                ),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // 主内容
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 图片区域
                            Expanded(
                              flex: 3,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      theme.primaryColor.withValues(alpha: 0.1),
                                      theme.colorScheme.secondary.withValues(alpha: 0.1),
                                    ],
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    // 图片
                                    if (_isImageLoading)
                                      const Center(
                                        child: AIGeneratedLoadingAnimation(
                                          text: '加载美食...',
                                          size: 60,
                                        ),
                                      )
                                    else
                                      AnimatedBuilder(
                                        animation: _imageController,
                                        child: widget.food.imageUrl != null
                                            ? Image.network(
                                                widget.food.imageUrl!,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.star),
                                                  );
                                                },
                                              )
                                            : Container(
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.star),
                                              ),
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _imageScaleAnimation.value,
                                            child: Opacity(
                                              opacity: _imageController.value,
                                              child: child,
                                            ),
                                          );
                                        },
                                      ),
                                    
                                    // 悬停遮罩
                                    AnimatedBuilder(
                                      animation: _overlayOpacityAnimation,
                                      builder: (context, child) {
                                        return Opacity(
                                          opacity: _overlayOpacityAnimation.value,
                                          child: Container(
                                            width: double.infinity,
                                            height: double.infinity,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  theme.primaryColor.withValues(alpha: 0.8),
                                                ],
                                              ),
                                            ),
                                            child: _isHovered
                                                ? Center(
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(20),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withValues(alpha: 0.1),
                                                            blurRadius: 8,
                                                            spreadRadius: 2,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(Icons.star),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            '查看详情',
                                                            style: TextStyle(
                                                              color: theme.primaryColor,
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                    
                                    // 收藏按钮
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: GestureDetector(
                                        onTap: _onFavoritePressed,
                                        child: AnimatedBuilder(
                                          animation: _favoriteScaleAnimation,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale: _favoriteScaleAnimation.value,
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.1),
                                                      blurRadius: 4,
                                                      spreadRadius: 1,
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(Icons.star),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // 信息区域
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 名称和价格
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            widget.food.name,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (widget.food.price != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.primaryColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '¥${widget.food.price}',
                                              style: theme.textTheme.labelMedium?.copyWith(
                                                color: theme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 8),
                                    
                                    // 描述
                                    if (widget.food.description != null)
                                      Text(
                                        widget.food.description!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    
                                    const Spacer(),
                                    
                                    // 标签和评分
                                    Row(
                                      children: [
                                        // 分类标签
                                        if (widget.food.cuisineType.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              widget.food.cuisineType,
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: theme.colorScheme.secondary,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        
                                        const Spacer(),
                                        
                                        // 评分
                                        Row(
                                          children: [
                                            const Icon(Icons.star),
                                            const SizedBox(width: 2),
                                            Text(
                                              '4.5', // TODO: 使用实际评分
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // 点击波纹效果
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onTap,
                              borderRadius: BorderRadius.circular(20),
                              splashColor: theme.primaryColor.withValues(alpha: 0.1),
                              highlightColor: theme.primaryColor.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 