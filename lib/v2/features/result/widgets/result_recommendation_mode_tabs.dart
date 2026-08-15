import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

enum ResultRecommendationMode {
  single,
  meal,
}

class ResultRecommendationModeTabs extends StatelessWidget {
  const ResultRecommendationModeTabs({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ResultRecommendationMode value;
  final ValueChanged<ResultRecommendationMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '推荐形式',
      child: Container(
        key: const ValueKey('result-recommendation-mode-tabs'),
        padding: const EdgeInsets.all(4),
        decoration: AppDecorations.card(
          color: AppPalette.surfaceMuted,
          radius: AppRadii.sm,
        ),
        child: Row(
          children: [
            _ModeTab(
              key: const ValueKey('result-mode-single'),
              label: '一道菜',
              icon: Icons.restaurant_rounded,
              selected: value == ResultRecommendationMode.single,
              onTap: () => onChanged(ResultRecommendationMode.single),
            ),
            _ModeTab(
              key: const ValueKey('result-mode-meal'),
              label: '一顿饭',
              icon: Icons.table_restaurant_rounded,
              selected: value == ResultRecommendationMode.meal,
              onTap: () => onChanged(ResultRecommendationMode.meal),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.small,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.enter,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: AppRadii.small,
              color: selected ? AppPalette.chili : Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: selected ? AppPalette.rice : AppPalette.ink,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: AppType.label.copyWith(
                    color: selected ? AppPalette.rice : AppPalette.ink,
                    fontWeight: FontWeight.w800,
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
