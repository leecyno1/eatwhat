import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/taste_tag.dart';

/// ChangeNotifier：管理口味偏好标签、权重与筛选
class TastePreferencesModel extends ChangeNotifier {
  final List<TasteTag> _all = [];
  String _activeCategory = 'all';

  String get activeCategory => _activeCategory;

  List<TasteTag> get all => List.unmodifiable(_all);

  List<TasteTag> get visibleTags {
    if (_activeCategory == 'all') return all;
    return _all.where((t) => t.category == _activeCategory).toList();
  }

  int get selectedCount => _all.where((t) => t.isSelected).length;

  void initializeWithDefaults() {
    if (_all.isNotEmpty) return;
    _restoreFromStorage();
    // 预置标签，覆盖常见味型/做法/食材/口感/禁忌
    final seed = <TasteTag>[
      // 味型
      TasteTag(id: 'spicy', name: '辣', category: 'taste', emoji: '🌶️'),
      TasteTag(id: 'numbing', name: '麻', category: 'taste', emoji: '🧪'),
      TasteTag(id: 'sour', name: '酸', category: 'taste', emoji: '🍋'),
      TasteTag(id: 'sweet', name: '甜', category: 'taste', emoji: '🍬'),
      TasteTag(id: 'salty', name: '咸', category: 'taste', emoji: '🧂'),
      TasteTag(id: 'fresh', name: '鲜', category: 'taste', emoji: '🍜'),
      TasteTag(id: 'light', name: '清淡', category: 'taste', emoji: '🥗'),
      TasteTag(id: 'oily', name: '重油', category: 'taste', emoji: '🍖'),

      // 烹法
      TasteTag(id: 'fried', name: '炸', category: 'method', emoji: '🍤'),
      TasteTag(id: 'grill', name: '烤', category: 'method', emoji: '🍢'),
      TasteTag(id: 'stew', name: '炖', category: 'method', emoji: '🍲'),
      TasteTag(id: 'steam', name: '蒸', category: 'method', emoji: '🥟'),
      TasteTag(id: 'saute', name: '煎', category: 'method', emoji: '🍳'),
      TasteTag(id: 'boil', name: '煮', category: 'method', emoji: '🍜'),

      // 食材
      TasteTag(id: 'beef', name: '牛肉', category: 'ingredient', emoji: '🥩'),
      TasteTag(id: 'pork', name: '猪肉', category: 'ingredient', emoji: '🍖'),
      TasteTag(id: 'chicken', name: '鸡肉', category: 'ingredient', emoji: '🍗'),
      TasteTag(id: 'fish', name: '鱼', category: 'ingredient', emoji: '🐟'),
      TasteTag(id: 'seafood', name: '海鲜', category: 'ingredient', emoji: '🦐'),
      TasteTag(id: 'veggie', name: '素食', category: 'ingredient', emoji: '🥦'),

      // 口感
      TasteTag(id: 'crispy', name: '酥脆', category: 'texture', emoji: '🍘'),
      TasteTag(id: 'tender', name: '嫩滑', category: 'texture', emoji: '🥛'),
      TasteTag(id: 'chewy', name: '筋道', category: 'texture', emoji: '🧀'),

      // 禁忌/过敏
      TasteTag(id: 'nut', name: '坚果过敏', category: 'avoid', emoji: '🥜'),
      TasteTag(id: 'milk', name: '乳制品过敏', category: 'avoid', emoji: '🥛'),
      TasteTag(id: 'spice', name: '不吃辣', category: 'avoid', emoji: '🚫'),
    ];

    if (_all.isEmpty) {
      _all.addAll(seed);
      notifyListeners();
    }
  }

  void setCategory(String category) {
    _activeCategory = category;
    notifyListeners();
  }

  void toggle(TasteTag tag) {
    final idx = _all.indexWhere((t) => t.id == tag.id);
    if (idx == -1) return;
    if (_all[idx].disliked) {
      _all[idx].disliked = false;
      _all[idx].weight = max(0, _all[idx].weight);
    } else {
      _all[idx].weight = _all[idx].weight > 0 ? 0 : 3; // 快速切换
    }
    notifyListeners();
    _persist();
  }

  void adjustWeight(TasteTag tag, double weight) {
    final idx = _all.indexWhere((t) => t.id == tag.id);
    if (idx == -1) return;
    _all[idx].weight = weight.clamp(0, 5);
    _all[idx].disliked = false;
    notifyListeners();
    _persist();
  }

  void dislike(TasteTag tag, {bool value = true}) {
    final idx = _all.indexWhere((t) => t.id == tag.id);
    if (idx == -1) return;
    _all[idx].disliked = value;
    if (value) _all[idx].weight = 0;
    notifyListeners();
    _persist();
  }

  void reset() {
    for (final t in _all) {
      t.weight = 0;
      t.disliked = false;
    }
    notifyListeners();
    _persist();
  }

  // --- 持久化 ---
  static const _prefsKey = 'taste_prefs_v1';

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _all
          .map((t) => {
                'id': t.id,
                'name': t.name,
                'category': t.category,
                'weight': t.weight,
                'disliked': t.disliked,
                'emoji': t.emoji,
              })
          .toList();
      await prefs.setString(_prefsKey, jsonEncode(data));
    } catch (_) {
      // ignore storage errors in UI layer
    }
  }

  Future<void> _restoreFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final list = jsonDecode(raw) as List<dynamic>;
      _all
        ..clear()
        ..addAll(list.map((m) => TasteTag(
              id: m['id'],
              name: m['name'],
              category: m['category'],
              weight: (m['weight'] as num).toDouble(),
              disliked: m['disliked'] as bool,
              emoji: m['emoji'],
            )));
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }
}
