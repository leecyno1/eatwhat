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

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('v2_completed_recipe_ids'), ['r-finish']);
    expect(await service.getRecentRecipeIds(), isEmpty);
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

  test('旧选择不迁移为已吃，新选择不学习长期偏好', () async {
    SharedPreferences.setMockInitialValues({
      'v2_recent_recipe_ids': ['old-choice'],
    });
    final service = V2PreferenceFeedbackService.instance;
    expect(await service.getCompletedRecipeIds(), isEmpty);
    await service.recordRecipeChosen('new-choice');
    expect(await service.getRecentRecipeIds(), ['new-choice', 'old-choice']);
    expect(await service.getCompletedRecipeIds(), isEmpty);
    expect(await service.getTagScores(), isEmpty);
    expect(await service.getExecutionPathScores(), isEmpty);
  });

  test('独立完成记录去重置顶限量，且不污染选择记录', () async {
    final service = V2PreferenceFeedbackService.instance;
    await service.recordCompletedRecipe('a', limit: 2);
    await service.recordCompletedRecipe('b', limit: 2);
    await service.recordCompletedRecipe('a', limit: 2);
    expect(await service.getCompletedRecipeIds(), ['a', 'b']);
    await service.recordCompletedRecipe('c', limit: 2);
    expect(await service.getCompletedRecipeIds(), ['c', 'a']);
    expect(await service.getCompletedRecipeIds(limit: 1), ['c']);
    expect(await service.getCompletedRecipeIds(limit: 0), isEmpty);
    expect(await service.getRecentRecipeIds(), isEmpty);
  });

  test('并发完成不会丢失菜品、渠道或长期口味分数', () async {
    final service = V2PreferenceFeedbackService.instance;
    await Future.wait([
      for (var i = 0; i < 8; i++)
        service.recordExecutionCompleted(
          recipeId: 'r-$i',
          path: ExecutionPath.cook,
          positiveTagIds: ['f_spicy', 'db_flavor_12'],
        ),
      service.recordPositiveTag('c_sichuan'),
    ]);

    expect(await service.getExecutionPathScore(ExecutionPath.cook), 16);
    expect(await service.getTagScores(), {
      'f_spicy': 16,
      'db_flavor_12': 16,
      'c_sichuan': 1,
    });
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('v2_completed_recipe_ids'),
        List.generate(8, (i) => 'r-${7 - i}'));
  });

  group('偏好分数时间衰减', () {
    late DateTime fakeNow;

    setUp(() {
      fakeNow = DateTime(2026, 1, 1, 12);
      V2PreferenceFeedbackService.debugClock = () => fakeNow;
    });

    tearDown(() {
      V2PreferenceFeedbackService.debugClock = null;
    });

    test('即刻读取不衰减', () async {
      final service = V2PreferenceFeedbackService.instance;
      await service.recordPositiveTag('f_spicy', delta: 4);

      expect(await service.getTagScore('f_spicy'), 4);
    });

    test('30 天前半衰，90 天约剩 1/8', () async {
      final service = V2PreferenceFeedbackService.instance;
      await service.recordPositiveTag('f_spicy', delta: 8);

      fakeNow = fakeNow.add(const Duration(days: 30));
      expect(await service.getTagScore('f_spicy'), 4);

      fakeNow = fakeNow.add(const Duration(days: 60));
      expect(await service.getTagScore('f_spicy'), 1);
    });

    test('衰减后新增量以全值入账', () async {
      final service = V2PreferenceFeedbackService.instance;
      await service.recordPositiveTag('f_spicy', delta: 4);

      fakeNow = fakeNow.add(const Duration(days: 30));
      expect(await service.getTagScore('f_spicy'), 2);

      await service.recordPositiveTag('f_spicy');
      expect(await service.getTagScore('f_spicy'), 3);
    });

    test('衰减到近零的旧信号在下次写入时被遗忘', () async {
      final service = V2PreferenceFeedbackService.instance;
      await service.recordPositiveTag('f_spicy');

      fakeNow = fakeNow.add(const Duration(days: 200));
      await service.recordPositiveTag('c_sichuan');

      final scores = await service.getTagScores();
      expect(scores.containsKey('f_spicy'), isFalse);
      expect(scores['c_sichuan'], 1);
    });

    test('旧格式（无时间戳）按新鲜分数迁移，升级不丢历史', () async {
      SharedPreferences.setMockInitialValues({
        'v2_tag_scores_json': '{"f_spicy": 5}',
      });
      final service = V2PreferenceFeedbackService.instance;

      expect(await service.getTagScore('f_spicy'), 5);

      fakeNow = fakeNow.add(const Duration(days: 30));
      // 5 × 0.5 = 2.5，round 半值远离零 → 3。
      expect(await service.getTagScore('f_spicy'), 3);
    });
  });
}
