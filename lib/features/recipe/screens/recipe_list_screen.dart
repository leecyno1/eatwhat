import 'package:flutter/material.dart';
import '../../../core/models/recipe.dart';
import '../../../core/services/recipe_database_service.dart';
import '../widgets/recipe_card.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RecipeDatabaseService _recipeService = RecipeDatabaseService();
  List<Recipe> _recipes = [];
  List<Recipe> _filteredRecipes = [];
  String _selectedCuisine = '';
  CookingMethod? _selectedCookingMethod;
  RecipeDifficulty? _selectedDifficulty;
  int? _maxTime;
  bool? _isVegetarian;
  final List<String> _selectedTags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _searchController.addListener(_filterRecipes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _recipeService.initialize();
      _recipes = await _recipeService.getAllRecipes();
      _filteredRecipes = List.from(_recipes);
    } catch (e) {
      debugPrint('加载菜谱失败: $e');
      _recipes = [];
      _filteredRecipes = [];
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _filterRecipes() async {
    final keyword = _searchController.text;

    try {
      _filteredRecipes = await _recipeService.searchRecipes(
        query: keyword.isEmpty ? null : keyword,
        cuisine: _selectedCuisine.isEmpty ? null : _selectedCuisine,
        method: _selectedCookingMethod,
        difficulty: _selectedDifficulty,
        maxTime: _maxTime,
        isVegetarian: _isVegetarian,
        tags: _selectedTags.isEmpty ? null : _selectedTags,
      );
    } catch (e) {
      debugPrint('搜索失败: $e');
      _filteredRecipes = [];
    }

    setState(() {});
  }

  void _showFilterSheet() {
    // TODO: Implement filter sheet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('筛选功能正在开发中')),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCuisine = '';
      _selectedCookingMethod = null;
      _selectedDifficulty = null;
      _maxTime = null;
      _isVegetarian = null;
      _selectedTags.clear();
      _searchController.clear();
    });
    _filterRecipes();
  }

  bool get _hasActiveFilters {
    return _selectedCuisine.isNotEmpty ||
        _selectedCookingMethod != null ||
        _selectedDifficulty != null ||
        _maxTime != null ||
        _isVegetarian != null ||
        _selectedTags.isNotEmpty ||
        _searchController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('菜谱大全'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterSheet,
          ),
          if (_hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索菜谱、食材或标签',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // 快速筛选标签
          if (_hasActiveFilters)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedCuisine.isNotEmpty)
                      _buildFilterChip('菜系: $_selectedCuisine', () {
                        setState(() {
                          _selectedCuisine = '';
                        });
                        _filterRecipes();
                      }),
                    if (_selectedCookingMethod != null)
                      _buildFilterChip('烹饪: ${_selectedCookingMethod!.label}', () {
                        setState(() {
                          _selectedCookingMethod = null;
                        });
                        _filterRecipes();
                      }),
                    if (_selectedDifficulty != null)
                      _buildFilterChip('难度: ${_selectedDifficulty!.label}', () {
                        setState(() {
                          _selectedDifficulty = null;
                        });
                        _filterRecipes();
                      }),
                    if (_maxTime != null)
                      _buildFilterChip('时间: ≤$_maxTime分钟', () {
                        setState(() {
                          _maxTime = null;
                        });
                        _filterRecipes();
                      }),
                    if (_isVegetarian == true)
                      _buildFilterChip('素食', () {
                        setState(() {
                          _isVegetarian = null;
                        });
                        _filterRecipes();
                      }),
                    ..._selectedTags.map((tag) => _buildFilterChip(tag, () {
                          setState(() {
                            _selectedTags.remove(tag);
                          });
                          _filterRecipes();
                        })),
                  ],
                ),
              ),
            ),

          // 结果统计
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '共找到 ${_filteredRecipes.length} 个菜谱',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // 菜谱列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecipes.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadRecipes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRecipes.length,
                          itemBuilder: (context, index) {
                            final recipe = _filteredRecipes[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: RecipeCard(
                                recipe: recipe,
                                onTap: () {
                                  print('点击菜谱: ${recipe.name}');
                                  // TODO: Navigate to recipe detail screen
                                },
                                onFavoriteToggle: (isFavorite) async {
                                  try {
                                    await _recipeService.toggleFavorite(recipe.id);
                                    await _loadRecipes();
                                  } catch (e) {
                                    debugPrint('收藏操作失败: $e');
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        backgroundColor: Colors.blue[50],
        deleteIconColor: Colors.blue[700],
        labelStyle: TextStyle(
          color: Colors.blue[700],
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _hasActiveFilters ? '没有找到符合条件的菜谱' : '暂无菜谱数据',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          if (_hasActiveFilters)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('清除筛选条件'),
            ),
        ],
      ),
    );
  }
}
