import 'package:cached_network_image/cached_network_image.dart';
import 'package:eatwhat_app/core/services/unified_recipe_database_service.dart';
import 'package:eatwhat_app/v2/core/data/models/dish_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/repositories/tag_repository_v2.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_router.dart';
import 'package:eatwhat_app/v2/core/services/v2_favorites_service.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/details/recipe_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FavoritesPageV2 extends StatefulWidget {
  const FavoritesPageV2({super.key});

  @override
  State<FavoritesPageV2> createState() => _FavoritesPageV2State();
}

class _FavoritesPageV2State extends State<FavoritesPageV2>
    with SingleTickerProviderStateMixin {
  final V2FavoritesService _favorites = V2FavoritesService.instance;
  final UnifiedRecipeDatabaseService _db =
      UnifiedRecipeDatabaseService.instance;
  final TagRepositoryV2 _tagRepo = TagRepositoryV2();

  late final TabController _tabController;
  bool _loading = true;
  Set<String> _favoriteTagIds = {};
  Set<String> _favoriteDishIds = {};
  List<RecipeModel> _favoriteRecipes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _db.ensureInitialized();

    final favTags = await _favorites.getFavoriteTagIds();
    final favDishIds = await _favorites.getFavoriteDishIds();

    final rows =
        await _db.fetchRecipesByDishIds(favDishIds.toList(), limit: 200);
    final mapped = rows.map(RecipeModel.fromUnifiedDbRow).toList();

    if (!mounted) return;
    setState(() {
      _favoriteTagIds = favTags;
      _favoriteDishIds = favDishIds;
      _favoriteRecipes = mapped;
      _loading = false;
    });
  }

  Future<void> _toggleTag(String tagId) async {
    await _favorites.toggleFavoriteTag(tagId);
    await _load();
  }

  Future<void> _toggleRecipe(String recipeId) async {
    await _favorites.toggleFavoriteDish(recipeId);
    await _load();
  }

  Future<void> _openRecipeDetail(RecipeModel recipe) async {
    final routeData = AppV2RecipeDetailRouteData(recipe: recipe);
    if (GoRouter.maybeOf(context) != null) {
      await context.push(AppV2Routes.recipeDetail, extra: routeData);
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailPage(recipe: recipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('收藏'),
        backgroundColor: AppPalette.rice,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.sunsetOrange,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.sunsetOrange,
          tabs: const [
            Tab(text: '偏好'),
            Tab(text: '菜品'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFavoriteTags(),
                _buildFavoriteRecipes(),
              ],
            ),
    );
  }

  Widget _buildFavoriteTags() {
    final allTags = _tagRepo.getAllTags();
    final tags = _favoriteTagIds
        .map((id) => allTags.firstWhere(
              (t) => t.id == id,
              orElse: () => allTags.first,
            ))
        .toList();

    if (_favoriteTagIds.isEmpty) {
      return _empty(
        title: '还没有收藏偏好',
        subtitle: '在实体池选择偏好后，打开顶部托盘即可查看和保存口味组合。',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: tags.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm - 2),
      itemBuilder: (context, index) {
        final t = tags[index];
        final id = t.id;
        return Material(
          color: AppPalette.rice,
          borderRadius: AppRadii.card,
          elevation: 1,
          child: ListTile(
            title: Text(
              t.label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              id,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: IconButton(
              onPressed: () => _toggleTag(id),
              icon: Icon(
                Icons.favorite,
                color: AppColors.sunsetOrange,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoriteRecipes() {
    if (_favoriteDishIds.isEmpty) {
      return _empty(
        title: '还没有收藏菜品',
        subtitle: '在推荐结果页点“爱心”即可收藏菜品。',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _favoriteRecipes.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final r = _favoriteRecipes[index];
        return Material(
          color: AppPalette.rice,
          borderRadius: AppRadii.card,
          elevation: 1,
          child: InkWell(
            borderRadius: AppRadii.card,
            onTap: () => _openRecipeDetail(r),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: AppRadii.small,
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: r.imageUrl != null && r.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: r.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppColors.lightBackground,
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.lightBackground,
                                alignment: Alignment.center,
                                child: const Icon(Icons.restaurant),
                              ),
                            )
                          : Container(
                              color: AppColors.sunsetOrange
                                  .withValues(alpha: 0.08),
                              alignment: Alignment.center,
                              child: const Icon(Icons.restaurant),
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          r.description.isNotEmpty
                              ? r.description
                              : r.tags.take(3).join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () => _toggleRecipe(r.dishId),
                    icon: Icon(
                      Icons.favorite,
                      color: AppColors.sunsetOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _empty({required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
