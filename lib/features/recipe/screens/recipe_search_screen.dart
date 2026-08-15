import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/models/recipe.dart';
import '../../../core/services/real_xiachufang_crawler_service.dart';
import '../../../shared/widgets/modern_loading_animation.dart';
import '../../../shared/widgets/glassmorphic_container.dart';
import 'complete_recipe_detail_screen.dart';

/// 菜谱搜索界面 - Phase 2 新增
/// 集成真实搜索功能和智能推荐
class RecipeSearchScreen extends StatefulWidget {
  const RecipeSearchScreen({super.key});

  @override
  State<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends State<RecipeSearchScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _searchController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _textController = TextEditingController();
  final RealXiachufangCrawlerService _crawlerService = RealXiachufangCrawlerService();

  List<Recipe> _searchResults = [];
  List<String> _searchHistory = [];
  List<String> _hotSearches = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  // 搜索建议分类
  final List<String> _cuisineTypes = [
    '川菜',
    '粤菜',
    '湘菜',
    '鲁菜',
    '苏菜',
    '浙菜',
    '闽菜',
    '徽菜',
    '东北菜',
    '西北菜',
    '家常菜',
    '素食',
    '海鲜',
  ];

  final List<String> _mealTypes = [
    '早餐',
    '午餐',
    '晚餐',
    '夜宵',
    '下午茶',
    '汤品',
    '甜品',
    '小食',
    '快手菜',
    '宴客菜',
    '减脂餐',
    '儿童餐',
  ];

  final List<String> _cookingMethods = [
    '炒菜',
    '蒸菜',
    '炖菜',
    '煮菜',
    '烤制',
    '炸制',
    '凉拌',
    '烘焙',
    '煎制',
    '焖制',
    '卤制',
    '腌制',
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _searchController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _initializeData();

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _textController.dispose();
    super.dispose();
  }

  /// 初始化数据
  Future<void> _initializeData() async {
    await _crawlerService.initialize();

    // 模拟热门搜索
    _hotSearches = [
      '宫保鸡丁',
      '麻婆豆腐',
      '红烧肉',
      '蒸蛋羹',
      '番茄鸡蛋',
      '糖醋排骨',
      '可乐鸡翅',
      '鱼香肉丝',
      '回锅肉',
      '水煮鱼',
    ];

    // 从本地存储加载搜索历史
    _loadSearchHistory();
  }

  /// 加载搜索历史
  void _loadSearchHistory() {
    // TODO: 从SharedPreferences加载
    _searchHistory = ['家常菜', '川菜', '素食'];
  }

  /// 保存搜索历史
  void _saveSearchHistory(String query) {
    if (!_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.take(10).toList();
      }
      // TODO: 保存到SharedPreferences
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
      title: _buildSearchBar(),
      titleSpacing: 0,
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Container(
      height: 45.h,
      margin: EdgeInsets.only(right: 16.w),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 45.h,
        borderRadius: 22.5.r,
        child: TextField(
          controller: _textController,
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
          decoration: InputDecoration(
            hintText: '搜索菜谱、食材或做法...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16.sp),
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            suffixIcon: _textController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _textController.clear();
                      setState(() {
                        _hasSearched = false;
                        _searchResults.clear();
                      });
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.mic, color: Colors.orange),
                    onPressed: _startVoiceSearch,
                  ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          ),
          onChanged: (value) => setState(() {}),
          onSubmitted: _performSearch,
        ),
      ),
    );
  }

  /// 构建主体内容
  Widget _buildBody() {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ModernLoadingAnimation(),
            SizedBox(height: 20.h),
            Text(
              '正在搜索菜谱...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasSearched && _searchResults.isNotEmpty) {
      return _buildSearchResults();
    }

    return _buildSearchSuggestions();
  }

  /// 构建搜索建议页面
  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索历史
          if (_searchHistory.isNotEmpty) ...[
            _buildSectionTitle('搜索历史', Icons.history),
            SizedBox(height: 16.h),
            _buildTagGrid(_searchHistory, onTap: _performSearch),
            SizedBox(height: 32.h),
          ],

          // 热门搜索
          _buildSectionTitle('热门搜索', Icons.local_fire_department),
          SizedBox(height: 16.h),
          _buildTagGrid(_hotSearches, onTap: _performSearch),
          SizedBox(height: 32.h),

          // 菜系分类
          _buildSectionTitle('菜系分类', Icons.restaurant_menu),
          SizedBox(height: 16.h),
          _buildCategoryGrid(_cuisineTypes),
          SizedBox(height: 32.h),

          // 用餐时间
          _buildSectionTitle('用餐时间', Icons.schedule),
          SizedBox(height: 16.h),
          _buildCategoryGrid(_mealTypes),
          SizedBox(height: 32.h),

          // 烹饪方式
          _buildSectionTitle('烹饪方式', Icons.kitchen),
          SizedBox(height: 16.h),
          _buildCategoryGrid(_cookingMethods),
        ],
      ),
    );
  }

  /// 构建分区标题
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 构建标签网格
  Widget _buildTagGrid(List<String> tags, {required Function(String) onTap}) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: tags.map((tag) => _buildTag(tag, onTap: () => onTap(tag))).toList(),
    );
  }

  /// 构建分类网格
  Widget _buildCategoryGrid(List<String> categories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 2.5,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return _buildCategoryCard(categories[index]);
      },
    );
  }

  /// 构建标签
  Widget _buildTag(String text, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey[600]!),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  /// 构建分类卡片
  Widget _buildCategoryCard(String category) {
    return GestureDetector(
      onTap: () => _performSearch(category),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 40.h,
        borderRadius: 12.r,
        child: Center(
          child: Text(
            category,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建搜索结果
  Widget _buildSearchResults() {
    return Column(
      children: [
        // 结果统计
        Container(
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              Text(
                '搜索结果',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '共找到 ${_searchResults.length} 个菜谱',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),

        // 搜索结果列表
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return _buildResultCard(_searchResults[index]);
            },
          ),
        ),
      ],
    );
  }

  /// 构建搜索结果卡片
  Widget _buildResultCard(Recipe recipe) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: GestureDetector(
        onTap: () => _openRecipeDetail(recipe),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 100.h,
          borderRadius: 16.r,
          child: Row(
            children: [
              // 菜谱图片
              Container(
                width: 80.w,
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
                      ? Image.network(
                          recipe.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
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
          size: 24,
        ),
      ),
    );
  }

  /// 执行搜索
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    final searchQuery = query.trim();
    _textController.text = searchQuery;
    _saveSearchHistory(searchQuery);

    setState(() {
      _isSearching = true;
      _hasSearched = false;
    });

    _searchController.forward();

    try {
      final result = await _crawlerService.crawlRecipes(
        categories: [searchQuery],
        targetCount: 30,
        onProgress: (message) {
          debugPrint('搜索进度: $message');
        },
      );

      if (result.success) {
        setState(() {
          _searchResults = _crawlerService.crawledRecipes
              .where((recipe) =>
                  recipe.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  recipe.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  recipe.ingredients.any((ingredient) =>
                      ingredient.name.toLowerCase().contains(searchQuery.toLowerCase())))
              .toList();
          _hasSearched = true;
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchResults = [];
          _hasSearched = true;
          _isSearching = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _hasSearched = true;
        _isSearching = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('搜索失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 开始语音搜索
  void _startVoiceSearch() {
    HapticFeedback.lightImpact();

    // TODO: 集成语音识别
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('语音搜索功能开发中...'),
        duration: Duration(seconds: 1),
      ),
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
