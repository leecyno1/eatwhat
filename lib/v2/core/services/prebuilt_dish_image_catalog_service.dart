import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/v2/core/data/models/dish_image_manifest.dart';
import 'package:eatwhat_app/v2/core/data/models/dish_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:flutter/services.dart';

class PrebuiltDishImageCatalogService {
  PrebuiltDishImageCatalogService({
    Dio? dio,
    Future<String?> Function()? remoteManifestLoader,
    Future<String> Function()? assetManifestLoader,
    String assetPath = 'assets/data/dish_image_manifest.json',
  })  : _dio = dio ?? Dio(),
        _remoteManifestLoader = remoteManifestLoader,
        _assetManifestLoader =
            assetManifestLoader ?? (() => rootBundle.loadString(assetPath));

  static final PrebuiltDishImageCatalogService instance =
      PrebuiltDishImageCatalogService();

  final Dio _dio;
  final Future<String?> Function()? _remoteManifestLoader;
  final Future<String> Function() _assetManifestLoader;

  List<DishImageManifestEntry>? _entries;

  Future<void> loadManifest() async {
    if (_entries != null) return;

    final remoteRaw = await (_remoteManifestLoader?.call() ?? _loadRemote());
    if (remoteRaw != null && remoteRaw.trim().isNotEmpty) {
      _entries = _parseManifest(remoteRaw);
      return;
    }

    try {
      final assetRaw = await _assetManifestLoader();
      _entries = _parseManifest(assetRaw);
    } catch (_) {
      _entries = const [];
    }
  }

  Future<String?> resolveHeroUrl(RecipeModel recipe) async {
    final entry = await resolveEntry(recipe);
    if (entry == null || entry.heroUrl.trim().isEmpty) return null;
    return _resolveImageLocation(entry.heroUrl);
  }

  Future<String?> resolveThumbUrl(RecipeModel recipe) async {
    final entry = await resolveEntry(recipe);
    if (entry == null || entry.thumbUrl.trim().isEmpty) return null;
    return _resolveImageLocation(entry.thumbUrl);
  }

  Future<DishImageManifestEntry?> resolveEntry(RecipeModel recipe) async {
    await loadManifest();
    final entries = _entries ?? const <DishImageManifestEntry>[];
    if (entries.isEmpty) return null;

    final byId =
        entries.where((entry) => entry.dishId == recipe.dishId).toList();
    if (byId.isNotEmpty) return byId.first;

    final normalizedName = _normalize(recipe.name);
    if (normalizedName.isEmpty) return null;

    for (final entry in entries) {
      if (_normalize(entry.dishName) == normalizedName) {
        return entry;
      }
      if (entry.aliases.any((alias) => _normalize(alias) == normalizedName)) {
        return entry;
      }
    }

    return null;
  }

  Future<String?> _loadRemote() async {
    final url = EnvConfig.prebuiltImageIndexUrl.trim();
    if (url.isEmpty) return null;

    try {
      final response = await _dio.get<String>(url);
      return response.data;
    } catch (_) {
      return null;
    }
  }

  List<DishImageManifestEntry> _parseManifest(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const [];
    final items = decoded['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
        .map(DishImageManifestEntry.fromJson)
        .where((entry) =>
            entry.dishId.trim().isNotEmpty && entry.dishName.trim().isNotEmpty)
        .toList();
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-_·•,，。.!！？?、（）()]+'), '');
  }

  String? _resolveImageLocation(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('data:image/') ||
        value.startsWith('assets/')) {
      return value;
    }

    final configuredBase = EnvConfig.prebuiltImageBaseUrl.trim();
    if (configuredBase.isNotEmpty) {
      final normalizedBase = configuredBase.endsWith('/')
          ? configuredBase.substring(0, configuredBase.length - 1)
          : configuredBase;
      final normalizedPath = value.startsWith('/') ? value.substring(1) : value;
      return '$normalizedBase/$normalizedPath';
    }

    return null;
  }
}
