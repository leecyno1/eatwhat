import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_image_state_controller.dart';
import 'package:flutter/material.dart';

/// Full-bleed dish photography — the single protagonist of the result
/// stage. The photo bleeds to every screen edge; a cinematic double scrim
/// keeps the floating chrome readable while the mid-frame stays untouched
/// for the food itself.
class ResultHeroMedia extends StatelessWidget {
  const ResultHeroMedia({
    super.key,
    required this.recipe,
    required this.imageLoadState,
    required this.imageSource,
    required this.onRetryImage,
  });

  final RecipeModel recipe;
  final DishImageLoadState imageLoadState;
  final ImageSourceBadgeData? imageSource;
  final VoidCallback onRetryImage;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Stack(
      fit: StackFit.expand,
      children: [
        ResolvedRecipeImage(
          recipeName: recipe.name,
          imageUrl: recipe.imageUrl,
        ),
        // Cinematic scrim: a deep black curtain up top for the floating
        // header, the mid-frame left untouched for the food photography,
        // and a long bottom falloff that sinks the nameplate, rail and
        // action cards into the night stage.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xA6000000),
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0x73000000),
                  Color(0xF2000000),
                ],
                stops: [0.0, 0.20, 0.40, 0.68, 1.0],
              ),
            ),
          ),
        ),
        // Badges float clear of the header row above them.
        Positioned(
          left: 20,
          top: topInset + 64,
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
      ],
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
    // Night-glass chips: every tone shares the same dark glass body so
    // the badge never breaks the black-and-gold mood; only the ink and
    // rim shift to carry the meaning.
    final (background, border, textColor) = switch (data.tone) {
      ImageSourceTone.real => (
          Colors.black.withValues(alpha: 0.58),
          GoldPalette.gold.withValues(alpha: 0.65),
          GoldPalette.gold,
        ),
      ImageSourceTone.reference => (
          Colors.black.withValues(alpha: 0.58),
          GoldPalette.goldSoft.withValues(alpha: 0.55),
          GoldPalette.goldSoft,
        ),
      ImageSourceTone.ai => (
          Colors.black.withValues(alpha: 0.58),
          GoldPalette.creamMuted.withValues(alpha: 0.45),
          GoldPalette.creamMuted,
        ),
      ImageSourceTone.neutral => (
          Colors.black.withValues(alpha: 0.58),
          Colors.white.withValues(alpha: 0.28),
          GoldPalette.creamMuted,
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

    // Black-gold stand-in while no photography is available: a charcoal
    // panel, two candle-glow blooms, and the dish initial set in serif
    // inside a hairline gold ring — a monogram plate instead of a photo.
    // The ring rides slightly high so the bottom scrim and nameplate
    // never cut it in half.
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF201E23),
            Color(0xFF121114),
            GoldPalette.nightDeep,
          ],
          stops: [0.0, 0.52, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GoldPalette.gold.withValues(alpha: 0.09),
              ),
            ),
          ),
          Positioned(
            left: -26,
            bottom: -36,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GoldPalette.goldSoft.withValues(alpha: 0.07),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.28),
            child: Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: GoldPalette.goldHairline,
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: GoldPalette.goldSoft,
                    fontSize: 92,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'serif',
                    letterSpacing: 2,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
