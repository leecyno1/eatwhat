import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../core/services/howtocook_database_service.dart';

// HowToCook菜谱数据模型
class HowToCookRecipe {
  final String id;
  final String name;
  final String description;
  final int difficulty; // 1-5星级
  final String category;
  final String subcategory;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final List<String> notes;
  final List<String> tools;
  final int? cookingTime;
  final int servings;
  final String githubUrl;
  final String markdownContent;
  final DateTime createdAt;
  final DateTime updatedAt;

  HowToCookRecipe({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.category,
    this.subcategory = '',
    required this.ingredients,
    required this.steps,
    required this.notes,
    required this.tools,
    this.cookingTime,
    required this.servings,
    required this.githubUrl,
    required this.markdownContent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HowToCookRecipe.fromJson(Map<String, dynamic> json) {
    return HowToCookRecipe(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? 3,
      category: json['category'],
      subcategory: json['subcategory'] ?? '',
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((e) => RecipeIngredient.fromJson(e))
          .toList(),
      steps: (json['steps'] as List<dynamic>? ?? []).map((e) => RecipeStep.fromJson(e)).toList(),
      notes: List<String>.from(json['notes'] ?? []),
      tools: List<String>.from(json['tools'] ?? []),
      cookingTime: json['cooking_time'],
      servings: json['servings'] ?? 2,
      githubUrl: json['github_url'] ?? '',
      markdownContent: json['markdown_content'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class RecipeIngredient {
  final String name;
  final String amount;
  final String unit;
  final bool isMain;
  final int orderIndex;

  RecipeIngredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.isMain = true,
    this.orderIndex = 0,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'],
      amount: json['amount'] ?? '',
      unit: json['unit'] ?? '',
      isMain: json['is_main'] ?? true,
      orderIndex: json['order_index'] ?? 0,
    );
  }
}

class RecipeStep {
  final int stepNumber;
  final String description;
  final String? imageUrl;
  final String? notes;

  RecipeStep({
    required this.stepNumber,
    required this.description,
    this.imageUrl,
    this.notes,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      stepNumber: json['step_number'],
      description: json['description'],
      imageUrl: json['image_url'],
      notes: json['notes'],
    );
  }
}

// HowToCook控制器
class HowToCookController extends ChangeNotifier {
  final HowToCookDatabaseService _databaseService = HowToCookDatabaseService();

  List<HowToCookRecipe> _recipes = [];
  List<String> _categories = ['all'];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  int _selectedDifficulty = 0; // 0表示全部

  List<HowToCookRecipe> get recipes => _recipes;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  int get selectedDifficulty => _selectedDifficulty;

  // 加载菜谱数据
  Future<void> loadRecipes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 获取所有分类
      final categoriesFromDb = await _databaseService.getAllCategories();
      _categories = ['all', ...categoriesFromDb];

      // 根据当前过滤条件获取菜谱
      await _loadFilteredRecipes();
    } catch (e) {
      _error = '加载菜谱失败: $e';
      print('加载菜谱错误: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFilteredRecipes() async {
    try {
      // 使用数据库服务的高级搜索功能
      final recipesData = await _databaseService.searchRecipesAdvanced(
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        difficulty: _selectedDifficulty == 0 ? null : _selectedDifficulty,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

      // 转换数据库结果为HowToCookRecipe对象
      _recipes = [];
      for (final recipeData in recipesData) {
        // 获取完整的菜谱信息（包括食材和步骤）
        final completeRecipe = await _databaseService.getCompleteRecipe(recipeData['id']);
        if (completeRecipe != null) {
          _recipes.add(_mapToHowToCookRecipe(completeRecipe));
        }
      }
    } catch (e) {
      print('加载过滤菜谱错误: $e');
      throw e;
    }
  }

  HowToCookRecipe _mapToHowToCookRecipe(Map<String, dynamic> data) {
    // 转换食材数据
    List<RecipeIngredient> ingredients = [];
    if (data['ingredients'] != null) {
      ingredients = (data['ingredients'] as List).map((ingredientData) {
        return RecipeIngredient(
          name: ingredientData['name'] ?? '',
          amount: ingredientData['amount'] ?? '',
          unit: ingredientData['unit'] ?? '',
          isMain: (ingredientData['is_main'] ?? 1) == 1,
          orderIndex: ingredientData['order_index'] ?? 0,
        );
      }).toList();
    }

    // 转换制作步骤数据
    List<RecipeStep> steps = [];
    if (data['steps'] != null) {
      steps = (data['steps'] as List).map((stepData) {
        return RecipeStep(
          stepNumber: stepData['step_number'] ?? 1,
          description: stepData['description'] ?? '',
          imageUrl: stepData['image_url'],
          notes: stepData['notes'],
        );
      }).toList();
    }

    // 从描述中提取小贴士
    List<String> notes = [];
    String markdownContent = data['markdown_content'] ?? '';
    if (markdownContent.isNotEmpty) {
      notes = _extractNotesFromMarkdown(markdownContent);
    }

    // 从描述中提取工具
    List<String> tools = [];
    if (markdownContent.isNotEmpty) {
      tools = _extractToolsFromMarkdown(markdownContent);
    }

    return HowToCookRecipe(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      difficulty: data['difficulty'] ?? 3,
      category: data['category'] ?? '',
      subcategory: data['subcategory'] ?? '',
      ingredients: ingredients,
      steps: steps,
      notes: notes,
      tools: tools,
      cookingTime: data['cooking_time'],
      servings: data['servings'] ?? 2,
      githubUrl: data['github_url'] ?? '',
      markdownContent: markdownContent,
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  List<String> _extractNotesFromMarkdown(String markdown) {
    List<String> notes = [];
    final lines = markdown.split('\n');
    bool inNotesSection = false;

    for (final line in lines) {
      if (line.contains('## 附加内容') || line.contains('## 小贴士')) {
        inNotesSection = true;
        continue;
      }
      if (line.startsWith('## ') && inNotesSection) {
        break;
      }
      if (inNotesSection && line.trim().startsWith('- ')) {
        notes.add(line.trim().substring(2));
      }
    }

    return notes;
  }

  List<String> _extractToolsFromMarkdown(String markdown) {
    List<String> tools = [];
    final commonTools = ['锅', '刀', '勺', '铲', '碗', '盘', '筷子', '砧板', '蒸锅', '炒锅', '擀面杖'];

    for (final tool in commonTools) {
      if (markdown.contains(tool)) {
        tools.add(tool);
      }
    }

    return tools.toSet().toList(); // 去重
  }

  Future<void> setSelectedCategory(String category) async {
    if (_selectedCategory == category) return;

    _selectedCategory = category;
    _isLoading = true;
    notifyListeners();

    try {
      await _loadFilteredRecipes();
    } catch (e) {
      _error = '筛选菜谱失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSearchQuery(String query) async {
    if (_searchQuery == query) return;

    _searchQuery = query;
    _isLoading = true;
    notifyListeners();

    try {
      await _loadFilteredRecipes();
    } catch (e) {
      _error = '搜索菜谱失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSelectedDifficulty(int difficulty) async {
    if (_selectedDifficulty == difficulty) return;

    _selectedDifficulty = difficulty;
    _isLoading = true;
    notifyListeners();

    try {
      await _loadFilteredRecipes();
    } catch (e) {
      _error = '筛选菜谱失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _databaseService.close();
    super.dispose();
  }
}

// 主要的HowToCook菜谱展示页面
class HowToCookRecipeScreen extends StatefulWidget {
  const HowToCookRecipeScreen({super.key});

  @override
  State<HowToCookRecipeScreen> createState() => _HowToCookRecipeScreenState();
}

class _HowToCookRecipeScreenState extends State<HowToCookRecipeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HowToCookController>().loadRecipes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 现代化的SliverAppBar
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'HowToCook 菜谱',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(offset: Offset(0, 1), blurRadius: 3, color: Colors.black26)],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667eea),
                      Color(0xFF764ba2),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // 装饰性图案
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    // 中心图标
                    const Center(
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 60,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 搜索和过滤器区域
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 搜索框
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        context.read<HowToCookController>().setSearchQuery(value);
                      },
                      decoration: InputDecoration(
                        hintText: '搜索菜谱...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey[500]),
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<HowToCookController>().setSearchQuery('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 过滤器行
                  Consumer<HowToCookController>(
                    builder: (context, controller, child) {
                      return Row(
                        children: [
                          // 分类过滤
                          Expanded(
                            child: _buildCategoryFilter(controller),
                          ),
                          const SizedBox(width: 12),
                          // 难度过滤
                          Expanded(
                            child: _buildDifficultyFilter(controller),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 菜谱列表
          Consumer<HowToCookController>(
            builder: (context, controller, child) {
              if (controller.isLoading) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                        ),
                        SizedBox(height: 16),
                        Text('正在加载菜谱...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              if (controller.error != null) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          controller.error!,
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => controller.loadRecipes(),
                          child: const Text('重新加载'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (controller.recipes.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('没有找到符合条件的菜谱', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final recipe = controller.recipes[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildRecipeCard(recipe),
                      );
                    },
                    childCount: controller.recipes.length,
                  ),
                ),
              );
            },
          ),

          // 底部间距
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(HowToCookController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedCategory,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          onChanged: (value) {
            if (value != null) {
              controller.setSelectedCategory(value);
            }
          },
          items: controller.categories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                category == 'all' ? '全部分类' : category,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDifficultyFilter(HowToCookController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: controller.selectedDifficulty,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          onChanged: (value) {
            if (value != null) {
              controller.setSelectedDifficulty(value);
            }
          },
          items: [
            const DropdownMenuItem<int>(
              value: 0,
              child: Text('全部难度', style: TextStyle(fontSize: 14)),
            ),
            ...List.generate(5, (index) {
              final difficulty = index + 1;
              return DropdownMenuItem<int>(
                value: difficulty,
                child: Row(
                  children: [
                    Text('$difficulty星', style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    ...List.generate(
                        difficulty, (i) => const Icon(Icons.star, size: 12, color: Colors.amber)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(HowToCookRecipe recipe) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HowToCookRecipeDetailScreen(recipe: recipe),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部信息
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recipe.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(recipe.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getCategoryColor(recipe.category).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      recipe.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getCategoryColor(recipe.category),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 标签行
              Row(
                children: [
                  // 难度星级
                  Row(
                    children: [
                      Icon(Icons.whatshot, size: 16, color: Colors.orange[600]),
                      const SizedBox(width: 4),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 14,
                            color: index < recipe.difficulty ? Colors.amber : Colors.grey[300],
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // 制作时间
                  if (recipe.cookingTime != null) ...[
                    Icon(Icons.access_time, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.cookingTime}分钟',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  // 份数
                  Icon(Icons.people, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.servings}人份',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),

                  const Spacer(),

                  // 食材数量
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${recipe.ingredients.length}种食材',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 主要食材预览
              if (recipe.ingredients.isNotEmpty) ...[
                Text(
                  '主要食材：${recipe.ingredients.take(3).map((i) => i.name).join('、')}${recipe.ingredients.length > 3 ? ' 等' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '荤菜':
        return Colors.red;
      case '素菜':
        return Colors.green;
      case '主食':
        return Colors.orange;
      case '早餐':
        return Colors.blue;
      case '汤羹':
        return Colors.cyan;
      case '甜品':
        return Colors.pink;
      case '饮品':
        return Colors.purple;
      case '调料':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}

// 菜谱详情页面
class HowToCookRecipeDetailScreen extends StatefulWidget {
  final HowToCookRecipe recipe;

  const HowToCookRecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<HowToCookRecipeDetailScreen> createState() => _HowToCookRecipeDetailScreenState();
}

class _HowToCookRecipeDetailScreenState extends State<HowToCookRecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 详情页顶部
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: _getCategoryColor(widget.recipe.category),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  // 分享功能
                },
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {
                  // 收藏功能
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.recipe.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(offset: Offset(0, 1), blurRadius: 3, color: Colors.black26)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _getCategoryColor(widget.recipe.category),
                      _getCategoryColor(widget.recipe.category).withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // 装饰图案
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: Transform.rotate(
                          angle: math.pi / 6,
                          child: const Icon(
                            Icons.restaurant_menu,
                            size: 120,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // 基本信息overlay
                    Positioned(
                      bottom: 80,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoItem(
                              Icons.whatshot,
                              '难度',
                              '${List.generate(widget.recipe.difficulty, (i) => '★').join()}',
                            ),
                            if (widget.recipe.cookingTime != null)
                              _buildInfoItem(
                                Icons.access_time,
                                '时间',
                                '${widget.recipe.cookingTime}分钟',
                              ),
                            _buildInfoItem(
                              Icons.people,
                              '份数',
                              '${widget.recipe.servings}人份',
                            ),
                            _buildInfoItem(
                              Icons.list_alt,
                              '步骤',
                              '${widget.recipe.steps.length}步',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab栏
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '食材'),
                  Tab(text: '制作步骤'),
                  Tab(text: '小贴士'),
                ],
                labelColor: _getCategoryColor(widget.recipe.category),
                unselectedLabelColor: Colors.grey,
                indicatorColor: _getCategoryColor(widget.recipe.category),
                indicatorWeight: 3,
              ),
            ),
          ),

          // Tab内容
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIngredientsTab(),
                _buildStepsTab(),
                _buildNotesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '食材清单 (${widget.recipe.ingredients.length}种)',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.recipe.ingredients.map((ingredient) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
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
                    color: _getCategoryColor(widget.recipe.category),
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
                Text(
                  '${ingredient.amount} ${ingredient.unit}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        if (widget.recipe.tools.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            '所需工具',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.recipe.tools.map((tool) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCategoryColor(widget.recipe.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getCategoryColor(widget.recipe.category).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.kitchen,
                      size: 14,
                      color: _getCategoryColor(widget.recipe.category),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tool,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getCategoryColor(widget.recipe.category),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildStepsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '制作步骤 (${widget.recipe.steps.length}步)',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.recipe.steps.map((step) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(widget.recipe.category),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${step.stepNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      step.description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
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

  Widget _buildNotesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.recipe.notes.isNotEmpty) ...[
          Text(
            '制作小贴士',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.recipe.notes.map((note) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber[800],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
        ],

        // 菜谱信息
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '菜谱信息',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow('分类', widget.recipe.category),
              _buildInfoRow('难度', '${widget.recipe.difficulty} 星级'),
              if (widget.recipe.cookingTime != null)
                _buildInfoRow('制作时间', '${widget.recipe.cookingTime} 分钟'),
              _buildInfoRow('建议份数', '${widget.recipe.servings} 人份'),
              _buildInfoRow('食材种类', '${widget.recipe.ingredients.length} 种'),
              _buildInfoRow('制作步骤', '${widget.recipe.steps.length} 步'),
              if (widget.recipe.githubUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.link, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    const Text(
                      '来源：',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'HowToCook GitHub',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label：',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '荤菜':
        return Colors.red;
      case '素菜':
        return Colors.green;
      case '主食':
        return Colors.orange;
      case '早餐':
        return Colors.blue;
      case '汤羹':
        return Colors.cyan;
      case '甜品':
        return Colors.pink;
      case '饮品':
        return Colors.purple;
      case '调料':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}

// Tab栏委托
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
