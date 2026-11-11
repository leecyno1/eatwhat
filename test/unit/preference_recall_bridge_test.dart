import 'package:eatwhat_app/v2/core/services/preference_recall_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PreferenceRecallBridge', () {
    test('drops execution, location and playful cards from food recall', () {
      for (final label in ['在家做', '叫外卖', '去店里', '附近', '财运', '惊喜', '随便']) {
        expect(PreferenceRecallBridge.isFoodLabel(label), isFalse,
            reason: label);
      }
      expect(PreferenceRecallBridge.isFoodLabel('川菜'), isTrue);
      expect(
        PreferenceRecallBridge.expand(['财运', '川菜']),
        isNot(contains('财运')),
      );
    });

    test('bridges cuisine cards to concrete local recipe vocabulary', () {
      final sichuan = PreferenceRecallBridge.expand(['川菜']);
      expect(
        sichuan,
        containsAll(['川菜', '水煮牛肉', '水煮鱼', '回锅', '宫保', '麻婆']),
      );

      final western = PreferenceRecallBridge.expand(['西餐']);
      expect(
        western,
        containsAll(['西餐', '意大利面', '披萨', '牛排']),
      );
      expect(western, isNot(contains('财运')));
    });

    test('bridges scene and dietary cards without inventing nutrition', () {
      final teatime = PreferenceRecallBridge.expand(['下午茶']);
      expect(teatime, containsAll(['下午茶', '甜品', '饮品']));

      final vegetarian = PreferenceRecallBridge.expand(['素食']);
      expect(vegetarian, containsAll(['素食', '素菜', '豆腐']));
      expect(vegetarian.join(), isNot(contains('高蛋白')));
    });

    test('keeps the original label last and removes duplicates', () {
      final expanded = PreferenceRecallBridge.expand(['早餐', '早餐']);
      expect(expanded.last, '早餐');
      expect(expanded.where((label) => label == '早餐'), hasLength(1));
    });
  });
}
