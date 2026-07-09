import 'package:eatwhat_app/v2/core/data/models/dish_image_manifest.dart';

enum DishImageLoadState { idle, loading, resolved, failed }

enum ImageSourceTone { real, reference, ai, neutral }

class ImageSourceBadgeData {
  const ImageSourceBadgeData({
    required this.label,
    required this.tone,
  });

  factory ImageSourceBadgeData.fromManifest(DishImageManifestEntry? entry) {
    if (entry == null) {
      return const ImageSourceBadgeData(
        label: '当前菜图',
        tone: ImageSourceTone.neutral,
      );
    }
    switch (entry.sourceType) {
      case 'howtocook_real_local':
      case 'xiachufang_real_local':
        return const ImageSourceBadgeData(
          label: '实拍图',
          tone: ImageSourceTone.real,
        );
      case 'legacy_prebuilt_asset':
      case 'prebuilt_ai':
        return const ImageSourceBadgeData(
          label: '图库参考图',
          tone: ImageSourceTone.reference,
        );
      case 'howtocook_ai_optimized_review':
        return const ImageSourceBadgeData(
          label: 'AI 优化图',
          tone: ImageSourceTone.ai,
        );
      default:
        return const ImageSourceBadgeData(
          label: '当前菜图',
          tone: ImageSourceTone.neutral,
        );
    }
  }

  final String label;
  final ImageSourceTone tone;
}

class ResultImageStateController {
  final Map<String, DishImageLoadState> _stateByRecipeId = {};
  final Map<String, ImageSourceBadgeData> _sourceByRecipeId = {};

  DishImageLoadState stateFor(String recipeId) {
    return _stateByRecipeId[recipeId] ?? DishImageLoadState.idle;
  }

  ImageSourceBadgeData? sourceFor(String recipeId) {
    return _sourceByRecipeId[recipeId];
  }

  bool hasFailed(String recipeId) {
    return stateFor(recipeId) == DishImageLoadState.failed;
  }

  void markLoading(String recipeId) {
    _stateByRecipeId[recipeId] = DishImageLoadState.loading;
  }

  void markFailed(String recipeId) {
    _stateByRecipeId[recipeId] = DishImageLoadState.failed;
  }

  void markResolved(
    String recipeId, {
    ImageSourceBadgeData? source,
    bool keepExistingSource = false,
  }) {
    _stateByRecipeId[recipeId] = DishImageLoadState.resolved;
    if (source != null) {
      _sourceByRecipeId[recipeId] = source;
    } else if (!keepExistingSource) {
      _sourceByRecipeId.remove(recipeId);
    }
  }

  void markExistingImage(String recipeId) {
    markResolved(
      recipeId,
      source: _sourceByRecipeId[recipeId] ??
          const ImageSourceBadgeData(
            label: '当前菜图',
            tone: ImageSourceTone.neutral,
          ),
    );
  }
}
