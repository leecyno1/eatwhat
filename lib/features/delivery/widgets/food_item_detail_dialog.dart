import 'package:flutter/material.dart';
import '../../../core/models/food_item.dart';

/// 食品详情对话框
class FoodItemDetailDialog extends StatelessWidget {
  final FoodItem food;

  const FoodItemDetailDialog({
    super.key,
    required this.food,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 关闭按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '菜品详情',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 食品图片
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                food.imageUrl ?? 'https://via.placeholder.com/300x200?text=Food',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.grey,
                      size: 60,
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 食品名称
            Text(
              food.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 食品描述
            if (food.description?.isNotEmpty == true)
              Text(
                food.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // 价格信息
            Row(
              children: [
                Text(
                  '¥${food.currentPrice.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                if (food.hasDiscount)
                  Text(
                    '¥${food.originalPrice.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 其他信息
            if (food.preparationTime != null) ...[
              Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '制作时间：${food.preparationTime}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            if (food.rating > 0) ...[
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '评分：${food.rating.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            Row(
              children: [
                const Icon(Icons.shopping_bag, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '销量：${food.salesCount}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 操作按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: 添加到购物车逻辑
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${food.name} 已添加到购物车')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('添加到购物车', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 