import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/home/controllers/home_appetite_preview_resolver.dart';
import 'package:flutter/material.dart';

class HomeRecentSuccessEntry extends StatelessWidget {
  const HomeRecentSuccessEntry({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('home-recent-success-entry'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.68),
            border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
            boxShadow: [
              BoxShadow(
                color: AppPalette.chili.withValues(alpha: 0.1),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: AppPalette.herb.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.replay_rounded,
                    size: 15,
                    color: AppPalette.herb,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '上次吃得很爽',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.label.copyWith(
                      color: AppPalette.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '再来一口',
                  style: AppType.label.copyWith(
                    color: AppPalette.chiliDeep,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppPalette.chiliDeep.withValues(alpha: 0.72),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeStartInferenceButton extends StatelessWidget {
  const HomeStartInferenceButton({
    super.key,
    required this.canStartInference,
    required this.readySelectionCount,
    required this.onPressed,
  });

  final bool canStartInference;
  final int readySelectionCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: const ValueKey('home-start-inference-button'),
      onPressed: canStartInference ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: AppPalette.chili,
        disabledBackgroundColor: AppPalette.surfaceMuted,
        disabledForegroundColor: AppColors.textPrimary.withValues(alpha: 0.42),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.capsule,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              canStartInference ? '生成推荐 · $readySelectionCount 项' : '选择口味后生成',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, size: 18),
        ],
      ),
    );
  }
}

class HomeAppetitePreviewCard extends StatelessWidget {
  const HomeAppetitePreviewCard({
    super.key,
    required this.preview,
    required this.onTap,
  });

  final HomeAppetitePreview preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('home-appetite-preview-card'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFF9F1).withValues(alpha: 0.9),
                const Color(0xFFE8C7B8).withValues(alpha: 0.68),
                const Color(0xFFFFFCF7).withValues(alpha: 0.84),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC94B2C).withValues(alpha: 0.14),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B2D18).withValues(alpha: 0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    preview.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppPalette.appetiteGradient,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '今晚先看这口',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.microLabel.copyWith(
                                  color: AppPalette.chiliDeep,
                                  fontSize: 8.5,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                preview.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.label.copyWith(
                                  color: AppPalette.ink,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 76,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final chip in preview.chips.take(3)) ...[
                                  _AppetitePreviewChip(label: chip),
                                  const SizedBox(width: 4),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: AppPalette.chiliDeep.withValues(alpha: 0.72),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppetitePreviewChip extends StatelessWidget {
  const _AppetitePreviewChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.72),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppType.label.copyWith(
          fontSize: 10,
          color: AppColors.textPrimary.withValues(alpha: 0.68),
        ),
      ),
    );
  }
}
