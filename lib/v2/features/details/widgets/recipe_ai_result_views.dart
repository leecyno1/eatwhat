import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class NutritionView extends StatelessWidget {
  const NutritionView({super.key, required this.data});

  final NutritionAnalysis data;

  @override
  Widget build(BuildContext context) {
    final n = data.nutrition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        metaRow(
          left: '健康评分',
          right: '${data.healthScore}/10${data.isEstimated ? '（估算）' : ''}',
        ),
        const SizedBox(height: 8),
        metaRow(left: '建议份量', right: data.servingSize),
        const SizedBox(height: 14),
        sectionTitle('核心营养'),
        const SizedBox(height: 10),
        keyValue('热量', '${n.calories} kcal'),
        keyValue('蛋白质', '${n.protein} g'),
        keyValue('碳水', '${n.carbs} g'),
        keyValue('脂肪', '${n.fat} g'),
        keyValue('纤维', '${n.fiber} g'),
        keyValue('钠', '${n.sodium} mg'),
        keyValue('糖', '${n.sugar} g'),
        if (n.vitaminC != null) keyValue('维生素C', '${n.vitaminC} mg'),
        if (n.calcium != null) keyValue('钙', '${n.calcium} mg'),
        if (n.iron != null) keyValue('铁', '${n.iron} mg'),
        const SizedBox(height: 14),
        sectionTitle('饮食标签'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: data.dietaryTags
              .map((e) => pill(e, color: AppColors.freshLime))
              .toList(),
        ),
        const SizedBox(height: 14),
        sectionTitle('均衡建议'),
        const SizedBox(height: 10),
        ...data.balanceAdvice.map(bullet),
      ],
    );
  }
}

class WinePairingView extends StatelessWidget {
  const WinePairingView({super.key, required this.data});

  final WinePairing data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${data.servingTemperature}${data.isEstimated ? '（估算）' : ''}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        sectionTitle('搭配理由'),
        const SizedBox(height: 10),
        Text(
          data.reason,
          style: const TextStyle(
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        sectionTitle('口感'),
        const SizedBox(height: 10),
        Text(
          data.flavor,
          style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
        ),
        const SizedBox(height: 14),
        sectionTitle('补充信息'),
        const SizedBox(height: 10),
        if (data.alcoholContent != null && data.alcoholContent!.isNotEmpty)
          keyValue('酒精度', data.alcoholContent!),
        if (data.glassType != null && data.glassType!.isNotEmpty)
          keyValue('杯型', data.glassType!),
        if (data.origin != null && data.origin!.isNotEmpty)
          keyValue('品牌/产地', data.origin!),
      ],
    );
  }
}

class FortuneView extends StatelessWidget {
  const FortuneView({super.key, required this.data});

  final FortuneResult data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle('今日关键词'),
        const SizedBox(height: 10),
        metaRow(
          left: '幸运指数',
          right: '${data.luckyIndex}/10${data.isEstimated ? '（估算）' : ''}',
        ),
        const SizedBox(height: 8),
        metaRow(left: '菜名', right: data.dishName),
        const SizedBox(height: 14),
        sectionTitle('为什么是它'),
        const SizedBox(height: 10),
        Text(
          data.reason,
          style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
        ),
        const SizedBox(height: 14),
        sectionTitle('神秘话语'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.sunsetOrange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.sunsetOrange.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            data.mysticalMessage,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 14),
        sectionTitle('小提示'),
        const SizedBox(height: 10),
        ...data.tips.map(bullet),
      ],
    );
  }
}

Widget sectionTitle(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w900,
      color: AppColors.textPrimary,
    ),
  );
}

Widget keyValue(String k, String v) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            k,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget metaRow({required String left, required String right}) {
  return Row(
    children: [
      Text(
        left,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
      const Spacer(),
      Text(
        right,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

Widget bullet(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(
            color: AppColors.freshLime,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget pill(String text, {required Color color}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
    ),
  );
}
