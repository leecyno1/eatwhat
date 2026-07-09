import 'dart:convert';

import 'package:eatwhat_app/core/services/howtocook_database_service.dart';
import 'package:eatwhat_app/v2/core/data/models/howtocook_recipe_detail.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:flutter/services.dart';

typedef HowToCookSearchLoader = Future<List<Map<String, dynamic>>> Function(
  String query,
  int limit,
);
typedef HowToCookCompleteLoader = Future<Map<String, dynamic>?> Function(
  String recipeId,
);
typedef HowToCookAllRecipesLoader = Future<List<Map<String, dynamic>>> Function(
  int limit,
);

class V2HowToCookRecipeService {
  V2HowToCookRecipeService({
    HowToCookDatabaseService? databaseService,
    Future<String> Function()? assetIndexLoader,
    HowToCookSearchLoader? searchLoader,
    HowToCookCompleteLoader? completeLoader,
    HowToCookAllRecipesLoader? allRecipesLoader,
  })  : _databaseService = databaseService ?? HowToCookDatabaseService(),
        _assetIndexLoader = assetIndexLoader ??
            (() => rootBundle
                .loadString('assets/data/howtocook_image_index.json')),
        _searchLoader = searchLoader,
        _completeLoader = completeLoader,
        _allRecipesLoader = allRecipesLoader;

  static final V2HowToCookRecipeService instance = V2HowToCookRecipeService();

  final HowToCookDatabaseService _databaseService;
  final Future<String> Function() _assetIndexLoader;
  final HowToCookSearchLoader? _searchLoader;
  final HowToCookCompleteLoader? _completeLoader;
  final HowToCookAllRecipesLoader? _allRecipesLoader;

  Map<String, _HowToCookImageIndexEntry>? _imageIndexByRecipeId;
  Map<String, _HowToCookImageIndexEntry>? _imageIndexByName;

  Future<void> _ensureIndexLoaded() async {
    if (_imageIndexByRecipeId != null && _imageIndexByName != null) return;
    try {
      final raw = await _assetIndexLoader();
      final decoded = jsonDecode(raw);
      final items = decoded is Map<String, dynamic>
          ? (decoded['items'] as List<dynamic>? ?? const [])
          : const <dynamic>[];
      final byId = <String, _HowToCookImageIndexEntry>{};
      final byName = <String, _HowToCookImageIndexEntry>{};
      for (final item in items) {
        if (item is! Map) continue;
        final map = item.map((key, value) => MapEntry(key.toString(), value));
        final entry = _HowToCookImageIndexEntry.fromJson(map);
        if (entry.recipeId.isNotEmpty) {
          byId[entry.recipeId] = entry;
        }
        if (entry.name.isNotEmpty) {
          byName[_normalize(entry.name)] = entry;
        }
        for (final alias in entry.aliases) {
          final normalized = _normalize(alias);
          if (normalized.isNotEmpty) {
            byName.putIfAbsent(normalized, () => entry);
          }
        }
      }
      _imageIndexByRecipeId = byId;
      _imageIndexByName = byName;
    } catch (_) {
      _imageIndexByRecipeId = {};
      _imageIndexByName = {};
    }
  }

  Future<HowToCookRecipeDetail?> findBestDetailForRecipe(
      RecipeModel recipe) async {
    final query = recipe.name.trim();
    if (query.isEmpty) return null;
    try {
      await _ensureIndexLoaded();
    } catch (_) {
      return null;
    }

    List<Map<String, dynamic>> candidates;
    try {
      candidates = await (_searchLoader?.call(query, 12) ??
          _databaseService.searchRecipesAdvanced(searchQuery: query));
    } catch (_) {
      return null;
    }
    if (candidates.isEmpty) return null;

    final target = _normalize(query);
    Map<String, dynamic>? best;
    var bestScore = -1;
    for (final row in candidates) {
      final name = row['name']?.toString() ?? '';
      final normalizedName = _normalize(name);
      var score = 0;
      if (normalizedName == target) {
        score = 3;
      } else if (normalizedName.contains(target) ||
          target.contains(normalizedName)) {
        score = 2;
      } else if (name.contains(query)) {
        score = 1;
      }
      if (score > bestScore) {
        best = row;
        bestScore = score;
      }
    }
    if (best == null) return null;

    final recipeId = best['id']?.toString() ?? '';
    if (recipeId.isEmpty) return null;
    Map<String, dynamic>? detail;
    try {
      detail = await (_completeLoader?.call(recipeId) ??
          _databaseService.getCompleteRecipe(recipeId));
    } catch (_) {
      return null;
    }
    if (detail == null) return null;
    return _mapDetail(detail);
  }

