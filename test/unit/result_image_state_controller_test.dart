import 'package:eatwhat_app/v2/core/data/models/dish_image_manifest.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_image_state_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResultImageStateController', () {
    test('tracks loading, failed and resolved states by recipe id', () {
      final controller = ResultImageStateController();

      expect(controller.stateFor('r1'), DishImageLoadState.idle);
      expect(controller.hasFailed('r1'), isFalse);

      controller.markLoading('r1');
      expect(controller.stateFor('r1'), DishImageLoadState.loading);

      controller.markFailed('r1');
      expect(controller.stateFor('r1'), DishImageLoadState.failed);
      expect(controller.hasFailed('r1'), isTrue);

      controller.markResolved(
        'r1',
        source: const ImageSourceBadgeData(
          label: 'AI 生成图',
          tone: ImageSourceTone.ai,
        ),
      );
      expect(controller.stateFor('r1'), DishImageLoadState.resolved);
      expect(controller.sourceFor('r1')?.tone, ImageSourceTone.ai);
    });

    test('maps manifest sources to user-facing badges', () {
      final real = ImageSourceBadgeData.fromManifest(
        _entry(sourceType: 'howtocook_real_local'),
      );
      final legacy = ImageSourceBadgeData.fromManifest(
        _entry(sourceType: 'legacy_prebuilt_asset'),
      );
      final aiOptimized = ImageSourceBadgeData.fromManifest(
        _entry(sourceType: 'howtocook_ai_optimized_review'),
      );

      expect(real.label, '实拍图');
      expect(real.tone, ImageSourceTone.real);
      expect(legacy.label, '图库参考图');
      expect(legacy.tone, ImageSourceTone.reference);
      expect(aiOptimized.label, 'AI 优化图');
      expect(aiOptimized.tone, ImageSourceTone.ai);
    });

    test('existing image sources get a neutral current image badge', () {
      final controller = ResultImageStateController()..markExistingImage('r1');

      expect(controller.stateFor('r1'), DishImageLoadState.resolved);
      expect(controller.sourceFor('r1')?.label, '当前菜图');
      expect(controller.sourceFor('r1')?.tone, ImageSourceTone.neutral);
    });
  });
}

DishImageManifestEntry _entry({required String sourceType}) {
  return DishImageManifestEntry(
    dishId: 'r1',
    dishName: '麻婆豆腐',
    aliases: const [],
    heroUrl: 'assets/images/prebuilt_dishes/mapo.jpg',
    thumbUrl: 'assets/images/prebuilt_dishes/mapo-thumb.jpg',
    styleTag: 'warm_stew',
    updatedAt: '2026-06-14T00:00:00Z',
    sourceType: sourceType,
    sourceProject: 'HowToCook',
    sourcePath: '/fixtures/mapo.jpg',
    sourceRecipeName: '麻婆豆腐',
  );
}
