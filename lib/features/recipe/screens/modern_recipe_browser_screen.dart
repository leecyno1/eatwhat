import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';

import '../../../core/models/enhanced_recipe.dart';
import '../../../core/services/firecrawl_recipe_crawler_service.dart';
import '../../../core/utils/advanced_logger.dart';
import '../../../core/error/global_error_handler.dart';
import '../../../shared/widgets/glassmorphic_container.dart';
import '../../../shared/widgets/modern_card.dart';
import '../controllers/enhanced_recipe_controller.dart';

/// 现代化菜谱浏览界面 - 基于下厨房数据结构
class ModernRecipeBrowserScreen extends StatefulWidget {
  const ModernRecipeBrowserScreen({super.key});

  @override
  State<ModernRecipeBrowserScreen> createState() => _ModernRecipeBrowserScreenState();
}

class _ModernRecipeBrowserScreenState extends State<ModernRecipeBrowserScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // 搜索和筛选
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  RecipeCategory? _selectedCategory;
  RecipeDifficulty? _selectedDifficulty;

  // 显示模式
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 6, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    // 初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 加载初始数据
  void _loadInitialData() {
    final controller = Provider.of<EnhancedRecipeController>(context, listen: false);
    controller.loadRecommendedRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorContext: 'ModernRecipeBrowserScreen',
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildAppBar(),
                _buildSearchBar(),
                _buildCategoryTabs(),
                Expanded(
                  child: _buildRecipeContent(),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  /// 构建应用栏
  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '菜谱大全',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  '发现美味，享受生活',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF7F8C8D),
                  ),
                ),
              ],
            ),
          ),

          // 视图切换按钮
          _buildViewToggleButton(),

          SizedBox(width: 12.w),

          // 数据同步按钮
          _buildSyncButton(),
        ],
      ),
    );
  }

  /// 构建视图切换按钮
  Widget _buildViewToggleButton() {
    return GlassmorphicContainer(
      width: 44.w,
      height: 44.h,
      borderRadius: 12,
      blur: 20,
      borderWidth: 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _isGridView = !_isGridView;
            });
            HapticFeedback.lightImpact();
          },
          child: Icon(
            _isGridView ? Icons.view_list : Icons.grid_view,
            size: 20.sp,
            color: const Color(0xFF007AFF),
          ),
        ),
      ),
    );
  }

  /// 构建同步按钮
  Widget _buildSyncButton() {
    return Consumer<EnhancedRecipeController>(
      builder: (context, controller, child) {
        return GlassmorphicContainer(
          width: 44.w,
          height: 44.h,
          borderRadius: 12,
          blur: 20,
          borderWidth: 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: controller.isSyncing ? null : () => _startSync(),
              child: controller.isSyncing
                  ? SizedBox(
                      width: 20.sp,
                      height: 20.sp,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    )
                  : Icon(
                      Icons.sync,
                      size: 20.sp,
                      color: Colors.white,
                    ),
            ),
          ),
        );
      },
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 56.h,
        borderRadius: 16,
        blur: 20,
        borderWidth: 1,
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
            _searchRecipes(value);
          },
          decoration: InputDecoration(
            hintText: '搜索菜谱、食材或菜系...',
            hintStyle: TextStyle(
              fontSize: 16.sp,
              color: const Color(0xFF7F8C8D),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: const Color(0xFF007AFF),
              size: 24.sp,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                      _clearSearch();
                    },
                    icon: Icon(
                      Icons.clear,
                      color: const Color(0xFF7F8C8D),
                      size: 20.sp,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
          style: TextStyle(
            fontSize: 16.sp,
            color: const Color(0xFF2C3E50),
          ),
        ),
      ),
    );
  }

  /// 构建分类标签
  Widget _buildCategoryTabs() {
    return Container(
      height: 50.h,
      margin: EdgeInsets.only(bottom: 16.h),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [Color(0xFF007AFF), Color(0xFF5AC8FA)],
          ),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF7F8C8D),
        labelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.normal,
        ),
        tabs: const [
          Tab(text: '推荐'),
          Tab(text: '家常菜'),
          Tab(text: '快手菜'),
          Tab(text: '烘焙'),
          Tab(text: '汤羹'),
          Tab(text: '小吃'),
        ],
        onTap: (index) {
          _loadCategoryRecipes(index);
        },
      ),
    );
  }

  /// 构建菜谱内容
  Widget _buildRecipeContent() {
    return TabBarView(
      controller: _tabController,
      children: List.generate(6, (index) {
        return Consumer<EnhancedRecipeController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return _buildLoadingState();
            }

            if (controller.error != null) {
              return _buildErrorState(controller.error!);
            }

            final recipes = controller.recipes;

            if (recipes.isEmpty) {
              return _buildEmptyState();
            }

            return _buildRecipeList(recipes);
          },
        );
      }),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.75,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: const Color(0xFFE74C3C),
          ),
          SizedBox(height: 16.h),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF7F8C8D),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => _loadInitialData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 12.h,
              ),
            ),
            child: Text(
              '重试',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64.sp,
            color: const Color(0xFF7F8C8D),
          ),
          SizedBox(height: 16.h),
          Text(
            '暂无菜谱',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '试试搜索其他关键词',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF7F8C8D),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建菜谱列表
  Widget _buildRecipeList(List<EnhancedRecipe> recipes) {
    return AnimationLimiter(
      child: _isGridView ? _buildGridView(recipes) : _buildListView(recipes),
    );
  }

  /// 构建网格视图
  Widget _buildGridView(List<EnhancedRecipe> recipes) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.75,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        return AnimationConfiguration.staggeredGrid(
          position: index,
          duration: const Duration(milliseconds: 375),
          columnCount: 2,
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildRecipeCard(recipes[index]),
            ),
          ),
        );
      },
    );
  }

  /// 构建列表视图
  Widget _buildListView(List<EnhancedRecipe> recipes) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: _buildRecipeListCard(recipes[index]),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建菜谱卡片
  Widget _buildRecipeCard(EnhancedRecipe recipe) {
    return GestureDetector(
      onTap: () => _openRecipeDetail(recipe),
      child: ModernCard(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: _buildRecipeImage(recipe),
              ),
            ),

            // 信息
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // 作者
                    if (recipe.author != null)
                      Text(
                        'by ${recipe.author}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF7F8C8D),
                        ),
                      ),

                    const Spacer(),

                    // 评分和时间
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14.sp,
                          color: const Color(0xFFF39C12),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          recipe.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF7F8C8D),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.access_time,
                          size: 14.sp,
                          color: const Color(0xFF7F8C8D),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${recipe.totalTime.inMinutes}分钟',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF7F8C8D),
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
    );
  }

  /// 构建菜谱列表卡片
  Widget _buildRecipeListCard(EnhancedRecipe recipe) {
    return GestureDetector(
      onTap: () => _openRecipeDetail(recipe),
      child: ModernCard(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // 图片
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80.w,
                  height: 80.w,
                  child: _buildRecipeImage(recipe),
                ),
              ),

              SizedBox(width: 16.w),

              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    if (recipe.author != null)
                      Text(
                        'by ${recipe.author}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF7F8C8D),
                        ),
                      ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.star,
                          text: recipe.rating.toStringAsFixed(1),
                          color: const Color(0xFFF39C12),
                        ),
                        SizedBox(width: 12.w),
                        _buildInfoChip(
                          icon: Icons.access_time,
                          text: '${recipe.totalTime.inMinutes}分钟',
                          color: const Color(0xFF007AFF),
                        ),
                        SizedBox(width: 12.w),
                        _buildInfoChip(
                          icon: Icons.people,
                          text: '${recipe.makeCount}人做过',
                          color: const Color(0xFF27AE60),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 箭头
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: const Color(0xFF7F8C8D),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建菜谱图片
  Widget _buildRecipeImage(EnhancedRecipe recipe) {
    if (recipe.coverImage != null) {
      return CachedNetworkImage(
        imageUrl: recipe.coverImage!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholderImage(),
      );
    }

    return _buildPlaceholderImage();
  }

  /// 构建占位图片
  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 32.sp,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  /// 构建信息标签
  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建悬浮操作按钮
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _startCrawling,
      backgroundColor: const Color(0xFF007AFF),
      icon: const Icon(Icons.download, color: Colors.white),
      label: Text(
        '抓取菜谱',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
        ),
      ),
    );
  }

  /// 搜索菜谱
  void _searchRecipes(String query) {
    if (query.isEmpty) {
      _loadInitialData();
      return;
    }

    final controller = Provider.of<EnhancedRecipeController>(context, listen: false);
    controller.searchRecipes(query);
  }

  /// 清除搜索
  void _clearSearch() {
    final controller = Provider.of<EnhancedRecipeController>(context, listen: false);
    controller.clearSearch();
  }

  /// 加载分类菜谱
  void _loadCategoryRecipes(int categoryIndex) {
    final categories = [
      null, // 推荐
      RecipeCategory.homeStyle, // 家常菜
      RecipeCategory.quickDish, // 快手菜
      RecipeCategory.baking, // 烘焙
      RecipeCategory.soup, // 汤羹
      RecipeCategory.snack, // 小吃
    ];

    final controller = Provider.of<EnhancedRecipeController>(context, listen: false);

    if (categories[categoryIndex] == null) {
      controller.loadRecommendedRecipes();
    } else {
      controller.loadRecipesByCategory(categories[categoryIndex]!);
    }
  }

  /// 开始数据同步
  void _startSync() {
    final controller = Provider.of<EnhancedRecipeController>(context, listen: false);
    controller.syncRecipeData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('开始同步菜谱数据...'),
        backgroundColor: const Color(0xFF007AFF),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 开始抓取菜谱
  void _startCrawling() {
    showDialog(
      context: context,
      builder: (context) => const RecipeCrawlDialog(),
    );
  }

  /// 打开菜谱详情
  void _openRecipeDetail(EnhancedRecipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernRecipeDetailScreen(recipe: recipe),
      ),
    );
  }
}

