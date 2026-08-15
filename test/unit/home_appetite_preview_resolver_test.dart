import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/controllers/home_appetite_preview_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeAppetitePreviewResolver', () {
    test('多候选时优先选择分数更高的合规候选', () {
      final preview = const HomeAppetitePreviewResolver().resolve(
        const TasteStructuredConstraints(maxTimeMinutes: 15),
        candidates: const [
          HomeAppetiteCandidate(
            title: '葱油拌面',
            tags: ['快手', '面食'],
            imageAsset: 'assets/images/prebuilt_dishes/dish-21-dish_768.jpg',
            score: 6,
          ),
          HomeAppetiteCandidate(
            title: '香煎鸡腿饭',
            tags: ['快手', '高蛋白', '今日首推'],
            imageAsset: 'assets/images/prebuilt_dishes/dish-22-dish_768.jpg',
            score: 12,
            sourceLabel: 'HowToCook',
          ),
        ],
      );

      expect(preview.title, '香煎鸡腿饭');
      expect(preview.chips, contains('HowToCook'));
    });

    test('有推荐候选时优先使用候选生成预告', () {
      final preview = const HomeAppetitePreviewResolver().resolve(
        const TasteStructuredConstraints(maxTimeMinutes: 15),
        candidates: const [
          HomeAppetiteCandidate(
            title: '葱油拌面',
            tags: ['快手', '面食'],
            imageAsset: 'assets/images/prebuilt_dishes/dish-21-dish_768.jpg',
          ),
        ],
      );

      expect(preview.title, '葱油拌面');
      expect(preview.chips, contains('来自推荐'));
      expect(preview.chips, contains('15 分钟'));
    });

    test('候选违反饮食限制时不会覆盖硬约束预告', () {
      final preview = const HomeAppetitePreviewResolver().resolve(
        const TasteStructuredConstraints(dietaryRestrictions: ['素食']),
        candidates: const [
          HomeAppetiteCandidate(
            title: '红烧肉',
            tags: ['猪肉', '下饭'],
            imageAsset: 'assets/images/prebuilt_dishes/dish-22-dish_768.jpg',
          ),
        ],
      );

      expect(preview.title, '番茄豆腐面');
      expect(preview.chips, contains('素食'));
    });

    test('历史辣味偏好高时默认预告辣口菜', () {
      final preview = const HomeAppetitePreviewResolver().resolve(
        const TasteStructuredConstraints(),
        historyScores: const {'f_spicy': 5},
      );

      expect(preview.title, '麻辣冒菜');
      expect(preview.chips, contains('偏好辣口'));
    });

    test('饮食限制优先于历史口味偏好', () {
      final preview = const HomeAppetitePreviewResolver().resolve(
        const TasteStructuredConstraints(dietaryRestrictions: ['素食']),
        historyScores: const {'f_spicy': 5},
      );

      expect(preview.title, '番茄豆腐面');
      expect(preview.chips, contains('素食'));
    });
  });
}
