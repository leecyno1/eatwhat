import 'package:eatwhat_app/v2/core/services/v2_favorites_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('菜品收藏 API 复用既有 recipe 收藏存储', () async {
    final service = V2FavoritesService.instance;

    await service.setFavoriteRecipeIds({'dish-1'});

    expect(await service.getFavoriteDishIds(), {'dish-1'});
    expect(await service.isDishFavorited('dish-1'), isTrue);
    expect(await service.isDishFavorited('dish-2'), isFalse);
  });

  test('切换菜品收藏后旧 recipe API 仍能读到同一份数据', () async {
    final service = V2FavoritesService.instance;

    await service.toggleFavoriteDish('dish-8');

    expect(await service.isRecipeFavorited('dish-8'), isTrue);
    expect(await service.getFavoriteRecipeIds(), {'dish-8'});

    await service.toggleFavoriteDish('dish-8');

    expect(await service.isRecipeFavorited('dish-8'), isFalse);
    expect(await service.getFavoriteRecipeIds(), isEmpty);
  });
}
