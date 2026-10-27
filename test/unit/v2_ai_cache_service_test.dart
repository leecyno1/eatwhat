import 'dart:convert';

import 'package:eatwhat_app/v2/core/services/v2_ai_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('历史版本写入的 fallback JSON 缓存不再命中', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'v2_ai_cache:nutrition:dish-1:data': jsonEncode({
        'nutrition': {'calories': 123},
        'healthScore': 5,
        'balanceAdvice': <String>[],
        'dietaryTags': <String>[],
        'servingSize': '1人份',
        'isEstimated': true,
      }),
      'v2_ai_cache:nutrition:dish-1:ts': now,
    });

    final cached = await V2AiCacheService.instance.getJson(
      'nutrition:dish-1',
    );

    expect(cached, isNull);
  });
}
