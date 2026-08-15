import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/controllers/home_appetite_preview_controller.dart';
import 'package:eatwhat_app/v2/features/home/controllers/home_appetite_preview_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('空选择时预告输入会补家常热菜兜底信号', () {
    final input = const HomeAppetitePreviewController().buildInput(
      session: _session(),
      preview: const HomeAppetitePreview(
        title: '番茄肥牛锅',
        chips: ['15 分钟'],
        imageAsset: 'assets/images/prebuilt_dishes/dish-1-dish_768.jpg',
      ),
      currentRequirement: '',
      historyScores: const {'f_spicy': 2},
    );

    expect(input.likedTagIds, ['home_appetite_preview']);
    expect(input.likedTagLabels, ['家常', '热菜']);
    expect(input.freeformRequirement, '想吃番茄肥牛锅');
    expect(input.historyPreferenceSummary, {'f_spicy': 2});
  });

  test('已有文字需求时预告输入会追加想吃菜品', () {
    final input = const HomeAppetitePreviewController().buildInput(
      session: _session(),
      preview: const HomeAppetitePreview(
        title: '葱油拌面',
        chips: ['快手'],
        imageAsset: 'assets/images/prebuilt_dishes/dish-21-dish_768.jpg',
      ),
      currentRequirement: '30 元内',
      historyScores: const {},
    );

    expect(input.freeformRequirement, '30 元内，想吃葱油拌面');
  });
}

TasteDeckSessionState _session() {
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
  );
}
