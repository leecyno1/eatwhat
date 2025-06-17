import 'package:flutter/material.dart';
import '../../../core/models/food_item.dart';

/// 菜品卡片组件
class FoodItemCard extends StatelessWidget {
  final FoodItem foodItem;
  final VoidCallback? onTap;
  final bool showRestaurantInfo;
  final bool compact;
  
  const FoodItemCard({
    super.key,
    required this.foodItem,
    this.onTap,
    this.showRestaurantInfo = true,
    this.compact = false,
  });
  
  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactCard(context);
    }
    return _buildFullCard(context);
  }
  
  Widget _buildFullCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 菜品图片
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: foodItem.imageUrl != null
                        ? Image.network(
                            foodItem.imageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                  
                  // 标签
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildTagsRow(),
                  ),
                  
                  // 平台标识
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildPlatformBadge(),
                  ),
                ],
              ),
            ),
            
            // 菜品信息
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 菜品名称
                    Text(
                      foodItem.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 餐厅信息
                    if (showRestaurantInfo && foodItem.restaurant != null)
                      Text(
                        foodItem.restaurant!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const Spacer(),
                    
                    // 价格和评分
                    Row(
                      children: [
                        Expanded(
                          child: _buildPriceWidget(context),
                        ),
                        _buildRatingWidget(),
                      ],
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // 销量
                    Text(
                      foodItem.salesText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
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
  
  Widget _buildCompactCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // 菜品图片
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: foodItem.imageUrl != null
                    ? Image.network(
                        foodItem.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildSmallPlaceholderImage(),
                      )
                    : _buildSmallPlaceholderImage(),
              ),
              
              const SizedBox(width: 12),
              
              // 菜品信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 菜品名称和标签
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            foodItem.name,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildPlatformBadge(),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 餐厅信息
                    if (showRestaurantInfo && foodItem.restaurant != null)
                      Text(
                        foodItem.restaurant!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const SizedBox(height: 4),
                    
                    // 价格、评分和销量
                    Row(
                      children: [
                        _buildPriceWidget(context),
                        const SizedBox(width: 8),
                        _buildRatingWidget(),
                        const SizedBox(width: 8),
                        Text(
                          foodItem.salesText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
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
  
  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[200],
      child: const Icon(
        Icons.fastfood,
        color: Colors.grey,
        size: 32,
      ),
    );
  }
  
  Widget _buildSmallPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[200],
      child: const Icon(
        Icons.fastfood,
        color: Colors.grey,
        size: 24,
      ),
    );
  }
  
  Widget _buildTagsRow() {
    final tags = <Widget>[];
    
    if (foodItem.isRecommended) {
      tags.add(_buildTag('推荐', Colors.orange));
    }
    
    if (foodItem.isNew) {
      tags.add(_buildTag('新品', Colors.green));
    }
    
    if (foodItem.isHot) {
      tags.add(_buildTag('热销', Colors.red));
    }
    
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tags.take(2).toList(), // 最多显示2个标签
    );
  }
  
  Widget _buildTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildPlatformBadge() {
    Color color;
    String text;
    
    switch (foodItem.platform) {
      case DeliveryPlatform.meituan:
        color = Colors.yellow[700]!;
        text = '美团';
        break;
      case DeliveryPlatform.eleme:
        color = Colors.blue[700]!;
        text = '饿了么';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildPriceWidget(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          foodItem.priceText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (foodItem.originalPriceText != null) ..[
          const SizedBox(width: 4),
          Text(
            foodItem.originalPriceText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildRatingWidget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.star,
          color: Colors.amber,
          size: 12,
        ),
        const SizedBox(width: 2),
        Text(
          foodItem.ratingText,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 菜品网格组件
class FoodItemGrid extends StatelessWidget {
  final List<FoodItem> foodItems;
  final Function(FoodItem)? onItemTap;
  final bool showRestaurantInfo;
  final int crossAxisCount;
  final double childAspectRatio;
  
  const FoodItemGrid({
    super.key,
    required this.foodItems,
    this.onItemTap,
    this.showRestaurantInfo = true,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.8,
  });
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: foodItems.length,
      itemBuilder: (context, index) {
        final foodItem = foodItems[index];
        return FoodItemCard(
          foodItem: foodItem,
          onTap: () => onItemTap?.call(foodItem),
          showRestaurantInfo: showRestaurantInfo,
        );
      },
    );
  }
}

/// 菜品列表组件
class FoodItemList extends StatelessWidget {
  final List<FoodItem> foodItems;
  final Function(FoodItem)? onItemTap;
  final bool showRestaurantInfo;
  
  const FoodItemList({
    super.key,
    required this.foodItems,
    this.onItemTap,
    this.showRestaurantInfo = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: foodItems.length,
      itemBuilder: (context, index) {
        final foodItem = foodItems[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FoodItemCard(
            foodItem: foodItem,
            onTap: () => onItemTap?.call(foodItem),
            showRestaurantInfo: showRestaurantInfo,
            compact: true,
          ),
        );
      },
    );
  }
}