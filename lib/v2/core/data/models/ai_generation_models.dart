class NutritionInfo {
  final num calories;
  final num protein;
  final num carbs;
  final num fat;
  final num fiber;
  final num sodium;
  final num sugar;
  final num? vitaminC;
  final num? calcium;
  final num? iron;

  const NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sodium,
    required this.sugar,
    this.vitaminC,
    this.calcium,
    this.iron,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    num readNum(String key, {num fallback = 0}) {
      final v = json[key];
      if (v is num) return v;
      return num.tryParse(v?.toString() ?? '') ?? fallback;
    }

    num? readNumOrNull(String key) {
      final v = json[key];
      if (v == null) return null;
      if (v is num) return v;
      return num.tryParse(v.toString());
    }

    return NutritionInfo(
      calories: readNum('calories'),
      protein: readNum('protein'),
      carbs: readNum('carbs'),
      fat: readNum('fat'),
      fiber: readNum('fiber'),
      sodium: readNum('sodium'),
      sugar: readNum('sugar'),
      vitaminC: readNumOrNull('vitaminC'),
      calcium: readNumOrNull('calcium'),
      iron: readNumOrNull('iron'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sodium': sodium,
      'sugar': sugar,
      if (vitaminC != null) 'vitaminC': vitaminC,
      if (calcium != null) 'calcium': calcium,
      if (iron != null) 'iron': iron,
    };
  }
}

class NutritionAnalysis {
  final NutritionInfo nutrition;
  final int healthScore;
  final List<String> balanceAdvice;
  final List<String> dietaryTags;
  final String servingSize;
  final bool isEstimated;

  const NutritionAnalysis({
    required this.nutrition,
    required this.healthScore,
    required this.balanceAdvice,
    required this.dietaryTags,
    required this.servingSize,
    this.isEstimated = false,
  });

