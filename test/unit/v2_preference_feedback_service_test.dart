import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('执行路径偏好返回最高分路径，无正向记录时返回不限', () async {
    final service = V2PreferenceFeedbackService.instance;

    expect(await service.getPreferredExecutionPath(), ExecutionPath.any);

    await service.recordExecutionPathChosen(ExecutionPath.cook);
    await service.recordExecutionPathChosen(ExecutionPath.delivery, delta: 3);
    await service.recordExecutionPathChosen(ExecutionPath.dineIn, delta: 2);

    expect(await service.getPreferredExecutionPath(), ExecutionPath.delivery);
  });

  test('完成一次开吃会同时记录菜品、路径和口味反馈', () async {
    final service = V2PreferenceFeedbackService.instance;

    await service.recordExecutionCompleted(
      recipeId: 'r-finish',
      path: ExecutionPath.delivery,
      positiveTagIds: ['f_spicy', 'scene_lazy'],
    );

    expect(await service.getRecentRecipeIds(), contains('r-finish'));
    expect(await service.getExecutionPathScore(ExecutionPath.delivery), 2);
    expect(await service.getTagScore('f_spicy'), 2);
    expect(await service.getTagScore('scene_lazy'), 2);
  });

  test('完成反馈只记录规范化口味标签，忽略平台和来源等杂项信号', () async {
    final service = V2PreferenceFeedbackService.instance;

    await service.recordExecutionCompleted(
      recipeId: 'r-cook',
      path: ExecutionPath.cook,
      positiveTagIds: ['热菜', 'HowToCook', '酸梅汤', 'db_flavor_12'],
    );

    expect(await service.getTagScore('热菜'), 2);
    expect(await service.getTagScore('db_flavor_12'), 2);
    expect(await service.getTagScore('HowToCook'), 0);
    expect(await service.getTagScore('酸梅汤'), 0);
  });
}