/// 菜谱抓取对话框
class RecipeCrawlDialog extends StatefulWidget {
  const RecipeCrawlDialog({super.key});

  @override
  State<RecipeCrawlDialog> createState() => _RecipeCrawlDialogState();
}

class _RecipeCrawlDialogState extends State<RecipeCrawlDialog> {
  final FirecrawlRecipeCrawlerService _crawlerService = FirecrawlRecipeCrawlerService.instance;

  bool _isRunning = false;
  RecipeCrawlProgress? _progress;

  @override
  void initState() {
    super.initState();
    _crawlerService.setProgressCallback(_onProgressUpdate);
  }

  void _onProgressUpdate(RecipeCrawlProgress progress) {
    setState(() {
      _progress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('抓取菜谱数据'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_progress != null) ...[
            LinearProgressIndicator(
              value: _progress!.progressPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
            ),
            SizedBox(height: 16.h),
            Text(
              '${_progress!.phase.label}: ${_progress!.processedRecipes}/${_progress!.totalRecipes}',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              '成功: ${_progress!.successfulRecipes}, 失败: ${_progress!.failedRecipes}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ] else ...[
            const Text('准备开始抓取下厨房菜谱数据...'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isRunning ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isRunning ? _stopCrawling : _startCrawling,
          child: Text(_isRunning ? '停止' : '开始'),
        ),
      ],
    );
  }

  void _startCrawling() async {
    setState(() {
      _isRunning = true;
    });

    try {
      final result = await _crawlerService.startCrawling(
        categories: ['家常菜', '快手菜', '烘焙'],
        maxRecipes: 100,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('抓取完成！共获取${result.recipes.length}个菜谱'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('抓取失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  void _stopCrawling() {
    _crawlerService.stopCrawling();
    setState(() {
      _isRunning = false;
    });
  }
}

/// 现代化菜谱详情页面 - 占位实现
class ModernRecipeDetailScreen extends StatelessWidget {
  final EnhancedRecipe recipe;

  const ModernRecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
      ),
      body: Center(
        child: Text('菜谱详情页面 - 待实现'),
      ),
    );
  }
}
