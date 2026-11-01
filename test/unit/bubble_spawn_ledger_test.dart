import 'package:eatwhat_app/v2/features/home/game/bubble_spawn_ledger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BubbleSpawnLedger', () {
    test('同一 ID 只能占位一次', () {
      final ledger = BubbleSpawnLedger();

      expect(ledger.reserve('f_spicy'), isTrue);
      expect(ledger.reserve('f_spicy'), isFalse);
      expect(ledger.reserve('i_egg'), isTrue);
      expect(ledger.issuedIds, {'f_spicy', 'i_egg'});
    });

    test('排除集合同时包含已发放和额外已选 ID', () {
      final ledger = BubbleSpawnLedger()
        ..reserve('f_spicy')
        ..reserve('i_egg');

      expect(
        ledger.exclusions({'c_hotpot', 'i_egg'}),
        {'f_spicy', 'i_egg', 'c_hotpot'},
      );
    });

    test('新代次清空旧占位并保留显式保留项', () {
      final ledger = BubbleSpawnLedger()
        ..reserve('f_spicy')
        ..reserve('i_egg');

      final previous = ledger.generation;
      ledger.beginGeneration(preserve: {'f_spicy'});

      expect(ledger.generation, previous + 1);
      expect(ledger.issuedIds, {'f_spicy'});
      expect(ledger.reserve('i_egg'), isTrue);
    });
  });
}
