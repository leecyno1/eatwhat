import 'package:flutter/material.dart';
import '../../../core/models/restaurant.dart';
import '../../../core/models/food_item.dart';

/// 餐厅卡片组件
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final List<FoodItem>? recommendedItems;
  final VoidCallback? onTap;
  final bool showRecommendedItems;
  
  const RestaurantCard({
    super.key,
    required this.restaurant,
    this.recommendedItems,
    this.onTap,
    this.showRecommendedItems = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 餐厅基本信息
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 餐厅图片
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: restaurant.imageUrl != null
                        ? Image.network(
                            restaurant.imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 餐厅信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 餐厅名称和评分
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                restaurant.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildRatingWidget(),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // 餐厅描述
                        if (restaurant.description != null)
                          Text(
                            restaurant.description!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        
                        const SizedBox(height: 8),
                        
                        // 配送信息
                        Row(
                          children: [
                            _buildInfoChip(
                              icon: Icons.access_time,
                              text: restaurant.deliveryTimeText,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              icon: Icons.delivery_dining,
                              text: restaurant.deliveryFeeText,
                              color: Colors.green,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // 距离和起送价
                        Row(
                          children: [
                            if (restaurant.distance != null)
                              _buildInfoChip(
                                icon: Icons.location_on,
                                text: restaurant.distanceText,
                                color: Colors.orange,
                              ),
                            if (restaurant.distance != null && restaurant.minimumOrderAmount != null)
                              const SizedBox(width: 8),
                            if (restaurant.minimumOrderAmount != null)
                              _buildInfoChip(
                                icon: Icons.shopping_cart,
                                text: restaurant.minimumOrderText,
                                color: Colors.purple,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // 营业状态和标签
              const SizedBox(height: 8),
              Row(
                children: [
                  // 营业状态
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: restaurant.isOpen ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      restaurant.businessStatusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // 平台标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: restaurant.platform == DeliveryPlatform.meituan
                          ? Colors.yellow[700]
                          : Colors.blue[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      restaurant.platformText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // 优惠信息
                  if (restaurant.hasPromotion)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Text(
                        '有优惠',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              // 推荐菜品
              if (showRecommendedItems && recommendedItems != null && recommendedItems!.isNotEmpty) ..[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Text(
                  '推荐菜品',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: recommendedItems!.length,
                    itemBuilder: (context, index) {
                      final item = recommendedItems![index];
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 8),
                        child: _buildRecommendedItem(context, item),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.restaurant,
        color: Colors.grey,
        size: 32,
      ),
    );
  }
  
  Widget _buildRatingWidget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.star,
          color: Colors.amber,
          size: 16,
        ),
        const SizedBox(width: 2),
        Text(
          restaurant.ratingText,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecommendedItem(BuildContext context, FoodItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 菜品图片
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.fastfood, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
            ),
          ),
          
          // 菜品信息
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.priceText,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
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