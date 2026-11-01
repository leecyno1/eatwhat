import 'package:eatwhat_app/v2/features/details/recipe_difficulty_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('recipeDifficultyLabel', () {
    test('把 HowToCook 的 1-5 档数字转成中文', () {
      expect(recipeDifficultyLabel('1'), '很简单');
      expect(recipeDifficultyLabel('2'), '简单');
      expect(recipeDifficultyLabel('3'), '中等');
      expect(recipeDifficultyLabel('4'), '较难');
      expect(recipeDifficultyLabel('5'), '困难');
    });

    test('把英文难度枚举转成中文', () {
      expect(recipeDifficultyLabel('easy'), '简单');
      expect(recipeDifficultyLabel('medium'), '中等');
      expect(recipeDifficultyLabel('hard'), '较难');
      expect(recipeDifficultyLabel('Medium'), '中等');
    });

    test('无法识别的值保持原样，空值给出兜底文案', () {
      expect(recipeDifficultyLabel('挑战级'), '挑战级');
      expect(recipeDifficultyLabel('9'), '9');
      expect(recipeDifficultyLabel('  '), '难度未知');
    });
  });
}
