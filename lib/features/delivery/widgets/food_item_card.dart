import 'package:flutter/material.dart';
import '../../../core/models/food_item.dart';

/// 经过优化的菜品卡片
class FoodItemCard extends StatelessWidget {
  final FoodItem foodItem;

  const FoodItemCard({
    super.key,
    required this.foodItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧图片
          SizedBox(
            width: 120,
            height: 120,
            child: (foodItem.imageUrl?.isNotEmpty ?? false)
                ? Image.network(
                    foodItem.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2.0,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.restaurant_menu,
                          color: Colors.grey.shade400,
                          size: 40,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.restaurant_menu,
                      color: Colors.grey.shade400,
                      size: 40,
                    ),
                  ),
          ),
          // 右侧信息
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    foodItem.name,
                    style: theme.textTheme.headlineSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    foodItem.cuisineType ?? '其他',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // 查看详情或添加到购物车
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('查看'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
    this.showRestaurantInfo = false,
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
    this.showRestaurantInfo = false,
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
          ),
        );
      },
    );
  }
}

// 食物分类卡片
class FoodCategoryCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback? onTap;

  const FoodCategoryCard({
    super.key,
    required this.name,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl ?? 'https://via.placeholder.com/60x60?text=Food',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.grey,
                      size: 30,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// 推荐卡片组件
class RecommendationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<FoodItem> foods;
  final VoidCallback? onSeeMore;

  const RecommendationCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.foods,
    this.onSeeMore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (onSeeMore != null)
                  TextButton(
                    onPressed: onSeeMore,
                    child: const Text('查看更多'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: foods
                    .map<Widget>(
                      (food) => Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        child: FoodItemCard(
                          foodItem: food,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
