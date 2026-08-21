import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_image_state_controller.dart';
import 'package:flutter/material.dart';

class ResultHeroMedia extends StatelessWidget {
  const ResultHeroMedia({
    super.key,
    required this.recipe,
    required this.isGeneratingImage,
    required this.imageLoadState,
    required this.imageSource,
    required this.onRetryImage,
    this.height,
  });

  final RecipeModel recipe;
  final bool isGeneratingImage;
  final DishImageLoadState imageLoadState;
  final ImageSourceBadgeData? imageSource;
  final VoidCallback onRetryImage;

  /// Null fills the available space (the single-screen gold stage).
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GoldPalette.goldHairline),
        boxShadow: [
          BoxShadow(
            color: GoldPalette.gold.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ResolvedRecipeImage(
              recipeName: recipe.name,
              imageUrl: recipe.imageUrl,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.04),
                      Colors.transparent,
                      const Color(0xFF3A241B).withValues(alpha: 0.44),
                    ],
                    stops: const [0.0, 0.42, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: GoldPalette.goldHairline),
                    ),
                    child: Text(
                      switch (imageLoadState) {
                        DishImageLoadState.loading => 'AI 出图中',
                        DishImageLoadState.failed => '菜图暂未生成',
                        _ => '主厨推荐',
                      },
                      style: const TextStyle(
                        color: GoldPalette.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ),
                  if (imageSource != null &&
                      imageLoadState != DishImageLoadState.loading &&
                      imageLoadState != DishImageLoadState.failed) ...[
                    const SizedBox(width: 8),
                    ImageSourceChip(data: imageSource!),
                  ],
                  if (imageLoadState == DishImageLoadState.failed) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      key: const ValueKey('result-image-retry-button'),
                      onTap: onRetryImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.58),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: GoldPalette.goldHairline),
                        ),
                        child: const Text(
                          '重试出图',
                          style: TextStyle(
                            color: GoldPalette.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GoldPalette.creamText,
                        fontFamily: 'serif',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        height: 1.05,
                      ),
                    ),
                  ),
                  if (isGeneratingImage)
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImageSourceChip extends StatelessWidget {
  const ImageSourceChip({
    super.key,
    required this.data,
  });

  final ImageSourceBadgeData data;

  @override
  Widget build(BuildContext context) {
    final (background, border, textColor) = switch (data.tone) {
      ImageSourceTone.real => (
          const Color(0xFFEAF7EF),
          const Color(0xFF9FD0AE),
          const Color(0xFF27543B),
        ),
      ImageSourceTone.reference => (
          const Color(0xFFF7EEDF),
          const Color(0xFFE1C594),
          const Color(0xFF7A5220),
        ),
      ImageSourceTone.ai => (
          const Color(0xFFFBE7E2),
          const Color(0xFFF0B2A2),
          const Color(0xFF8A392B),
        ),
      ImageSourceTone.neutral => (
          Colors.white.withValues(alpha: 0.54),
          Colors.white.withValues(alpha: 0.76),
          AppColors.textPrimary,
        ),
    };

    return Container(
      key: const ValueKey('result-image-source-chip'),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: border,
        ),
      ),
      child: Text(
        data.label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class ResolvedRecipeImage extends StatelessWidget {
  const ResolvedRecipeImage({
    super.key,
    required this.recipeName,
    required this.imageUrl,
  });

  final String recipeName;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final value = imageUrl?.trim() ?? '';
    if (value.isEmpty) {
      return FallbackDishArtwork(recipeName: recipeName);
    }

    if (value.startsWith('assets/')) {
      return Image.asset(
        value,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return FallbackDishArtwork(recipeName: recipeName);
        },
      );
    }

    if (value.startsWith('data:image/')) {
      final commaIndex = value.indexOf(',');
      if (commaIndex == -1 || commaIndex >= value.length - 1) {
        return FallbackDishArtwork(recipeName: recipeName);
      }
      try {
        final bytes = base64Decode(value.substring(commaIndex + 1));
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return FallbackDishArtwork(recipeName: recipeName);
          },
        );
      } catch (_) {
        return FallbackDishArtwork(recipeName: recipeName);
      }
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: value,
        fit: BoxFit.cover,
        placeholder: (context, url) => FallbackDishArtwork(
          recipeName: recipeName,
        ),
        errorWidget: (context, url, error) => FallbackDishArtwork(
          recipeName: recipeName,
        ),
      );
    }

    return FallbackDishArtwork(recipeName: recipeName);
  }
}

class FallbackDishArtwork extends StatelessWidget {
  const FallbackDishArtwork({
    super.key,
    required this.recipeName,
  });

  final String recipeName;

  @override
  Widget build(BuildContext context) {
    final initial = recipeName.trim().isEmpty ? '味' : recipeName.trim()[0];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF1E3),
            Color(0xFFF9C89E),
            Color(0xFFE99F7F),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -22,
            top: -12,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            left: -18,
            bottom: -28,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF46B40).withValues(alpha: 0.14),
              ),
            ),
          ),
          Center(
            child: Text(
              initial,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 118,
                fontWeight: FontWeight.w800,
                fontFamily: 'SF Pro Rounded',
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
