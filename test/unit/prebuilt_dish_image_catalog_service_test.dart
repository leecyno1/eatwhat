import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/services/prebuilt_dish_image_catalog_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    dotenv.testLoad();
  });

  test('预制图库服务优先按 dishId 命中 hero 与 thumb', () async {
    final service = PrebuiltDishImageCatalogService(
      assetManifestLoader: () async => _sampleManifestJson,
      remoteManifestLoader: () async => null,
    );

    await service.loadManifest();

    const recipe = RecipeModel(
      id: 'r1',
      name: '番茄肥牛锅',
      description: '热一点，有锅气。',
    );

    expect(await service.resolveHeroUrl(recipe),
        'https://cdn.example.com/r1-hero.jpg');
    expect(await service.resolveThumbUrl(recipe),
        'https://cdn.example.com/r1-thumb.jpg');
  });

  test('预制图库服务在无 dishId 命中时可按菜名或别名匹配', () async {
    final service = PrebuiltDishImageCatalogService(
      assetManifestLoader: () async => _sampleManifestJson,
      remoteManifestLoader: () async => null,
    );

    await service.loadManifest();

    const recipe = RecipeModel(
      id: 'unknown-id',
      name: '金汤肥牛',
      description: '酸香热口。',
    );

    expect(await service.resolveHeroUrl(recipe),
        'https://cdn.example.com/r2-hero.jpg');
  });

  test('dishId 错位时不会把其他菜品图片配给当前菜品', () async {
    final service = PrebuiltDishImageCatalogService(
      assetManifestLoader: () async => _mismatchedIdManifestJson,
      remoteManifestLoader: () async => null,
    );

    const recipe = RecipeModel(
      id: '242',
      name: '汤面',
      description: '一碗热汤面。',
    );

    expect(
      await service.resolveHeroUrl(recipe),
      'https://cdn.example.com/noodle-hero.jpg',
    );
  });

  test('预制图库服务未命中时返回 null', () async {
    final service = PrebuiltDishImageCatalogService(
      assetManifestLoader: () async => _sampleManifestJson,
      remoteManifestLoader: () async => null,
    );

    await service.loadManifest();

    const recipe = RecipeModel(
      id: 'unknown-id',
      name: '不存在的菜',
      description: '没有图。',
    );

    expect(await service.resolveHeroUrl(recipe), isNull);
    expect(await service.resolveThumbUrl(recipe), isNull);
  });

  test('相对路径 manifest 在配置 base url 后可动态补全', () async {
    dotenv.testLoad(
      mergeWith: const {
        'PREBUILT_IMAGE_BASE_URL': 'https://cdn.example.com/eatwhat',
      },
    );

    final service = PrebuiltDishImageCatalogService(
      assetManifestLoader: () async => _relativeManifestJson,
      remoteManifestLoader: () async => null,
    );

    await service.loadManifest();

    const recipe = RecipeModel(
      id: '88',
      name: '可乐鸡翅',
      description: '香甜酱香。',
    );

    expect(
      await service.resolveHeroUrl(recipe),
      'https://cdn.example.com/eatwhat/images/dish-88-kelajichi_1280.jpg',
    );
    expect(
      await service.resolveThumbUrl(recipe),
      'https://cdn.example.com/eatwhat/images/dish-88-kelajichi_768.jpg',
    );
  });

  test('相对路径 manifest 在未配置 base url 时回退 null', () async {
    final service = PrebuiltDishImageCatalogService(
      assetManifestLoader: () async => _relativeManifestJson,
      remoteManifestLoader: () async => null,
    );

    await service.loadManifest();

    const recipe = RecipeModel(
      id: '88',
      name: '可乐鸡翅',
      description: '香甜酱香。',
    );

    expect(await service.resolveHeroUrl(recipe), isNull);
    expect(await service.resolveThumbUrl(recipe), isNull);
  });
}

const _sampleManifestJson = '''
{
  "items": [
    {
      "dishId": "r1",
      "dishName": "番茄肥牛锅",
      "aliases": ["番茄肥牛"],
      "heroUrl": "https://cdn.example.com/r1-hero.jpg",
      "thumbUrl": "https://cdn.example.com/r1-thumb.jpg",
      "styleTag": "warm_stew",
      "updatedAt": "2026-04-06T12:00:00Z",
      "sourceType": "howtocook_real_local",
      "sourceProject": "HowToCook",
      "sourcePath": "/repo/HowToCook/dishes/meat_dish/番茄肥牛锅/1.jpg",
      "sourceRecipeName": "番茄肥牛锅"
    },
    {
      "dishId": "r2",
      "dishName": "金汤肥牛",
      "aliases": ["酸汤肥牛", "金汤肥牛锅"],
      "heroUrl": "https://cdn.example.com/r2-hero.jpg",
      "thumbUrl": "https://cdn.example.com/r2-thumb.jpg",
      "styleTag": "golden_broth",
      "updatedAt": "2026-04-06T12:00:00Z",
      "sourceType": "legacy_prebuilt_asset",
      "sourceProject": "eatwhat_assets",
      "sourcePath": "assets/images/prebuilt_dishes/r2.jpg",
      "sourceRecipeName": "金汤肥牛"
    }
  ]
}
''';

const _relativeManifestJson = '''
{
  "items": [
    {
      "dishId": "88",
      "dishName": "可乐鸡翅",
      "aliases": ["鸡翅"],
      "heroUrl": "images/dish-88-kelajichi_1280.jpg",
      "thumbUrl": "images/dish-88-kelajichi_768.jpg",
      "styleTag": "home_braise",
      "updatedAt": "2026-04-06T12:00:00Z",
      "sourceType": "legacy_prebuilt_asset",
      "sourceProject": "eatwhat_assets",
      "sourcePath": "images/dish-88-kelajichi_1280.jpg",
      "sourceRecipeName": "可乐鸡翅"
    }
  ]
}
''';

const _mismatchedIdManifestJson = '''
{
  "items": [
    {
      "dishId": "242",
      "dishName": "扬州炒饭",
      "aliases": [],
      "heroUrl": "https://cdn.example.com/rice-hero.jpg",
      "thumbUrl": "https://cdn.example.com/rice-thumb.jpg",
      "styleTag": "staple",
      "updatedAt": "2026-08-15T00:00:00Z"
    },
    {
      "dishId": "901",
      "dishName": "汤面",
      "aliases": [],
      "heroUrl": "https://cdn.example.com/noodle-hero.jpg",
      "thumbUrl": "https://cdn.example.com/noodle-thumb.jpg",
      "styleTag": "staple",
      "updatedAt": "2026-08-15T00:00:00Z"
    }
  ]
}
''';
