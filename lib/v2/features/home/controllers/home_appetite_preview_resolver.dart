import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';

class HomeAppetitePreview {
  const HomeAppetitePreview({
    required this.title,
    required this.chips,
    required this.imageAsset,
  });

  final String title;
  final List<String> chips;
  final String imageAsset;
}

class HomeAppetiteCandidate {
  const HomeAppetiteCandidate({
    required this.title,
    required this.tags,
    required this.imageAsset,
    this.score = 0,
    this.sourceLabel,
  });

  final String title;
  final List<String> tags;
  final String imageAsset;
  final double score;
  final String? sourceLabel;
}

class HomeAppetitePreviewResolver {
  const HomeAppetitePreviewResolver();

  HomeAppetitePreview resolve(
    TasteStructuredConstraints constraints, {
    List<HomeAppetiteCandidate> candidates = const [],
    Map<String, int> historyScores = const {},
    String freeformRequirement = '',
  }) {
    final isVegetarian = constraints.dietaryRestrictions.contains('素食');
    final avoidSpicy = constraints.dietaryRestrictions.contains('不要辣') ||
        freeformRequirement.contains('不要辣');
    final spicyScore =
        (historyScores['f_spicy'] ?? 0) + (historyScores['辣'] ?? 0);

    final candidate = _firstAllowedCandidate(
      candidates,
      constraints,
      avoidSpicy: avoidSpicy,
    );
    if (candidate != null) {
      return HomeAppetitePreview(
        title: candidate.title,
        chips: [
          if (constraints.maxTimeMinutes != null)
            '${constraints.maxTimeMinutes} 分钟',
          if (constraints.maxBudgetYuan != null)
            '${constraints.maxBudgetYuan} 元内',
          candidate.sourceLabel?.trim().isNotEmpty == true
              ? candidate.sourceLabel!.trim()
              : '来自推荐',
        ],
        imageAsset: candidate.imageAsset,
      );
    }

    if (isVegetarian) {
      return HomeAppetitePreview(
        title: '番茄豆腐面',
        chips: [
          if (constraints.maxTimeMinutes != null)
            '${constraints.maxTimeMinutes} 分钟',
          if (constraints.maxBudgetYuan != null)
            '${constraints.maxBudgetYuan} 元内',
          '素食',
        ],
        imageAsset: 'assets/images/prebuilt_dishes/dish-20-dish_768.jpg',
      );
    }

    if (constraints.executionPreference == TasteExecutionPreference.delivery) {
      return HomeAppetitePreview(
        title: avoidSpicy ? '菌菇鸡汤饭' : '椒麻鸡丝凉面',
        chips: [
          if (constraints.maxTimeMinutes != null)
            '${constraints.maxTimeMinutes} 分钟',
          if (constraints.maxBudgetYuan != null)
            '${constraints.maxBudgetYuan} 元内',
          '叫外卖',
        ],
        imageAsset: 'assets/images/prebuilt_dishes/dish-13-dish_768.jpg',
      );
    }

    if (constraints.executionPreference == TasteExecutionPreference.dineIn) {
      return HomeAppetitePreview(
        title: '砂锅牛肉粉',
        chips: [
          if (constraints.locationPreference == TasteLocationPreference.nearby)
            '附近',
          if (constraints.maxBudgetYuan != null)
            '${constraints.maxBudgetYuan} 元内',
          '去店里',
        ],
        imageAsset: 'assets/images/prebuilt_dishes/dish-17-dish_768.jpg',
      );
    }

    if (constraints.executionPreference == TasteExecutionPreference.cook) {
      return HomeAppetitePreview(
        title: '番茄肥牛锅',
        chips: [
          if (constraints.maxTimeMinutes != null)
            '${constraints.maxTimeMinutes} 分钟',
          if (constraints.partySize != null) '${constraints.partySize} 人',
          '在家做',
        ],
        imageAsset: 'assets/images/prebuilt_dishes/dish-1-dish_768.jpg',
      );
    }

    if (!avoidSpicy && spicyScore >= 3) {
      return HomeAppetitePreview(
        title: '麻辣冒菜',
        chips: [
          constraints.maxTimeMinutes == null
              ? '20 分钟'
              : '${constraints.maxTimeMinutes} 分钟',
          if (constraints.maxBudgetYuan != null)
            '${constraints.maxBudgetYuan} 元内',
          '偏好辣口',
        ],
        imageAsset: 'assets/images/prebuilt_dishes/dish-18-dish_768.jpg',
      );
    }

    return HomeAppetitePreview(
      title: '番茄肥牛锅',
      chips: [
        constraints.maxTimeMinutes == null
            ? '15 分钟'
            : '${constraints.maxTimeMinutes} 分钟',
        constraints.maxBudgetYuan == null
            ? '30 元内'
            : '${constraints.maxBudgetYuan} 元内',
        '可做可点',
      ],
      imageAsset: 'assets/images/prebuilt_dishes/dish-1-dish_768.jpg',
    );
  }

  HomeAppetiteCandidate? _firstAllowedCandidate(
    List<HomeAppetiteCandidate> candidates,
    TasteStructuredConstraints constraints, {
    required bool avoidSpicy,
  }) {
    HomeAppetiteCandidate? best;
    var bestScore = double.negativeInfinity;
    for (final candidate in candidates) {
      final haystack = '${candidate.title}|${candidate.tags.join('|')}';
      if (constraints.dietaryRestrictions.contains('素食') &&
          _containsAny(haystack, const ['肉', '猪', '牛', '鸡', '鱼', '虾'])) {
        continue;
      }
      if (avoidSpicy && _containsAny(haystack, const ['辣', '椒麻', '麻辣'])) {
        continue;
      }
      if (candidate.score > bestScore) {
        best = candidate;
        bestScore = candidate.score;
      }
    }
    return best;
  }

  bool _containsAny(String haystack, List<String> needles) {
    return needles.any(haystack.contains);
  }
}
