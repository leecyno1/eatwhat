import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../core/models/enhanced_recipe.dart';
import '../../../core/services/howtocook_database_service.dart';
import '../../../core/utils/advanced_logger.dart';

/// 现代化菜谱推荐界面 - 基于HowToCook数据
class ModernRecipeRecommendationScreen extends StatefulWidget {
  final List<String>? preferredCategories;
  final String? searchKeyword;

  const ModernRecipeRecommendationScreen({
    super.key,
    this.preferredCategories,
    this.searchKeyword,
  });

  @override
  State<ModernRecipeRecommendationScreen> createState() => _ModernRecipeRecommendationScreenState();
}

class _ModernRecipeRecommendationScreenState extends State<ModernRecipeRecommendationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;

  final HowToCookDatabaseService _databaseService = HowToCookDatabaseService();
  final AdvancedLogger _logger = AdvancedLogger.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<EnhancedRecipe> _recipes = [];
  List<EnhancedRecipe> _filteredRecipes = [];
  bool _isLoading = false;
  bool _isGridView = true;
  String _searchTerm = '';

  // 筛选选项
  String _selectedCategory = '全部';
  String _selectedDifficulty = '全部';
  List<String> _categories = [];
  final List<String> _difficulties = ['简单', '中等', '困难'];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    if (widget.searchKeyword != null) {
      _searchController.text = widget.searchKeyword!;
      _searchTerm = widget.searchKeyword!;
    }

    _loadRecipes();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _logger.info('开始加载菜谱数据...', tag: 'ModernRecipeRecommendation');

      final database = await _databaseService.database;
      _logger.info('数据库连接成功', tag: 'ModernRecipeRecommendation');

      final List<Map<String, dynamic>> maps = await database.query(
        'howtocook_recipes',
        limit: 100,
        orderBy: 'popularity_score DESC',
      );

      _logger.info('查询到 ${maps.length} 条原始数据', tag: 'ModernRecipeRecommendation');

      final recipes = maps.map((map) => _mapToEnhancedRecipe(map)).toList();
      final categories = recipes.map((r) => r.category.label).toSet().toList();

      setState(() {
        _recipes = recipes;
        _filteredRecipes = recipes;
        _categories = categories;
        _isLoading = false;
      });

      _filterRecipes();
      _staggerController.forward();

      _logger.info(
          'Loaded ${recipes.length} recipes from HowToCook database, filtered to ${_filteredRecipes.length}',
          tag: 'ModernRecipeRecommendation');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _logger.error('Failed to load recipes: $e', tag: 'ModernRecipeRecommendation');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载菜谱失败: ${e.toString()}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  EnhancedRecipe _mapToEnhancedRecipe(Map<String, dynamic> map) {
    return EnhancedRecipe(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      difficulty: _mapDifficulty(map['difficulty'] ?? 3),
      category: _mapCategory(map['category'] ?? '其他'),
      servings: map['servings'] ?? 1,
      ingredients: [],
      steps: [],
      coverImage: _generateImageUrl(map['name']),
      rating: (map['popularity_score'] ?? 0.0) / 20.0 + 3.5,
      reviewCount: 0,
      favoriteCount: 0,
      makeCount: 0,
      tags: [],
      prepTime: Duration(minutes: (map['cooking_time'] ?? 30) ~/ 2),
      cookTime: Duration(minutes: map['cooking_time'] ?? 30),
      totalTime: Duration(minutes: map['cooking_time'] ?? 30),
      nutrition: const RecipeNutrition(),
      source: RecipeSource.xiachufang,
    );
  }

  RecipeCategory _mapCategory(String category) {
    switch (category) {
      case '荤菜':
        return RecipeCategory.meatDish;
      case '素菜':
        return RecipeCategory.vegetarian;
      case '主食':
        return RecipeCategory.rice;
      case '早餐':
        return RecipeCategory.homeStyle;
      case '调料':
        return RecipeCategory.sauce;
      default:
        return RecipeCategory.homeStyle;
    }
  }

  RecipeDifficulty _mapDifficulty(int difficulty) {
    switch (difficulty) {
      case 1:
      case 2:
        return RecipeDifficulty.easy;
      case 3:
        return RecipeDifficulty.medium;
      case 4:
      case 5:
        return RecipeDifficulty.hard;
      default:
        return RecipeDifficulty.medium;
    }
  }

  String _generateImageUrl(String recipeName) {
    // 根据菜名生成相应的图片URL
    final Map<String, String> imageMap = {
      '孜然牛肉': 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=400&h=300&fit=crop',
      '番茄红酱': 'https://images.unsplash.com/photo-1551782450-17144efb9c50?w=400&h=300&fit=crop',
      '炸酱面': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400&h=300&fit=crop',
      '椒盐排条': 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=400&h=300&fit=crop',
      '蚂蚁上树': 'https://images.unsplash.com/photo-1565299507177-b0ac66763828?w=400&h=300&fit=crop',
      '鸡蛋三明治': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400&h=300&fit=crop',
      '酱排骨': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&h=300&fit=crop',
    };

    return imageMap[recipeName] ??
        'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop';
  }

  void _filterRecipes() {
    setState(() {
      _filteredRecipes = _recipes.where((recipe) {
        final matchesSearch = recipe.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
            recipe.description.toLowerCase().contains(_searchTerm.toLowerCase()) ||
            recipe.category.label.toLowerCase().contains(_searchTerm.toLowerCase());

        final matchesCategory =
            _selectedCategory == '全部' || recipe.category.label == _selectedCategory;

        final matchesDifficulty = _selectedDifficulty == '全部' ||
            _getDifficultyText(recipe.difficulty) == _selectedDifficulty;

        return matchesSearch && matchesCategory && matchesDifficulty;
      }).toList();
    });
  }

  String _getDifficultyText(RecipeDifficulty difficulty) {
    switch (difficulty) {
      case RecipeDifficulty.beginner:
      case RecipeDifficulty.easy:
        return '简单';
      case RecipeDifficulty.medium:
        return '中等';
      case RecipeDifficulty.hard:
      case RecipeDifficulty.expert:
        return '困难';
    }
  }

  Color _getDifficultyColor(RecipeDifficulty difficulty) {
    switch (difficulty) {
      case RecipeDifficulty.beginner:
      case RecipeDifficulty.easy:
        return Colors.green;
      case RecipeDifficulty.medium:
        return Colors.orange;
      case RecipeDifficulty.hard:
      case RecipeDifficulty.expert:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('菜谱推荐', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_3x3),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // 搜索栏
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  // 搜索输入框
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: '搜索菜谱...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchTerm = value;
                        });
                        _filterRecipes();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 筛选标签
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // 类别筛选
                        _buildFilterChip('全部', _selectedCategory == '全部', () {
                          setState(() {
                            _selectedCategory = '全部';
                          });
                          _filterRecipes();
                        }),
                        ..._categories.map((category) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _buildFilterChip(category, _selectedCategory == category, () {
                                setState(() {
                                  _selectedCategory = category;
                                });
                                _filterRecipes();
                              }),
                            )),

                        const SizedBox(width: 16),

                        // 难度筛选
                        ..._difficulties.map((difficulty) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _buildFilterChip(difficulty, _selectedDifficulty == difficulty,
                                  () {
                                setState(() {
                                  _selectedDifficulty = difficulty;
                                });
                                _filterRecipes();
                              }),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 结果计数
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '找到 ${_filteredRecipes.length} 个菜谱',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),

            // 菜谱列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredRecipes.isEmpty
                      ? _buildEmptyState()
                      : _buildRecipeList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue[600]! : Colors.grey[400]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
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
            '没有找到相关菜谱',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '试试调整搜索条件或筛选器',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeList() {
    if (_isGridView) {
      return AnimationLimiter(
        child: GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _filteredRecipes.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: 2,
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildRecipeGridCard(_filteredRecipes[index]),
                ),
              ),
            );
          },
        ),
      );
    } else {
      return AnimationLimiter(
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: _filteredRecipes.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRecipeListCard(_filteredRecipes[index]),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildRecipeGridCard(EnhancedRecipe recipe) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: recipe.coverImage ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant_menu, size: 40, color: Colors.grey),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant_menu, size: 40, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),

          // 内容
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // 类别和评分
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          recipe.category.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.star, size: 14, color: Colors.amber[600]),
                      const SizedBox(width: 2),
                      Text(
                        recipe.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 时间和难度
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 2),
                      Text(
                        '${recipe.totalTime.inMinutes}分钟',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(recipe.difficulty),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getDifficultyText(recipe.difficulty),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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

  Widget _buildRecipeListCard(EnhancedRecipe recipe) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 120,
        child: Row(
          children: [
            // 图片
            Container(
              width: 120,
              height: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: recipe.coverImage ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant_menu, size: 40, color: Colors.grey),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant_menu, size: 40, color: Colors.grey),
                  ),
                ),
              ),
            ),

            // 内容
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // 描述
                    Text(
                      recipe.description.isNotEmpty ? recipe.description : '美味的${recipe.name}，值得一试',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // 底部信息
                    // 底部信息 - 修复溢出问题，使用Flexible布局
                    Row(
                      children: [
                        // 分类标签 - 使用Flexible防止溢出
                        Flexible(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              recipe.category.toString().split('.').last,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // 时间信息 - 使用Flexible防止溢出
                        Flexible(
                          flex: 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  '${recipe.totalTime.inMinutes}分钟',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),

                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(recipe.difficulty),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getDifficultyText(recipe.difficulty),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),

                        const Spacer(),

                        Icon(Icons.star, size: 14, color: Colors.amber[600]),
                        const SizedBox(width: 2),
                        Text(
                          recipe.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
