import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/recipe.dart';
import '../models/user_preference_score.dart';
import 'user_preference_manager.dart';
import 'real_xiachufang_crawler_service.dart';

/// 菜谱数据库服务
class RecipeDatabaseService {
  static const String _recipesKey = 'cached_recipes';
  static const String _favoritesKey = 'favorite_recipes';
  static const String _bookmarksKey = 'bookmarked_recipes';
  static const String _realDataKey = 'real_recipe_data_loaded';

  final UserPreferenceManager _preferenceManager = UserPreferenceManager();
  final RealXiachufangCrawlerService _crawlerService = RealXiachufangCrawlerService();
  final List<Recipe> _recipes = [];
  final Set<String> _favoriteIds = {};
  final Set<String> _bookmarkIds = {};

  static final RecipeDatabaseService _instance = RecipeDatabaseService._internal();
  factory RecipeDatabaseService() => _instance;
  RecipeDatabaseService._internal();

  /// 初始化数据库
  Future<void> initialize() async {
    await _loadCachedData();

    // 优先尝试加载真实数据
    if (_recipes.isEmpty) {
      debugPrint('📊 未找到缓存数据，尝试加载真实菜谱数据...');
      await _loadRealRecipes();
    }

    // 如果真实数据加载失败，使用示例数据
    if (_recipes.isEmpty) {
      debugPrint('⚠️ 真实数据加载失败，使用示例数据');
      await _loadSampleRecipes();
    }

    debugPrint('菜谱数据库初始化完成，共 ${_recipes.length} 个菜谱');
  }

  /// 加载真实菜谱数据
  Future<void> _loadRealRecipes() async {
    try {
      await _crawlerService.initialize();

      // 检查是否已有真实数据缓存
      final prefs = await SharedPreferences.getInstance();
      final hasRealData = prefs.getBool(_realDataKey) ?? false;

      if (!hasRealData) {
        debugPrint('🕷️ 开始爬取真实菜谱数据...');

        final result = await _crawlerService.crawlRecipes(
          categories: ['家常菜', '川菜', '粤菜', '湘菜'],
          targetCount: 50, // 先爬取50个菜谱
          onProgress: (message) => debugPrint('📈 $message'),
        );

        if (result.success) {
          final realRecipes = _crawlerService.crawledRecipes;
          _recipes.addAll(realRecipes);

          await prefs.setBool(_realDataKey, true);
          await _saveCachedData();

          debugPrint('✅ 成功加载 ${realRecipes.length} 个真实菜谱');
        } else {
          debugPrint('❌ 真实数据爬取失败: ${result.message}');
        }
      }
    } catch (e) {
      debugPrint('❌ 加载真实数据时出错: $e');
    }
  }

  /// 加载缓存数据
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 加载收藏
      final favoritesJson = prefs.getString(_favoritesKey);
      if (favoritesJson != null) {
        final favoritesList = List<String>.from(jsonDecode(favoritesJson));
        _favoriteIds.addAll(favoritesList);
      }

      // 加载书签
      final bookmarksJson = prefs.getString(_bookmarksKey);
      if (bookmarksJson != null) {
        final bookmarksList = List<String>.from(jsonDecode(bookmarksJson));
        _bookmarkIds.addAll(bookmarksList);
      }

