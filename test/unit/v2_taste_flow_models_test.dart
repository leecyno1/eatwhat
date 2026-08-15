import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<TasteDeckCard> buildCards(int count) {
    return List.generate(
      count,
      (index) => TasteDeckCard(
        id: 'tag_$index',
        label: '标签$index',
        category: index.isEven ? 'flavor' : 'scene',
        accentHexes: const ['0xFFFF6A4D', '0xFFFF3D3D'],
        iconName: 'local_fire_department',
      ),
    );
  }

  test('2x4 会话默认展示第一页 8 张卡', () {
    final session = TasteDeckSessionState.initial(
      deck: buildCards(16),
      cardDeckSeed: 7,
    );

    expect(session.currentPageCards.length, TasteDeckSessionState.pageSize);
    expect(session.currentPageCards.first.id, 'tag_0');
    expect(session.currentPageCards.last.id, 'tag_7');
    expect(session.currentPageNumber, 1);
    expect(session.totalPageCount, 2);
  });

  test('单卡上下滑后只替换当前槽位，其余卡位保持不动', () {
    final cards = buildCards(20);
    final session = TasteDeckSessionState.initial(
      deck: cards,
      cardDeckSeed: 7,
    ).recordReaction(cards.first, TasteCardReaction.liked);

    expect(session.likedTagIds, ['tag_0']);
    expect(session.currentPageCards.length, TasteDeckSessionState.pageSize);
    expect(session.currentPageCards.first.id, 'tag_8');
    expect(session.currentPageCards[1].id, 'tag_1');
    expect(session.currentPageCards[7].id, 'tag_7');
    expect(session.pageReactionFor('tag_0'), TasteCardReaction.liked);
    expect(session.currentPageNumber, 1);
  });

  test('已出现过的卡在补牌和翻页后不会再次回流', () {
    final cards = buildCards(40);
    final session = TasteDeckSessionState.initial(
      deck: cards,
      cardDeckSeed: 11,
    )
        .recordReaction(cards[0], TasteCardReaction.liked)
        .recordReaction(cards[1], TasteCardReaction.disliked)
        .advancePage();

    expect(
        session.seenTagIds, containsAll(['tag_0', 'tag_1', 'tag_8', 'tag_9']));
    expect(session.currentPageCards.map((card) => card.id),
        isNot(contains('tag_0')));
    expect(session.currentPageCards.map((card) => card.id),
        isNot(contains('tag_1')));
    final currentIds = session.currentPageCards.map((card) => card.id).toList();
    expect(currentIds.toSet().length, currentIds.length);
  });

  test('整版翻页会把未处理卡记为略过，并进入下一组', () {
    final cards = buildCards(40);
    final session = TasteDeckSessionState.initial(
      deck: cards,
      cardDeckSeed: 9,
    )
        .recordReaction(cards[0], TasteCardReaction.liked)
        .recordReaction(cards[1], TasteCardReaction.disliked)
        .advancePage();

    expect(session.likedTagIds, ['tag_0']);
    expect(session.dislikedTagIds, ['tag_1']);
    expect(session.skippedTagIds.length, TasteDeckSessionState.pageSize);
    expect(session.currentPageNumber, 2);
    expect(session.currentPageCards.first.id, 'tag_10');
  });

  test('2x4 结果和文本要求会一起进入推理输入', () {
    final cards = buildCards(40);
    final session = TasteDeckSessionState.initial(
      deck: cards,
      cardDeckSeed: 7,
    )
        .recordReaction(cards[0], TasteCardReaction.liked)
        .recordReaction(cards[1], TasteCardReaction.disliked)
        .advancePage()
        .copyWith(
          freeformRequirement: '来点热的，辣一点，适合夜宵',
          faceStage: TasteDeckFaceStage.signature,
        );

    final input = TasteInferenceInput.fromSession(
      session,
      historyPreferenceSummary: const {'tag_0': 4, 'tag_1': -2},
    );

    expect(input.likedTagLabels, ['标签0']);
    expect(input.dislikedTagLabels, ['标签1']);
    expect(input.skippedTagLabels.length, TasteDeckSessionState.pageSize);
    expect(input.freeformRequirement, '来点热的，辣一点，适合夜宵');
    expect(input.primarySignals, contains('标签0'));
    expect(input.primarySignals, contains('来点热的，辣一点，适合夜宵'));
  });

  test('结构化约束会随会话进入推理输入', () {
    final session = TasteDeckSessionState.initial(
      deck: buildCards(12),
      cardDeckSeed: 7,
    ).copyWith(
      structuredConstraints: const TasteStructuredConstraints(
        maxTimeMinutes: 15,
        maxBudgetYuan: 30,
        partySize: 1,
        dietaryRestrictions: ['素食'],
        executionPreference: TasteExecutionPreference.delivery,
        locationPreference: TasteLocationPreference.nearby,
      ),
    );

    final input = TasteInferenceInput.fromSession(
      session,
      historyPreferenceSummary: const {},
    );

    expect(input.structuredConstraints.maxTimeMinutes, 15);
    expect(input.structuredConstraints.maxBudgetYuan, 30);
    expect(input.structuredConstraints.partySize, 1);
    expect(input.structuredConstraints.dietaryRestrictions, ['素食']);
    expect(
      input.structuredConstraints.executionPreference,
      TasteExecutionPreference.delivery,
    );
    expect(
      input.structuredConstraints.locationPreference,
      TasteLocationPreference.nearby,
    );
    expect(input.primarySignals, contains('15 分钟内'));
    expect(input.primarySignals, contains('30 元内'));
    expect(input.primarySignals, contains('1 人'));
    expect(input.primarySignals, contains('素食'));
    expect(input.primarySignals, contains('叫外卖'));
    expect(input.primarySignals, contains('附近'));
    expect(session.canStartInference, isTrue);
  });
}