  factory NutritionAnalysis.fromJson(Map<String, dynamic> json) {
    final nutritionRaw = json['nutrition'];
    final nutrition = nutritionRaw is Map<String, dynamic>
        ? NutritionInfo.fromJson(nutritionRaw)
        : const NutritionInfo(
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            fiber: 0,
            sodium: 0,
            sugar: 0,
          );

    int readInt(String key, {int fallback = 0}) {
      final v = json[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    List<String> readList(String key) {
      final v = json[key];
      if (v is List) {
        return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      return const [];
    }

    return NutritionAnalysis(
      nutrition: nutrition,
      healthScore: readInt('healthScore'),
      balanceAdvice: readList('balanceAdvice'),
      dietaryTags: readList('dietaryTags'),
      servingSize: (() {
        final v = (json['servingSize']?.toString() ?? '').trim();
        return v.isNotEmpty ? v : '1人份';
      })(),
      isEstimated: (json['isEstimated'] == true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nutrition': nutrition.toJson(),
      'healthScore': healthScore,
      'balanceAdvice': balanceAdvice,
      'dietaryTags': dietaryTags,
      'servingSize': servingSize,
      'isEstimated': isEstimated,
    };
  }
}

class WinePairing {
  final String name;
  final String type;
  final String reason;
  final String servingTemperature;
  final String? glassType;
  final String? alcoholContent;
  final String flavor;
  final String? origin;
  final bool isEstimated;

  const WinePairing({
    required this.name,
    required this.type,
    required this.reason,
    required this.servingTemperature,
    required this.flavor,
    this.glassType,
    this.alcoholContent,
    this.origin,
    this.isEstimated = false,
  });

  factory WinePairing.fromJson(Map<String, dynamic> json) {
    String readString(String key, {String fallback = ''}) {
      final v = (json[key]?.toString() ?? '').trim();
      return v.isEmpty ? fallback : v;
    }

    return WinePairing(
      name: readString('name', fallback: '无酒精气泡水'),
      type: readString('type', fallback: 'other'),
      reason: readString('reason', fallback: '清爽解腻，适配大多数家常菜。'),
      servingTemperature: readString('servingTemperature', fallback: '冰镇'),
      glassType:
          readString('glassType').isEmpty ? null : readString('glassType'),
      alcoholContent: readString('alcoholContent').isEmpty
          ? null
          : readString('alcoholContent'),
      flavor: readString('flavor', fallback: '清爽'),
      origin: readString('origin').isEmpty ? null : readString('origin'),
      isEstimated: (json['isEstimated'] == true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'reason': reason,
      'servingTemperature': servingTemperature,
      if (glassType != null) 'glassType': glassType,
      if (alcoholContent != null) 'alcoholContent': alcoholContent,
      'flavor': flavor,
      if (origin != null) 'origin': origin,
      'isEstimated': isEstimated,
    };
  }
}

class FortuneResult {
  final String id;
  final String type;
  final String date;
  final String dishName;
  final String reason;
  final int luckyIndex;
  final String description;
  final List<String> tips;
  final String difficulty;
  final int cookingTime;
  final String mysticalMessage;
  final List<String>? ingredients;
  final List<String>? steps;
  final bool isEstimated;

  const FortuneResult({
    required this.id,
    required this.type,
    required this.date,
    required this.dishName,
    required this.reason,
    required this.luckyIndex,
    required this.description,
    required this.tips,
    required this.difficulty,
    required this.cookingTime,
    required this.mysticalMessage,
    this.ingredients,
    this.steps,
    this.isEstimated = false,
  });

  factory FortuneResult.fromJson(Map<String, dynamic> json) {
    String readString(String key, {String fallback = ''}) {
      final v = (json[key]?.toString() ?? '').trim();
      return v.isEmpty ? fallback : v;
    }

    int readInt(String key, {int fallback = 0}) {
      final v = json[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    List<String>? readStringListOrNull(String key) {
      final v = json[key];
      if (v is! List) return null;
      final out =
          v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      return out.isEmpty ? null : out;
    }

    return FortuneResult(
      id: readString('id',
          fallback: 'fortune_${DateTime.now().millisecondsSinceEpoch}'),
      type: readString('type', fallback: 'daily'),
      date: readString('date', fallback: _todayString()),
      dishName: readString('dishName'),
      reason: readString('reason', fallback: '今天就适合来点不一样的。'),
      luckyIndex: readInt('luckyIndex', fallback: 7).clamp(1, 10),
      description: readString('description', fallback: '平平无奇的一天，也能吃出惊喜。'),
      tips: (json['tips'] is List)
          ? (json['tips'] as List)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
          : const ['相信直觉，别纠结。'],
      difficulty: readString('difficulty', fallback: 'medium'),
      cookingTime: readInt('cookingTime', fallback: 25),
      mysticalMessage: readString('mysticalMessage', fallback: '锅铲一响，烦恼退散。'),
      ingredients: readStringListOrNull('ingredients'),
      steps: readStringListOrNull('steps'),
      isEstimated: (json['isEstimated'] == true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'date': date,
      'dishName': dishName,
      'reason': reason,
      'luckyIndex': luckyIndex,
      'description': description,
      'tips': tips,
      'difficulty': difficulty,
      'cookingTime': cookingTime,
      'mysticalMessage': mysticalMessage,
      if (ingredients != null) 'ingredients': ingredients,
      if (steps != null) 'steps': steps,
      'isEstimated': isEstimated,
    };
  }
}

String _todayString() {
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)}';
}

class AiRefinedRecommendations {
  final List<String> recipeIds;
  final Map<String, String> reasonsById;
  final String? summary;
  final bool isEstimated;

  const AiRefinedRecommendations({
    required this.recipeIds,
    required this.reasonsById,
    this.summary,
    this.isEstimated = false,
  });

  factory AiRefinedRecommendations.fromJson(Map<String, dynamic> json) {
    final idsRaw = json['recipeIds'];
    final ids = (idsRaw is List)
        ? idsRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    final reasonsRaw = json['reasonsById'];
    final reasons = <String, String>{};
    if (reasonsRaw is Map) {
      for (final entry in reasonsRaw.entries) {
        final k = entry.key.toString();
        final v = entry.value?.toString() ?? '';
        if (k.isNotEmpty && v.trim().isNotEmpty) {
          reasons[k] = v.trim();
        }
      }
    }

    final summary = (json['summary']?.toString() ?? '').trim();
    return AiRefinedRecommendations(
      recipeIds: ids,
      reasonsById: reasons,
      summary: summary.isEmpty ? null : summary,
      isEstimated: (json['isEstimated'] == true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipeIds': recipeIds,
      'reasonsById': reasonsById,
      if (summary != null) 'summary': summary,
      'isEstimated': isEstimated,
    };
  }
}
