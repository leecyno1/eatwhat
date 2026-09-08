import 'package:cached_network_image/cached_network_image.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class RecipeHeroImage extends StatelessWidget {
  const RecipeHeroImage({
    super.key,
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty) {
      return RecipeImagePlaceholder(
        color: AppColors.sunsetOrange.withValues(alpha: 0.3),
      );
    }

    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => RecipeImagePlaceholder(
          color: AppColors.sunsetOrange.withValues(alpha: 0.3),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: GoldPalette.panel,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: GoldPalette.panel,
        child: const Icon(Icons.broken_image, size: 50),
      ),
    );
  }
}

class RecipeImagePlaceholder extends StatelessWidget {
  const RecipeImagePlaceholder({
    super.key,
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    // 黑金花字盘风格：深色渐变底 + 柔金餐具标，呼应结果页 fallback。
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF201E23), Color(0xFF121114), GoldPalette.nightDeep],
          stops: [0.0, 0.52, 1.0],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 80,
          color: GoldPalette.goldSoft.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
