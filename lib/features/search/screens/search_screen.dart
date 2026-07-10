import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/themes/design_tokens.dart';
import '../../../shared/widgets/ui/rounded_card.dart';
import '../../recommendation/widgets/food_card.dart';
import '../widgets/search_filters.dart';
import '../widgets/search_suggestions.dart';
import '../../../core/models/food.dart';
import '../../../core/data/food_database.dart';
import '../../../core/services/storage_service.dart';

/// 搜索页面
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<Food> _allFoods = [];
  List<Food> _searchResults = [];
  List<String> _searchHistory = [];
  List<String> _suggestions = [];

  bool _isLoading = false;
  bool _showSuggestions = false;
  String _searchQuery = '';

  // 筛选器状态
  List<String> _selectedCuisines = [];
  List<String> _selectedTastes = [];
  RangeValues _caloriesRange = const RangeValues(0, 1000);
  RangeValues _ratingRange = const RangeValues(0, 5);
  String _sortBy = 'relevance'; // relevance, rating, calories, name

  late AnimationController _resultsController;
  late Animation<double> _resultsAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化动画
    _resultsController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _resultsAnimation = CurvedAnimation(
      parent: _resultsController,
      curve: Curves.easeOutQuart,
    );

    _initializeData();
    _setupSearchListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _resultsController.dispose();
    super.dispose();
  }

  /// 初始化数据
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    try {
      // 加载所有食物数据
      _allFoods = FoodDatabase.getAllFoods();

      // 加载搜索历史
      _loadSearchHistory();

      // 生成搜索建议
      _generateSuggestions();
    } catch (e) {
      debugPrint('初始化搜索数据失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 设置搜索监听器
  void _setupSearchListener() {
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query != _searchQuery) {
        setState(() {
          _searchQuery = query;
          _showSuggestions = query.isNotEmpty && _searchResults.isEmpty;
        });

        if (query.isNotEmpty) {
          _performSearch(query);
        } else {
          _clearSearch();
        }
      }
    });

    _searchFocus.addListener(() {
      setState(() {
        _showSuggestions =
            _searchFocus.hasFocus && _searchQuery.isNotEmpty && _searchResults.isEmpty;
      });
    });
  }

  /// 执行搜索
  Future<void> _performSearch(String query) async {
    if (query.length < 2) return; // 至少2个字符才搜索

    setState(() => _isLoading = true);

    try {
      // 模拟搜索延迟
      await Future.delayed(const Duration(milliseconds: 300));

      final results = _allFoods.where((food) {
        final queryLower = query.toLowerCase();

        // 搜索食物名称
        if ((food.name).toLowerCase().contains(queryLower)) return true;

        // 搜索菜系
        if ((food.cuisineType ?? '').toLowerCase().contains(queryLower)) return true;

        // 搜索食材
        if ((food.ingredients ?? const [])
            .any((ingredient) => ingredient.toLowerCase().contains(queryLower))) {
          return true;
        }

        // 搜索口味属性
        if ((food.tasteAttributes ?? const [])
            .any((taste) => taste.toLowerCase().contains(queryLower))) {
          return true;
        }

        // 搜索场景
        if ((food.scenarios)?.any((scenario) => scenario.toLowerCase().contains(queryLower)) ==
            true) {
          return true;
        }

        return false;
      }).toList();

      // 应用筛选和排序
      final filteredResults = _applyFilters(results);
      final sortedResults = _applySorting(filteredResults);

      setState(() {
        _searchResults = sortedResults;
        _showSuggestions = false;
      });

      _resultsController.forward();

      // 保存搜索历史
      if (results.isNotEmpty) {
        _saveSearchHistory(query);
      }
    } catch (e) {
      debugPrint('搜索失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 应用筛选器
  List<Food> _applyFilters(List<Food> foods) {
    return foods.where((food) {
      // 菜系筛选
      if (_selectedCuisines.isNotEmpty && !_selectedCuisines.contains(food.cuisineType)) {
        return false;
      }

      // 口味筛选
      if (_selectedTastes.isNotEmpty &&
          !(_selectedTastes.any((taste) => (food.tasteAttributes ?? const []).contains(taste)))) {
        return false;
      }

      // 热量筛选
      if (food.calories != null) {
        if (food.calories! < _caloriesRange.start || food.calories! > _caloriesRange.end) {
          return false;
        }
      }

      // 评分筛选
      if (food.rating < _ratingRange.start || food.rating > _ratingRange.end) {
        return false;
      }

      return true;
    }).toList();
  }

  /// 应用排序
  List<Food> _applySorting(List<Food> foods) {
    final sortedFoods = List<Food>.from(foods);

    switch (_sortBy) {
      case 'rating':
        sortedFoods.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'calories':
        sortedFoods.sort((a, b) => (a.calories ?? 0).compareTo(b.calories ?? 0));
        break;
      case 'name':
        sortedFoods.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'relevance':
      default:
        // 保持搜索相关性排序
        break;
    }

    return sortedFoods;
  }

  /// 清空搜索
  void _clearSearch() {
    setState(() {
      _searchResults.clear();
      _showSuggestions = false;
    });
    _resultsController.reset();
  }

  /// 加载搜索历史
  void _loadSearchHistory() {
    // TODO: 从存储服务加载搜索历史
    _searchHistory = ['川菜', '麻辣', '素食', '快餐', '甜品']; // 临时数据
  }

  /// 保存搜索历史
  void _saveSearchHistory(String query) {
    if (!_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.take(10).toList();
      }
      // TODO: 保存到存储服务
    }
  }

  /// 生成搜索建议
  void _generateSuggestions() {
    final cuisines =
        _allFoods.map((f) => f.cuisineType ?? '').where((e) => e.isNotEmpty).toSet().toList();
    final tastes = _allFoods
        .expand((f) => (f.tasteAttributes ?? const <String>[]))
        .toSet()
        .toList()
        .cast<String>();
    _suggestions = [...cuisines, ...tastes].take(20).cast<String>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildSearchBar(),
        titleSpacing: 0,
        actions: [
          IconButton(icon: const Icon(Icons.tune_rounded), onPressed: _showFilters, tooltip: '筛选'),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        decoration: InputDecoration(
          hintText: '搜索美食、菜系、食材...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _clearSearch();
                  },
                )
              : null,
          border: const OutlineInputBorder(
              borderRadius: DesignTokens.bigRadius, borderSide: BorderSide.none),
          filled: true,
          fillColor: DesignTokens.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            _performSearch(value);
          }
        },
      ),
    );
  }

  /// 构建主体内容
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_showSuggestions) {
      return SearchSuggestions(
        suggestions: _suggestions,
        searchHistory: _searchHistory,
        onSuggestionSelected: (suggestion) {
          _searchController.text = suggestion;
          _performSearch(suggestion);
        },
        onHistorySelected: (history) {
          _searchController.text = history;
          _performSearch(history);
        },
      );
    }

    if (_searchQuery.isEmpty) {
      return _buildEmptyState();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResultsState();
    }

    return _buildSearchResults();
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star),
          SizedBox(height: 16),
          Text(
            '搜索你想吃的美食',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '支持搜索菜名、菜系、食材、口味',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
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
          const Icon(Icons.star),
          const SizedBox(height: 16),
          Text(
            '没有找到"$_searchQuery"相关的美食',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '试试其他关键词或调整筛选条件',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _clearFilters,
            child: const Text('清除筛选'),
          ),
        ],
      ),
    );
  }

  /// 构建搜索结果
  Widget _buildSearchResults() {
    return Column(
      children: [
        // 结果统计和排序
        _buildResultsHeader(),

        // 搜索结果列表
        Expanded(
          child: FadeTransition(
            opacity: _resultsAnimation,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final food = _searchResults[index];

                return AnimatedContainer(
                  duration: Duration(milliseconds: 300 + index * 40),
                  curve: Curves.easeOutBack,
                  margin: const EdgeInsets.only(bottom: 14),
                  child: RoundedCard(
                    padding: const EdgeInsets.all(0),
                    child: FoodCard(
                      food: food,
                      onTap: () => _showFoodDetail(food),
                      onFavorite: () => _toggleFavorite(food),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 构建结果头部
  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(color: DesignTokens.creamAlt),
      child: Row(
        children: [
          Text(
            '找到 ${_searchResults.length} 个结果',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          DropdownButton<String>(
            value: _sortBy,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'relevance', child: Text('相关性')),
              DropdownMenuItem(value: 'rating', child: Text('评分')),
              DropdownMenuItem(value: 'calories', child: Text('热量')),
              DropdownMenuItem(value: 'name', child: Text('名称')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _sortBy = value);
                _performSearch(_searchQuery);
              }
            },
          ),
        ],
      ),
    );
  }

  /// 显示筛选器
  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SearchFilters(
        selectedCuisines: _selectedCuisines,
        selectedTastes: _selectedTastes,
        caloriesRange: _caloriesRange,
        ratingRange: _ratingRange,
        onFiltersChanged: (cuisines, tastes, calories, rating) {
          setState(() {
            _selectedCuisines = cuisines;
            _selectedTastes = tastes;
            _caloriesRange = calories;
            _ratingRange = rating;
          });

          if (_searchQuery.isNotEmpty) {
            _performSearch(_searchQuery);
          }
        },
      ),
    );
  }

  /// 清除筛选器
  void _clearFilters() {
    setState(() {
      _selectedCuisines.clear();
      _selectedTastes.clear();
      _caloriesRange = const RangeValues(0, 1000);
      _ratingRange = const RangeValues(0, 5);
    });

    if (_searchQuery.isNotEmpty) {
      _performSearch(_searchQuery);
    }
  }

  /// 切换收藏状态
  Future<void> _toggleFavorite(Food food) async {
    try {
      if (StorageService.isFoodFavorited(food.id)) {
        await StorageService.removeFavoriteFood(food.id);
      } else {
        await StorageService.addFavoriteFood(food);
      }

      setState(() {}); // 刷新UI
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('切换收藏失败: $e');
    }
  }

  /// 显示食物详情
  void _showFoodDetail(Food food) {
    // 添加到浏览历史
    StorageService.addFoodHistory(food);

    // TODO: 导航到食物详情页
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
}
