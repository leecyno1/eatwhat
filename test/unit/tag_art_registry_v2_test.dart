import 'package:eatwhat_app/v2/core/data/repositories/tag_art_registry_v2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('24 张核心卡有专属视觉 spec', () {
    expect(TagArtRegistryV2.coreTagIds.length, 24);

    final spicy = TagArtRegistryV2.specFor('f_spicy');
    expect(spicy.artKey, 'pepper-flare');
    expect(spicy.surfacePattern, 'ember');
    expect(spicy.symbolLayout, 'crest');

    final fallback = TagArtRegistryV2.specFor('unknown_tag');
    expect(fallback.artKey, 'default');
    expect(fallback.surfacePattern, 'category');
  });
}
