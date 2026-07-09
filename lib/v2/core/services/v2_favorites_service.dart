import 'package:shared_preferences/shared_preferences.dart';

/// V2 收藏服务（轻量版）
///
/// - 收藏偏好标签：用于气泡采样时强制注入
/// - 收藏菜品：用于结果页/历史偏好
class V2FavoritesService {
  V2FavoritesService._internal();
  static final V2FavoritesService instance = V2FavoritesService._internal();

  static const _keyFavoriteTagIds = 'v2_favorite_tag_ids';
  static const _keyFavoriteRecipeIds = 'v2_favorite_recipe_ids';

  Future<Set<String>> getFavoriteTagIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyFavoriteTagIds) ?? const [];
    return list.toSet();
  }

  Future<Set<String>> getFavoriteRecipeIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyFavoriteRecipeIds) ?? const [];
    return list.toSet();
  }

  Future<Set<String>> getFavoriteDishIds() => getFavoriteRecipeIds();

  Future<bool> isTagFavorited(String tagId) async {
    final tags = await getFavoriteTagIds();
    return tags.contains(tagId);
  }

  Future<bool> isRecipeFavorited(String recipeId) async {
    final recipes = await getFavoriteRecipeIds();
    return recipes.contains(recipeId);
  }

  Future<bool> isDishFavorited(String dishId) async {
    final dishes = await getFavoriteDishIds();
    return dishes.contains(dishId);
  }

  Future<void> toggleFavoriteTag(String tagId) async {
    final prefs = await SharedPreferences.getInstance();
    final current =
        (prefs.getStringList(_keyFavoriteTagIds) ?? const []).toSet();
    if (current.contains(tagId)) {
      current.remove(tagId);
    } else {
      current.add(tagId);
    }
    await prefs.setStringList(_keyFavoriteTagIds, current.toList());
  }

  Future<void> setFavoriteTagIds(Set<String> tagIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFavoriteTagIds, tagIds.toList());
  }

  Future<void> toggleFavoriteRecipe(String recipeId) async {
    final prefs = await SharedPreferences.getInstance();
    final current =
        (prefs.getStringList(_keyFavoriteRecipeIds) ?? const []).toSet();
    if (current.contains(recipeId)) {
      current.remove(recipeId);
    } else {
      current.add(recipeId);
    }
    await prefs.setStringList(_keyFavoriteRecipeIds, current.toList());
  }

  Future<void> toggleFavoriteDish(String dishId) =>
      toggleFavoriteRecipe(dishId);

  Future<void> setFavoriteRecipeIds(Set<String> recipeIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFavoriteRecipeIds, recipeIds.toList());
  }

  Future<void> setFavoriteDishIds(Set<String> dishIds) =>
      setFavoriteRecipeIds(dishIds);
}
