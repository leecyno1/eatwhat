import 'package:flutter/material.dart';
import '../../core/services/delivery_api_service.dart';
import '../../core/models/food_item.dart';
import 'widgets/food_item_card.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DeliveryApiService _apiService = DeliveryApiService();
  Future<List<FoodItem>>? _foodItemsFuture;

  @override
  void initState() {
    super.initState();
    _loadRecommendedFoods();
  }

  void _loadRecommendedFoods() {
    setState(() {
      _foodItemsFuture = _apiService.getRecommendedFoods();
    });
  }

  void _searchFood(String query) {
    if (query.trim().isEmpty) {
      _loadRecommendedFoods();
    } else {
      setState(() {
        _foodItemsFuture = _apiService.searchFood(query);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('外卖与配送'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0)
                .copyWith(bottom: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索麻辣香锅...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: _searchFood,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<FoodItem>>(
              future: _foodItemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('加载失败: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadRecommendedFoods,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('暂无菜品数据'),
                      ],
                    ),
                  );
                } else {
                  final foodItems = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: foodItems.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FoodItemCard(foodItem: foodItems[index]),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 