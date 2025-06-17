import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/models/restaurant.dart';
import '../../core/models/food_item.dart';
import '../../core/services/delivery_recommendation_service.dart';
import '../../core/services/delivery_api_service.dart';
import '../../core/services/user_preference_service.dart';
import '../../core/services/recommendation_engine.dart';
import '../../core/utils/api_config.dart';
import 'widgets/restaurant_card.dart';
import 'widgets/food_item_card.dart';
import 'widgets/delivery_search_bar.dart';
import 'widgets/meal_type_selector.dart';

/// 外卖主界面
class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final DeliveryRecommendationService _recommendationService;
  
  Position? _currentPosition;
  DeliveryRecommendation? _todayRecommendation;
  List<Restaurant> _nearbyRestaurants = [];
  DeliverySearchResult? _searchResult;
  
  bool _isLoading = false;
  bool _isLocationLoading = false;
  String _searchKeyword = '';
  MealType _selectedMealType = MealType.lunch;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
    _getCurrentLocation();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _initializeServices() {
    final apiService = DeliveryApiService(
      config: ApiConfig.development(),
    );
    final preferenceService = UserPreferenceService();
    final recommendationEngine = RecommendationEngine();
    
    _recommendationService = DeliveryRecommendationService(
      apiService: apiService,
      preferenceService: preferenceService,
      recommendationEngine: recommendationEngine,
    );
  }
  
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });
    
    try {
      // 检查位置权限
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationPermissionDialog();
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showLocationPermissionDialog();
        return;
      }
      
      // 获取当前位置
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
      });
      
      // 加载推荐数据
      await _loadRecommendations();
    } catch (e) {
      print('获取位置失败: $e');
      _showErrorSnackBar('获取位置失败，请检查位置权限设置');
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }
  
  Future<void> _loadRecommendations() async {
    if (_currentPosition == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 获取今日推荐
      final recommendation = await _recommendationService.getTodayDeliveryRecommendation(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        mealType: _selectedMealType,
      );
      
      // 获取附近餐厅
      final restaurants = await _recommendationService.getNearbyRecommendedRestaurants(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        limit: 20,
      );
      
      setState(() {
        _todayRecommendation = recommendation;
        _nearbyRestaurants = restaurants;
      });
    } catch (e) {
      print('加载推荐失败: $e');
      _showErrorSnackBar('加载推荐失败，请稍后重试');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _performSearch(String keyword) async {
    if (_currentPosition == null || keyword.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _searchKeyword = keyword;
    });
    
    try {
      final result = await _recommendationService.searchDelivery(
        keyword: keyword,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
      
      setState(() {
        _searchResult = result;
      });
    } catch (e) {
      print('搜索失败: $e');
      _showErrorSnackBar('搜索失败，请稍后重试');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _onMealTypeChanged(MealType mealType) {
    setState(() {
      _selectedMealType = mealType;
    });
    _loadRecommendations();
  }
  
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要位置权限'),
        content: const Text('为了为您推荐附近的美食，需要获取您的位置信息。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('外卖推荐'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '推荐'),
            Tab(text: '附近'),
            Tab(text: '搜索'),
          ],
        ),
      ),
      body: _isLocationLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在获取位置信息...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecommendationTab(),
                _buildNearbyTab(),
                _buildSearchTab(),
              ],
            ),
    );
  }
  
  Widget _buildRecommendationTab() {
    if (_currentPosition == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('无法获取位置信息'),
            SizedBox(height: 8),
            Text('请检查位置权限设置', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: CustomScrollView(
        slivers: [
          // 餐次选择器
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MealTypeSelector(
                selectedMealType: _selectedMealType,
                onMealTypeChanged: _onMealTypeChanged,
              ),
            ),
          ),
          
          // 今日推荐
          if (_todayRecommendation != null && _todayRecommendation!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedMealType.displayName}推荐',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          
          if (_todayRecommendation != null && _todayRecommendation!.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final recommendation = _todayRecommendation!.recommendations[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: RestaurantCard(
                      restaurant: recommendation.restaurant,
                      recommendedItems: recommendation.recommendedItems,
                      onTap: () => _navigateToRestaurantDetail(recommendation.restaurant),
                    ),
                  );
                },
                childCount: _todayRecommendation!.recommendations.length,
              ),
            ),
          
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          
          if (_todayRecommendation == null || _todayRecommendation!.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.restaurant, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('暂无推荐'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadRecommendations,
                        child: const Text('重新加载'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildNearbyTab() {
    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: _nearbyRestaurants.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('附近暂无餐厅'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _nearbyRestaurants.length,
              itemBuilder: (context, index) {
                final restaurant = _nearbyRestaurants[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RestaurantCard(
                    restaurant: restaurant,
                    onTap: () => _navigateToRestaurantDetail(restaurant),
                  ),
                );
              },
            ),
    );
  }
  
  Widget _buildSearchTab() {
    return Column(
      children: [
        // 搜索栏
        Padding(
          padding: const EdgeInsets.all(16),
          child: DeliverySearchBar(
            onSearch: _performSearch,
          ),
        ),
        
        // 搜索结果
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
    );
  }
  
  Widget _buildSearchResults() {
    if (_searchResult == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('搜索美食或餐厅'),
          ],
        ),
      );
    }
    
    if (_searchResult!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('未找到"${_searchResult!.keyword}"相关结果'),
          ],
        ),
      );
    }
    
    return CustomScrollView(
      slivers: [
        // 餐厅结果
        if (_searchResult!.restaurants.isNotEmpty) ..[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '餐厅 (${_searchResult!.restaurants.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final restaurant = _searchResult!.restaurants[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: RestaurantCard(
                    restaurant: restaurant,
                    onTap: () => _navigateToRestaurantDetail(restaurant),
                  ),
                );
              },
              childCount: _searchResult!.restaurants.length,
            ),
          ),
        ],
        
        // 菜品结果
        if (_searchResult!.foodItems.isNotEmpty) ..[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '菜品 (${_searchResult!.foodItems.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final foodItem = _searchResult!.foodItems[index];
                return FoodItemCard(
                  foodItem: foodItem,
                  onTap: () => _showFoodItemDetail(foodItem),
                );
              },
              childCount: _searchResult!.foodItems.length,
            ),
          ),
        ],
      ],
    );
  }
  
  void _navigateToRestaurantDetail(Restaurant restaurant) {
    // TODO: 导航到餐厅详情页
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('查看 ${restaurant.name} 详情'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  void _showFoodItemDetail(FoodItem foodItem) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 拖拽指示器
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 菜品详情内容
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 菜品图片
                      if (foodItem.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            foodItem.imageUrl!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: double.infinity,
                              height: 200,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // 菜品名称
                      Text(
                        foodItem.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // 价格和评分
                      Row(
                        children: [
                          Text(
                            foodItem.priceText,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (foodItem.originalPriceText != null) ..[
                            const SizedBox(width: 8),
                            Text(
                              foodItem.originalPriceText!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(foodItem.ratingText),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // 销量
                      Text(
                        foodItem.salesText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 描述
                      if (foodItem.description != null) ..[
                        Text(
                          '商品描述',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          foodItem.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // 餐厅信息
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.store, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              foodItem.restaurant ?? '未知餐厅',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}