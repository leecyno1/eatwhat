import 'lib/core/services/real_xiachufang_crawler_service.dart';

void main() async {
  print('🚀 开始测试真实下厨房数据爬取服务...');

  final crawler = RealXiachufangCrawlerService();

  try {
    // 初始化爬虫服务
    print('\n🔧 正在初始化爬虫服务...');
    await crawler.initialize();
    print('✅ 爬虫服务初始化完成');

    // 测试爬取菜谱（使用小批量测试）
    print('\n📖 正在爬取菜谱数据...');
    final result = await crawler.crawlRecipes(
      categories: ['home-cooking'], // 只测试家常菜分类
      targetCount: 5, // 仅爬取5个菜谱用于测试
      onProgress: (message) => print('📈 $message'),
    );

    print('✅ 爬取结果: ${result.success ? "成功" : "失败"}');
    print('💬 消息: ${result.message}');
    print('📊 爬取到 ${result.recipesCount} 个菜谱');
    if (result.duration != null) {
      print('⏱️ 耗时: ${result.duration!.inSeconds} 秒');
    }

    // 获取已爬取的菜谱数据
    final recipes = crawler.crawledRecipes;
    print('\n📚 已爬取的菜谱总数: ${recipes.length}');

    // 显示前几个菜谱的信息
    for (int i = 0; i < recipes.length && i < 3; i++) {
      final recipe = recipes[i];
      print('\n${i + 1}. 菜谱: ${recipe.name}');
      print(
          '   📝 描述: ${recipe.description.length > 50 ? recipe.description.substring(0, 50) + '...' : recipe.description}');
      print('   ⏱️ 烹饪时间: ${recipe.cookingTime}');
      print('   👥 份量: ${recipe.servings}');
      print('   🔥 步骤数量: ${recipe.steps.length}');
      print('   🥬 食材数量: ${recipe.ingredients.length}');
      print('   🏷️ 菜系: ${recipe.cuisine}');

      // 显示第一个步骤
      if (recipe.steps.isNotEmpty) {
        print('   📋 第一步: ${recipe.steps[0].description}');
      }

      // 显示第一个食材
      if (recipe.ingredients.isNotEmpty) {
        print('   🥬 首个食材: ${recipe.ingredients[0].name} - ${recipe.ingredients[0].amount}');
      }
    }

    // 显示爬取统计
    final stats = crawler.crawlStatistics;
    if (stats.isNotEmpty) {
      print('\n📈 爬取统计:');
      stats.forEach((key, value) {
        print('   $key: $value');
      });
    }

    print('\n🎉 爬虫测试完成!');
    print('📄 数据已保存到本地文件，可用于后续开发');
  } catch (e, stackTrace) {
    print('❌ 测试过程中发生错误: $e');
    print('📚 错误堆栈: $stackTrace');
  }
}