  Future<List<HowToCookRecipeDetail>> getLibraryRecipes({
    String query = '',
    String category = '',
    int limit = 60,
  }) async {
    try {
      await _ensureIndexLoaded();
    } catch (_) {
      return const [];
    }
    List<Map<String, dynamic>> rows;
    try {
      rows = query.trim().isEmpty
          ? await (_allRecipesLoader?.call(limit) ?? _loadAllRecipes(limit))
          : await (_searchLoader?.call(query.trim(), limit) ??
              _databaseService.searchRecipesAdvanced(
                searchQuery: query.trim(),
              ));
    } catch (_) {
      return const [];
    }

    final summaries = rows
        .map(_mapSummary)
        .where((item) {
          if (category.trim().isEmpty) return true;
          return item.category.trim() == category.trim();
        })
        .take(limit)
        .toList();

    return summaries;
  }

  Future<List<RecipeModel>> getImageBackedRecipes({
    String query = '',
    int limit = 20,
    List<String> extraTags = const [],
  }) async {
    try {
      await _ensureIndexLoaded();
    } catch (_) {
      return const [];
    }

    final normalizedQuery = _normalize(query);
    final seen = <String>{};
    final entries = [
      ...?_imageIndexByRecipeId?.values,
      ...?_imageIndexByName?.values,
    ]
        .where((entry) {
          if (entry.assetImageUrls.isEmpty || entry.name.trim().isEmpty) {
            return false;
          }
          final key = entry.recipeId.isNotEmpty ? entry.recipeId : entry.name;
          if (!seen.add(key)) return false;
          if (normalizedQuery.isEmpty) return true;
          final normalizedName = _normalize(entry.name);
          return normalizedName.contains(normalizedQuery) ||
              normalizedQuery.contains(normalizedName) ||
              entry.aliases.any((alias) {
                final normalizedAlias = _normalize(alias);
                return normalizedAlias.contains(normalizedQuery) ||
                    normalizedQuery.contains(normalizedAlias);
              });
        })
        .take(limit)
        .toList();

    return entries.map((entry) {
      final markdownCategory = _categoryFromMarkdownPath(entry.markdownPath);
      final tags = {
        if (markdownCategory.isNotEmpty) markdownCategory,
        ...extraTags.where((item) => item.trim().isNotEmpty),
      }.toList();
      final idSource = entry.recipeId.isNotEmpty
          ? entry.recipeId
          : entry.name.replaceAll(RegExp(r'\s+'), '_');
      return RecipeModel(
        id: 'howtocook_image_$idSource',
        name: entry.name,
        description: '来自 HowToCook 图库的参考菜图，适合先看图定方向。',
        tags: tags,
        imageUrl: entry.assetImageUrls.first,
      );
    }).toList();
  }

