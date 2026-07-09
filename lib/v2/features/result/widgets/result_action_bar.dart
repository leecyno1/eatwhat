import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ResultTagChip extends StatelessWidget {
  const ResultTagChip({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppPalette.rice.withValues(alpha: 0.46),
        borderRadius: AppRadii.capsule,
        border: Border.all(
          color: AppPalette.rice.withValues(alpha: 0.72),
        ),
      ),
      child: Text(
        label,
        style: AppType.label.copyWith(
          color: AppColors.textPrimary.withValues(alpha: 0.74),
        ),
      ),
    );
  }
}

class ResultActionBar extends StatelessWidget {
  const ResultActionBar({
    super.key,
    required this.onReroll,
    required this.onConfirm,
    required this.onOpenSimilarRecipes,
    required this.onOpenRecipe,
  });

  final VoidCallback onReroll;
  final VoidCallback onConfirm;
  final VoidCallback onOpenSimilarRecipes;
  final VoidCallback onOpenRecipe;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ResultActionButton(
            icon: Icons.refresh_rounded,
            color: AppColors.textPrimary,
            onTap: onReroll,
            label: '再看看',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ResultActionButton(
            key: const ValueKey('execution-entry-button'),
            icon: Icons.alt_route_rounded,
            color: AppColors.freshLime,
            isPrimary: true,
            onTap: onConfirm,
            label: '就吃这个',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ResultActionButton(
            key: const ValueKey('result-open-howtocook-library'),
            icon: Icons.view_carousel_rounded,
            color: AppColors.textPrimary,
            onTap: onOpenSimilarRecipes,
            label: '同源做法',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ResultActionButton(
            icon: Icons.menu_book_rounded,
            color: AppColors.textPrimary,
            onTap: onOpenRecipe,
            label: '菜谱',
          ),
        ),
      ],
    ).animate().fadeIn().scale(delay: 200.ms);
  }
}

class ResultActionButton extends StatelessWidget {
  const ResultActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.label,
    this.isPrimary = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadii.panel,
          color: isPrimary ? color : AppPalette.rice.withValues(alpha: 0.46),
          border: isPrimary
              ? null
              : Border.all(color: AppPalette.rice.withValues(alpha: 0.74)),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary ? AppPalette.rice : AppColors.textPrimary,
              size: isPrimary ? 28 : 24,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppType.label.copyWith(
                color: isPrimary ? AppPalette.rice : AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
