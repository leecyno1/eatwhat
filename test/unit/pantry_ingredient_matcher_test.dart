import 'package:eatwhat_app/core/services/pantry_ingredient_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('常用别名用于召回，重复输入只算一份已有食材', () {
    expect(PantryIngredientMatcher.searchTerms(['番茄', '西红柿', '土豆']),
        ['番茄', '西红柿', '土豆', '马铃薯']);
    final match = PantryIngredientMatcher.match(
      pantry: ['番茄', '西红柿', '鸡蛋', '鸡蛋'],
      ingredients: ['西红柿一个', '鸡蛋 2 个', '食用油', '盐'],
    );
    expect(match.matchedPantry, ['番茄', '鸡蛋']);
    expect(match.missingIngredients, ['食用油', '盐']);
    expect(match.missingMainCount, 0);
  });

  test('不把原料视作同名加工品或英文子串', () {
    final match = PantryIngredientMatcher.match(
      pantry: ['番茄', '鸡蛋', 'egg', '牛肉'],
      ingredients: ['番茄酱', '鸡蛋豆腐', 'eggplant', '牛肉酱'],
    );
    expect(match.matchedPantry, isEmpty);
    expect(match.missingIngredients, hasLength(4));
  });

  test('份量写法不妨碍识别，未知名不做模糊替代', () {
    final match = PantryIngredientMatcher.match(
      pantry: ['鸡蛋', '番茄', '番茄酱'],
      ingredients: ['2个鸡蛋', '西红柿 200 克', '番茄酱适量', '圣女果'],
    );
    expect(match.matchedPantry, ['鸡蛋', '番茄', '番茄酱']);
    expect(match.missingIngredients, ['圣女果']);
  });

  test('合并调味行只命中一项时仍提醒其余用料', () {
    final match = PantryIngredientMatcher.match(
      pantry: ['葱'],
      ingredients: ['葱、姜、蒜', '盐'],
    );
    expect(match.matchedPantry, ['葱']);
    expect(match.missingIngredients, ['葱、姜、蒜', '盐']);
    expect(match.missingMainCount, 0);
    expect(match.missingSeasoningCount, 3);
  });

  test('先覆盖已有食材，再少补主料，最后比较未确认的调味料', () {
    final partial = PantryIngredientMatcher.match(
        pantry: ['鸡蛋', '番茄'], ingredients: ['鸡蛋']);
    final both = PantryIngredientMatcher.match(
        pantry: ['鸡蛋', '番茄'], ingredients: ['鸡蛋', '西红柿', '盐', '油']);
    final extra = PantryIngredientMatcher.match(
        pantry: ['鸡蛋', '番茄'], ingredients: ['鸡蛋', '西红柿', '牛肉']);
    expect(both.compareTo(partial), lessThan(0));
    expect(both.compareTo(extra), lessThan(0));
    expect(both.missingIngredients, ['盐', '油'], reason: '不能假设家中已有调味品');
    expect(both.compareTo(both), 0);
  });

  test('空输入与空配方不生成虚假命中', () {
    expect(PantryIngredientMatcher.searchTerms([' ', '']), isEmpty);
    final match =
        PantryIngredientMatcher.match(pantry: ['鸡蛋'], ingredients: []);
    expect(match.matchedPantry, isEmpty);
    expect(match.missingIngredients, isEmpty);
  });
}
