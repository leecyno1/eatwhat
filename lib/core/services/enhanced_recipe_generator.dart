import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../models/recipe.dart';
import 'xiachufang_crawler_service.dart';

/// 增强菜谱数据生成服务
/// 生成大量高质量的菜谱数据用于测试和开发
class EnhancedRecipeGenerator {
  static final EnhancedRecipeGenerator _instance = EnhancedRecipeGenerator._internal();
  factory EnhancedRecipeGenerator() => _instance;
  EnhancedRecipeGenerator._internal();

  final XiachufangCrawlerService _crawlerService = XiachufangCrawlerService();
  final Random _random = Random();

  /// 生成大量菜谱数据
  Future<List<Recipe>> generateRecipes({
    int targetCount = 1000,
    bool includeImages = true,
    Function(int current, int total)? onProgress,
  }) async {
    debugPrint('🚀 开始生成 $targetCount 个菜谱数据...');

    await _crawlerService.initialize();

    final recipes = <Recipe>[];
    final categories = _getExtendedCategories();
    final recipesPerCategory = (targetCount / categories.length).ceil();

    int currentCount = 0;

    for (int categoryIndex = 0; categoryIndex < categories.length; categoryIndex++) {
      final category = categories[categoryIndex];

      for (int i = 0; i < recipesPerCategory && currentCount < targetCount; i++) {
        try {
          final recipe = await _generateEnhancedRecipe(category, currentCount);
          recipes.add(recipe);
          currentCount++;

          // 进度回调
          onProgress?.call(currentCount, targetCount);

          // 每100个菜谱打印一次进度
          if (currentCount % 100 == 0) {
            debugPrint('📈 已生成 $currentCount/$targetCount 个菜谱');
          }
        } catch (e) {
          debugPrint('⚠️ 生成菜谱失败: $category-$i, 错误: $e');
        }
      }
    }

    debugPrint('🎉 菜谱数据生成完成！总计: ${recipes.length} 个');

    // 保存到本地文件
    await _saveRecipesToFile(recipes);

    return recipes;
  }

  /// 获取扩展的菜系分类
  List<String> _getExtendedCategories() {
    return [
      // 八大菜系
      '川菜', '粤菜', '湘菜', '鲁菜', '苏菜', '浙菜', '闽菜', '徽菜',
      // 地方特色菜
      '东北菜', '新疆菜', '西藏菜', '云南菜', '贵州菜', '广西菜', '海南菜',
      // 功能分类
      '家常菜', '素食', '甜品', '汤类', '面食', '米饭类', '小吃',
      // 国际菜系
      '日式料理', '韩式料理', '意大利菜', '法式料理', '泰式料理',
      // 特殊需求
      '减脂菜', '孕妇菜', '儿童菜', '老人菜', '糖尿病友好'
    ];
  }

