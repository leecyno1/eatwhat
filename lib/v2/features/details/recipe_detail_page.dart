import 'package:eatwhat_app/v2/core/data/models/howtocook_recipe_detail.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_router.dart';
import 'package:eatwhat_app/v2/core/services/generation_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recipe_execution_progress_service.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/features/details/howtocook_library_page.dart';
import 'package:eatwhat_app/v2/features/details/widgets/recipe_ai_result_views.dart';
import 'package:eatwhat_app/v2/features/details/widgets/recipe_detail_controls.dart';
import 'package:eatwhat_app/v2/features/details/widgets/recipe_detail_media.dart';
import 'package:eatwhat_app/v2/features/details/widgets/recipe_detail_sections.dart';
import 'package:eatwhat_app/v2/features/execution/execution_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class RecipeDetailPage extends StatefulWidget {
  const RecipeDetailPage({
    super.key,
    required this.recipe,
    this.howToCookRecipeService,
    this.startInCookingMode = false,
  });

  final RecipeModel recipe;
  final V2HowToCookRecipeService? howToCookRecipeService;
  final bool startInCookingMode;

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final GenerationService _generation = GenerationService.instance;
  final V2RecipeExecutionProgressService _progressService =
      V2RecipeExecutionProgressService.instance;
  final V2PreferenceFeedbackService _feedbackService =
      V2PreferenceFeedbackService.instance;
  late RecipeModel _recipe;
  late final V2HowToCookRecipeService _howToCookRecipeService;
  bool _loadingHowToCookDetail = false;
  List<HowToCookRecipeDetail> _relatedRecipes = const [];
  List<String> _baseIngredients = const [];
  int _baseServings = 2;
  int _selectedServings = 2;
  Set<int> _completedStepIndexes = const {};
  Set<int> _completedShoppingIndexes = const {};
  late bool _cookingMode;

  @override
  void initState() {
    super.initState();
    _howToCookRecipeService =
        widget.howToCookRecipeService ?? V2HowToCookRecipeService.instance;
    _recipe = widget.recipe;
    _cookingMode = widget.startInCookingMode;
    _bootstrapHowToCookDetail();
  }

  Future<void> _bootstrapHowToCookDetail() async {
    setState(() => _loadingHowToCookDetail = true);
    final hasUnifiedRecipeBody = _isHowToCookRecipe(_recipe) &&
        _recipe.ingredients.isNotEmpty &&
        _recipe.steps.isNotEmpty;
    final detail = hasUnifiedRecipeBody
        ? null
        : await _howToCookRecipeService.findBestDetailForRecipe(_recipe);
    final enriched = hasUnifiedRecipeBody
        ? _recipe.copyWith(source: 'HowToCook')
        : detail == null
            ? await _howToCookRecipeService.enrichRecipe(_recipe)
            : _recipe.copyWith(
                description: detail.description.trim().isNotEmpty
                    ? detail.description.trim()
                    : _recipe.description,
                ingredients: detail.ingredients.isNotEmpty
                    ? detail.ingredients
                    : _recipe.ingredients,
                steps: detail.steps.isNotEmpty ? detail.steps : _recipe.steps,
                tags: {
                  ..._recipe.tags,
                  if (detail.category.trim().isNotEmpty) detail.category.trim(),
                  if (detail.subcategory.trim().isNotEmpty)
                    detail.subcategory.trim(),
                }.toList(),
                imageUrl: (_recipe.imageUrl?.trim().isNotEmpty ?? false)
                    ? _recipe.imageUrl
                    : (detail.imageAssetUrls.isNotEmpty
                        ? detail.imageAssetUrls.first
                        : _recipe.imageUrl),
                source: 'HowToCook',
              );
    final completedStepIndexes =
        await _progressService.getCompletedStepIndexes(enriched.id);
    final completedShoppingIndexes =
        await _progressService.getCompletedShoppingIndexes(enriched.id);
    if (!mounted) return;
    setState(() {
      _recipe = enriched;
      _baseIngredients = List<String>.from(enriched.ingredients);
      _baseServings = detail?.servings ?? _baseServings;
      _selectedServings = detail?.servings ?? _selectedServings;
      _completedStepIndexes =
          _clampedCompletedStepIndexes(completedStepIndexes, enriched.steps);
      _completedShoppingIndexes = _clampedShoppingIndexes(
          completedShoppingIndexes, enriched.ingredients);
      _loadingHowToCookDetail = false;
    });
    final related = await _howToCookRecipeService.getRelatedRecipes(enriched);
    if (!mounted) return;
    setState(() {
      _relatedRecipes = related;
    });
  }

  bool _isHowToCookRecipe(RecipeModel recipe) {
    final source = recipe.source.trim().toLowerCase();
    return source == 'howtocook' || source == 'unified_db';
  }

  Future<void> _openHowToCookLibrary() async {
    final routeData = AppV2HowToCookLibraryRouteData(
      service: _howToCookRecipeService,
    );
    if (GoRouter.maybeOf(context) != null) {
      await context.push(AppV2Routes.howtocookLibrary, extra: routeData);
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HowToCookLibraryPage(
          service: _howToCookRecipeService,
        ),
      ),
    );
  }

  Future<void> _openRelatedRecipe(HowToCookRecipeDetail item) async {
    final preview = item.toRecipeModel(
      fallbackId: item.id,
      fallbackSource: 'HowToCook',
    );
    final routeData = AppV2RecipeDetailRouteData(
      recipe: preview,
      howToCookRecipeService: _howToCookRecipeService,
    );
    if (GoRouter.maybeOf(context) != null) {
      await context.push(AppV2Routes.recipeDetail, extra: routeData);
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeDetailPage(
          recipe: preview,
          howToCookRecipeService: _howToCookRecipeService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      bottomNavigationBar: _buildBottomBar(context),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RecipeHeaderSection(
                    recipe: _recipe,
                    loadingDetail: _loadingHowToCookDetail,
                  ),
                  const SizedBox(height: 16),
                  RecipeCookBriefSection(
                    recipe: _recipe,
                    completedStepIndexes: _completedStepIndexes,
                    onStartCooking: () {
                      setState(() => _cookingMode = true);
                    },
                    onOpenShoppingList: _showShoppingList,
                  ),
                  if (_cookingMode) ...[
                    const SizedBox(height: 16),
                    _buildCookingModePanel(),
                  ],
                  const SizedBox(height: 24),
                  RecipeIngredientsSection(
                    ingredients: _scaledIngredients(),
                    servings: _selectedServings,
                    substitutionSuggestions: _buildSubstitutionSuggestions(),
                    onDecreaseServings: _selectedServings > 1
                        ? () {
                            setState(() => _selectedServings -= 1);
                          }
                        : null,
                    onIncreaseServings: () {
                      setState(() => _selectedServings += 1);
                    },
                    onOpenShoppingList: _showShoppingList,
                  ),
                  const SizedBox(height: 24),
                  RecipeStepsSection(
                    steps: _recipe.steps,
                    completedStepIndexes: _completedStepIndexes,
                    onToggleStep: _toggleStepCompletion,
                  ),
                  const SizedBox(height: 24),
                  RelatedRecipesSection(
                    relatedRecipes: _relatedRecipes,
                    onOpenLibrary: _openHowToCookLibrary,
                    onOpenRecipe: _openRelatedRecipe,
                  ),
                  const SizedBox(height: 24),
                  _buildAiToolkit(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_cookingMode)
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('recipe-cooking-complete-button'),
                  onPressed: _recordCookingCompleted,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('完成这次做菜'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sunsetOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              )
            else ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ExecutionSheet.show(
                    context,
                    dishName: _recipe.name,
                  ),
                  icon: const Icon(Icons.alt_route_rounded),
                  label: const Text('更多方式'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.sunsetOrange,
                    side: BorderSide(
                      color: AppColors.sunsetOrange.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('recipe-start-cooking-button'),
                  onPressed: () => setState(() => _cookingMode = true),
                  icon: const Icon(Icons.soup_kitchen_rounded),
                  label: const Text('开始做菜'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sunsetOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _recordCookingCompleted() async {
    final positiveTags = <String>{
      ..._recipe.tags.take(3),
      if (_recipe.source.trim().isNotEmpty) _recipe.source.trim(),
    }.where((tag) => tag.trim().isNotEmpty).toList();
    await _feedbackService.recordExecutionCompleted(
      recipeId: _recipe.id,
      path: ExecutionPath.cook,
      positiveTagIds: positiveTags,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已记住这次自制完成'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildCookingModePanel() {
    final completedCount =
        _recipe.steps.asMap().keys.where(_completedStepIndexes.contains).length;
    return Container(
      key: const ValueKey('recipe-cooking-mode-panel'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sunsetOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.sunsetOrange.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.sunsetOrange.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.soup_kitchen_rounded,
              color: AppColors.sunsetOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '做菜模式',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '先备料，再按步骤勾选；遇到等待时间可以直接点计时。',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.92),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '当前进度：完成 $completedCount/${_recipe.steps.length}',
                  style: const TextStyle(
                    color: AppColors.sunsetOrange,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08);
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.sunsetOrange,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'recipe_image_${_recipe.id}',
              child: RecipeHeroImage(imageUrl: _recipe.imageUrl),
            ),
            // Gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _scaledIngredients() {
    final source =
        _baseIngredients.isNotEmpty ? _baseIngredients : _recipe.ingredients;
    if (source.isEmpty ||
        _baseServings <= 0 ||
        _selectedServings == _baseServings) {
      return source;
    }
    final ratio = _selectedServings / _baseServings;
    return source
        .map((ingredient) => _scaleIngredientLine(ingredient, ratio))
        .toList();
  }

  void _toggleStepCompletion(int index) {
    late final Set<int> next;
    setState(() {
      next = Set<int>.from(_completedStepIndexes);
      if (!next.add(index)) {
        next.remove(index);
      }
      _completedStepIndexes = next;
    });
    _progressService.saveCompletedStepIndexes(_recipe.id, next);
  }

  Set<int> _clampedCompletedStepIndexes(
    Set<int> indexes,
    List<String> steps,
  ) {
    return indexes.where((index) => index >= 0 && index < steps.length).toSet();
  }

  Future<void> _showShoppingList() async {
    final ingredients = _scaledIngredients();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return RecipeShoppingListSheet(
          ingredients: ingredients,
          completedIndexes: _clampedShoppingIndexes(
            _completedShoppingIndexes,
            ingredients,
          ),
          onToggleItem: _toggleShoppingItem,
          onCopy: () {
            Clipboard.setData(
              ClipboardData(text: ingredients.join('\n')),
            );
            ScaffoldMessenger.of(this.context).showSnackBar(
              const SnackBar(
                content: Text('购物清单已复制'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );
  }

  void _toggleShoppingItem(int index) {
    late final Set<int> next;
    setState(() {
      next = Set<int>.from(_completedShoppingIndexes);
      if (!next.add(index)) {
        next.remove(index);
      }
      _completedShoppingIndexes = next;
    });
    _progressService.saveCompletedShoppingIndexes(_recipe.id, next);
  }

  Set<int> _clampedShoppingIndexes(
    Set<int> indexes,
    List<String> ingredients,
  ) {
    return indexes
        .where((index) => index >= 0 && index < ingredients.length)
        .toSet();
  }

  String _scaleIngredientLine(String line, double ratio) {
    final trimmed = line.trim();
    final match =
        RegExp(r'^(.*?)[ ]+(\d+(?:\.\d+)?)([^\d\s].*)$').firstMatch(trimmed);
    if (match == null) return trimmed;
    final name = match.group(1)?.trim() ?? trimmed;
    final amountText = match.group(2) ?? '';
    final unit = match.group(3)?.trim() ?? '';
    final amount = double.tryParse(amountText);
    if (amount == null) return trimmed;
    final scaled = amount * ratio;
    final scaledText =
        scaled % 1 == 0 ? scaled.toStringAsFixed(0) : scaled.toStringAsFixed(1);
    return '$name $scaledText$unit';
  }

  List<String> _buildSubstitutionSuggestions() {
    final source =
        _baseIngredients.isNotEmpty ? _baseIngredients : _recipe.ingredients;
    const substitutionMap = <String, String>{
      '鸡腿': '鸡腿可换成鸡翅根，口感更嫩，时间保持不变。',
      '香菇': '香菇可换成杏鲍菇，整体会更弹一点。',
      '肥牛': '肥牛可换成牛腩片，锅味会更厚。',
      '番茄': '番茄不够熟时可补少量番茄膏稳住酸甜。',
      '土豆': '土豆可换成山药，口感会更绵。',
    };
    final suggestions = <String>[];
    for (final item in source) {
      for (final entry in substitutionMap.entries) {
        if (item.contains(entry.key)) {
          suggestions.add(entry.value);
        }
      }
    }
    return suggestions.toSet().take(3).toList();
  }

  Widget _buildAiToolkit(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '做菜加成',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            AiActionChip(
              icon: Icons.monitor_heart,
              label: '营养分析',
              onTap: () => _showNutritionSheet(context),
            ),
            AiActionChip(
              icon: Icons.local_bar,
              label: '饮品搭配',
              onTap: () => _showWineSheet(context),
            ),
            AiActionChip(
              icon: Icons.auto_fix_high,
              label: '趣味占卜',
              onTap: () => _showFortuneSheet(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '提示：主菜谱来自 HowToCook，下面只提供做菜时的辅助参考。',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }

  Future<void> _showNutritionSheet(BuildContext context) async {
    await _showAiResultSheet(
      context,
      title: '营养分析',
      future: _generation.getNutritionAnalysis(_recipe),
      builder: (data) => NutritionView(data: data),
    );
  }

  Future<void> _showWineSheet(BuildContext context) async {
    await _showAiResultSheet(
      context,
      title: '饮品搭配',
      future: _generation.getWinePairing(_recipe),
      builder: (data) => WinePairingView(data: data),
    );
  }

  Future<void> _showFortuneSheet(BuildContext context) async {
    await _showAiResultSheet(
      context,
      title: '趣味占卜',
      future: _generation.getFortune(recipe: _recipe),
      builder: (data) => FortuneView(data: data),
    );
  }

  Future<void> _showAiResultSheet<T>(
    BuildContext context, {
    required String title,
    required Future<T> future,
    required Widget Function(T data) builder,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final height = MediaQuery.of(context).size.height * 0.72;
        return Container(
          height: height,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<T>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            '生成失败：${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      );
                    }
                    final data = snapshot.data;
                    if (data == null) {
                      return const Center(
                        child: Text(
                          '暂无结果',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: builder(data),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
