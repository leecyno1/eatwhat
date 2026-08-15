import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/controllers/home_recent_success_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('没有最近成功菜品时不生成复用输入', () {
    final input = const HomeRecentSuccessController().buildInput(
      session: _session(),
      historyScores: const {},
      recentRecipeIds: const [],
    );

    expect(input, isNull);
  });

  test('最近成功菜品会生成可直达推荐链路的输入', () {
    final session = _session(
      structuredConstraints:
          const TasteStructuredConstraints(maxBudgetYuan: 30),
    );

    final input = const HomeRecentSuccessController().buildInput(
      session: session,
      historyScores: const {'f_spicy': 3},
      recentRecipeIds: const ['dish_88'],
    );

    expect(input, isNotNull);
    expect(input!.likedTagIds, ['recent_success']);
    expect(input.likedTagLabels, ['最近成功']);
    expect(input.freeformRequirement, '复用上次吃得很爽的选择');
    expect(input.structuredConstraints.maxBudgetYuan, 30);
    expect(input.historyPreferenceSummary, {'f_spicy': 3});
  });
}

TasteDeckSessionState _session({
  TasteStructuredConstraints structuredConstraints =
      const TasteStructuredConstraints(),
}) {
  return TasteDeckSessionState.initial(
    deck: const [
      TasteDeckCard(
        id: 'f_spicy',
        label: '辣',
        category: 'flavor',
        accentHexes: ['0xFFF46B40'],
        iconName: 'spa',
        backTitle: '辣度轮廓',
        examples: ['辣'],
      ),
    ],
    cardDeckSeed: 1,
  ).copyWith(structuredConstraints: structuredConstraints);
}