  /// 生成增强版菜谱
  Future<Recipe> _generateEnhancedRecipe(String category, int index) async {
    final templates = _getEnhancedRecipeTemplates();
    final categoryTemplates = templates[category] ?? templates['家常菜']!;
    final baseTemplate = categoryTemplates[index % categoryTemplates.length];

    // 添加随机变化和个性化
    final enhanced = _enhanceRecipeTemplate(baseTemplate, category, index);

    return Recipe(
      id: 'enhanced_${category}_${index.toString().padLeft(4, '0')}',
      name: enhanced['name'],
      description: enhanced['description'],
      cuisine: category,
      cookingMethod: enhanced['cookingMethod'],
      difficulty: enhanced['difficulty'],
      preparationTime: enhanced['preparationTime'],
      cookingTime: enhanced['cookingTime'],
      servings: enhanced['servings'],
      imageUrl: enhanced['imageUrl'],
      tags: List<String>.from(enhanced['tags']),
      ingredients:
          (enhanced['ingredients'] as List).map((i) => RecipeIngredient.fromJson(i)).toList(),
      steps: (enhanced['steps'] as List).map((s) => CookingStep.fromJson(s)).toList(),
      nutrition: NutritionInfo.fromJson(enhanced['nutrition']),
      rating: enhanced['rating'],
      reviewCount: enhanced['reviewCount'],
      authorId: enhanced['authorId'],
      authorName: enhanced['authorName'],
      createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
      updatedAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
      // Phase 2 增强字段
      tasteProfile: List<String>.from(enhanced['tasteProfile']),
      scenarioTags: List<String>.from(enhanced['scenarioTags']),
      healthBenefits: List<String>.from(enhanced['healthBenefits']),
      seasonalInfo: SeasonalInfo.fromJson(enhanced['seasonalInfo']),
      equipment: CookingEquipment.fromJson(enhanced['equipment']),
      tasteIntensity: Map<String, double>.from(enhanced['tasteIntensity']),
      spiceLevel: enhanced['spiceLevel'],
      origin: enhanced['origin'],
      isAuthentic: enhanced['isAuthentic'],
      cookingTechniques: List<String>.from(enhanced['cookingTechniques']),
      ingredientSubstitutes: Map<String, String>.from(enhanced['ingredientSubstitutes']),
      costEstimate: enhanced['costEstimate'],
      mealTypes: List<String>.from(enhanced['mealTypes']),
    );
  }

  /// 增强菜谱模板
  Map<String, dynamic> _enhanceRecipeTemplate(
      Map<String, dynamic> baseTemplate, String category, int index) {
    final enhanced = Map<String, dynamic>.from(baseTemplate);

    // 随机化评分和评论数
    enhanced['rating'] = 3.5 + _random.nextDouble() * 1.5;
    enhanced['reviewCount'] = 10 + _random.nextInt(1000);

    // 个性化作者信息
    enhanced['authorId'] = 'author_${category}_${(index ~/ 10) + 1}';
    enhanced['authorName'] = _generateRandomAuthorName(category);

    // 随机化营养信息
    _randomizeNutrition(enhanced);

    // 随机化成本
    enhanced['costEstimate'] = 5.0 + _random.nextDouble() * 50.0;

    return enhanced;
  }

  /// 生成随机作者名称
  String _generateRandomAuthorName(String category) {
    final prefixes = ['美食达人', '厨房新手', '料理专家', '家庭主厨', '营养师'];
    final names = ['小王', '小李', '小张', '小刘', '小陈', '小赵', '小吴', '小周'];
    final suffixes = ['的厨房', '爱料理', '美食记', '私房菜', '创意菜'];

    if (_random.nextBool()) {
      return '${prefixes[_random.nextInt(prefixes.length)]}${names[_random.nextInt(names.length)]}';
    } else {
      return '${names[_random.nextInt(names.length)]}${suffixes[_random.nextInt(suffixes.length)]}';
    }
  }

  /// 随机化营养信息
  void _randomizeNutrition(Map<String, dynamic> template) {
    final nutrition = template['nutrition'] as Map<String, dynamic>;

    // 在基础值上添加随机变化
    nutrition['calories'] =
        (nutrition['calories'] as num).toDouble() * (0.8 + _random.nextDouble() * 0.4);
    nutrition['protein'] =
        (nutrition['protein'] as num).toDouble() * (0.8 + _random.nextDouble() * 0.4);
    nutrition['carbs'] =
        (nutrition['carbs'] as num).toDouble() * (0.8 + _random.nextDouble() * 0.4);
    nutrition['fat'] = (nutrition['fat'] as num).toDouble() * (0.8 + _random.nextDouble() * 0.4);
  }

