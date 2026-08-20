import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class ResultFeedbackBand extends StatelessWidget {
  const ResultFeedbackBand({
    super.key,
    required this.onEnjoyed,
    required this.onNotForMe,
    this.selection,
  });

  final VoidCallback onEnjoyed;
  final VoidCallback onNotForMe;
  final ResultFeedbackSelection? selection;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('result-feedback-band'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: AppDecorations.nightCard(),
      child: Row(
        children: [
          Expanded(
            child: _FeedbackButton(
              key: const ValueKey('result-feedback-enjoyed'),
              icon: Icons.thumb_up_alt_rounded,
              label: '合口味',
              selected: selection == ResultFeedbackSelection.enjoyed,
              onTap: onEnjoyed,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _FeedbackButton(
              key: const ValueKey('result-feedback-not-for-me'),
              icon: Icons.tune_rounded,
              label: '不合适',
              selected: selection == ResultFeedbackSelection.notForMe,
              onTap: onNotForMe,
            ),
          ),
        ],
      ),
    );
  }
}

enum ResultFeedbackSelection {
  enjoyed,
  notForMe,
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppPalette.rice : AppPalette.moonlight;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.sunsetOrange : AppPalette.nightElevated,
          borderRadius: AppRadii.card,
          border: Border.all(
            color: selected
                ? AppColors.sunsetOrange
                : AppPalette.moonlight.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypeNight.label.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
