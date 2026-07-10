import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/models/enhanced_recipe.dart';
import '../../../core/services/firecrawl_recipe_crawler_service.dart';
import '../../../core/services/real_mcp_firecrawl_service.dart';
import '../../../core/services/unified_recipe_database_service.dart';
import '../../../core/utils/advanced_logger.dart';
import '../../../core/error/global_error_handler.dart';

/// 增强菜谱控制器 - 管理菜谱数据和状态
class EnhancedRecipeController extends ChangeNotifier {
  final AdvancedLogger _logger = AdvancedLogger.instance;
  final FirecrawlRecipeCrawlerService _crawlerService =
      FirecrawlRecipeCrawlerService.instance;
  final RealMCPFirecrawlService _realMCPService =
      RealMCPFirecrawlService.instance;
  final UnifiedRecipeDatabaseService _unifiedDbService =
      UnifiedRecipeDatabaseService.instance;

  // 数据状态
  List<EnhancedRecipe> _recipes = [];
  List<EnhancedRecipe> _filteredRecipes = [];

  // 加载状态
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _isSearching = false;

  // 错误状态
  String? _error;

  // 搜索和筛选
  String _currentSearchQuery = '';
  RecipeCategory? _currentCategory;
  Set<String> _selectedTags = {};

  // 分页
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMoreData = true;

  // Getters
  List<EnhancedRecipe> get recipes =>
      _filteredRecipes.isNotEmpty ? _filteredRecipes : _recipes;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String get currentSearchQuery => _currentSearchQuery;
  RecipeCategory? get currentCategory => _currentCategory;
  Set<String> get selectedTags => _selectedTags;
  bool get hasMoreData => _hasMoreData;
  int get totalRecipes => _recipes.length;