  /// 获取增强版菜谱模板
  Map<String, List<Map<String, dynamic>>> _getEnhancedRecipeTemplates() {
    return {
      // 川菜扩展
      '川菜': [
        _createRecipeTemplate('水煮鱼', '川菜', CookingMethod.boil, RecipeDifficulty.hard,
            ['麻', '辣', '鲜'], ['下饭菜', '聚餐'], 35, 25),
        _createRecipeTemplate('回锅肉', '川菜', CookingMethod.stirFry, RecipeDifficulty.medium,
            ['香', '辣', '咸'], ['下饭菜'], 15, 20),
        _createRecipeTemplate('夫妻肺片', '川菜', CookingMethod.coldMix, RecipeDifficulty.medium,
            ['麻', '辣', '香'], ['凉菜', '开胃'], 30, 0),
        _createRecipeTemplate('蚂蚁上树', '川菜', CookingMethod.stirFry, RecipeDifficulty.easy,
            ['香', '辣'], ['下饭菜'], 10, 15),
      ],

      // 粤菜扩展
      '粤菜': [
        _createRecipeTemplate('白灼虾', '粤菜', CookingMethod.boil, RecipeDifficulty.easy, ['鲜', '清淡'],
            ['宴客', '健康'], 5, 8),
        _createRecipeTemplate('蒜蓉蒸扇贝', '粤菜', CookingMethod.steam, RecipeDifficulty.medium,
            ['鲜', '香'], ['宴客'], 15, 10),
        _createRecipeTemplate(
            '广式烧鸭', '粤菜', CookingMethod.grill, RecipeDifficulty.hard, ['香', '甜'], ['宴客'], 60, 120),
      ],

      // 素食
      '素食': [
        _createRecipeTemplate('红烧豆腐', '素食', CookingMethod.braise, RecipeDifficulty.easy, ['咸', '鲜'],
            ['素食', '健康'], 10, 15),
        _createRecipeTemplate('素炒三丝', '素食', CookingMethod.stirFry, RecipeDifficulty.easy,
            ['清淡', '鲜'], ['素食', '减脂'], 8, 5),
        _createRecipeTemplate('麻婆豆腐（素版）', '素食', CookingMethod.braise, RecipeDifficulty.medium,
            ['麻', '辣'], ['素食', '下饭菜'], 15, 12),
      ],

      // 减脂菜
      '减脂菜': [
        _createRecipeTemplate('蒸蛋羹', '减脂菜', CookingMethod.steam, RecipeDifficulty.easy, ['清淡', '嫩'],
            ['减脂', '健康'], 5, 10),
        _createRecipeTemplate('凉拌黄瓜', '减脂菜', CookingMethod.coldMix, RecipeDifficulty.easy,
            ['清爽', '酸'], ['减脂', '凉菜'], 10, 0),
        _createRecipeTemplate('清蒸鲈鱼', '减脂菜', CookingMethod.steam, RecipeDifficulty.medium,
            ['鲜', '清淡'], ['减脂', '高蛋白'], 15, 12),
      ],

      // 家常菜扩展
      '家常菜': [
        _createRecipeTemplate(
            '糖醋里脊', '家常菜', CookingMethod.fry, RecipeDifficulty.medium, ['酸', '甜'], ['下饭菜'], 20, 15),
        _createRecipeTemplate('可乐鸡翅', '家常菜', CookingMethod.braise, RecipeDifficulty.easy,
            ['甜', '香'], ['下饭菜', '儿童'], 10, 25),
        _createRecipeTemplate('蒜苔炒肉', '家常菜', CookingMethod.stirFry, RecipeDifficulty.easy,
            ['香', '咸'], ['下饭菜'], 10, 8),
      ],

      // 甜品
      '甜品': [
        _createRecipeTemplate(
            '红豆沙', '甜品', CookingMethod.boil, RecipeDifficulty.easy, ['甜', '香'], ['甜品'], 10, 60),
        _createRecipeTemplate(
            '双皮奶', '甜品', CookingMethod.steam, RecipeDifficulty.medium, ['甜', '嫩'], ['甜品'], 15, 30),
        _createRecipeTemplate(
            '芒果布丁', '甜品', CookingMethod.steam, RecipeDifficulty.easy, ['甜', '清香'], ['甜品'], 20, 240),
      ],
    };
  }

