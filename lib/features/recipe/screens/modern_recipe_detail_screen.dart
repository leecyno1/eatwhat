import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../core/models/enhanced_recipe.dart';
import '../../../core/services/howtocook_database_service.dart';
import '../../../core/utils/advanced_logger.dart';

/// 现代化菜谱详情界面
class ModernRecipeDetailScreen extends StatefulWidget {
  final EnhancedRecipe recipe;

  const ModernRecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<ModernRecipeDetailScreen> createState() => _ModernRecipeDetailScreenState();
}

class _ModernRecipeDetailScreenState extends State<ModernRecipeDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _heroController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _heroAnimation;

  final ScrollController _scrollController = ScrollController();
  final HowToCookDatabaseService _databaseService = HowToCookDatabaseService();
  final AdvancedLogger _logger = AdvancedLogger.instance;

  bool _isLoading = false;
  bool _isFavorited = false;
  int _currentStep = 0;
  List<RecipeIngredient> _ingredients = [];
  List<RecipeStep> _steps = [];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _heroAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutBack),
    );

    _loadRecipeDetails();
    _fadeController.forward();
    _heroController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _heroController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipeDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final database = await _databaseService.database;

      // 加载食材信息
      final ingredientsMaps = await database.query(
        'howtocook_ingredients',
        where: 'recipe_id = ?',
        whereArgs: [widget.recipe.id],
      );

      // 加载制作步骤
      final stepsMaps = await database.query(
        'howtocook_steps',
        where: 'recipe_id = ?',
        whereArgs: [widget.recipe.id],
        orderBy: 'step_order ASC',
      );

      setState(() {
        _ingredients = ingredientsMaps
            .map((map) => RecipeIngredient(
                  name: (map['ingredient_name'] as String?) ?? '',
                  amount: map['amount']?.toString(),
                  unit: map['unit']?.toString(),
                  category: map['category']?.toString(),
                ))
            .toList();

        _steps = stepsMaps
            .map((map) => RecipeStep(
                  order: (map['step_order'] as int?) ?? 1,
                  description: (map['description'] as String?) ?? '',
                ))
            .toList();

        _isLoading = false;
      });

      _logger.info('Loaded recipe details for ${widget.recipe.name}', tag: 'RecipeDetail');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _logger.error('Failed to load recipe details: $e', tag: 'RecipeDetail');
    }
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
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Hero Image with AppBar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: Icon(
                    _isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorited ? Colors.red : Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFavorited = !_isFavorited;
                    });
                    HapticFeedback.lightImpact();
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    // 实现分享功能
                    HapticFeedback.lightImpact();
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'recipe_${widget.recipe.id}',
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black26],
                    ),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: widget.recipe.coverImage ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Recipe Info
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe Title
                    Text(
                      widget.recipe.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    if (widget.recipe.description.isNotEmpty)
                      Text(
                        widget.recipe.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Recipe Stats
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              Icons.access_time,
                              '${widget.recipe.totalTime.inMinutes}分钟',
                              '制作时间',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          Expanded(
                            child: _buildStatItem(
                              Icons.restaurant,
                              '${widget.recipe.servings}人份',
                              '份量',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          Expanded(
                            child: _buildStatItem(
                              Icons.bar_chart,
                              _getDifficultyText(widget.recipe.difficulty),
                              '难度',
                              color: _getDifficultyColor(widget.recipe.difficulty),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rating and Category
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.recipe.category.label,
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Icon(Icons.star, size: 20, color: Colors.amber[600]),
                            const SizedBox(width: 4),
                            Text(
                              widget.recipe.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ' (${widget.recipe.reviewCount})',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
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
          ),

          // Ingredients Section
          SliverToBoxAdapter(
            child: AnimationLimiter(
              child: Container(
                color: Colors.white,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '食材清单',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_ingredients.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              '暂无食材信息',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ingredients.length,
                        itemBuilder: (context, index) {
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: _buildIngredientItem(_ingredients[index]),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Steps Section
          SliverToBoxAdapter(
            child: AnimationLimiter(
              child: Container(
                color: Colors.white,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '制作步骤',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_steps.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.list_alt_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              '暂无制作步骤',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _steps.length,
                        itemBuilder: (context, index) {
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: _buildStepItem(_steps[index], index),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Nutrition Info
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 8, bottom: 100),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '营养信息',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildNutritionInfo(),
                ],
              ),
            ),
          ),
        ],
      ),

      // Floating Action Button
      floatingActionButton: ScaleTransition(
        scale: _heroAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            // 实现开始烹饪功能
            HapticFeedback.mediumImpact();
          },
          backgroundColor: Colors.orange[600],
          icon: const Icon(Icons.play_arrow, color: Colors.white),
          label: const Text(
            '开始烹饪',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color ?? Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientItem(RecipeIngredient ingredient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green[500],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ingredient.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (ingredient.amount != null)
            Text(
              '${ingredient.amount} ${ingredient.unit ?? ''}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepItem(RecipeStep step, int index) {
    final isActive = index == _currentStep;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Number
          GestureDetector(
            onTap: () {
              setState(() {
                _currentStep = index;
              });
              HapticFeedback.lightImpact();
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive ? Colors.orange[600] : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${step.order}',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Step Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive ? Colors.orange[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? Colors.orange[200]! : Colors.grey[200]!,
                ),
              ),
              child: Text(
                step.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionInfo() {
    final nutrition = widget.recipe.nutrition;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildNutritionItem('卡路里', '${nutrition.calories.toInt()}', 'kcal'),
          ),
          Expanded(
            child: _buildNutritionItem('蛋白质', '${nutrition.protein.toInt()}', 'g'),
          ),
          Expanded(
            child: _buildNutritionItem('碳水', '${nutrition.carbs.toInt()}', 'g'),
          ),
          Expanded(
            child: _buildNutritionItem('脂肪', '${nutrition.fat.toInt()}', 'g'),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
