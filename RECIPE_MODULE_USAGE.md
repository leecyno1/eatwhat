# 菜谱模块使用说明

## 概述

《吃什么》应用的菜谱模块已完成重构，基于下厨房数据结构设计，提供现代化的菜谱浏览和管理功能。

## 核心组件

### 1. 数据模型

#### EnhancedRecipe
- **位置**: `lib/core/models/enhanced_recipe.dart`
- **功能**: 完整的菜谱数据模型，包含25+字段
- **特性**: 
  - 支持从下厨房数据创建 (`fromXiachufangData`)
  - 完整的JSON序列化
  - 营养信息、制作步骤、食材清单等

#### 数据结构示例
```dart
EnhancedRecipe(
  id: 'recipe_001',
  name: '红烧肉',
  description: '经典家常菜，色泽红润，肥而不腻',
  rating: 4.8,
  difficulty: RecipeDifficulty.medium,
  totalTime: Duration(minutes: 90),
  ingredients: [
    RecipeIngredient(name: '五花肉', amount: '500', unit: '克'),
    // ...
  ],
  steps: [
    RecipeStep(order: 1, description: '五花肉切块，冷水下锅焯水'),
    // ...
  ]
)
```

### 2. 服务层

#### FirecrawlRecipeCrawlerService
- **位置**: `lib/core/services/firecrawl_recipe_crawler_service.dart`
- **功能**: 使用Firecrawl抓取下厨房菜谱数据
- **特性**:
  - 批量抓取支持
  - 进度监控
  - 错误处理与重试
  - 数据清洗与验证

#### 使用示例
```dart
final crawler = FirecrawlRecipeCrawlerService.instance;
await crawler.initialize();

final result = await crawler.startCrawling(
  categories: ['家常菜', '快手菜'],
  maxRecipes: 100,
);

print('抓取完成: ${result.recipes.length} 个菜谱');
```

### 3. 状态管理

#### EnhancedRecipeController
- **位置**: `lib/features/recipe/controllers/enhanced_recipe_controller.dart`
- **功能**: 菜谱数据状态管理
- **特性**:
  - 推荐菜谱加载
  - 分类筛选
  - 搜索功能
  - 收藏管理
  - 分页加载

#### 主要方法
```dart
// 加载推荐菜谱
await controller.loadRecommendedRecipes();

// 按分类加载
await controller.loadRecipesByCategory(RecipeCategory.homeStyle);

// 搜索菜谱
await controller.searchRecipes('红烧肉');

// 同步数据
await controller.syncRecipeData();
```

### 4. 用户界面

#### ModernRecipeBrowserScreen
- **位置**: `lib/features/recipe/screens/modern_recipe_browser_screen.dart`
- **功能**: 现代化菜谱浏览界面
- **特性**:
  - 网格/列表视图切换
  - 实时搜索
  - 分类标签页
  - 抓取进度对话框
  - 玻璃态设计

#### CompleteRecipeDetailScreen  
- **位置**: `lib/features/recipe/screens/complete_recipe_detail_screen.dart`
- **功能**: 完整菜谱详情页
- **特性**:
  - 沉浸式图片头部
  - 详细制作步骤
  - 营养信息展示
  - 收藏与分享功能

## 路由配置

新增路由路径：
- `/recipes` - 菜谱浏览页面
- `/recipe/:id` - 菜谱详情页面

### 导航示例
```dart
// 跳转到菜谱浏览
context.go('/recipes');

// 跳转到菜谱详情
context.go('/recipe/recipe_001');
```

## 集成方式

### 1. Provider注册

在`main.dart`中已经注册：
```dart
ChangeNotifierProvider(
  create: (context) => EnhancedRecipeController()..initialize(),
)
```

### 2. 使用Controller

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedRecipeController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return CircularProgressIndicator();
        }
        
        return ListView.builder(
          itemCount: controller.recipes.length,
          itemBuilder: (context, index) {
            final recipe = controller.recipes[index];
            return RecipeCard(recipe: recipe);
          },
        );
      },
    );
  }
}
```

## 开发指南

### 1. 添加新的菜谱分类

在`enhanced_recipe.dart`中的`RecipeCategory`枚举添加：
```dart
enum RecipeCategory {
  // 现有分类...
  newCategory('新分类');
}
```

### 2. 扩展搜索功能

在`EnhancedRecipeController`的`_performLocalSearch`方法中添加新的搜索条件。

### 3. 自定义抓取规则

在`FirecrawlRecipeCrawlerService`中修改解析方法：
- `_parseRecipeContent` - 主解析逻辑
- `_extractRecipeName` - 名称提取
- `_extractIngredients` - 食材提取
- `_extractSteps` - 步骤提取

## 性能优化

### 1. 缓存策略
- 菜谱数据本地缓存
- 图片懒加载
- 分页加载减少内存占用

### 2. 网络优化
- 批量API请求
- 请求去重
- 错误重试机制

### 3. UI优化
- 虚拟滚动列表
- 图片占位符
- 骨架屏加载

## 错误处理

所有组件都集成了全局错误处理：
- 网络错误自动重试
- 数据解析错误优雅降级
- UI错误边界保护
- 详细日志记录

## 测试

### 单元测试
```bash
flutter test test/recipe/
```

### 集成测试
```bash
flutter test integration_test/recipe/
```

## 未来扩展

1. **离线支持**: 菜谱数据离线缓存
2. **AI推荐**: 基于用户偏好的智能推荐
3. **社交功能**: 用户评论、点赞、分享
4. **购物清单**: 一键生成食材清单
5. **营养分析**: 详细营养成分分析

## 注意事项

1. Firecrawl服务需要有效的API密钥
2. 下厨房数据抓取请遵守robots.txt规则
3. 大量数据操作建议在后台线程执行
4. 图片资源较大，注意网络流量优化

## 支持

如有问题，请查看：
1. 代码中的注释和文档
2. `advanced_logger.dart` 中的日志输出
3. `global_error_handler.dart` 中的错误信息