  /// 创建菜谱模板的辅助方法
  Map<String, dynamic> _createRecipeTemplate(
    String name,
    String cuisine,
    CookingMethod method,
    RecipeDifficulty difficulty,
    List<String> tasteProfile,
    List<String> scenarioTags,
    int prepTime,
    int cookTime,
  ) {
    return {
      'name': name,
      'description': '精心制作的$name，味道正宗，营养丰富',
      'cuisine': cuisine,
      'cookingMethod': method,
      'difficulty': difficulty,
      'preparationTime': prepTime,
      'cookingTime': cookTime,
      'servings': 2 + _random.nextInt(4),
      'imageUrl': 'https://images.xiachufang.com/${name.toLowerCase().replaceAll(' ', '_')}.jpg',
      'tags': [...tasteProfile, ...scenarioTags, '美味'],
      'ingredients': _generateRandomIngredients(5 + _random.nextInt(8)),
      'steps': _generateRandomSteps(3 + _random.nextInt(5)),
      'nutrition': _generateRandomNutrition(),
      'rating': 4.0 + _random.nextDouble(),
      'reviewCount': 20 + _random.nextInt(500),
      'authorId': 'generated_author',
      'authorName': '美食达人',
      'tasteProfile': tasteProfile,
      'scenarioTags': scenarioTags,
      'healthBenefits': _generateHealthBenefits(),
      'seasonalInfo': _generateSeasonalInfo(),
      'equipment': _generateEquipment(),
      'tasteIntensity': _generateTasteIntensity(tasteProfile),
      'spiceLevel': _getSpiceLevel(tasteProfile),
      'origin': _getOriginFromCuisine(cuisine),
      'isAuthentic': _random.nextBool(),
      'cookingTechniques': _generateCookingTechniques(method),
      'ingredientSubstitutes': {},
      'costEstimate': 10.0 + _random.nextDouble() * 30.0,
      'mealTypes': _generateMealTypes(),
    };
  }

  /// 生成随机食材
  List<Map<String, dynamic>> _generateRandomIngredients(int count) {
    final commonIngredients = [
      '猪肉',
      '牛肉',
      '鸡肉',
      '鸡蛋',
      '豆腐',
      '土豆',
      '番茄',
      '洋葱',
      '大蒜',
      '生姜',
      '青椒',
      '胡萝卜',
      '白菜',
      '韭菜',
      '豆芽',
      '香菇'
    ];

    final ingredients = <Map<String, dynamic>>[];
    for (int i = 0; i < count; i++) {
      ingredients.add({
        'name': commonIngredients[_random.nextInt(commonIngredients.length)],
        'amount': (50 + _random.nextInt(200)).toString(),
        'unit': ['克', '个', '汤匙', '茶匙'][_random.nextInt(4)],
        'isMain': i < 2,
        'note': null,
      });
    }
    return ingredients;
  }

  /// 生成随机烹饪步骤
  List<Map<String, dynamic>> _generateRandomSteps(int count) {
    final stepTemplates = ['准备所有食材，清洗干净', '热锅下油，爆香蒜姜', '加入主料翻炒至变色', '调入调料，继续翻炒', '最后调味装盘即可'];

    final steps = <Map<String, dynamic>>[];
    for (int i = 0; i < count; i++) {
      steps.add({
        'stepNumber': i + 1,
        'description': stepTemplates[i % stepTemplates.length],
        'estimatedTime': 2 + _random.nextInt(8),
        'tip': '注意火候控制',
      });
    }
    return steps;
  }

  /// 生成随机营养信息
  Map<String, dynamic> _generateRandomNutrition() {
    return {
      'calories': 150.0 + _random.nextDouble() * 200.0,
      'protein': 10.0 + _random.nextDouble() * 25.0,
      'carbs': 15.0 + _random.nextDouble() * 30.0,
      'fat': 5.0 + _random.nextDouble() * 20.0,
      'fiber': 1.0 + _random.nextDouble() * 5.0,
      'sodium': 300.0 + _random.nextDouble() * 700.0,
      'sugar': 2.0 + _random.nextDouble() * 15.0,
      'cholesterol': _random.nextDouble() * 100.0,
      'calcium': 50.0 + _random.nextDouble() * 200.0,
      'iron': 2.0 + _random.nextDouble() * 8.0,
      'vitaminC': 5.0 + _random.nextDouble() * 50.0,
    };
  }

