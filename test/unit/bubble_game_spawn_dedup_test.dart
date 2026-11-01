import 'dart:async';

import 'package:eatwhat_app/v2/core/data/schema/unified_tag_model.dart';
import 'package:eatwhat_app/v2/features/home/game/bubble_data_manager.dart';
import 'package:eatwhat_app/v2/features/home/game/bubble_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('待挂载实体也参与去重，两波投放不产生重复 ID', (tester) async {
    final gate = Completer<void>();
    final game = BubbleGame(
      dataManagerOverride: _FixedBubbleDataManager(),
      geometryLoader: (_, __) async {
        await gate.future;
        return null;
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: GameWidget(game: game))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    gate.complete();
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final ids = game.entities.map((entity) => entity.data.id).toList();
    expect(ids, hasLength(2));
    expect(ids.toSet().length, ids.length);
    expect(game.issuedTagIds, ids.toSet());

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('快速切换分类后旧代次实体不会留在舞台', (tester) async {
    final gate = Completer<void>();
    final game = BubbleGame(
      dataManagerOverride: _FixedBubbleDataManager(),
      geometryLoader: (_, __) async {
        await gate.future;
        return null;
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: GameWidget(game: game))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    game.setCategory('cuisine');
    gate.complete();
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final ids = game.entities.map((entity) => entity.data.id).toList();
    expect(ids, isNotEmpty);
    expect(ids.toSet().length, ids.length);
    expect(ids.every((id) => id == 'c_hotpot'), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

class _FixedBubbleDataManager extends BubbleDataManager {
  @override
  Future<void> initialize() async {}

  @override
  List<BubbleData> getInitialBubbles(
    int count, {
    String? category,
    Set<String> excludedTagIds = const {},
  }) {
    if (category == 'cuisine') {
      return [BubbleData(tag: _hotpot())];
    }
    return [
      BubbleData(tag: _spicy()),
      BubbleData(tag: _egg()),
    ];
  }

  UnifiedTagModel _spicy() => const UnifiedTagModel(
        id: 'f_spicy',
        label: '辣',
        category: 'flavor',
        iconAsset: 'local_fire_department',
        visual: VisualConfig(
          shapeType: 'chili',
          colors: ['0xFFF45B33', '0xFFFFB545'],
        ),
      );

  UnifiedTagModel _egg() => const UnifiedTagModel(
        id: 'i_egg',
        label: '鸡蛋',
        category: 'ingredient',
        iconAsset: 'egg',
        visual: VisualConfig(
          shapeType: 'circle',
          colors: ['0xFFFFB545', '0xFFFFE0A3'],
        ),
      );

  UnifiedTagModel _hotpot() => const UnifiedTagModel(
        id: 'c_hotpot',
        label: '火锅',
        category: 'cuisine',
        iconAsset: 'soup_kitchen',
        visual: VisualConfig(
          shapeType: 'pot',
          colors: ['0xFFC94B2C', '0xFFFF8A65'],
        ),
      );
}
