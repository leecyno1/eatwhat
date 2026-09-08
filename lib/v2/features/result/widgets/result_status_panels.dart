import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class EmptyRecommendationState extends StatelessWidget {
  const EmptyRecommendationState({
    super.key,
    required this.tags,
    required this.resolutionStatus,
    required this.primarySource,
    required this.onReselect,
  });

  final List<String> tags;
  final RecommendationResolutionStatus resolutionStatus;
  final String? primarySource;
  final VoidCallback onReselect;

  @override
  Widget build(BuildContext context) {
    final hint =
        tags.isEmpty ? '回到首页调整口味签名' : '回到首页调整口味签名：${tags.take(3).join('、')}';
    final badge = switch (primarySource?.trim()) {
      'error' => '推荐服务异常',
      'ai' => 'AI 未生成结果',
      'hybrid' => '本地 + AI',
      'local_fallback' => '已切换本地推荐',
      'unified_db' => '本地候选为空',
      _ => switch (resolutionStatus) {
          RecommendationResolutionStatus.aiResolved => 'AI 未生成结果',
          RecommendationResolutionStatus.dbResolved => '本地候选为空',
          RecommendationResolutionStatus.hybridResolved => '本地 + AI',
          RecommendationResolutionStatus.localFallback => '已切换本地推荐',
          RecommendationResolutionStatus.empty => '本轮未命中',
        },
    };

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
        decoration: BoxDecoration(
          color: GoldPalette.panel,
          borderRadius: AppRadii.panel,
          border: Border.all(color: GoldPalette.goldHairline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.black.withValues(alpha: 0.45),
                border: Border.all(color: GoldPalette.goldHairline),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: GoldPalette.goldSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '这轮没有收束出合适的菜',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GoldPalette.creamText,
                fontFamily: 'serif',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GoldPalette.creamMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const ValueKey('result-empty-reselect-button'),
              onPressed: onReselect,
              style: FilledButton.styleFrom(
                backgroundColor: GoldPalette.gold,
                foregroundColor: GoldPalette.nightDeep,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
                shape: RoundedRectangleBorder(borderRadius: AppRadii.capsule),
              ),
              child: const Text('返回重选口味'),
            ),
          ],
        ),
      ),
    );
  }
}
