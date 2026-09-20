import 'dart:async';

import 'package:eatwhat_app/core/models/recipe.dart';
import 'package:eatwhat_app/core/services/real_xiachufang_crawler_service.dart';
import 'package:eatwhat_app/features/recipe/screens/recipe_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openSearch(
    WidgetTester tester,
    _DelayedCrawler crawler,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => MaterialApp(
          home: RecipeSearchScreen(crawlerService: crawler),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submitSearch(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), '  番茄  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('正在搜索菜谱...'), findsOneWidget);
  }

  for (final outcome in ['成功', '业务失败', '异常']) {
    testWidgets('离开搜索页后$outcome响应不再更新页面或显示提示', (tester) async {
      final crawler = _DelayedCrawler();
      await openSearch(tester, crawler);
      await submitSearch(tester);
      expect(crawler.queries, [
        ['番茄']
      ]);
      expect(crawler.targetCounts, [30]);

      await tester.pumpWidget(const MaterialApp(home: Text('已离开搜索页')));
      await tester.pumpAndSettle();
      if (outcome == '异常') {
        crawler.response.completeError(StateError('搜索连接失败'));
      } else {
        crawler.response.complete(CrawlResult(
          success: outcome == '成功',
          message: '搜索服务返回',
          recipesCount: 0,
        ));
      }
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('已离开搜索页'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(crawler.recipeReads, 0);
    });
  }

  testWidgets('页面仍存在时显示按名称、描述、食材匹配的结果，清空可回到建议', (tester) async {
    final crawler = _DelayedCrawler()
      ..recipes = [
        Recipe.fromJson({'id': 'name', 'name': '番茄炒蛋'}),
        Recipe.fromJson({
          'id': 'description',
          'name': '酸甜浓汤',
          'description': '番茄熬制',
        }),
        Recipe.fromJson({
          'id': 'ingredient',
          'name': '家常炖菜',
          'ingredients': [
            {'name': '番茄'},
          ],
        }),
        Recipe.fromJson({'id': 'other', 'name': '清蒸鱼'}),
      ];
    await openSearch(tester, crawler);
    await submitSearch(tester);
    crawler.response.complete(CrawlResult(
      success: true,
      message: '搜索成功',
      recipesCount: 4,
    ));
    await tester.pumpAndSettle();

    expect(find.text('正在搜索菜谱...'), findsNothing);
    expect(find.text('共找到 3 个菜谱'), findsOneWidget);
    expect(find.text('番茄炒蛋'), findsOneWidget);
    expect(find.text('酸甜浓汤'), findsOneWidget);
    expect(find.text('家常炖菜'), findsOneWidget);
    expect(find.text('清蒸鱼'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(crawler.recipeReads, 1);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    expect(find.text('搜索结果'), findsNothing);
    expect(find.text('热门搜索'), findsOneWidget);
    expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    expect(tester.takeException(), isNull);
  });

  for (final throws in [false, true]) {
    testWidgets('页面仍存在时失败显示提示，随后可以重新搜索，异常=$throws', (tester) async {
      final crawler = _DelayedCrawler()
        ..recipes = [
          Recipe.fromJson({'id': 'retry', 'name': '番茄炒蛋'})
        ];
      await openSearch(tester, crawler);
      await submitSearch(tester);
      if (throws) {
        crawler.response.completeError(StateError('连接中断'));
      } else {
        crawler.response.complete(CrawlResult(
          success: false,
          message: '搜索服务不可用',
          recipesCount: 0,
        ));
      }
      await tester.pumpAndSettle();

      expect(find.text('正在搜索菜谱...'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(throws ? '搜索失败: Bad state: 连接中断' : '搜索服务不可用'),
        findsOneWidget,
      );
      expect(crawler.recipeReads, 0);

      crawler.response = Completer<CrawlResult>();
      await submitSearch(tester);
      crawler.response.complete(CrawlResult(
        success: true,
        message: '搜索成功',
        recipesCount: 1,
      ));
      await tester.pumpAndSettle();
      expect(find.text('共找到 1 个菜谱'), findsOneWidget);
      expect(find.text('番茄炒蛋'), findsOneWidget);
      expect(crawler.queries, [
        ['番茄'],
        ['番茄']
      ]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('空白搜索不发起请求', (tester) async {
    final crawler = _DelayedCrawler();
    await openSearch(tester, crawler);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(crawler.queries, isEmpty);
    expect(find.text('正在搜索菜谱...'), findsNothing);
    expect(find.text('热门搜索'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('成功但无匹配结果时结束加载并保留搜索建议', (tester) async {
    final crawler = _DelayedCrawler();
    await openSearch(tester, crawler);
    await submitSearch(tester);
    crawler.response.complete(CrawlResult(
      success: true,
      message: '搜索成功',
      recipesCount: 0,
    ));
    await tester.pumpAndSettle();

    expect(find.text('正在搜索菜谱...'), findsNothing);
    expect(find.text('热门搜索'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _DelayedCrawler extends Fake implements RealXiachufangCrawlerService {
  Completer<CrawlResult> response = Completer<CrawlResult>();
  final queries = <List<String>?>[];
  final targetCounts = <int>[];
  List<Recipe> recipes = [];
  int recipeReads = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<CrawlResult> crawlRecipes({
    List<String>? categories,
    int targetCount = 500,
    Function(String message)? onProgress,
    Function(int current, int total)? onCountProgress,
  }) {
    queries.add(categories);
    targetCounts.add(targetCount);
    return response.future;
  }

  @override
  List<Recipe> get crawledRecipes {
    recipeReads++;
    return recipes;
  }
}
