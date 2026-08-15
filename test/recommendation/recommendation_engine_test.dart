import 'package:flutter_test/flutter_test.dart';
import 'package:eatwhat_app/core/services/recommendation_engine.dart';
import 'package:eatwhat_app/core/models/user_preference.dart';
import 'package:eatwhat_app/core/data/food_database.dart';

/// 由于 FoodDatabase 是静态的，这里构造一个最小可测集：
/// 假设 FoodDatabase.getAllFoods() 已含有多种菜品；
/// 我们主要验证排序逻辑、副作用（缓存、多样性）可工作，而不依赖具体数据全集。
void main() {
  group('RecommendationEngine 基础行为', () {
    late RecommendationEngine engine;
    late UserPreference pref;

    setUp(() {
      engine = RecommendationEngine();
      pref = UserPreference.defaultPreference().copyWith(
        // 构造一些模拟偏好，提升可预测性
        favoriteFoods: [],
        dislikedFoods: [],
        cuisinePreferences: {
          '川菜': 8.0,
          '粤菜': 2.0,
        },
        tastePreferences: {
          '辣': 9.0,
          '鲜': 6.0,
          '甜': -3.0,
        },
      );
    });

    test('个性化结果非空且按分数降序', () {
      final scored = engine.getPersonalizedScoredRecommendations(
        pref,
        limit: 8,
        ensureDiversity: false, // 关闭多样性，验证纯分数降序
      );
      expect(scored, isNotEmpty);
      for (int i = 1; i < scored.length; i++) {
        expect(scored[i - 1].score >= scored[i].score, isTrue, reason: '分数应降序排列');
      }
    });

    test('不喜欢的食物应被显著惩罚', () {
      // 用基线结果的第一名作为目标，确保在列表中能找到
      final baselineList = engine.getPersonalizedScoredRecommendations(
        pref,
        limit: FoodDatabase.getAllFoods().length,
        ensureDiversity: false,
      );
      expect(baselineList, isNotEmpty);
      final target = baselineList.first.food;

      final baselineScore = baselineList.firstWhere((f) => f.food.name == target.name).score;

      // 更新偏好，明确更新时间戳以避开缓存键命中
      final updatedPref = pref.copyWith(
        dislikedFoods: [target.name],
        lastUpdated: DateTime.now().add(const Duration(seconds: 1)),
      );

      final afterList = engine.getPersonalizedScoredRecommendations(
        updatedPref,
        limit: FoodDatabase.getAllFoods().length,
        ensureDiversity: false,
      );
      final afterScore = afterList.firstWhere((f) => f.food.name == target.name).score;

      expect(afterScore < baselineScore, isTrue, reason: '被标记不喜欢后分数应下降');
    });

    test('缓存命中应返回同一实例引用', () {
      final first = engine.getPersonalizedScoredRecommendations(pref, limit: 5);
      final second = engine.getPersonalizedScoredRecommendations(pref, limit: 5);
      // 因为内部直接返回缓存 List 引用（当前实现），引用相等即可判定命中
      expect(identical(first, second), isTrue, reason: '应命中缓存返回同一引用');
    });

    test('多样性 (MMR) 不应返回全部高度相似项', () {
      // 为了测试多样性，我们用一个较大 limit 前后对比关闭多样性
      final withDiversity =
          engine.getPersonalizedScoredRecommendations(pref, limit: 10, ensureDiversity: true);

      // 简单启发式：如果有多样性，前5个中 cuisineType 应该出现 >=2 个不同值
      final cuisinesWith = withDiversity.take(5).map((e) => e.food.cuisineType).toSet();

      expect(cuisinesWith.length >= 2, isTrue, reason: '启用多样性后前5个菜系应>=2种');

      // 不能严格要求 noDiversity 一定是 1 种，因为源数据未知，但可打印调试
      // 若失败可根据真实数据进行调整
    });
  });
}
