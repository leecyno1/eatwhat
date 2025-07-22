import 'package:flutter/material.dart';
import 'lib/core/models/recipe.dart';
import 'lib/core/services/recipe_database_service.dart';

void main() async {
  // 测试菜谱数据库服务
  print('🧪 开始测试菜谱系统...');
  
  final recipeService = RecipeDatabaseService();
  
  try {
    // 初始化数据库
    print('📚 初始化菜谱数据库...');
    await recipeService.initialize();
    
    // 获取所有菜谱
    print('📋 获取所有菜谱...');
    final allRecipes = await recipeService.getAllRecipes();
    print('✅ 成功加载 ${allRecipes.length} 个菜谱');
    
    // 显示菜谱列表
    for (var recipe in allRecipes) {
      print('🍽️ ${recipe.name} - ${recipe.cuisine} | ${recipe.difficulty.label} | ${recipe.rating}⭐');
    }
    
    // 测试推荐算法
    print('\n🎯 测试推荐算法...');
    final recommendations = await recipeService.getRecommendedRecipes(limit: 3);
    print('✅ 推荐算法返回 ${recommendations.length} 个菜谱');
    
    // 测试搜索功能
    print('\n🔍 测试搜索功能...');
    final searchResults = await recipeService.searchRecipes(query: '川菜');
    print('✅ 搜索"川菜"返回 ${searchResults.length} 个结果');
    
    // 测试收藏功能
    print('\n❤️ 测试收藏功能...');
    await recipeService.toggleFavorite(allRecipes.first.id);
    print('✅ 收藏功能测试完成');
    
    // 测试快手菜筛选
    print('\n⚡ 测试快手菜筛选...');
    final quickRecipes = await recipeService.getQuickRecipes();
    print('✅ 找到 ${quickRecipes.length} 个快手菜');
    
    print('\n🎉 所有测试完成！菜谱系统功能正常');
    
  } catch (e) {
    print('❌ 测试失败: $e');
  }
}

// 运行测试的简单方法
class RecipeTestRunner {
  static Future<void> runTests() async {
    await main();
  }
}