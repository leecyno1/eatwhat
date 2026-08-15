# 集成测试编写指南

## 基本结构

集成测试测试整个应用或多个功能模块的交互。放在 `integration_test/` 目录下。

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:eatwhat_app/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('端到端测试', () {
    testWidgets('完整的用户流程', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(const MyApp());
      
      // 验证首页显示
      expect(find.text('首页'), findsOneWidget);
    });
  });
}
```

## 示例1：新手引导流程

```dart
testWidgets('新手引导应该正常显示', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
  
  // 验证首次启动时显示引导
  expect(find.text('长按可以收藏'), findsOneWidget);
  
  // 点击"下一步"
  await tester.tap(find.byType(ElevatedButton).first);
  await tester.pumpAndSettle();
  
  // 验证下一步的内容
  expect(find.text('向上滑动表示喜欢'), findsOneWidget);
  
  // 点击"跳过"
  await tester.tap(find.text('跳过'));
  await tester.pumpAndSettle();
  
  // 验证引导关闭
  expect(find.text('长按可以收藏'), findsNothing);
});
```

## 示例2：气泡交互流程

```dart
testWidgets('气泡滑动交互应该正常工作', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
  
  // 找到气泡widget
  final bubbleWidget = find.byType(BubbleWidget);
  expect(bubbleWidget, findsOneWidget);
  
  // 向上滑动（表示喜欢）
  await tester.drag(bubbleWidget, const Offset(0, -200));
  await tester.pumpAndSettle();
  
  // 验证显示下一个气泡
  expect(find.byType(BubbleWidget), findsOneWidget);
  
  // 向下滑动（表示不喜欢）
  await tester.drag(bubbleWidget, const Offset(0, 200));
  await tester.pumpAndSettle();
  
  // 验证又显示新的气泡
  expect(find.byType(BubbleWidget), findsOneWidget);
});
```

## 示例3：推荐到下单完整流程

```dart
testWidgets('从推荐到加入购物车的完整流程', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
  
  // 第1步：完成气泡选择
  await _completeBubbleSelection(tester);
  
  // 第2步：验证推荐结果显示
  expect(find.text('推荐结果'), findsOneWidget);
  expect(find.byType(FoodCard), findsWidgets);
  
  // 第3步：点击第一个菜品
  await tester.tap(find.byType(FoodCard).first);
  await tester.pumpAndSettle();
  
  // 第4步：验证详情页显示
  expect(find.text('加入购物车'), findsOneWidget);
  
  // 第5步：加入购物车
  await tester.tap(find.text('加入购物车'));
  await tester.pumpAndSettle();
  
  // 第6步：验证购物车更新
  expect(find.text('购物车(1)'), findsOneWidget);
  
  // 第7步：打开购物车
  await tester.tap(find.text('购物车(1)'));
  await tester.pumpAndSettle();
  
  // 第8步：验证购物车内容
  expect(find.text('结算'), findsOneWidget);
});

Future<void> _completeBubbleSelection(WidgetTester tester) async {
  for (int i = 0; i < 3; i++) {
    await tester.drag(
      find.byType(BubbleWidget),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
  }
}
```

## 测试工具方法

### 常用查找器 (Finder)

```dart
find.text('按钮文字')                  // 按文本查找
find.byType(ElevatedButton)           // 按类型查找
find.byKey(Key('myKey'))              // 按Key查找
find.byIcon(Icons.search)             // 按图标查找
find.byWidgetPredicate((widget) => ...)  // 自定义查找
```

### 常用操作

```dart
await tester.tap(find.text('按钮'))      // 点击
await tester.enterText(find.byType(TextField), 'text')  // 输入文字
await tester.drag(finder, Offset(0, 100))  // 拖动
await tester.longPress(finder)             // 长按
await tester.pumpWidget(widget)            // 渲染widget
await tester.pumpAndSettle()               // 等待所有动画完成
await tester.binding.window.physicalSizeTestValue = const Size(500, 800);
```

## 最佳实践

1. **使用meaningful descriptions**: 描述应该清楚说明测试的意图
2. **按流程顺序编写**: 按照真实用户使用流程编写测试
3. **验证关键结果**: 只验证用户能看到的结果
4. **使用pumpAndSettle**: 等待动画和异步操作完成
5. **提取重复代码**: 使用辅助函数简化测试代码

## 运行集成测试

```bash
# 在模拟器或真机上运行集成测试
flutter test integration_test/app_test.dart

# 在Android上运行
flutter test integration_test/app_test.dart --target=integration_test/app_test.dart

# 生成性能报告
flutter test integration_test/app_test.dart --profile
```
