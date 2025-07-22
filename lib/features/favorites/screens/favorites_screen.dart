import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/models/food.dart';
import '../../recommendation/widgets/food_card.dart';
import '../widgets/favorites_empty_state.dart';

/// 收藏页面
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  List<Food> _favoriteFoods = [];
  List<Food> _filteredFoods = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCuisine = '全部';

  late AnimationController _listController;
  late Animation<double> _listAnimation;

  final TextEditingController _searchController = TextEditingController();
  final List<String> _cuisineTypes = [
    '全部',
    '川菜',
    '粤菜',
    '鲁菜',
    '苏菜',
    '湘菜',
    '日料',
    '韩料',
    '西餐',
    '泰菜'
  ];

  @override
  void initState() {
    super.initState();

    // 初始化动画
    _listController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _listAnimation = CurvedAnimation(
      parent: _listController,
      curve: Curves.easeOutQuart,
    );

    _loadFavorites();
  }

  @override
  void dispose() {
    _listController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 加载收藏食物
  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 300)); // UI过渡动画

      _favoriteFoods = StorageService.getFavoriteFoods();
      _applyFilters();

      _listController.forward();
    } catch (e) {
      debugPrint('加载收藏失败: $e');
      _showErrorMessage('加载收藏失败');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 应用搜索和筛选
  void _applyFilters() {
    _filteredFoods = _favoriteFoods.where((food) {
      // 搜索过滤
      final matchesSearch = _searchQuery.isEmpty ||
          food.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          food.ingredients.any((ingredient) =>
              ingredient.toLowerCase().contains(_searchQuery.toLowerCase()));

      // 菜系过滤
      final matchesCuisine =
          _selectedCuisine == '全部' || food.cuisineType == _selectedCuisine;

      return matchesSearch && matchesCuisine;
    }).toList();

    // 按添加时间排序（最新的在前面）
    _filteredFoods.sort((a, b) => b.name.compareTo(a.name));
  }

  /// 移除收藏
  Future<void> _removeFavorite(Food food) async {
    try {
      await StorageService.removeFavoriteFood(food.id);

      HapticFeedback.lightImpact();

      setState(() {
        _favoriteFoods.removeWhere((f) => f.id == food.id);
        _applyFilters();
      });

      _showSuccessMessage('已从收藏中移除');
    } catch (e) {
      _showErrorMessage('移除收藏失败');
    }
  }

  /// 清空所有收藏
  Future<void> _clearAllFavorites() async {
    final confirmed = await _showConfirmDialog(
      '清空收藏',
      '确定要清空所有收藏吗？此操作不可撤销。',
    );

    if (confirmed) {
      try {
        for (final food in _favoriteFoods) {
          await StorageService.removeFavoriteFood(food.id);
        }

        setState(() {
          _favoriteFoods.clear();
          _filteredFoods.clear();
        });

        _showSuccessMessage('已清空所有收藏');
      } catch (e) {
        _showErrorMessage('清空收藏失败');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        elevation: 0,
        actions: [
          if (_favoriteFoods.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearAllFavorites,
              tooltip: '清空收藏',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _favoriteFoods.isEmpty
              ? const FavoritesEmptyState()
              : _buildFavoritesList(),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('加载收藏中...'),
        ],
      ),
    );
  }

  /// 构建收藏列表
  Widget _buildFavoritesList() {
    return Column(
      children: [
        // 搜索和筛选栏
        _buildSearchAndFilter(),

        // 结果统计
        _buildResultStats(),

        // 收藏列表
        Expanded(
          child: _filteredFoods.isEmpty
              ? _buildNoResultsState()
              : _buildAnimatedList(),
        ),
      ],
    );
  }

  /// 构建搜索和筛选栏
  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 搜索框
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索收藏的食物...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _applyFilters();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
          ),

          const SizedBox(height: 12),

          // 菜系筛选
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _cuisineTypes.length,
              itemBuilder: (context, index) {
                final cuisine = _cuisineTypes[index];
                final isSelected = _selectedCuisine == cuisine;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cuisine),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCuisine = cuisine;
                        _applyFilters();
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建结果统计
  Widget _buildResultStats() {
    if (_filteredFoods.isEmpty && _searchQuery.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '共 ${_filteredFoods.length} 个收藏',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (_filteredFoods.length != _favoriteFoods.length)
            Text(
              '(已筛选)',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  /// 构建动画列表
  Widget _buildAnimatedList() {
    return FadeTransition(
      opacity: _listAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredFoods.length,
        itemBuilder: (context, index) {
          final food = _filteredFoods[index];

          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + index * 50),
            curve: Curves.easeOutBack,
            margin: const EdgeInsets.only(bottom: 16),
            child: Dismissible(
              key: Key(food.id),
              background: _buildDismissBackground(),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) => _removeFavorite(food),
              confirmDismiss: (direction) => _showRemoveConfirmDialog(food),
              child: FoodCard(
                food: food,
                onTap: () => _showFoodDetail(food),
                onFavorite: () => _removeFavorite(food),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建滑动删除背景
  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete, color: Colors.white),
          SizedBox(height: 4),
          Text('移除', style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  /// 构建无结果状态
  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '没有找到匹配的收藏',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '尝试修改搜索条件或菜系筛选',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedCuisine = '全部';
                _applyFilters();
              });
            },
            child: const Text('重置筛选'),
          ),
        ],
      ),
    );
  }

  /// 显示食物详情
  void _showFoodDetail(Food food) {
    // TODO: 实现食物详情页面
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(food.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('菜系: ${food.cuisineType}'),
            if (food.description != null) ...[
              const SizedBox(height: 8),
              Text('描述: ${food.description}'),
            ],
            const SizedBox(height: 8),
            Text('评分: ${food.rating.toStringAsFixed(1)} ⭐'),
            if (food.calories != null) ...[
              const SizedBox(height: 8),
              Text('热量: ${food.calories} 卡'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 显示移除确认对话框
  Future<bool?> _showRemoveConfirmDialog(Food food) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除收藏'),
        content: Text('确定要将「${food.name}」从收藏中移除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 显示确认对话框
  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// 显示成功消息
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 显示错误消息
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
