import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/food_provider.dart';
import '../../../core/models/food.dart';

/// 食物卡片Widget
class FoodCard extends ConsumerWidget {
  final Food food;
  final VoidCallback? onTap;
  final bool showFavoriteButton;

  const FoodCard({
    Key? key,
    required this.food,
    this.onTap,
    this.showFavoriteButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            // 食物图片
            _buildImage(),

            // 食物信息
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 名称和收藏按钮
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showFavoriteButton) _buildFavoriteButton(),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // 评分
                  if (food.rating > 0) _buildRating(),

                  const SizedBox(height: 8),

                  // 标签
                  if (food.tags.isNotEmpty) _buildTags(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: food.imageUrl != null
            ? Image.network(
                food.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.restaurant,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return IconButton(
      icon: const Icon(Icons.favorite_border),
      onPressed: () {
        // TODO: 实现收藏功能
      },
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildRating() {
    return Row(
      children: [
        const Icon(
          Icons.star,
          size: 16,
          color: Colors.amber,
        ),
        const SizedBox(width: 4),
        Text(
          food.rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: food.tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 食物列表Widget
class FoodList extends ConsumerWidget {
  final ScrollController? scrollController;
  final EdgeInsets? padding;

  const FoodList({
    Key? key,
    this.scrollController,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodState = ref.watch(foodProvider);

    if (foodState.isLoading && foodState.foods.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (foodState.error != null && foodState.foods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(foodState.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(foodProvider.notifier).loadFoods();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (foodState.foods.isEmpty) {
      return const Center(
        child: Text('暂无数据'),
      );
    }

    return GridView.builder(
      controller: scrollController,
      padding: padding ?? const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: foodState.foods.length,
      itemBuilder: (context, index) {
        final food = foodState.foods[index];
        return FoodCard(
          food: food,
          onTap: () {
            // TODO: 导航到详情页
          },
        );
      },
    );
  }
}
