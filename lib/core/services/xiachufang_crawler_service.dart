import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/recipe.dart';

/// 下厨房数据爬取服务
/// Phase 3: 对齐下厨房数据库颗粒度，实现菜谱数据爬取和同步
class XiachufangCrawlerService {
  static final XiachufangCrawlerService _instance = XiachufangCrawlerService._internal();
  factory XiachufangCrawlerService() => _instance;
  XiachufangCrawlerService._internal();

  final List<Recipe> _crawledRecipes = [];
  final Map<String, dynamic> _crawlStats = {};

  bool _isInitialized = false;
  bool _isCrawling = false;

  // 爬取配置
  static const String baseUrl = 'https://www.xiachufang.com';
  static const Duration requestDelay = Duration(milliseconds: 1000);
  static const int maxRetries = 3;
  static const int batchSize = 50;

  /// 获取爬取的菜谱数据
  List<Recipe> get crawledRecipes => List.from(_crawledRecipes);

  /// 获取爬取统计
  Map<String, dynamic> get crawlStatistics => Map.from(_crawlStats);

  /// 是否正在爬取
  bool get isCrawling => _isCrawling;

  /// 初始化爬取服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🕷️ 初始化下厨房数据爬取服务...');

    // 初始化统计数据
    _crawlStats.clear();
    _crawlStats['totalRecipes'] = 0;
    _crawlStats['successfulCrawls'] = 0;
    _crawlStats['failedCrawls'] = 0;
    _crawlStats['startTime'] = null;
    _crawlStats['endTime'] = null;

