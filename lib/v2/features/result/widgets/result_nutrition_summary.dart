import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_enrichment_controller.dart';
import 'package:flutter/material.dart';

class NutritionSummaryCard extends StatelessWidget {
  const NutritionSummaryCard({
    super.key,
    required this.data,
    required this.loadState,
  });

  final NutritionAnalysis? data;
  final NutritionLoadState loadState;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '营养速览',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (loadState == NutritionLoadState.loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.sunsetOrange,
                    ),
                  ),
                )
              else if (loadState == NutritionLoadState.loaded && data != null)
                Text(
                  '健康分 ${data!.healthScore}/10',
                  style: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.46),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            switch (loadState) {
              NutritionLoadState.loading => '正在整理这道菜的基础营养结构。',
              NutritionLoadState.loaded => '给你一眼能看懂的热量和营养结构，作为选择参考。',
              NutritionLoadState.unavailable => '营养信息暂时不可用',
            },
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.52),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (loadState != NutritionLoadState.loaded || data == null)
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                NutritionMetric(label: '热量', value: '--'),
                NutritionMetric(label: '蛋白质', value: '--'),
                NutritionMetric(label: '碳水', value: '--'),
                NutritionMetric(label: '脂肪', value: '--'),
              ],
            )
          else ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                NutritionMetric(
                  label: '热量',
                  value: '${data!.nutrition.calories} kcal',
                ),
                NutritionMetric(
                  label: '蛋白质',
                  value: '${data!.nutrition.protein} g',
                ),
                NutritionMetric(
                  label: '碳水',
                  value: '${data!.nutrition.carbs} g',
                ),
                NutritionMetric(
                  label: '脂肪',
                  value: '${data!.nutrition.fat} g',
                ),
              ],
            ),
            if (data!.dietaryTags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in data!.dietaryTags.take(3))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: AppColors.freshLime.withValues(alpha: 0.12),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class NutritionMetric extends StatelessWidget {
  const NutritionMetric({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppDecorations.card(
        color: AppPalette.surfaceMuted,
        radius: AppRadii.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.44),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
