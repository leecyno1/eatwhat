import 'package:eatwhat_app/v2/core/services/generation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GenerationService 能解析 MiniMax image_urls 数组', () {
    final url = GenerationService.extractMiniMaxImageUrl({
      'data': {
        'image_urls': [
          'https://example.com/generated-dish.jpg',
        ],
      },
      'base_resp': {
        'status_code': 0,
        'status_msg': 'success',
      },
    });

    expect(url, 'https://example.com/generated-dish.jpg');
  });
}