  /// 生成健康功效
  List<String> _generateHealthBenefits() {
    final benefits = ['补充蛋白质', '维生素丰富', '低脂肪', '高纤维', '抗氧化', '补血', '美容'];
    return benefits.take(2 + _random.nextInt(3)).toList();
  }

  /// 生成季节信息
  Map<String, dynamic> _generateSeasonalInfo() {
    final seasons = ['春', '夏', '秋', '冬'];
    final selectedSeasons = seasons.where((_) => _random.nextBool()).toList();

    return {
      'bestSeasons': selectedSeasons.isEmpty ? ['春', '夏', '秋', '冬'] : selectedSeasons,
      'seasonalIngredients': [],
      'seasonalScore': 0.5 + _random.nextDouble() * 0.5,
    };
  }

  /// 生成厨具要求
  Map<String, dynamic> _generateEquipment() {
    final requiredEquipment = ['炒锅', '锅铲', '菜刀', '砧板'];
    final optionalEquipment = ['蒸锅', '电饭煲', '微波炉'];

    return {
      'required': requiredEquipment.take(2 + _random.nextInt(3)).toList(),
      'optional': optionalEquipment.take(_random.nextInt(2)).toList(),
      'difficultyLevel': ['基础', '中等', '高级'][_random.nextInt(3)],
    };
  }

  /// 生成口味强度
  Map<String, double> _generateTasteIntensity(List<String> tasteProfile) {
    final intensity = <String, double>{};
    for (final taste in tasteProfile) {
      intensity['${taste}度'] = 0.3 + _random.nextDouble() * 0.7;
    }
    return intensity;
  }

  /// 获取辣度等级
  String _getSpiceLevel(List<String> tasteProfile) {
    if (tasteProfile.contains('辣')) {
      return ['微辣', '中辣', '重辣'][_random.nextInt(3)];
    }
    return '不辣';
  }

  /// 从菜系获取起源地
  String _getOriginFromCuisine(String cuisine) {
    final origins = {
      '川菜': '四川',
      '粤菜': '广东',
      '湘菜': '湖南',
      '鲁菜': '山东',
      '素食': '中国',
      '减脂菜': '现代',
      '家常菜': '中国',
      '甜品': '中国'
    };
    return origins[cuisine] ?? '中国';
  }

  /// 生成烹饪技巧
  List<String> _generateCookingTechniques(CookingMethod method) {
    final techniques = {
      CookingMethod.stirFry: ['爆炒', '快炒', '调味'],
      CookingMethod.steam: ['蒸制', '调味'],
      CookingMethod.boil: ['水煮', '调味'],
      CookingMethod.braise: ['焖煮', '调色', '调味'],
    };
    return techniques[method] ?? ['调味'];
  }

  /// 生成餐类
  List<String> _generateMealTypes() {
    final mealTypes = ['早餐', '午餐', '晚餐', '夜宵'];
    return mealTypes.where((_) => _random.nextBool()).toList();
  }

  /// 保存菜谱到文件
  Future<void> _saveRecipesToFile(List<Recipe> recipes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file =
          File('${directory.path}/enhanced_recipes_${DateTime.now().millisecondsSinceEpoch}.json');

      final data = {
        'metadata': {
          'generateTime': DateTime.now().toIso8601String(),
          'totalRecipes': recipes.length,
          'version': '2.0',
          'generator': 'EnhancedRecipeGenerator',
        },
        'recipes': recipes.map((r) => r.toJson()).toList(),
      };

      await file.writeAsString(jsonEncode(data), flush: true);
      debugPrint('💾 增强菜谱数据已保存到: ${file.path}');
    } catch (e) {
      debugPrint('❌ 保存增强菜谱数据失败: $e');
    }
  }
}
