enum MealPlanningDirection {
  balanced,
  health,
  experience,
}

extension MealPlanningDirectionCopy on MealPlanningDirection {
  String get label {
    return switch (this) {
      MealPlanningDirection.balanced => '均衡',
      MealPlanningDirection.health => '健康向',
      MealPlanningDirection.experience => '体验向',
    };
  }

  List<String> get recallLabels {
    return switch (this) {
      MealPlanningDirection.balanced => const [],
      MealPlanningDirection.health => const ['轻食', '清淡', '高蛋白', '蔬菜'],
      MealPlanningDirection.experience => const ['浓郁', '香辣', '特色', '惊喜'],
    };
  }

  String get aiInstruction {
    return switch (this) {
      MealPlanningDirection.balanced => '规划方向：均衡。兼顾营养、满足感和日常可执行性。',
      MealPlanningDirection.health => '规划方向：健康向。优先蔬菜、优质蛋白、适量主食和较轻烹饪方式，控制油盐与负担。',
      MealPlanningDirection.experience =>
        '规划方向：体验向。优先风味层次、新鲜感和满足感，同时尊重忌口与硬性约束。',
    };
  }
}
