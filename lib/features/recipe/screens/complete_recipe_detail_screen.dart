import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/models/enhanced_recipe.dart';
import '../controllers/enhanced_recipe_controller.dart';
import '../../../core/error/global_error_handler.dart';
import '../../../shared/widgets/glassmorphic_container.dart';

/// 完整菜谱详情界面 - 基于增强菜谱数据模型
/// 展示从下厨房爬取的真实菜谱数据
class CompleteRecipeDetailScreen extends StatefulWidget {
  final String recipeId;
  final VoidCallback? onBack;

  const CompleteRecipeDetailScreen({
    super.key,
    required this.recipeId,
    this.onBack,
  });

  @override
  State<CompleteRecipeDetailScreen> createState() => _CompleteRecipeDetailScreenState();
}

class _CompleteRecipeDetailScreenState extends State<CompleteRecipeDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late ScrollController _scrollController;
  bool _isFavorite = false;
  EnhancedRecipe? _recipe;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _scrollController = ScrollController();

    // 启动动画
    _fadeController.forward();
    _slideController.forward();

    // 加载菜谱数据
    _loadRecipeData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 加载菜谱数据
  Future<void> _loadRecipeData() async {
    try {
      final controller = context.read<EnhancedRecipeController>();
      final recipe = await controller.getRecipeDetail(widget.recipeId);

      if (mounted) {
        setState(() {
          _recipe = recipe;
          _isLoading = false;
          if (recipe != null) {
            _isFavorite = recipe.favoriteCount > 0; // 简单的收藏逻辑
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '加载菜谱失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorContext: 'CompleteRecipeDetailScreen',
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: _buildBody(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadRecipeData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                '重试',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (_recipe == null) {
      return const Center(
        child: Text(
          '菜谱未找到',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // 美观的图片header
        _buildImageHeader(),

        // 主要内容区域
        SliverToBoxAdapter(
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildMainContent(),
          ),
        ),
      ],
    );
  }

  /// 构建图片header
  Widget _buildImageHeader() {
    return SliverAppBar(
      expandedHeight: 300.h,
      pinned: true,
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
          ),
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: Colors.white),
          ),
          onPressed: _shareRecipe,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 菜谱图片
            _recipe!.coverImage?.isNotEmpty == true
                ? Image.network(
                    _recipe!.coverImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),

            // 渐变遮罩
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // 底部标题区域
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 菜谱名称
                  Text(
                    _recipe!.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // 基本信息行
                  Row(
                    children: [
                      _buildInfoChip(Icons.schedule, '${_recipe!.totalTime.inMinutes}分钟'),
                      SizedBox(width: 12.w),
                      _buildInfoChip(Icons.people, '${_recipe!.servings}人份'),
                      SizedBox(width: 12.w),
                      _buildInfoChip(Icons.star, '${_recipe!.rating.toStringAsFixed(1)}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
          size: 80,
        ),
      ),
    );
  }

  /// 构建信息芯片
  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建主要内容
  Widget _buildMainContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 菜谱描述
            _buildDescriptionSection(),

            SizedBox(height: 24.h),

            // 口味标签
            _buildTasteSection(),

            SizedBox(height: 24.h),

            // 食材列表
            _buildIngredientsSection(),

            SizedBox(height: 24.h),

            // 烹饪步骤
            _buildStepsSection(),

            SizedBox(height: 24.h),

            // 营养信息
            _buildNutritionSection(),

            SizedBox(height: 24.h),

            // 小贴士
            if (_recipe!.notes?.isNotEmpty ?? false) _buildTipsSection(),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  /// 构建描述部分
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '菜谱介绍',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Text(
            _recipe!.description,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建口味标签部分
  Widget _buildTasteSection() {
    if (_recipe!.tasteAttributes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '口味特色',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _recipe!.tasteAttributes.map((taste) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.red],
                ),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                taste,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建食材部分
  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '所需食材',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Column(
            children: _recipe!.ingredients.asMap().entries.map((entry) {
              final index = entry.key;
              final ingredient = entry.value;
              final isLast = index == _recipe!.ingredients.length - 1;

              return Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(color: Colors.grey[700]!),
                        ),
                ),
                child: Row(
                  children: [
                    // 主料/辅料标识
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        color: ingredient.isMain ? Colors.orange : Colors.grey[600],
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // 食材名称
                    Expanded(
                      flex: 3,
                      child: Text(
                        ingredient.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // 用量
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${ingredient.amount ?? ''} ${ingredient.unit ?? ''}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 构建步骤部分
  Widget _buildStepsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '制作步骤',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        ..._recipe!.steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;

          return Container(
            margin: EdgeInsets.only(bottom: 16.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 步骤序号
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.red],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),

                // 步骤内容
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.description,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            height: 1.5,
                          ),
                        ),
                        if (step.duration != null) ...[
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(Icons.timer, color: Colors.orange, size: 16),
                              SizedBox(width: 4.w),
                              Text(
                                '${step.duration!.inMinutes}分钟',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  /// 构建营养信息部分
  Widget _buildNutritionSection() {
    final nutrition = _recipe!.nutrition;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '营养信息',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildNutritionItem('热量', '${nutrition.calories.toInt()}', 'kcal'),
              ),
              Container(
                width: 1,
                height: 40.h,
                color: Colors.grey[700],
              ),
              Expanded(
                child: _buildNutritionItem('蛋白质', '${nutrition.protein.toStringAsFixed(1)}', 'g'),
              ),
              Container(
                width: 1,
                height: 40.h,
                color: Colors.grey[700],
              ),
              Expanded(
                child: _buildNutritionItem('脂肪', '${nutrition.fat.toStringAsFixed(1)}', 'g'),
              ),
              Container(
                width: 1,
                height: 40.h,
                color: Colors.grey[700],
              ),
              Expanded(
                child: _buildNutritionItem('碳水', '${nutrition.carbs.toStringAsFixed(1)}', 'g'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建营养项目
  Widget _buildNutritionItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.orange,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  /// 构建小贴士部分
  Widget _buildTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '制作小贴士',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.blue[900]?.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.blue[700]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb, color: Colors.blue[300], size: 20),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  _recipe!.notes!,
                  style: TextStyle(
                    color: Colors.blue[100],
                    fontSize: 14.sp,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 切换收藏状态
  void _toggleFavorite() async {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    HapticFeedback.lightImpact();

    try {
      final controller = context.read<EnhancedRecipeController>();
      if (_isFavorite) {
        await controller.favoriteRecipe(widget.recipeId);
      } else {
        await controller.unfavoriteRecipe(widget.recipeId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? '已添加到收藏' : '已取消收藏'),
            duration: const Duration(seconds: 1),
            backgroundColor: _isFavorite ? Colors.red : Colors.grey[700],
          ),
        );
      }
    } catch (e) {
      // 失败时回滚状态
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 分享菜谱
  void _shareRecipe() {
    HapticFeedback.lightImpact();

    // TODO: 实现分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('分享功能开发中...'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
