import 'package:flutter/material.dart';
import '../../../core/models/recipe.dart';
import '../../../core/services/recipe_database_service.dart';
import '../widgets/recipe_card.dart';

class RecipeDemoScreen extends StatefulWidget {
  const RecipeDemoScreen({super.key});

  @override
  State<RecipeDemoScreen> createState() => _RecipeDemoScreenState();
}

class _RecipeDemoScreenState extends State<RecipeDemoScreen> {
  final RecipeDatabaseService _recipeService = RecipeDatabaseService();
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _recipeService.initialize();
      _recipes = await _recipeService.getRecommendedRecipes();
    } catch (e) {
      debugPrint('加载菜谱失败: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('菜谱推荐演示'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
              ? const Center(child: Text('暂无菜谱数据'))
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            color: Colors.orange.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '为您推荐 ${_recipes.length} 道美味菜谱',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = _recipes[index];
                          return RecipeCard(
                            recipe: recipe,
                            onTap: () {
                              _showRecipeDetails(recipe);
                            },
                            onFavoriteToggle: (isFavorite) {
                              _handleFavoriteToggle(recipe, isFavorite);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showRecipeDetails(Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                recipe.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // 基本信息
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text('${recipe.rating}'),
                            const SizedBox(width: 16),
                            Icon(Icons.access_time, color: Colors.grey, size: 16),
                            const SizedBox(width: 4),
                            Text('${recipe.totalTime}分钟'),
                            const SizedBox(width: 16),
                            Icon(Icons.people, color: Colors.grey, size: 16),
                            const SizedBox(width: 4),
                            Text('${recipe.servings}人份'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 描述
                        Text(
                          recipe.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 食材
                        const Text(
                          '食材',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...recipe.ingredients
                            .map((ingredient) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        ingredient.isMain ? Icons.star : Icons.fiber_manual_record,
                                        size: 16,
                                        color: ingredient.isMain ? Colors.orange : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        ingredient.name,
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${ingredient.amount} ${ingredient.unit}',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                        const SizedBox(height: 24),

                        // 制作步骤
                        const Text(
                          '制作步骤',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...recipe.steps
                            .map((step) => Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade600,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${step.stepNumber}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              step.description,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                height: 1.5,
                                              ),
                                            ),
                                            if (step.tip != null) ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.lightbulb_outline,
                                                      size: 16,
                                                      color: Colors.blue.shade600,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        step.tip!,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.blue.shade600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),

                        // 营养信息
                        const SizedBox(height: 24),
                        const Text(
                          '营养信息',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  _buildNutritionItem(
                                      '卡路里', '${recipe.nutrition.calories.toInt()}kcal'),
                                  const SizedBox(width: 16),
                                  _buildNutritionItem(
                                      '蛋白质', '${recipe.nutrition.protein.toStringAsFixed(1)}g'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildNutritionItem(
                                      '碳水', '${recipe.nutrition.carbs.toStringAsFixed(1)}g'),
                                  const SizedBox(width: 16),
                                  _buildNutritionItem(
                                      '脂肪', '${recipe.nutrition.fat.toStringAsFixed(1)}g'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _handleFavoriteToggle(Recipe recipe, bool isFavorite) {
    setState(() {
      final index = _recipes.indexWhere((r) => r.id == recipe.id);
      if (index != -1) {
        _recipes[index] = _recipes[index].copyWith(isFavorite: isFavorite);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite ? '已添加到收藏' : '已取消收藏'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
