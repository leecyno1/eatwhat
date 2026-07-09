import 'package:eatwhat_app/v2/core/data/models/howtocook_recipe_detail.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_router.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/features/details/recipe_detail_page.dart';
import 'package:eatwhat_app/v2/features/home/widgets/floating_editorial_background.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HowToCookLibraryPage extends StatefulWidget {
  const HowToCookLibraryPage({
    super.key,
    this.service,
    this.initialCategory = '',
    this.initialQuery = '',
  });

  final V2HowToCookRecipeService? service;
  final String initialCategory;
  final String initialQuery;

  @override
  State<HowToCookLibraryPage> createState() => _HowToCookLibraryPageState();
}

class _HowToCookLibraryPageState extends State<HowToCookLibraryPage> {
  late final V2HowToCookRecipeService _service;
  final TextEditingController _controller = TextEditingController();
  late Future<List<HowToCookRecipeDetail>> _future;
  late Future<List<String>> _categoriesFuture;
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? V2HowToCookRecipeService.instance;
    _selectedCategory = widget.initialCategory.trim();
    _controller.text = widget.initialQuery.trim();
    _future = _service.getLibraryRecipes(
      query: _controller.text.trim(),
      category: _selectedCategory,
      limit: 80,
    );
    _categoriesFuture = _service.getLibraryCategories();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    setState(() {
      _future = _service.getLibraryRecipes(
        query: _controller.text.trim(),
        category: _selectedCategory,
        limit: 80,
      );
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = _selectedCategory == category ? '' : category;
      _future = _service.getLibraryRecipes(
        query: _controller.text.trim(),
        category: _selectedCategory,
        limit: 80,
      );
    });
  }

  Future<void> _openRecipeDetail(HowToCookRecipeDetail recipe) async {
    final preview = recipe.toRecipeModel(
      fallbackId: recipe.id,
      fallbackSource: 'HowToCook',
    );
    final routeData = AppV2RecipeDetailRouteData(
      recipe: preview,
      howToCookRecipeService: _service,
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
          howToCookRecipeService: _service,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Stack(
        children: [
          const FloatingEditorialBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          '家常菜谱',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: '搜索菜名、菜系或做法关键词',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.86),
                      suffixIcon: IconButton(
                        onPressed: _search,
                        icon: const Icon(Icons.search_rounded),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<String>>(
                    future: _categoriesFuture,
                    builder: (context, snapshot) {
                      final categories = snapshot.data ?? const <String>[];
                      if (categories.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final category in categories) ...[
                                _FilterChip(
                                  label: category,
                                  selected: _selectedCategory == category,
                                  onTap: () => _selectCategory(category),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: FutureBuilder<List<HowToCookRecipeDetail>>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final recipes = snapshot.data!;
                        if (recipes.isEmpty) {
                          return const Center(
                            child: Text(
                              '当前没有匹配到合适菜谱',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: recipes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final recipe = recipes[index];
                            return InkWell(
                              onTap: () => _openRecipeDetail(recipe),
                              borderRadius: BorderRadius.circular(24),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.76),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.82),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: _RecipeThumb(
                                        imageUrl:
                                            recipe.imageAssetUrls.isNotEmpty
                                                ? recipe.imageAssetUrls.first
                                                : null,
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          0,
                                          14,
                                          14,
                                          14,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    recipe.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                if (recipe
                                                    .imageAssetUrls.isNotEmpty)
                                                  const _MetaChip(
                                                    label: '实拍图',
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              recipe.description.trim().isEmpty
                                                  ? '适合在家做，点开查看食材和步骤。'
                                                  : recipe.description,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textSecondary,
                                                height: 1.45,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                if (recipe.category
                                                    .trim()
                                                    .isNotEmpty)
                                                  _MetaChip(
                                                      label: recipe.category),
                                                if (recipe.cookingTimeMinutes !=
                                                    null)
                                                  _MetaChip(
                                                    label:
                                                        '${recipe.cookingTimeMinutes} 分钟',
                                                  ),
                                                if (recipe.servings != null)
                                                  _MetaChip(
                                                    label:
                                                        '${recipe.servings} 人份',
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
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeThumb extends StatelessWidget {
  const _RecipeThumb({
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 86,
        height: 86,
        child: url.startsWith('assets/')
            ? Image.asset(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _ThumbPlaceholder(),
              )
            : const _ThumbPlaceholder(),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.sunsetOrange.withValues(alpha: 0.3),
            AppColors.freshLime.withValues(alpha: 0.18),
          ],
        ),
      ),
      child: const Icon(
        Icons.restaurant_menu_rounded,
        color: Colors.white,
        size: 34,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.sunsetOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.sunsetOrange,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.sunsetOrange
              : Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.sunsetOrange
                : Colors.white.withValues(alpha: 0.9),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