      // 加载菜谱缓存
      final recipesJson = prefs.getString(_recipesKey);
      if (recipesJson != null) {
        final recipesList = List<Map<String, dynamic>>.from(jsonDecode(recipesJson));
        _recipes.clear();
        _recipes.addAll(recipesList.map((json) => Recipe.fromJson(json)));
      }
    } catch (e) {
      debugPrint('加载缓存数据时出错: $e');
    }
  }

  /// 保存缓存数据
  Future<void> _saveCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 保存收藏
      await prefs.setString(_favoritesKey, jsonEncode(_favoriteIds.toList()));

      // 保存书签
      await prefs.setString(_bookmarksKey, jsonEncode(_bookmarkIds.toList()));

      // 保存菜谱（限制数量以避免存储过大）
      final recipesToSave = _recipes.take(100).toList();
      await prefs.setString(_recipesKey, jsonEncode(recipesToSave.map((r) => r.toJson()).toList()));
    } catch (e) {
      debugPrint('保存缓存数据时出错: $e');
    }
  }

  /// 加载示例菜谱数据
  Future<void> _loadSampleRecipes() async {
    if (_recipes.isNotEmpty) return;

    final sampleRecipes = _createSampleRecipes();
    _recipes.addAll(sampleRecipes);
    await _saveCachedData();
  }

  /// 创建示例菜谱数据（使用真实图片链接）
  List<Recipe> _createSampleRecipes() {
    return [
      // 川菜
      Recipe(
        id: 'recipe_001',
        name: '宫保鸡丁',
        description: '经典川菜，鸡肉嫩滑，花生香脆，麻辣鲜香',
        cuisine: '川菜',
        cookingMethod: CookingMethod.stirFry,
        difficulty: RecipeDifficulty.medium,
        preparationTime: 15,
        cookingTime: 10,
        servings: 3,
        imageUrl:
            'https://cp1.douguo.com/upload/caiku/1/c/a/yuan_1c18f0e5a5a04ba2b6a6c56b7ce30f2a.jpg',
        tags: ['川菜', '下饭菜', '家常菜', '鸡肉'],
        ingredients: [
          RecipeIngredient(name: '鸡胸肉', amount: '300', unit: '克', isMain: true),
          RecipeIngredient(name: '花生米', amount: '100', unit: '克', isMain: true),
          RecipeIngredient(name: '干辣椒', amount: '10', unit: '个', isMain: false),
          RecipeIngredient(name: '花椒', amount: '1', unit: '茶匙', isMain: false),
          RecipeIngredient(name: '生抽', amount: '2', unit: '汤匙', isMain: false),
          RecipeIngredient(name: '老抽', amount: '1', unit: '茶匙', isMain: false),
          RecipeIngredient(name: '料酒', amount: '1', unit: '汤匙', isMain: false),
          RecipeIngredient(name: '白糖', amount: '1', unit: '茶匙', isMain: false),
          RecipeIngredient(name: '盐', amount: '1', unit: '茶匙', isMain: false),
          RecipeIngredient(name: '淀粉', amount: '1', unit: '汤匙', isMain: false),
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            description: '鸡胸肉切成1.5cm的小丁，加入料酒、生抽、淀粉腌制15分钟',
            estimatedTime: 15,
            tip: '腌制时间足够，鸡肉更入味',
          ),
          CookingStep(
            stepNumber: 2,
            description: '热锅下油，放入花生米炸至金黄酥脆，捞出沥油',
            estimatedTime: 3,
            tip: '小火慢炸，避免炸糊',
          ),
          CookingStep(
            stepNumber: 3,
            description: '锅内留少许油，下干辣椒和花椒爆香',
            estimatedTime: 1,
            tip: '火候要适中，避免炸焦',
          ),
          CookingStep(
            stepNumber: 4,
            description: '倒入腌好的鸡丁，大火快炒至变色',
            estimatedTime: 3,
            tip: '动作要快，保持鸡肉嫩滑',
          ),
          CookingStep(
            stepNumber: 5,
            description: '加入调料汁（生抽、老抽、白糖、盐），翻炒均匀',
            estimatedTime: 2,
            tip: '调料汁可以提前调好',
          ),
          CookingStep(
            stepNumber: 6,
            description: '最后加入炸好的花生米，快速翻炒几下即可出锅',
            estimatedTime: 1,
            tip: '花生米最后放，保持酥脆',
          ),
        ],
        nutrition: NutritionInfo(
          calories: 420,
          protein: 35.5,
          carbs: 15.2,
          fat: 24.8,
          fiber: 3.2,
          sodium: 890,
        ),
        rating: 4.8,
        reviewCount: 1256,
        authorId: 'chef_001',
        authorName: '川菜大师',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        tips: '鸡肉腌制时间要足够，炒制过程要大火快炒，保持鸡肉嫩滑。花生米要提前炸好，最后放入保持酥脆。',
        seasonalInfo: SeasonalInfo(),
        equipment: CookingEquipment(),
      ),

      // 粤菜
      Recipe(
        id: 'recipe_002',
        name: '白切鸡',
        description: '粤菜经典，鸡肉鲜嫩，清淡爽口',
        cuisine: '粤菜',
        cookingMethod: CookingMethod.boil,
        difficulty: RecipeDifficulty.easy,
        preparationTime: 10,
        cookingTime: 25,
        servings: 4,
        imageUrl:
            'https://cp1.douguo.com/upload/caiku/2/5/1/yuan_2537ec8b4c5c54a15f75ede81a69a601.jpg',
        tags: ['粤菜', '清淡', '白切', '鸡肉'],
        ingredients: [
          RecipeIngredient(name: '整鸡', amount: '1', unit: '只', isMain: true),
          RecipeIngredient(name: '生姜', amount: '50', unit: '克', isMain: false),
          RecipeIngredient(name: '大葱', amount: '2', unit: '根', isMain: false),
          RecipeIngredient(name: '料酒', amount: '2', unit: '汤匙', isMain: false),
          RecipeIngredient(name: '盐', amount: '1', unit: '茶匙', isMain: false),
          RecipeIngredient(name: '生抽', amount: '3', unit: '汤匙', isMain: false),
          RecipeIngredient(name: '香油', amount: '1', unit: '汤匙', isMain: false),
          RecipeIngredient(name: '白糖', amount: '1', unit: '茶匙', isMain: false),
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            description: '整鸡洗净，去除内脏，用盐搓洗鸡皮',
            estimatedTime: 5,
            tip: '用盐搓洗可以去除腥味',
          ),
          CookingStep(
            stepNumber: 2,
            description: '锅内放水，加入生姜片、大葱段、料酒煮开',
            estimatedTime: 5,
            tip: '水要足够没过整鸡',
          ),
          CookingStep(
            stepNumber: 3,
            description: '放入整鸡，大火煮开后转小火煮20分钟',
            estimatedTime: 20,
            tip: '保持微沸状态，避免煮烂',
          ),
          CookingStep(
            stepNumber: 4,
            description: '关火后焖5分钟，捞出放入冰水中冷却',
            estimatedTime: 5,
            tip: '冰水冷却让鸡皮更紧致',
          ),
          CookingStep(
            stepNumber: 5,
            description: '调制蘸料：生抽、香油、白糖、姜蓉调匀',
            estimatedTime: 3,
            tip: '蘸料是关键，要调味均衡',
          ),
          CookingStep(
            stepNumber: 6,
            description: '鸡肉斩件装盘，配蘸料即可',
            estimatedTime: 5,
            tip: '斩件要整齐，摆盘要美观',
          ),
        ],
        nutrition: NutritionInfo(
          calories: 310,
          protein: 42.8,
          carbs: 2.1,
          fat: 14.2,
          fiber: 0.1,
          sodium: 720,
        ),
        rating: 4.6,
        reviewCount: 892,
        authorId: 'chef_002',
        authorName: '粤菜师傅',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
        tips: '选用新鲜的土鸡，煮制时间要准确，过长会使鸡肉老柴。冰水冷却是关键步骤，能让鸡皮紧致有弹性。',
        seasonalInfo: SeasonalInfo(),
        equipment: CookingEquipment(),
      ),

      // 家常菜
      Recipe(
        id: 'recipe_003',
        name: '红烧肉',
        description: '经典家常菜，肉质软糯，甜而不腻',
        cuisine: '家常菜',
        cookingMethod: CookingMethod.braise,
        difficulty: RecipeDifficulty.medium,
        preparationTime: 10,
        cookingTime: 60,
        servings: 4,
        imageUrl:
            'https://cp1.douguo.com/upload/caiku/4/b/8/yuan_4b5b1c0a8a0c42888e4b8c8d35ed7a58.jpg',
        tags: ['家常菜', '红烧', '猪肉', '下饭菜'],
        ingredients: [
          RecipeIngredient(name: '五花肉', amount: '500', unit: '克', isMain: true),
          RecipeIngredient(name: '冰糖', amount: '30', unit: '克', isMain: false),
          RecipeIngredient(name: '生抽', amount: '3', unit: '汤匙', isMain: false),
          RecipeIngredient(name: '老抽', amount: '1', unit: '汤匙', isMain: false),
          RecipeIngredient(name: '料酒', amount: '2', unit: '汤匙', isMain: false),
          RecipeIngredient(name: '生姜', amount: '20', unit: '克', isMain: false),
          RecipeIngredient(name: '大葱', amount: '1', unit: '根', isMain: false),
          RecipeIngredient(name: '八角', amount: '2', unit: '个', isMain: false),
          RecipeIngredient(name: '桂皮', amount: '1', unit: '小块', isMain: false),
          RecipeIngredient(name: '盐', amount: '1', unit: '茶匙', isMain: false),
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            description: '五花肉洗净切成3cm见方的块，冷水下锅焯水',
            estimatedTime: 10,
            tip: '焯水可以去除血沫和腥味',
          ),
          CookingStep(
            stepNumber: 2,
            description: '锅内放少许油，下冰糖小火炒出糖色',
            estimatedTime: 5,
            tip: '糖色要炒至焦糖色，不要炒糊',
          ),
          CookingStep(
            stepNumber: 3,
            description: '下肉块翻炒，让每块肉都裹上糖色',
            estimatedTime: 3,
            tip: '要翻炒均匀，上色一致',
          ),
          CookingStep(
            stepNumber: 4,
            description: '加入生抽、老抽、料酒，翻炒均匀',
            estimatedTime: 2,
            tip: '老抽主要用于上色',
          ),
          CookingStep(
            stepNumber: 5,
            description: '加入开水没过肉块，放入生姜、大葱、八角、桂皮',
            estimatedTime: 2,
            tip: '一定要用开水，避免肉质变硬',
          ),
          CookingStep(
            stepNumber: 6,
            description: '大火烧开后转小火炖45分钟，最后大火收汁',
            estimatedTime: 50,
            tip: '炖制时间要足够，让肉质软糯',
          ),
        ],
        nutrition: NutritionInfo(
          calories: 580,
          protein: 28.5,
          carbs: 12.8,
          fat: 45.2,
          fiber: 0.5,
          sodium: 1120,
        ),
        rating: 4.9,
        reviewCount: 2341,
        authorId: 'chef_003',
        authorName: '家常菜达人',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now().subtract(const Duration(days: 15)),
        tips: '选用肥瘦相间的五花肉，炒糖色是关键步骤，炖制时间要足够，最后大火收汁让色泽红亮。',
        seasonalInfo: SeasonalInfo(),
        equipment: CookingEquipment(),
      ),

      // 素食
      Recipe(
        id: 'recipe_004',
        name: '麻婆豆腐',
        description: '经典川菜，豆腐嫩滑，麻辣鲜香',
        cuisine: '川菜',
        cookingMethod: CookingMethod.stirFry,
        difficulty: RecipeDifficulty.easy,
        preparationTime: 8,
        cookingTime: 12,
        servings: 3,
        imageUrl:
            'https://cp1.douguo.com/upload/caiku/1/4/5/yuan_140c5b6d20c7e8a5a9a7a5d3e08b1be5.jpg',
        tags: ['川菜', '素食', '豆腐', '麻辣'],
        ingredients: [
          RecipeIngredient(name: '嫩豆腐', amount: '400', unit: '克', isMain: true),
          RecipeIngredient(name: '肉末', amount: '100', unit: '克', isMain: true),
          RecipeIngredient(name: '豆瓣酱', amount: '2', unit: '汤匙', isMain: false),
          RecipeIngredient(name: '生抽', amount: '1', unit: '汤匙', isMain: false),
          RecipeIngredient(name: '花椒粉', amount: '1', unit: '茶匙', isMain: false),
          RecipeIngredient(name: '大蒜', amount: '3', unit: '瓣', isMain: false),
          RecipeIngredient(name: '生姜', amount: '1', unit: '小块', isMain: false),
          RecipeIngredient(name: '青蒜', amount: '2', unit: '根', isMain: false),
          RecipeIngredient(name: '水淀粉', amount: '2', unit: '汤匙', isMain: false),
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            description: '豆腐切成2cm见方的块，用淡盐水浸泡5分钟',
            estimatedTime: 5,
            tip: '盐水浸泡可以去除豆腥味',
          ),
          CookingStep(
            stepNumber: 2,
            description: '热锅下油，爆香蒜蓉和姜蓉',
            estimatedTime: 1,
            tip: '小火爆香，不要炒糊',
          ),
          CookingStep(
            stepNumber: 3,
            description: '下肉末炒散，炒至变色',
            estimatedTime: 3,
            tip: '肉末要炒散，不要结团',
          ),
          CookingStep(
            stepNumber: 4,
            description: '加入豆瓣酱炒出红油，下豆腐块轻轻推匀',
            estimatedTime: 2,
            tip: '动作要轻，避免豆腐破碎',
          ),
          CookingStep(
            stepNumber: 5,
            description: '加入生抽和少许水，焖煮3分钟',
            estimatedTime: 3,
            tip: '让豆腐充分入味',
          ),
          CookingStep(
            stepNumber: 6,
            description: '用水淀粉勾芡，撒上花椒粉和青蒜段即可',
            estimatedTime: 2,
            tip: '勾芡要适量，不要太稠',
          ),
        ],
        nutrition: NutritionInfo(
          calories: 220,
          protein: 18.5,
          carbs: 8.2,
          fat: 14.8,
          fiber: 2.5,
          sodium: 980,
        ),
        rating: 4.7,
        reviewCount: 1567,
        authorId: 'chef_004',
        authorName: '素食专家',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        tips: '选用嫩豆腐，处理时要轻，豆瓣酱是关键调料，最后撒花椒粉提味。',
        seasonalInfo: SeasonalInfo(),
        equipment: CookingEquipment(),
      ),

      // 汤类
      Recipe(
        id: 'recipe_005',
        name: '冬瓜排骨汤',
        description: '清淡营养，排骨鲜香，冬瓜清甜',
        cuisine: '家常菜',
        cookingMethod: CookingMethod.boil,
        difficulty: RecipeDifficulty.easy,
        preparationTime: 15,
        cookingTime: 90,
        servings: 4,
        imageUrl:
            'https://cp1.douguo.com/upload/caiku/8/1/2/yuan_8196c2b7a5c54e8b89e1a2b3c4d5e6f7.jpg',
        tags: ['汤类', '清淡', '营养', '排骨'],
        ingredients: [
          RecipeIngredient(name: '排骨', amount: '500', unit: '克', isMain: true),
          RecipeIngredient(name: '冬瓜', amount: '400', unit: '克', isMain: true),
          RecipeIngredient(name: '生姜', amount: '20', unit: '克', isMain: false),
          RecipeIngredient(name: '大葱', amount: '1', unit: '根', isMain: false),
          RecipeIngredient(name: '料酒', amount: '1', unit: '汤匙', isMain: false),
          RecipeIngredient(name: '盐', amount: '1', unit: '茶匙', isMain: false),
          RecipeIngredient(name: '胡椒粉', amount: '1', unit: '茶匙', isMain: false),
          RecipeIngredient(name: '香菜', amount: '2', unit: '根', isMain: false),
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            description: '排骨洗净切段，冷水下锅焯水去血沫',
            estimatedTime: 10,
            tip: '焯水要彻底，去除血沫和腥味',
          ),
          CookingStep(
            stepNumber: 2,
            description: '冬瓜去皮去瓤，切成厚片',
            estimatedTime: 5,
            tip: '不要切太薄，避免煮烂',
          ),
          CookingStep(
            stepNumber: 3,
            description: '砂锅内放水，下排骨、生姜、大葱、料酒',
            estimatedTime: 5,
            tip: '用砂锅煲汤味道更好',
          ),
          CookingStep(
            stepNumber: 4,
            description: '大火烧开后转小火煲1小时',
            estimatedTime: 60,
            tip: '小火慢煲，汤色会更清澈',
          ),
          CookingStep(
            stepNumber: 5,
            description: '加入冬瓜片，继续煲15分钟',
            estimatedTime: 15,
            tip: '冬瓜不要煲太久，保持形状',
          ),
          CookingStep(
            stepNumber: 6,
            description: '最后调味，撒上香菜即可',
            estimatedTime: 2,
            tip: '盐要最后放，避免肉质变硬',
          ),
        ],
        nutrition: NutritionInfo(
          calories: 180,
          protein: 22.5,
          carbs: 6.8,
          fat: 7.2,
          fiber: 1.8,
          sodium: 650,
        ),
        rating: 4.5,
        reviewCount: 876,
        authorId: 'chef_005',
        authorName: '汤品专家',
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
        updatedAt: DateTime.now().subtract(const Duration(days: 8)),
        tips: '选用新鲜排骨，煲汤时间要足够，冬瓜后放，调味要清淡。',
        seasonalInfo: SeasonalInfo(),
        equipment: CookingEquipment(),
      ),
    ];
  }

  /// 根据用户偏好推荐菜谱
  Future<List<Recipe>> getRecommendedRecipes({
    int limit = 10,
    List<String>? userPreferences,
  }) async {
    if (_recipes.isEmpty) {
      await _loadSampleRecipes();
    }

    // 获取用户偏好统计
    final preferenceStats = _preferenceManager.getPreferenceStats();
    final topPreferences = preferenceStats['topPreferences'] as List<UserPreferenceScore>;

    // 计算每个菜谱的推荐分数
    final scoredRecipes = _recipes.map((recipe) {
      double score = 0.0;

      // 基于用户偏好计算分数
      for (final preference in topPreferences) {
        // 检查菜谱标签是否匹配偏好
        if (recipe.tags.any((tag) => tag.contains(preference.entityName))) {
          score += preference.score * 0.3;
        }

        // 检查菜谱名称是否匹配偏好
        if (recipe.name.contains(preference.entityName)) {
          score += preference.score * 0.5;
        }

        // 检查菜谱描述是否匹配偏好
        if (recipe.description.contains(preference.entityName)) {
          score += preference.score * 0.2;
        }
      }

      // 加入菜谱本身的评分权重
      score += recipe.rating * 10;

      // 加入随机因子，避免推荐过于固化
      final random = Random();
      score += random.nextDouble() * 20;

      return MapEntry(recipe, score);
    }).toList();

    // 按分数排序
    scoredRecipes.sort((a, b) => b.value.compareTo(a.value));

    // 返回推荐结果
    final recommendations = scoredRecipes
        .take(limit)
        .map((entry) => entry.key.copyWith(
              isFavorite: _favoriteIds.contains(entry.key.id),
              isBookmarked: _bookmarkIds.contains(entry.key.id),
            ))
        .toList();

    debugPrint('推荐了 ${recommendations.length} 个菜谱');
    return recommendations;
  }

  /// 搜索菜谱
  Future<List<Recipe>> searchRecipes({
    String? query,
    String? cuisine,
    CookingMethod? method,
    RecipeDifficulty? difficulty,
    int? maxTime,
    bool? isVegetarian,
    List<String>? tags,
    int limit = 20,
  }) async {
    if (_recipes.isEmpty) {
      await _loadSampleRecipes();
    }

    var filteredRecipes = _recipes.where((recipe) {
      // 关键词搜索
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        if (!recipe.name.toLowerCase().contains(lowerQuery) &&
            !recipe.description.toLowerCase().contains(lowerQuery) &&
            !recipe.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))) {
          return false;
        }
      }

      // 菜系筛选
      if (cuisine != null && recipe.cuisine != cuisine) {
        return false;
      }

      // 烹饪方法筛选
      if (method != null && recipe.cookingMethod != method) {
        return false;
      }

      // 难度筛选
      if (difficulty != null && recipe.difficulty != difficulty) {
        return false;
      }

      // 时间筛选
      if (maxTime != null && recipe.totalTime > maxTime) {
        return false;
      }

      // 素食筛选
      if (isVegetarian != null && recipe.isVegetarian != isVegetarian) {
        return false;
      }

      // 标签筛选
      if (tags != null && tags.isNotEmpty) {
        if (!tags.any((tag) => recipe.tags.contains(tag))) {
          return false;
        }
      }

      return true;
    }).toList();

    // 按评分排序
    filteredRecipes.sort((a, b) => b.rating.compareTo(a.rating));

    return filteredRecipes
        .take(limit)
        .map((recipe) => recipe.copyWith(
              isFavorite: _favoriteIds.contains(recipe.id),
              isBookmarked: _bookmarkIds.contains(recipe.id),
            ))
        .toList();
  }

  /// 获取菜谱详情
  Future<Recipe?> getRecipeById(String id) async {
    if (_recipes.isEmpty) {
      await _loadSampleRecipes();
    }

    final recipe = _recipes.firstWhere(
      (recipe) => recipe.id == id,
      orElse: () => throw Exception('Recipe not found'),
    );

    return recipe.copyWith(
      isFavorite: _favoriteIds.contains(recipe.id),
      isBookmarked: _bookmarkIds.contains(recipe.id),
    );
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(String recipeId) async {
    if (_favoriteIds.contains(recipeId)) {
      _favoriteIds.remove(recipeId);
    } else {
      _favoriteIds.add(recipeId);
    }
    await _saveCachedData();
  }

  /// 切换书签状态
  Future<void> toggleBookmark(String recipeId) async {
    if (_bookmarkIds.contains(recipeId)) {
      _bookmarkIds.remove(recipeId);
    } else {
      _bookmarkIds.add(recipeId);
    }
    await _saveCachedData();
  }

  /// 获取收藏的菜谱
  Future<List<Recipe>> getFavoriteRecipes() async {
    if (_recipes.isEmpty) {
      await _loadSampleRecipes();
    }

    return _recipes
        .where((recipe) => _favoriteIds.contains(recipe.id))
        .map((recipe) => recipe.copyWith(isFavorite: true))
        .toList();
  }

  /// 获取书签菜谱
  Future<List<Recipe>> getBookmarkedRecipes() async {
    if (_recipes.isEmpty) {
      await _loadSampleRecipes();
    }

    return _recipes
        .where((recipe) => _bookmarkIds.contains(recipe.id))
        .map((recipe) => recipe.copyWith(isBookmarked: true))
        .toList();
  }

  /// 获取热门菜谱
  Future<List<Recipe>> getPopularRecipes({int limit = 10}) async {
    if (_recipes.isEmpty) {
      await _loadSampleRecipes();
    }

    final popularRecipes = _recipes.toList()
      ..sort((a, b) => (b.rating * b.reviewCount).compareTo(a.rating * a.reviewCount));

    return popularRecipes
        .take(limit)
        .map((recipe) => recipe.copyWith(
              isFavorite: _favoriteIds.contains(recipe.id),
              isBookmarked: _bookmarkIds.contains(recipe.id),
            ))
        .toList();
  }

  /// 获取快手菜谱
  Future<List<Recipe>> getQuickRecipes({int limit = 10}) async {
    if (_recipes.isEmpty) {
      await _loadSampleRecipes();
    }

    final quickRecipes = _recipes.where((recipe) => recipe.isQuickDish).toList()
      ..sort((a, b) => a.totalTime.compareTo(b.totalTime));

    return quickRecipes
        .take(limit)
        .map((recipe) => recipe.copyWith(
              isFavorite: _favoriteIds.contains(recipe.id),
              isBookmarked: _bookmarkIds.contains(recipe.id),
            ))
        .toList();
  }

  /// 获取分类菜谱
  Future<List<Recipe>> getRecipesByCategory(String category, {int limit = 10}) async {
    if (_recipes.isEmpty) {
      await _loadSampleRecipes();
    }

    final categoryRecipes = _recipes
        .where((recipe) => recipe.cuisine == category || recipe.tags.contains(category))
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return categoryRecipes
        .take(limit)
        .map((recipe) => recipe.copyWith(
              isFavorite: _favoriteIds.contains(recipe.id),
              isBookmarked: _bookmarkIds.contains(recipe.id),
            ))
        .toList();
  }

  /// 获取所有菜谱
  Future<List<Recipe>> getAllRecipes() async {
    if (_recipes.isEmpty) {
      await _loadSampleRecipes();
    }

    return _recipes
        .map((recipe) => recipe.copyWith(
              isFavorite: _favoriteIds.contains(recipe.id),
              isBookmarked: _bookmarkIds.contains(recipe.id),
            ))
        .toList();
  }

  /// 增加浏览次数
  Future<void> increaseViewCount(String recipeId) async {
    final index = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (index != -1) {
      _recipes[index] = _recipes[index].copyWith(
        viewCount: _recipes[index].viewCount + 1,
      );
      await _saveCachedData();
    }
  }

  /// 强制刷新真实数据
  Future<bool> refreshRealData({
    Function(String message)? onProgress,
  }) async {
    try {
      onProgress?.call('🚀 开始更新真实菜谱数据...');

      await _crawlerService.initialize();

      final result = await _crawlerService.crawlRecipes(
        categories: ['家常菜', '川菜', '粤菜', '湘菜', '鲁菜', '苏菜'],
        targetCount: 100, // 更新时爬取更多数据
        onProgress: onProgress,
      );

      if (result.success) {
        // 清空现有数据，加载新数据
        _recipes.clear();
        final realRecipes = _crawlerService.crawledRecipes;
        _recipes.addAll(realRecipes);

        // 更新缓存
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_realDataKey, true);
        await _saveCachedData();

        onProgress?.call('✅ 数据更新完成，共获取 ${realRecipes.length} 个菜谱');
        return true;
      } else {
        onProgress?.call('❌ 数据更新失败: ${result.message}');
        return false;
      }
    } catch (e) {
      onProgress?.call('❌ 数据更新过程出错: $e');
      return false;
    }
  }

  /// 清空缓存
  Future<void> clearCache() async {
    _recipes.clear();
    _favoriteIds.clear();
    _bookmarkIds.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recipesKey);
    await prefs.remove(_favoritesKey);
    await prefs.remove(_bookmarksKey);
  }
}
