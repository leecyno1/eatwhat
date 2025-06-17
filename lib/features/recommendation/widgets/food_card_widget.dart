import 'package:flutter/material.dart';
import '../../../core/models/food.dart';
import '../screens/food_detail_screen.dart';

/// 食物卡片组件
class FoodCardWidget extends StatefulWidget {
  final Food food;
  final Function(String)? onLike;
  final Function(String)? onDislike;
  final VoidCallback? onTap;

  const FoodCardWidget({
    Key? key,
    required this.food,
    this.onLike,
    this.onDislike,
    this.onTap,
  }) : super(key: key);

  @override
  State<FoodCardWidget> createState() => _FoodCardWidgetState();
}

class _FoodCardWidgetState extends State<FoodCardWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isLiked = false;
  bool _isDisliked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: () {
          widget.onTap?.call();
          // 导航到食物详情页面
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FoodDetailScreen(food: widget.food),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 食物图片区域
                _buildImageSection(),
                
                // 食物信息区域
                _buildInfoSection(),
                
                // 操作按钮区域
                _buildActionSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建图片区域
  Widget _buildImageSection() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.purple.withOpacity(0.6),
            Colors.blue.withOpacity(0.4),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 占位符图片
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.restaurant,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          
          // 评分标签
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.food.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 菜系标签
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.food.cuisineType,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息区域
  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 食物名称
          Text(
            widget.food.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 食物描述
          if (widget.food.description != null)
            Text(
              widget.food.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          
          const SizedBox(height: 12),
          
          // 标签区域
          _buildTagsSection(),
          
          const SizedBox(height: 12),
          
          // 营养信息
          _buildNutritionInfo(),
        ],
      ),
    );
  }

  /// 构建标签区域
  Widget _buildTagsSection() {
    final allTags = [
      ...widget.food.tasteAttributes,
      ...widget.food.ingredients.take(3), // 只显示前3个食材
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: allTags.take(5).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建营养信息
  Widget _buildNutritionInfo() {
    return Row(
      children: [
        if (widget.food.calories != null) ...[
          _buildNutritionItem(
            icon: Icons.local_fire_department,
            label: '${widget.food.calories} 卡',
            color: Colors.orange,
          ),
          const SizedBox(width: 16),
        ],
        
        _buildNutritionItem(
          icon: Icons.people,
          label: '${widget.food.ratingCount} 评价',
          color: Colors.blue,
        ),
        
        const Spacer(),
        
        if (widget.food.preparationTime != null)
          _buildNutritionItem(
            icon: Icons.access_time,
            label: widget.food.preparationTime!,
            color: Colors.green,
          ),
      ],
    );
  }

  /// 构建营养信息项
  Widget _buildNutritionItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建操作区域
  Widget _buildActionSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 不喜欢按钮
          _buildActionButton(
            icon: Icons.thumb_down,
            isActive: _isDisliked,
            activeColor: Colors.red,
            onPressed: () {
              setState(() {
                _isDisliked = !_isDisliked;
                if (_isDisliked) _isLiked = false;
              });
              if (_isDisliked) {
                widget.onDislike?.call(widget.food.id);
              }
            },
          ),
          
          const Spacer(),
          
          // 查看详情按钮
          TextButton(
            onPressed: widget.onTap,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              '查看详情',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const Spacer(),
          
          // 喜欢按钮
          _buildActionButton(
            icon: Icons.thumb_up,
            isActive: _isLiked,
            activeColor: Colors.green,
            onPressed: () {
              setState(() {
                _isLiked = !_isLiked;
                if (_isLiked) _isDisliked = false;
              });
              if (_isLiked) {
                widget.onLike?.call(widget.food.id);
              }
            },
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? activeColor : Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 20,
          color: isActive ? activeColor : Colors.white.withOpacity(0.7),
        ),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
      ),
    );
  }
} 