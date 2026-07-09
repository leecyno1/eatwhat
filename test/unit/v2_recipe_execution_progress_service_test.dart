import 'package:eatwhat_app/v2/core/services/v2_recipe_execution_progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('菜谱执行进度会保存、排序并恢复完成步骤', () async {
    final service = V2RecipeExecutionProgressService.instance;

    expect(await service.getCompletedStepIndexes('r1'), isEmpty);

    await service.saveCompletedStepIndexes('r1', {3, 0, 2});

    expect(await service.getCompletedStepIndexes('r1'), {0, 2, 3});
  });

  test('菜谱执行进度会忽略损坏与无效数据', () async {
    SharedPreferences.setMockInitialValues({
      'v2_recipe_execution_progress_r1': '[1,-2,"bad",3]',
      'v2_recipe_execution_progress_r2': '{broken',
    });
    final service = V2RecipeExecutionProgressService.instance;

    expect(await service.getCompletedStepIndexes('r1'), {1, 3});
    expect(await service.getCompletedStepIndexes('r2'), isEmpty);
  });

  test('购物清单进度会保存、排序并恢复已买食材', () async {
    final service = V2RecipeExecutionProgressService.instance;

    expect(await service.getCompletedShoppingIndexes('r1'), isEmpty);

    await service.saveCompletedShoppingIndexes('r1', {2, 0});

    expect(await service.getCompletedShoppingIndexes('r1'), {0, 2});
  });

  test('购物清单进度会忽略损坏与无效数据', () async {
    SharedPreferences.setMockInitialValues({
      'v2_recipe_shopping_r1': '[0,-1,"bad",2]',
      'v2_recipe_shopping_r2': '{broken',
    });
    final service = V2RecipeExecutionProgressService.instance;

    expect(await service.getCompletedShoppingIndexes('r1'), {0, 2});
    expect(await service.getCompletedShoppingIndexes('r2'), isEmpty);
  });
}
