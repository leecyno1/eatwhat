import 'package:eatwhat_app/v2/core/data/models/meal_planning_direction.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/data/repositories/tag_repository_v2.dart';
import 'package:eatwhat_app/v2/core/services/v2_meal_habit_learning_service.dart';
import 'package:eatwhat_app/v2/features/home/game/bubble_data_manager.dart';
import 'package:eatwhat_app/v2/features/home/game/bubble_game.dart';
import 'package:eatwhat_app/v2/features/home/game/taste_entity_visual_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('全部标准偏好都有明确概念实体映射', () {
    final tags = TagRepositoryV2().getAllTags();
    final missing = tags
        .where(
          (tag) => !TasteEntityVisualCatalog.hasExplicitMapping(tag.label),
        )
        .map((tag) => tag.label)
        .toList();

    expect(tags.length, greaterThanOrEqualTo(90));
    expect(missing, isEmpty);
    expect(TasteEntityVisualCatalog.conceptFor('低碳').glyph, '🥑');
    expect(TasteEntityVisualCatalog.conceptFor('辣').glyph, '🌶️');
    expect(TasteEntityVisualCatalog.conceptFor('高蛋白').glyph, '🥚');
  });

  test('首次全部偏好池固定包含方案 4 的代表实体', () async {
    final manager = BubbleDataManager();
    await manager.initialize();

    final labels =
        manager.getInitialBubbles(22).map((bubble) => bubble.label).toSet();

    expect(labels, containsAll(const ['低碳', '辣', '鸡蛋']));
  });

  test('实体容器分三层共辖 60 个偏好实体', () {
    expect(BubbleGame.visibleBubbleCount, 60);
    expect(BubbleGame.potLayerCount, 3);
  });

  test('四组筛选覆盖全部 94 个实体', () async {
    final manager = BubbleDataManager();
    await manager.initialize();

    expect(manager.countForCategory('ingredient_dietary'), 24);
    expect(manager.countForCategory('flavor_staple'), 23);
    expect(manager.countForCategory('cuisine'), 26);
    expect(manager.countForCategory('scene_fun'), 21);
    expect(manager.totalTagCount, 94);
  });

  test('实体资源路径由标签 ID 稳定映射', () async {
    final manager = BubbleDataManager();
    await manager.initialize();

    final entity = manager
        .getInitialBubbles(25, category: 'ingredient_dietary')
        .firstWhere((item) => item.id == 'i_beef');

    expect(entity.assetName, 'preference_entities/i_beef.png');
    expect(
      entity.assetPath,
      'assets/images/preference_entities/i_beef.png',
    );
  });

  test('历史健康信号会推断为健康向', () async {
    final snapshot = await V2MealHabitLearningService.instance.buildSnapshot(
      tagScores: const {
        'i_vegetable': 8,
        'i_fish': 5,
        'f_light': 4,
      },
    );

    expect(snapshot.recommendedDirection, MealPlanningDirection.health);
    expect(snapshot.evidenceCount, greaterThan(0));
    expect(snapshot.insight, contains('健康向'));
  });

  test('历史刺激风味信号会推断为体验向', () async {
    final snapshot = await V2MealHabitLearningService.instance.buildSnapshot(
      tagScores: const {
        'f_spicy': 7,
        'f_rich': 5,
        'c_hotpot': 4,
      },
    );

    expect(snapshot.recommendedDirection, MealPlanningDirection.experience);
    expect(snapshot.insight, contains('体验向'));
  });

  test('规划方向会进入推理信号与 AI 指令', () {
    final session = TasteDeckSessionState.initial(
      deck: const [
        TasteDeckCard(
          id: 'i_egg',
          label: '鸡蛋',
          category: 'ingredient',
          accentHexes: ['0xFFFFB545'],
          iconName: 'egg_alt',
        ),
      ],
      cardDeckSeed: 1,
    ).copyWith(likedTagIds: const ['i_egg']);

    final input = TasteInferenceInput.fromSession(
      session,
      historyPreferenceSummary: const {},
      planningDirection: MealPlanningDirection.health,
    );

    expect(input.planningDirection, MealPlanningDirection.health);
    expect(input.primarySignals, contains('高蛋白'));
    expect(input.planningDirection.aiInstruction, contains('控制油盐'));
  });

  test('用户选择的规划方向会被持续学习', () async {
    await V2MealHabitLearningService.instance.recordDirection(
      MealPlanningDirection.experience,
    );
    await V2MealHabitLearningService.instance.recordDirection(
      MealPlanningDirection.experience,
    );

    final snapshot = await V2MealHabitLearningService.instance.buildSnapshot(
      tagScores: const {},
    );

    expect(snapshot.recommendedDirection, MealPlanningDirection.experience);
    expect(snapshot.confidence, 1);
  });
}
