import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/models/recipe.dart';
import '../../../core/services/recipe_database_service.dart';
import '../../../shared/widgets/modern_loading_animation.dart';
import '../../../shared/widgets/glassmorphic_container.dart';
import 'complete_recipe_detail_screen.dart';

/// 菜谱推荐界面 - Phase 2 集成真实数据
/// 展示基于下厨房爬取数据的推荐菜谱
class RecipeRecommendationScreen extends StatefulWidget {
  final List<String>? preferredTags;
  final String? searchKeyword;

  const RecipeRecommendationScreen({
    super.key,
    this.preferredTags,
    this.searchKeyword,
  });

  @override
  State<RecipeRecommendationScreen> createState() => _RecipeRecommendationScreenState();
}

class _RecipeRecommendationScreenState extends State<RecipeRecommendationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;

  final RecipeDatabaseService _databaseService = RecipeDatabaseService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Recipe> _recipes = [];
  List<Recipe> _filteredRecipes = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _hasError = false;
  String _errorMessage = '';

  // 筛选选项
  String _selectedDifficulty = '全部';
  String _selectedCookingTime = '全部';
  String _selectedCategory = '全部';
  List<String> _selectedTags = [];

  final List<String> _difficultyOptions = ['全部', '简单', '中等', '困难'];
  final List<String> _timeOptions = ['全部', '15分钟内', '30分钟内', '1小时内', '1小时以上'];
  final List<String> _categoryOptions = ['全部', '家常菜', '快手菜', '素食', '汤品', '甜品', '烘焙'];
  final List<String> _commonTags = ['清淡', '麻辣', '酸甜', '鲜美', '营养', '低脂', '高蛋白', '暖胃'];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // 初始搜索
    if (widget.searchKeyword?.isNotEmpty ?? false) {
      _searchController.text = widget.searchKeyword!;
    }

    if (widget.preferredTags?.isNotEmpty ?? false) {
      _selectedTags.addAll(widget.preferredTags!);
    }

    _loadRecommendations();

    _fadeController.forward();
    _staggerController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: _buildBody(),
          );
        },
      ),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        '推荐菜谱',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // 刷新真实数据按钮
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: _isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
          ),
          onPressed: _isRefreshing ? null : _refreshRealData,
          tooltip: '更新真实数据',
        ),
        // 筛选按钮
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.filter_list, color: Colors.white),
          ),
          onPressed: _showFilterDialog,
        ),
      ],
    );
  }

  /// 构建主体内容
  Widget _buildBody() {
    if (_isLoading && _recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ModernLoadingAnimation(),
            SizedBox(height: 20.h),
            Text(
              '正在加载推荐菜谱...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError && _recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            SizedBox(height: 20.h),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: _loadRecommendations,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(height: 100.h), // AppBar 高度补偿

        // 搜索栏
        _buildSearchBar(),

        SizedBox(height: 16.h),

        // 筛选标签
        _buildFilterTags(),

        SizedBox(height: 16.h),

        // 菜谱列表
        Expanded(
          child: _buildRecipeList(),
        ),
      ],
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 50.h,
        borderRadius: 25.r,
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
          decoration: InputDecoration(
            hintText: '搜索菜谱名称或食材...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16.sp),
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      _applyFilters();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
          ),
          onChanged: (value) {
            setState(() {});
            _applyFilters();
          },
        ),
      ),
    );
  }

  /// 构建筛选标签
  Widget _buildFilterTags() {
    return SizedBox(
      height: 40.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        children: [
          _buildFilterChip('难度: $_selectedDifficulty'),
          SizedBox(width: 8.w),
          _buildFilterChip('时间: $_selectedCookingTime'),
          SizedBox(width: 8.w),
          _buildFilterChip('分类: $_selectedCategory'),
          if (_selectedTags.isNotEmpty) ...[
            SizedBox(width: 8.w),
            ..._selectedTags.map((tag) => Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: _buildFilterChip(tag, isTag: true),
                )),
          ],
        ],
      ),
    );
  }

  /// 构建筛选芯片
  Widget _buildFilterChip(String text, {bool isTag = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isTag ? Colors.orange.withValues(alpha: 0.3) : Colors.grey[800],
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isTag ? Colors.orange : Colors.grey[600]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              color: isTag ? Colors.orange : Colors.white,
              fontSize: 12.sp,
            ),
          ),
          if (isTag) ...[
            SizedBox(width: 4.w),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTags.remove(text);
                });
                _applyFilters();
              },
              child: Icon(
                Icons.close,
                color: Colors.orange,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建菜谱列表
  Widget _buildRecipeList() {
    if (_filteredRecipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              color: Colors.grey[600],
              size: 80,
            ),
            SizedBox(height: 20.h),
            Text(
              '暂无符合条件的菜谱',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              '试试调整筛选条件',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: _filteredRecipes.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredRecipes.length) {
          return Padding(
            padding: EdgeInsets.all(20.w),
            child: const Center(child: ModernLoadingAnimation()),
          );
        }

        return AnimatedBuilder(
          animation: _staggerController,
          builder: (context, child) {
            final delay = (index * 0.1).clamp(0.0, 1.0);
            final staggerAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: _staggerController,
              curve: Interval(delay, 1.0, curve: Curves.easeOut),
            ));

            return Transform.translate(
              offset: Offset(0, (1 - staggerAnimation.value) * 50),
              child: Opacity(
                opacity: staggerAnimation.value,
                child: _buildRecipeCard(_filteredRecipes[index], index),
              ),
            );
          },
        );
      },
    );
  }

  /// 构建菜谱卡片
  Widget _buildRecipeCard(Recipe recipe, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: GestureDetector(
        onTap: () => _openRecipeDetail(recipe),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 120.h,
          borderRadius: 16.r,
          child: Row(
            children: [
              // 菜谱图片
              Container(
                width: 100.w,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    bottomLeft: Radius.circular(16.r),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    bottomLeft: Radius.circular(16.r),
                  ),
                  child: recipe.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: recipe.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.withValues(alpha: 0.3),
                                  Colors.grey.withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
              ),

              // 菜谱信息
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 菜谱名称
                      Text(
                        recipe.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 4.h),

                      // 描述
                      Text(
                        recipe.description,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 12.sp,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const Spacer(),

                      // 底部信息
                      Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.orange, size: 14),
                          SizedBox(width: 4.w),
                          Text(
                            '${recipe.cookingTime}分钟',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Icon(Icons.people, color: Colors.blue, size: 14),
                          SizedBox(width: 4.w),
                          Text(
                            '${recipe.servings}人份',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12.sp,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 14),
                              SizedBox(width: 2.w),
                              Text(
                                recipe.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
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
      ),
    );
  }

  /// 构建占位图片
  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withValues(alpha: 0.3),
            Colors.red.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.restaurant,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  /// 加载推荐菜谱
  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // 使用数据库服务获取菜谱
      await _databaseService.initialize();

      final searchQuery = widget.searchKeyword ?? _searchController.text;

      List<Recipe> allRecipes;
      if (searchQuery.isNotEmpty) {
        // 有搜索关键词时进行搜索
        allRecipes = await _databaseService.searchRecipes(
          query: searchQuery,
          limit: 50,
        );
      } else {
        // 否则获取所有菜谱
        allRecipes = await _databaseService.getAllRecipes();
      }

      setState(() {
        _recipes = allRecipes;
        _filteredRecipes = allRecipes;
        _isLoading = false;
      });

      _applyFilters();
      _fadeController.forward();
      _staggerController.forward();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = '数据加载失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 刷新真实数据
  Future<void> _refreshRealData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final success = await _databaseService.refreshRealData(
        onProgress: (message) {
          debugPrint('数据更新: $message');
          // 可以在这里显示进度提示
        },
      );

      if (success) {
        // 重新加载推荐
        await _loadRecommendations();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 数据更新成功！'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ 数据更新失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 更新过程出错: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  /// 应用筛选条件
  void _applyFilters() {
    setState(() {
      _filteredRecipes = _recipes.where((recipe) {
        // 搜索关键词筛选
        final searchTerm = _searchController.text.toLowerCase();
        if (searchTerm.isNotEmpty) {
          final matchName = recipe.name.toLowerCase().contains(searchTerm);
          final matchIngredients = recipe.ingredients.any(
            (ingredient) => ingredient.name.toLowerCase().contains(searchTerm),
          );
          if (!matchName && !matchIngredients) return false;
        }

        // 难度筛选
        if (_selectedDifficulty != '全部') {
          final difficultyMap = {
            '简单': RecipeDifficulty.easy,
            '中等': RecipeDifficulty.medium,
            '困难': RecipeDifficulty.hard,
          };
          if (recipe.difficulty != difficultyMap[_selectedDifficulty]) return false;
        }

        // 时间筛选
        if (_selectedCookingTime != '全部') {
          final timeRanges = {
            '15分钟内': (0, 15),
            '30分钟内': (0, 30),
            '1小时内': (0, 60),
            '1小时以上': (60, 999),
          };
          final range = timeRanges[_selectedCookingTime];
          if (range != null) {
            if (recipe.cookingTime < range.$1 || recipe.cookingTime > range.$2) return false;
          }
        }

        // 标签筛选
        if (_selectedTags.isNotEmpty) {
          final hasMatchingTag = _selectedTags
              .any((tag) => recipe.tasteProfile.contains(tag) || recipe.tags.contains(tag));
          if (!hasMatchingTag) return false;
        }

        return true;
      }).toList();
    });
  }

  /// 显示筛选对话框
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                '筛选条件',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.h),

              // 难度选择
              _buildFilterSection('难度', _difficultyOptions, _selectedDifficulty, (value) {
                setState(() => _selectedDifficulty = value);
              }),

              SizedBox(height: 20.h),

              // 时间选择
              _buildFilterSection('制作时间', _timeOptions, _selectedCookingTime, (value) {
                setState(() => _selectedCookingTime = value);
              }),

              SizedBox(height: 20.h),

              // 分类选择
              _buildFilterSection('菜品分类', _categoryOptions, _selectedCategory, (value) {
                setState(() => _selectedCategory = value);
              }),

              SizedBox(height: 20.h),

              // 口味标签
              Text(
                '口味偏好',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: _commonTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.orange : Colors.grey[700],
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const Spacer(),

              // 按钮
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedDifficulty = '全部';
                          _selectedCookingTime = '全部';
                          _selectedCategory = '全部';
                          _selectedTags.clear();
                        });
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('重置'),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('应用'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建筛选选项部分
  Widget _buildFilterSection(
      String title, List<String> options, String selected, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: options.map((option) {
            final isSelected = selected == option;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange : Colors.grey[700],
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 打开菜谱详情
  void _openRecipeDetail(Recipe recipe) {
    HapticFeedback.lightImpact();

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CompleteRecipeDetailScreen(recipeId: recipe.id),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
