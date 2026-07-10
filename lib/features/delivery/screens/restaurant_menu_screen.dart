import 'package:flutter/material.dart';
import '../../../core/models/restaurant.dart';
import '../../../core/models/food_item.dart';
import '../../../core/services/delivery_api_service.dart';
import '../widgets/food_item_card.dart';
import '../widgets/food_item_detail_dialog.dart';

/// 餐厅菜单页面
class RestaurantMenuScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantMenuScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  final DeliveryApiService _apiService = DeliveryApiService();
  List<FoodItem> _menuItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final menu = await _apiService.getRestaurantMenu(widget.restaurant.id);
      setState(() {
        _menuItems = menu;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载菜单失败：${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showFoodItemDetail(FoodItem food) {
    showDialog(
      context: context,
      builder: (context) => FoodItemDetailDialog(food: food),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.restaurant.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 餐厅信息
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 餐厅图片
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.restaurant.logoUrl ?? 'https://via.placeholder.com/60x60?text=Logo',
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
                            child: const Icon(Icons.restaurant, color: Colors.grey),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 餐厅信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.restaurant.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (widget.restaurant.description != null)
                            Text(
                              widget.restaurant.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (widget.restaurant.rating != null) ...[
                                const Icon(Icons.star, size: 14, color: Colors.orange),
                                const SizedBox(width: 2),
                                Text(
                                  widget.restaurant.rating!.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (widget.restaurant.deliveryTime != null) ...[
                                const Icon(Icons.timer, size: 14, color: Colors.grey),
                                const SizedBox(width: 2),
                                Text(
                                  '${widget.restaurant.deliveryTime}分钟',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (widget.restaurant.deliveryFee != null) ...[
                                const Icon(Icons.delivery_dining, size: 14, color: Colors.grey),
                                const SizedBox(width: 2),
                                Text(
                                  '配送费¥${widget.restaurant.deliveryFee!.toStringAsFixed(1)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.restaurant.announcement?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.campaign, size: 16, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.restaurant.announcement!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // 菜单内容
          Expanded(
            child: _buildMenuContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMenu,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_menuItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无菜单', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMenu,
      child: ListView.builder(
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showFoodItemDetail(_menuItems[index]),
            child: FoodItemCard(
              foodItem: _menuItems[index],
            ),
          );
        },
      ),
    );
  }
}