    _isInitialized = true;
    debugPrint('✅ 下厨房数据爬取服务初始化完成');
  }

  /// 开始爬取菜谱数据
  Future<CrawlResult> startCrawling({
    List<String>? categories,
    int maxRecipes = 1000,
    bool includeImages = true,
  }) async {
    if (_isCrawling) {
      return CrawlResult(
        success: false,
        message: '爬取任务正在进行中',
        recipesCount: 0,
      );
    }

    _isCrawling = true;
    _crawlStats['startTime'] = DateTime.now().toIso8601String();

    try {
      debugPrint('🚀 开始爬取下厨房菜谱数据...');
      debugPrint('📊 目标数量: $maxRecipes, 包含图片: $includeImages');

      // 1. 获取菜谱分类列表
      final categoryList = categories ?? await _getCategoryList();
      debugPrint('📂 发现 ${categoryList.length} 个分类');

      // 2. 按分类爬取菜谱
      int totalCrawled = 0;
      for (final category in categoryList) {
        if (totalCrawled >= maxRecipes) break;

        final categoryResult = await _crawlCategoryRecipes(
          category,
          maxRecipes: (maxRecipes / categoryList.length).ceil(),
          includeImages: includeImages,
        );

        totalCrawled += categoryResult.length;
        debugPrint('📈 分类 $category 爬取完成: ${categoryResult.length} 个菜谱');
      }

      _crawlStats['endTime'] = DateTime.now().toIso8601String();
      _crawlStats['totalRecipes'] = _crawledRecipes.length;

      final result = CrawlResult(
        success: true,
        message: '爬取完成',
        recipesCount: _crawledRecipes.length,
        categories: categoryList,
        duration: _calculateDuration(),
      );

      // 3. 保存爬取数据
      await _saveCrawledData();

      debugPrint('🎉 菜谱数据爬取完成: ${result.recipesCount} 个菜谱');
      return result;
    } catch (e) {
      debugPrint('❌ 爬取过程出错: $e');
      return CrawlResult(
        success: false,
        message: '爬取失败: $e',
        recipesCount: _crawledRecipes.length,
      );
    } finally {
      _isCrawling = false;
    }
  }

  /// 模拟爬取菜谱数据（由于实际网站限制，使用模拟数据）
  Future<List<Recipe>> _crawlCategoryRecipes(String category,
      {required int maxRecipes, required bool includeImages}) async {
    final recipes = <Recipe>[];

    // 模拟网络请求延迟
    await Future.delayed(requestDelay);

    // 生成该分类的模拟菜谱数据
    for (int i = 0; i < maxRecipes; i++) {
      try {
        final recipe = await _generateMockRecipe(category, i);
        recipes.add(recipe);
        _crawledRecipes.add(recipe);
        _crawlStats['successfulCrawls'] = (_crawlStats['successfulCrawls'] ?? 0) + 1;

        // 下载图片（如果需要）
        if (includeImages) {
          await _downloadRecipeImages(recipe);
        }
      } catch (e) {
        debugPrint('⚠️ 生成菜谱 $category-$i 失败: $e');
        _crawlStats['failedCrawls'] = (_crawlStats['failedCrawls'] ?? 0) + 1;
      }

      // 控制爬取速度
      if (i % 10 == 0) {
        await Future.delayed(Duration(milliseconds: 500));
      }
    }

    return recipes;
  }

  /// 生成模拟菜谱数据（对齐下厨房数据结构）
  Future<Recipe> _generateMockRecipe(String category, int index) async {
    final recipeData = _getRecipeTemplate(category, index);

    return Recipe(
      id: 'xcf_${category}_${index.toString().padLeft(4, '0')}',
      name: recipeData['name'],
      description: recipeData['description'],
      cuisine: recipeData['cuisine'],
      cookingMethod: recipeData['cookingMethod'],
      difficulty: recipeData['difficulty'],
      preparationTime: recipeData['preparationTime'],
      cookingTime: recipeData['cookingTime'],
      servings: recipeData['servings'],
      imageUrl: recipeData['imageUrl'],
      tags: List<String>.from(recipeData['tags']),
      ingredients:
          (recipeData['ingredients'] as List).map((i) => RecipeIngredient.fromJson(i)).toList(),
      steps: (recipeData['steps'] as List).map((s) => CookingStep.fromJson(s)).toList(),
      nutrition: NutritionInfo.fromJson(recipeData['nutrition']),
      rating: recipeData['rating'],
      reviewCount: recipeData['reviewCount'],
      authorId: recipeData['authorId'],
      authorName: recipeData['authorName'],
      createdAt: DateTime.now().subtract(Duration(days: index)),
      updatedAt: DateTime.now().subtract(Duration(days: index ~/ 2)),
      // Phase 2 增强字段
      tasteProfile: List<String>.from(recipeData['tasteProfile']),
      scenarioTags: List<String>.from(recipeData['scenarioTags']),
      healthBenefits: List<String>.from(recipeData['healthBenefits']),
      seasonalInfo: SeasonalInfo.fromJson(recipeData['seasonalInfo']),
      equipment: CookingEquipment.fromJson(recipeData['equipment']),
      tasteIntensity: Map<String, double>.from(recipeData['tasteIntensity']),
      spiceLevel: recipeData['spiceLevel'],
      origin: recipeData['origin'],
      isAuthentic: recipeData['isAuthentic'],
      cookingTechniques: List<String>.from(recipeData['cookingTechniques']),
      ingredientSubstitutes: Map<String, String>.from(recipeData['ingredientSubstitutes']),
      costEstimate: recipeData['costEstimate'],
      mealTypes: List<String>.from(recipeData['mealTypes']),
    );
  }

  /// 获取菜谱数据模板
  Map<String, dynamic> _getRecipeTemplate(String category, int index) {
    final templates = _getXiachufangRecipeTemplates();
    final template = templates[category] ?? templates['川菜']!;
    final recipeTemplate = template[index % template.length];

    // 添加随机变化
    final random = DateTime.now().millisecond % 100;

    return {
      ...recipeTemplate,
      'rating': (4.0 + random / 100.0).clamp(3.5, 5.0),
      'reviewCount': 50 + (random * 10),
      'authorId': 'author_${category}_${(index ~/ 5) + 1}',
      'authorName': _generateAuthorName(category, index),
    };
  }

  /// 下厨房风格的菜谱模板数据
  Map<String, List<Map<String, dynamic>>> _getXiachufangRecipeTemplates() {
    return {
      '川菜': [
        {
          'name': '正宗宫保鸡丁',
          'description': '四川传统名菜，麻辣鲜香，鸡肉嫩滑，花生酥脆',
          'cuisine': '川菜',
          'cookingMethod': CookingMethod.stirFry,
          'difficulty': RecipeDifficulty.medium,
          'preparationTime': 20,
          'cookingTime': 15,
          'servings': 3,
          'imageUrl': 'https://images.xiachufang.com/gongbao_chicken.jpg',
          'tags': ['下饭菜', '家常菜', '麻辣', '川菜经典'],
          'ingredients': [
            {'name': '鸡胸肉', 'amount': '300', 'unit': '克', 'isMain': true, 'note': '切丁'},
            {'name': '花生米', 'amount': '80', 'unit': '克', 'isMain': false, 'note': '油炸酥脆'},
            {'name': '干辣椒', 'amount': '10', 'unit': '个', 'isMain': false, 'note': '切段'},
            {'name': '花椒', 'amount': '1', 'unit': '茶匙', 'isMain': false, 'note': null},
          ],
          'steps': [
            {
              'stepNumber': 1,
              'description': '鸡胸肉切成1.5cm见方的丁，用料酒、生抽、蛋清腌制15分钟',
              'estimatedTime': 15,
              'tip': '腌制时间不能太短'
            },
            {
              'stepNumber': 2,
              'description': '热锅下油，爆香花椒和干辣椒段',
              'estimatedTime': 2,
              'tip': '火候不能太大，避免糊锅'
            },
            {
              'stepNumber': 3,
              'description': '下鸡丁大火快炒至变色，加入调料炒匀',
              'estimatedTime': 5,
              'tip': '动作要快，保持鸡肉嫩滑'
            },
          ],
          'nutrition': {
            'calories': 285,
            'protein': 28.5,
            'carbs': 12.8,
            'fat': 14.2,
            'fiber': 2.1,
            'sodium': 680,
            'sugar': 8.5,
            'cholesterol': 75,
          },
          'tasteProfile': ['麻', '辣', '咸', '鲜', '香'],
          'scenarioTags': ['下饭菜', '聚餐', '宵夜'],
          'healthBenefits': ['高蛋白', '补充维生素'],
          'seasonalInfo': {
            'bestSeasons': ['春', '秋', '冬'],
            'seasonalIngredients': ['花生米'],
            'seasonalScore': 0.8,
          },
          'equipment': {
            'required': ['炒锅', '锅铲'],
            'optional': ['料酒壶'],
            'difficultyLevel': '中等',
          },
          'tasteIntensity': {'辣度': 0.7, '麻度': 0.8, '咸度': 0.6, '鲜度': 0.9},
          'spiceLevel': '中辣',
          'origin': '四川',
          'isAuthentic': true,
          'cookingTechniques': ['爆炒', '腌制'],
          'ingredientSubstitutes': {'鸡胸肉': '鸡腿肉'},
          'costEstimate': 25.0,
          'mealTypes': ['午餐', '晚餐'],
        },
        {
          'name': '经典麻婆豆腐',
          'description': '川菜代表菜，豆腐嫩滑，麻辣鲜香，口感层次丰富',
          'cuisine': '川菜',
          'cookingMethod': CookingMethod.braise,
          'difficulty': RecipeDifficulty.easy,
          'preparationTime': 10,
          'cookingTime': 12,
          'servings': 2,
          'imageUrl': 'https://images.xiachufang.com/mapo_tofu.jpg',
          'tags': ['素食可选', '下饭菜', '麻辣', '嫩滑'],
          'ingredients': [
            {'name': '嫩豆腐', 'amount': '1', 'unit': '盒', 'isMain': true, 'note': '切块'},
            {'name': '肉末', 'amount': '100', 'unit': '克', 'isMain': true, 'note': '猪肉末'},
            {'name': '郫县豆瓣酱', 'amount': '2', 'unit': '汤匙', 'isMain': false, 'note': '剁碎'},
            {'name': '花椒粉', 'amount': '1', 'unit': '茶匙', 'isMain': false, 'note': null},
          ],
          'steps': [
            {
              'stepNumber': 1,
              'description': '豆腐用盐水焯烫2分钟，去除豆腥味',
              'estimatedTime': 3,
              'tip': '水开后再放豆腐'
            },
            {
              'stepNumber': 2,
              'description': '热锅下油，爆炒肉末至变色，加入豆瓣酱炒出红油',
              'estimatedTime': 4,
              'tip': '豆瓣酱要炒出香味'
            },
            {
              'stepNumber': 3,
              'description': '加入豆腐块轻轻推炒，调味收汁',
              'estimatedTime': 5,
              'tip': '动作要轻，避免豆腐碎裂'
            },
          ],
          'nutrition': {
            'calories': 195,
            'protein': 15.2,
            'carbs': 8.5,
            'fat': 12.8,
            'fiber': 1.8,
            'sodium': 920,
            'sugar': 3.2,
            'cholesterol': 35,
          },
          'tasteProfile': ['麻', '辣', '鲜', '嫩'],
          'scenarioTags': ['下饭菜', '素食', '家常菜'],
          'healthBenefits': ['补充蛋白质', '低卡路里'],
          'seasonalInfo': {
            'bestSeasons': ['春', '夏', '秋', '冬'],
            'seasonalIngredients': [],
            'seasonalScore': 1.0,
          },
          'equipment': {
            'required': ['平底锅', '锅铲'],
            'optional': [],
            'difficultyLevel': '基础',
          },
          'tasteIntensity': {'辣度': 0.6, '麻度': 0.7, '咸度': 0.8, '鲜度': 0.8},
          'spiceLevel': '中辣',
          'origin': '四川',
          'isAuthentic': true,
          'cookingTechniques': ['爆炒', '焯水'],
          'ingredientSubstitutes': {'肉末': '素肉末（素食版）'},
          'costEstimate': 15.0,
          'mealTypes': ['午餐', '晚餐'],
        },
      ],
      '粤菜': [
        {
          'name': '广式白切鸡',
          'description': '粤菜经典，鸡肉鲜嫩，原汁原味，配蘸料食用',
          'cuisine': '粤菜',
          'cookingMethod': CookingMethod.boil,
          'difficulty': RecipeDifficulty.medium,
          'preparationTime': 15,
          'cookingTime': 25,
          'servings': 4,
          'imageUrl': 'https://images.xiachufang.com/white_cut_chicken.jpg',
          'tags': ['清淡', '原味', '健康', '宴客菜'],
          'ingredients': [
            {'name': '土鸡', 'amount': '1', 'unit': '只', 'isMain': true, 'note': '约1.5公斤'},
            {'name': '生姜', 'amount': '50', 'unit': '克', 'isMain': false, 'note': '切片'},
            {'name': '料酒', 'amount': '2', 'unit': '汤匙', 'isMain': false, 'note': null},
            {'name': '盐', 'amount': '适量', 'unit': '', 'isMain': false, 'note': null},
          ],
          'steps': [
            {
              'stepNumber': 1,
              'description': '整鸡清洗干净，冷水下锅，加姜片和料酒',
              'estimatedTime': 5,
              'tip': '冷水下锅可以去腥'
            },
            {
              'stepNumber': 2,
              'description': '大火烧开后转小火，煮20分钟关火焖5分钟',
              'estimatedTime': 25,
              'tip': '时间要掌握好，避免过老'
            },
            {
              'stepNumber': 3,
              'description': '捞起过冰水定型，切块装盘',
              'estimatedTime': 8,
              'tip': '冰水可以让鸡皮更爽脆'
            },
          ],
          'nutrition': {
            'calories': 165,
            'protein': 25.8,
            'carbs': 0,
            'fat': 6.2,
            'fiber': 0,
            'sodium': 85,
            'sugar': 0,
            'cholesterol': 85,
          },
          'tasteProfile': ['鲜', '清淡', '原味'],
          'scenarioTags': ['宴客', '健康', '清淡'],
          'healthBenefits': ['高蛋白', '低脂肪', '易消化'],
          'seasonalInfo': {
            'bestSeasons': ['春', '夏', '秋'],
            'seasonalIngredients': ['土鸡'],
            'seasonalScore': 0.7,
          },
          'equipment': {
            'required': ['汤锅', '漏勺'],
            'optional': ['冰水盆'],
            'difficultyLevel': '中等',
          },
          'tasteIntensity': {'鲜度': 0.9, '清淡': 0.9, '咸度': 0.3},
          'spiceLevel': '不辣',
          'origin': '广东',
          'isAuthentic': true,
          'cookingTechniques': ['水煮', '冰镇'],
          'ingredientSubstitutes': {'土鸡': '三黄鸡'},
          'costEstimate': 45.0,
          'mealTypes': ['午餐', '晚餐'],
        },
      ],
      '家常菜': [
        {
          'name': '番茄炒蛋',
          'description': '最经典的家常菜，酸甜开胃，营养丰富，老少皆宜',
          'cuisine': '家常菜',
          'cookingMethod': CookingMethod.stirFry,
          'difficulty': RecipeDifficulty.easy,
          'preparationTime': 5,
          'cookingTime': 8,
          'servings': 2,
          'imageUrl': 'https://images.xiachufang.com/tomato_egg.jpg',
          'tags': ['快手菜', '下饭菜', '酸甜', '营养'],
          'ingredients': [
            {'name': '番茄', 'amount': '3', 'unit': '个', 'isMain': true, 'note': '切块'},
            {'name': '鸡蛋', 'amount': '4', 'unit': '个', 'isMain': true, 'note': '打散'},
            {'name': '白糖', 'amount': '1', 'unit': '茶匙', 'isMain': false, 'note': null},
            {'name': '盐', 'amount': '适量', 'unit': '', 'isMain': false, 'note': null},
          ],
          'steps': [
            {
              'stepNumber': 1,
              'description': '鸡蛋加盐打散，热锅下油炒熟盛起',
              'estimatedTime': 3,
              'tip': '鸡蛋要炒得嫩一些'
            },
            {'stepNumber': 2, 'description': '番茄下锅炒出汁水，加糖调味', 'estimatedTime': 3, 'tip': '糖可以中和酸味'},
            {
              'stepNumber': 3,
              'description': '倒入炒蛋快速翻炒均匀即可',
              'estimatedTime': 2,
              'tip': '最后炒制时间不要太长'
            },
          ],
          'nutrition': {
            'calories': 142,
            'protein': 12.5,
            'carbs': 8.2,
            'fat': 7.8,
            'fiber': 2.1,
            'sodium': 245,
            'sugar': 6.8,
            'cholesterol': 375,
          },
          'tasteProfile': ['酸', '甜', '鲜'],
          'scenarioTags': ['快手菜', '下饭菜', '儿童'],
          'healthBenefits': ['维生素C', '蛋白质', '胡萝卜素'],
          'seasonalInfo': {
            'bestSeasons': ['夏', '秋'],
            'seasonalIngredients': ['番茄'],
            'seasonalScore': 0.8,
          },
          'equipment': {
            'required': ['炒锅', '锅铲'],
            'optional': [],
            'difficultyLevel': '基础',
          },
          'tasteIntensity': {'酸度': 0.6, '甜度': 0.5, '鲜度': 0.7},
          'spiceLevel': '不辣',
          'origin': '中国',
          'isAuthentic': true,
          'cookingTechniques': ['炒制'],
          'ingredientSubstitutes': {'白糖': '番茄酱'},
          'costEstimate': 8.0,
          'mealTypes': ['早餐', '午餐', '晚餐'],
        },
      ],
    };
  }

  /// 获取菜谱分类列表
  Future<List<String>> _getCategoryList() async {
    // 模拟获取分类数据
    return ['川菜', '粤菜', '湘菜', '鲁菜', '苏菜', '浙菜', '闽菜', '徽菜', '家常菜', '素食'];
  }

  /// 生成作者名称
  String _generateAuthorName(String category, int index) {
    final authorNames = [
      '美食达人小王',
      '厨房新手',
      '川菜师傅',
      '粤菜大厨',
      '家常菜妈妈',
      '素食主义者',
      '健康料理师',
      '烘焙爱好者',
      '营养师小李',
      '美食博主'
    ];
    return authorNames[(category.hashCode + index) % authorNames.length];
  }

  /// 下载菜谱图片
  Future<void> _downloadRecipeImages(Recipe recipe) async {
    try {
      // 模拟图片下载
      await Future.delayed(Duration(milliseconds: 200));
      debugPrint('📸 已下载菜谱图片: ${recipe.name}');
    } catch (e) {
      debugPrint('⚠️ 图片下载失败: ${recipe.name} - $e');
    }
  }

  /// 保存爬取的数据
  Future<void> _saveCrawledData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/xiachufang_recipes.json');

      final data = {
        'metadata': {
          'crawlTime': DateTime.now().toIso8601String(),
          'totalRecipes': _crawledRecipes.length,
          'version': '1.0',
        },
        'recipes': _crawledRecipes.map((r) => r.toJson()).toList(),
      };

      await file.writeAsString(jsonEncode(data), flush: true);
      debugPrint('💾 菜谱数据已保存到: ${file.path}');
    } catch (e) {
      debugPrint('❌ 保存数据失败: $e');
    }
  }

  /// 计算爬取耗时
  Duration? _calculateDuration() {
    final startTimeStr = _crawlStats['startTime'];
    final endTimeStr = _crawlStats['endTime'];

    if (startTimeStr != null && endTimeStr != null) {
      final startTime = DateTime.parse(startTimeStr);
      final endTime = DateTime.parse(endTimeStr);
      return endTime.difference(startTime);
    }

    return null;
  }

  /// 清理爬取数据
  void clearCrawledData() {
    _crawledRecipes.clear();
    _crawlStats.clear();
    debugPrint('🗑️ 已清理爬取数据');
  }

  /// 获取菜谱数据摘要
  Map<String, dynamic> getDataSummary() {
    final cuisineCount = <String, int>{};
    final difficultyCount = <String, int>{};

    for (final recipe in _crawledRecipes) {
      cuisineCount[recipe.cuisine] = (cuisineCount[recipe.cuisine] ?? 0) + 1;
      difficultyCount[recipe.difficulty.label] =
          (difficultyCount[recipe.difficulty.label] ?? 0) + 1;
    }

    return {
      'totalRecipes': _crawledRecipes.length,
      'cuisineDistribution': cuisineCount,
      'difficultyDistribution': difficultyCount,
      'averageRating': _crawledRecipes.isEmpty
          ? 0.0
          : _crawledRecipes.map((r) => r.rating).reduce((a, b) => a + b) / _crawledRecipes.length,
      'crawlStats': _crawlStats,
    };
  }
}

/// 爬取结果数据模型
class CrawlResult {
  final bool success;
  final String message;
  final int recipesCount;
  final List<String>? categories;
  final Duration? duration;

  CrawlResult({
    required this.success,
    required this.message,
    required this.recipesCount,
    this.categories,
    this.duration,
  });

  @override
  String toString() =>
      'CrawlResult(success: $success, recipes: $recipesCount, duration: ${duration?.inSeconds}s)';
}