  Future<List<String>> getLibraryCategories() async {
    final items = await getLibraryRecipes(limit: 400);
    final categories = items
        .map((item) => item.category.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return categories;
  }

  Future<List<HowToCookRecipeDetail>> getRelatedRecipes(
    RecipeModel recipe, {
    int limit = 6,
  }) async {
    final items = await getLibraryRecipes(limit: 400);
    final currentName = _normalize(recipe.name);
    final recipeTags = recipe.tags
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();

    final scored = <({HowToCookRecipeDetail item, int score})>[];
    for (final item in items) {
      if (_normalize(item.name) == currentName) continue;
      final itemCategory = item.category.trim();
      final itemSubcategory = item.subcategory.trim();
      var score = 0;
      if (itemCategory.isNotEmpty && recipeTags.contains(itemCategory)) {
        score += 3;
      }
      if (itemSubcategory.isNotEmpty && recipeTags.contains(itemSubcategory)) {
        score += 2;
      }
      final sameCategory =
          itemCategory.isNotEmpty && recipeTags.contains(itemCategory);
      if (sameCategory && score > 0) {
        scored.add((item: item, score: score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).map((entry) => entry.item).toList();
  }

  Future<RecipeModel> enrichRecipe(RecipeModel recipe) async {
    final detail = await findBestDetailForRecipe(recipe);
    if (detail == null) return recipe;
    final mergedTags = {
      ...recipe.tags,
      if (detail.category.trim().isNotEmpty) detail.category.trim(),
      if (detail.subcategory.trim().isNotEmpty) detail.subcategory.trim(),
    }.toList();

    return recipe.copyWith(
      description: detail.description.trim().isNotEmpty
          ? detail.description.trim()
          : recipe.description,
      ingredients: detail.ingredients.isNotEmpty
          ? detail.ingredients
          : recipe.ingredients,
      steps: detail.steps.isNotEmpty ? detail.steps : recipe.steps,
      tags: mergedTags,
      imageUrl: (recipe.imageUrl?.trim().isNotEmpty ?? false)
          ? recipe.imageUrl
          : (detail.imageAssetUrls.isNotEmpty
              ? detail.imageAssetUrls.first
              : recipe.imageUrl),
      source: recipe.source.trim().isNotEmpty ? recipe.source : 'HowToCook',
    );
  }

  Future<List<Map<String, dynamic>>> _loadAllRecipes(int limit) async {
    final rows = await _databaseService.getAllRecipes();
    return rows.take(limit).map(Map<String, dynamic>.from).toList();
  }

  HowToCookRecipeDetail _mapSummary(Map<String, dynamic> row) {
    final name = row['name']?.toString() ?? '';
    final id = row['id']?.toString() ?? '';
    final imageEntry = _imageIndexByRecipeId?[id] ??
        _imageIndexByName?[_normalize(name)] ??
        _imageIndexByName?[_normalize(
          row['title']?.toString() ?? '',
        )];
    return HowToCookRecipeDetail(
      id: id,
      name: name,
      description: row['description']?.toString() ?? '',
      ingredients: const [],
      steps: const [],
      imageAssetUrls: imageEntry?.assetImageUrls ?? const [],
      aliases: imageEntry?.aliases ?? const [],
      category: row['category']?.toString() ?? '',
      subcategory: row['subcategory']?.toString() ?? '',
      difficulty: _asInt(row['difficulty'], fallback: 3),
      cookingTimeMinutes: _asNullableInt(row['cooking_time']),
      servings: _asNullableInt(row['servings']),
      githubUrl: row['github_url']?.toString() ?? '',
      sourceProject: imageEntry?.sourceProject ?? 'HowToCook',
      markdownPath: imageEntry?.markdownPath ?? '',
    );
  }

  HowToCookRecipeDetail _mapDetail(Map<String, dynamic> row) {
    final summary = _mapSummary(row);
    final ingredients = (row['ingredients'] as List<dynamic>? ?? const [])
        .map((item) =>
            item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
        .map(_formatIngredient)
        .where((item) => item.isNotEmpty)
        .toList();
    final steps = (row['steps'] as List<dynamic>? ?? const [])
        .map((item) => item is Map ? item['description']?.toString() ?? '' : '')
        .where((item) => item.trim().isNotEmpty)
        .map((item) => item.trim())
        .toList();
    return HowToCookRecipeDetail(
      id: summary.id,
      name: summary.name,
      description: summary.description,
      ingredients: ingredients,
      steps: steps,
      imageAssetUrls: summary.imageAssetUrls,
      aliases: summary.aliases,
      category: summary.category,
      subcategory: summary.subcategory,
      difficulty: summary.difficulty,
      cookingTimeMinutes: summary.cookingTimeMinutes,
      servings: summary.servings,
      githubUrl: summary.githubUrl,
      sourceProject: summary.sourceProject,
      markdownPath: summary.markdownPath,
    );
  }

  String _formatIngredient(Map<String, dynamic> item) {
    final name = item['name']?.toString().trim() ?? '';
    final amount = item['amount']?.toString().trim() ?? '';
    final unit = item['unit']?.toString().trim() ?? '';
    if (name.isEmpty) return '';
    final suffix = '$amount$unit'.trim();
    return suffix.isEmpty ? name : '$name $suffix';
  }

  int _asInt(Object? value, {required int fallback}) {
    final parsed = _asNullableInt(value);
    return parsed ?? fallback;
  }

  int? _asNullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-_·•,，。.!！？?、（）()]+'), '');
  }

  String _categoryFromMarkdownPath(String path) {
    final parts = path.split('/').where((part) => part.isNotEmpty).toList();
    final first = parts.isEmpty ? '' : parts.first;
    return switch (first) {
      'meat_dish' => '荤菜',
      'vegetable_dish' => '素菜',
      'aquatic' => '水产',
      'breakfast' => '早餐',
      'soup' => '汤羹',
      'drink' => '饮品',
      'staple' => '主食',
      'dessert' => '甜品',
      _ => '',
    };
  }
}

class _HowToCookImageIndexEntry {
  const _HowToCookImageIndexEntry({
    required this.recipeId,
    required this.name,
    required this.aliases,
    required this.assetImageUrls,
    required this.markdownPath,
    required this.sourceProject,
  });

  factory _HowToCookImageIndexEntry.fromJson(Map<String, dynamic> json) {
    return _HowToCookImageIndexEntry(
      recipeId: json['recipeId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      aliases: (json['aliases'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      assetImageUrls: (json['assetImageUrls'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      markdownPath: json['markdownPath']?.toString() ?? '',
      sourceProject: json['sourceProject']?.toString() ?? 'HowToCook',
    );
  }

  final String recipeId;
  final String name;
  final List<String> aliases;
  final List<String> assetImageUrls;
  final String markdownPath;
  final String sourceProject;
}