  /// 初始化控制器
  Future<void> initialize() async {
    _logger.info('Initializing EnhancedRecipeController...',
        tag: 'RecipeController');

    try {
      await _unifiedDbService.ensureInitialized();
      await _crawlerService.initialize();
      await loadRecommendedRecipes();
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize recipe controller: $e',
          stackTrace: stackTrace, tag: 'RecipeController');
      _setError('初始化失败: $e');
    }
  }

  /// 加载推荐菜谱
  Future<void> loadRecommendedRecipes() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      _logger.info('Loading recommended recipes...', tag: 'RecipeController');

      final rows = await _unifiedDbService.fetchTopRecipes(limit: 60);
      final recommendations = rows.map(_mapUnifiedRowToRecipe).toList();

      _recipes = recommendations;
      _filteredRecipes = [];
      _resetPagination();

      _logger.info(
          'Loaded ${recommendations.length} recommended recipes from unified DB',
          tag: 'RecipeController');
    } catch (e, stackTrace) {
      _logger.error('Failed to load recommended recipes: $e',
          stackTrace: stackTrace, tag: 'RecipeController');
      _setError('加载推荐菜谱失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 按分类加载菜谱
  Future<void> loadRecipesByCategory(RecipeCategory category) async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();
    _currentCategory = category;

    try {
      _logger.info('Loading recipes for category: ${category.label}',
          tag: 'RecipeController');

      var categoryRecipes =
          _recipes.where((recipe) => recipe.category == category).toList();
      if (categoryRecipes.isEmpty) {
        final cuisineLabel = _mapCategoryToCuisineLabel(category);
        if (cuisineLabel != null) {
          final rows = await _unifiedDbService
              .fetchRecipesByCuisine(cuisineLabel, limit: 40);
          categoryRecipes = rows.map(_mapUnifiedRowToRecipe).toList();
        }
      }

      _filteredRecipes = categoryRecipes;

      _resetPagination();

      _logger.info(
          'Loaded ${_filteredRecipes.length} recipes for category ${category.label}',
          tag: 'RecipeController');
    } catch (e, stackTrace) {
      _logger.error('Failed to load recipes by category: $e',
          stackTrace: stackTrace, tag: 'RecipeController');
      _setError('加载分类菜谱失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 搜索菜谱
  Future<void> searchRecipes(String query) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    _isSearching = true;
    _currentSearchQuery = query.trim();
    _clearError();
    notifyListeners();

    try {
      _logger.info('Searching recipes with query: $query',
          tag: 'RecipeController');

      final rows = await _unifiedDbService.searchRecipes(query, limit: 40);
      var searchResults = rows.map(_mapUnifiedRowToRecipe).toList();
      if (searchResults.isEmpty) {
        searchResults = _performLocalSearch(query);
      }
      _filteredRecipes = searchResults;
      _resetPagination();

      _logger.info('Found ${searchResults.length} recipes for query: $query',
          tag: 'RecipeController');
    } catch (e, stackTrace) {
      _logger.error('Failed to search recipes: $e',
          stackTrace: stackTrace, tag: 'RecipeController');
      _setError('搜索失败: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// 清除搜索
  void clearSearch() {
    _currentSearchQuery = '';
    _filteredRecipes = [];
    _currentCategory = null;
    _selectedTags.clear();
    _resetPagination();
    notifyListeners();

    _logger.info('Search cleared', tag: 'RecipeController');
  }

  /// 同步菜谱数据
  Future<void> syncRecipeData() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _clearError();
    notifyListeners();

    try {
      _logger.info('Starting recipe data sync...', tag: 'RecipeController');

      final result = await _crawlerService.startCrawling(
        categories: ['家常菜', '快手菜', '烘焙', '汤羹'],
        maxRecipes: 50,
      );

      // 合并新抓取的菜谱
      final newRecipes = result.recipes
          .where((newRecipe) =>
              !_recipes.any((existing) => existing.id == newRecipe.id))
          .toList();

      _recipes.addAll(newRecipes);

      _logger.info('Sync completed: added ${newRecipes.length} new recipes',
          tag: 'RecipeController', extra: result.toJson());
    } catch (e, stackTrace) {
      _logger.error('Failed to sync recipe data: $e',
          stackTrace: stackTrace, tag: 'RecipeController');
      _setError('同步失败: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 使用真实MCP服务同步菜谱数据
  Future<void> syncRecipeDataWithRealMCP({
    List<String>? categories,
    int? maxRecipes,
  }) async {
    if (_isSyncing) return;

    _isSyncing = true;
    _clearError();
    notifyListeners();

    try {
      _logger.info('Starting real MCP recipe data sync...',
          tag: 'RecipeController',
          extra: {
            'categories': categories?.length ?? 0,
            'max_recipes': maxRecipes,
          });

      await _realMCPService.initialize();

      // 设置进度回调
      _realMCPService.setProgressCallback((progress) {
        _logger.info(
            'Real MCP sync progress: ${progress.progressPercentage * 100}%',
            tag: 'RecipeController');
        notifyListeners();
      });

      final result = await _realMCPService.startCrawling(
        categories: categories ?? ['家常菜', '快手菜'],
        maxRecipes: maxRecipes ?? 10,
        fullCrawl: false,
      );

      // 合并新抓取的菜谱（使用真实MCP数据）
      final newRecipes = (result.recipes as List<dynamic>)
          .cast<EnhancedRecipe>()
          .where((newRecipe) =>
              !_recipes.any((existing) => existing.id == newRecipe.id))
          .toList();

      _recipes.addAll(newRecipes);

      // 如果当前没有显示任何菜谱，显示新抓取的
      if (_filteredRecipes.isEmpty && _recipes.isEmpty) {
        _filteredRecipes = newRecipes;
      }

      _logger.info(
          'Real MCP sync completed: added ${newRecipes.length} new recipes',
          tag: 'RecipeController',
          extra: {
            'total_recipes': _recipes.length,
            'new_recipes': newRecipes.length,
            'success_rate': result.successRate,
            'duration_seconds': result.duration.inSeconds,
          });
    } catch (e, stackTrace) {
      _logger.error('Failed to sync recipe data with real MCP: $e',
          stackTrace: stackTrace, tag: 'RecipeController');
      _setError('真实MCP同步失败: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 添加标签筛选
  void addTagFilter(String tag) {
    _selectedTags.add(tag);
    _applyFilters();
    notifyListeners();
  }

  /// 移除标签筛选
  void removeTagFilter(String tag) {
    _selectedTags.remove(tag);
    _applyFilters();
    notifyListeners();
  }

  /// 清除所有筛选
  void clearAllFilters() {
    _selectedTags.clear();
    _currentCategory = null;
    _filteredRecipes = [];
    _resetPagination();
    notifyListeners();
  }

  /// 获取菜谱详情
  Future<EnhancedRecipe?> getRecipeDetail(String recipeId) async {
    try {
      // 先从本地查找
      final localRecipe = _recipes.firstWhere(
        (recipe) => recipe.id == recipeId,
        orElse: () => throw StateError('Recipe not found'),
      );

      return localRecipe;
    } catch (e) {
      _logger.warning('Recipe not found locally: $recipeId',
          tag: 'RecipeController');

      // TODO: 从网络获取菜谱详情
      return null;
    }
  }

  /// 收藏菜谱
  Future<void> favoriteRecipe(String recipeId) async {
    try {
      _logger.userAction('favorite_recipe', context: {'recipe_id': recipeId});

      // TODO: 实现收藏逻辑
      // await _favoriteService.addFavorite(recipeId);

      _logger.info('Recipe favorited: $recipeId', tag: 'RecipeController');
    } catch (e, stackTrace) {
      _logger.error('Failed to favorite recipe: $e',
          stackTrace: stackTrace, tag: 'RecipeController');
      _setError('收藏失败: $e');
    }
  }

  /// 取消收藏菜谱
  Future<void> unfavoriteRecipe(String recipeId) async {
    try {
      _logger.userAction('unfavorite_recipe', context: {'recipe_id': recipeId});

      // TODO: 实现取消收藏逻辑
      // await _favoriteService.removeFavorite(recipeId);

      _logger.info('Recipe unfavorited: $recipeId', tag: 'RecipeController');
    } catch (e, stackTrace) {
      _logger.error('Failed to unfavorite recipe: $e',
          stackTrace: stackTrace, tag: 'RecipeController');
      _setError('取消收藏失败: $e');
    }
  }

  /// 加载更多菜谱（分页）
  Future<void> loadMore() async {
    if (_isLoading || !_hasMoreData) return;

    _setLoading(true);

    try {
      final rows = await _unifiedDbService.fetchTopRecipes(
        limit: _pageSize,
        offset: _recipes.length,
      );
      final moreRecipes = rows.map(_mapUnifiedRowToRecipe).toList();

      if (moreRecipes.isEmpty) {
        _hasMoreData = false;
      } else {
        _recipes.addAll(moreRecipes);
        if (_filteredRecipes.isNotEmpty) {
          _applyFilters();
        }
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to load more recipes: $e',
          stackTrace: stackTrace, tag: 'RecipeController');
      _setError('加载更多失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 刷新菜谱列表
  Future<void> refresh() async {
    _resetPagination();
    await loadRecommendedRecipes();
  }

  // 私有方法

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _resetPagination() {
    _currentPage = 0;
    _hasMoreData = true;
  }

  /// 应用筛选条件
  void _applyFilters() {
    var filtered = List<EnhancedRecipe>.from(_recipes);

    // 分类筛选
    if (_currentCategory != null) {
      filtered = filtered
          .where((recipe) => recipe.category == _currentCategory)
          .toList();
    }

    // 标签筛选
    if (_selectedTags.isNotEmpty) {
      filtered = filtered
          .where((recipe) =>
              _selectedTags.every((tag) => recipe.tags.contains(tag)))
          .toList();
    }

    _filteredRecipes = filtered;
  }

  /// 执行本地搜索
  List<EnhancedRecipe> _performLocalSearch(String query) {
    final queryLower = query.toLowerCase();

    return _recipes.where((recipe) {
      // 搜索菜谱名称
      if (recipe.name.toLowerCase().contains(queryLower)) return true;

      // 搜索描述
      if (recipe.description.toLowerCase().contains(queryLower)) return true;

      // 搜索标签
      if (recipe.tags.any((tag) => tag.toLowerCase().contains(queryLower)))
        return true;

      // 搜索食材
      if (recipe.ingredients.any(
          (ingredient) => ingredient.name.toLowerCase().contains(queryLower)))
        return true;

      // 搜索菜系
      if (recipe.cuisineType?.toLowerCase().contains(queryLower) == true)
        return true;

      return false;
    }).toList();
  }

  EnhancedRecipe _mapUnifiedRowToRecipe(Map<String, dynamic> row) {
    final ingredientsRaw = (row['ingredients'] as List<dynamic>? ?? [])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final stepsRaw = (row['steps'] as List<dynamic>? ?? [])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final nutritionRaw =
        Map<String, dynamic>.from(row['nutrition'] as Map? ?? {});
    final tasteProfile =
        Map<String, dynamic>.from(row['taste_profile_map'] as Map? ?? {});
    final tags = <String>{...List<String>.from(row['tags'] ?? const [])};
    tags.addAll(List<String>.from(row['scenes'] ?? const []));
    tags.addAll(List<String>.from(row['health_tags'] ?? const []));

    final totalTimeMinutes = (row['total_time_minutes'] ?? 30) as int;
    final prepTimeMinutes =
        (totalTimeMinutes * 0.3).clamp(5, totalTimeMinutes).round();
    final cookTimeMinutes =
        (totalTimeMinutes - prepTimeMinutes).clamp(5, totalTimeMinutes).round();
    final popularity = (row['popularity_score'] ?? 0) as num;

    return EnhancedRecipe(
      id: row['recipe_id'].toString(),
      name: row['dish_name']?.toString() ?? '',
      description: row['recipe_description']?.toString() ?? '',
      author: row['source']?.toString(),
      rating: (row['average_rating'] ?? 4.2) is num
          ? (row['average_rating'] as num).toDouble()
          : 4.2,
      reviewCount: popularity.round(),
      favoriteCount: (popularity / 3).round(),
      makeCount: (popularity / 4).round(),
      viewCount: popularity.round(),
      category: _mapCuisineToCategory(row['cuisine']?.toString()),
      tags: tags.toList(),
      difficulty: _mapDifficultyFromDb(row['difficulty'] as int?),
      prepTime: Duration(minutes: prepTimeMinutes),
      cookTime: Duration(minutes: cookTimeMinutes),
      totalTime: Duration(minutes: totalTimeMinutes),
      servings: (row['servings'] ?? 2) as int,
      methods: List<String>.from(row['cooking_methods'] ?? const []),
      ingredients: ingredientsRaw.map(RecipeIngredient.fromMap).toList(),
      steps: stepsRaw.map(RecipeStep.fromMap).toList(),
      nutrition: RecipeNutrition.fromMap(nutritionRaw),
      tasteAttributes: _buildTasteAttributes(tasteProfile),
      spiceLevel: ((tasteProfile['spicy'] ?? 0.0) as num).toDouble() * 5,
      allergens: const [],
      coverImage: row['cover_image_url']?.toString(),
      images: [
        if (row['cover_image_url'] != null) row['cover_image_url'].toString(),
      ],
      source: _mapSourceFromDb(row['source']?.toString()),
      cuisineType: row['cuisine']?.toString(),
      isVerified: true,
      status: RecipeStatus.active,
      metadata: {
        'dish_id': row['dish_id'],
        'source_recipe_id': row['source_recipe_id'],
      },
    );
  }

  RecipeCategory _mapCuisineToCategory(String? cuisine) {
    if (cuisine == null || cuisine.isEmpty) return RecipeCategory.homeStyle;
    final lower = cuisine.toLowerCase();
    if (lower.contains('素')) return RecipeCategory.vegetarian;
    if (lower.contains('汤') || lower.contains('羹')) return RecipeCategory.soup;
    if (lower.contains('甜') || lower.contains('糕'))
      return RecipeCategory.dessert;
    if (lower.contains('饮')) return RecipeCategory.beverage;
    if (lower.contains('面')) return RecipeCategory.noodles;
    if (lower.contains('饭')) return RecipeCategory.riceDish;
    return RecipeCategory.homeStyle;
  }

  String? _mapCategoryToCuisineLabel(RecipeCategory category) {
    switch (category) {
      case RecipeCategory.vegetarian:
        return '素菜';
      case RecipeCategory.soup:
        return '汤羹';
      case RecipeCategory.dessert:
        return '甜品';
      case RecipeCategory.beverage:
        return '饮品';
      default:
        return null;
    }
  }

  RecipeDifficulty _mapDifficultyFromDb(int? difficulty) {
    if (difficulty == null) return RecipeDifficulty.medium;
    if (difficulty <= 1) return RecipeDifficulty.beginner;
    if (difficulty == 2) return RecipeDifficulty.easy;
    if (difficulty == 3) return RecipeDifficulty.medium;
    if (difficulty == 4) return RecipeDifficulty.hard;
    return RecipeDifficulty.expert;
  }

  RecipeSource _mapSourceFromDb(String? source) {
    switch (source) {
      case 'xiachufang':
        return RecipeSource.xiachufang;
      case 'howtocook':
        return RecipeSource.imported;
      case 'ai':
        return RecipeSource.generated;
      default:
        return RecipeSource.unknown;
    }
  }

  List<String> _buildTasteAttributes(Map<String, dynamic> tasteProfile) {
    final attributes = <String>[];
    tasteProfile.forEach((key, value) {
      if (value is num && value.toDouble() >= 0.4) {
        attributes.add(key);
      }
    });
    return attributes;
  }

  @override
  void dispose() {
    _logger.info('EnhancedRecipeController disposed', tag: 'RecipeController');
    super.dispose();
  }
}
