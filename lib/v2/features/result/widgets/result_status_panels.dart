import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class RecommendationExplanationCard extends StatelessWidget {
  const RecommendationExplanationCard({
    super.key,
    required this.resolutionStatus,
    required this.primarySource,
    required this.recalledCount,
    required this.recallLabels,
    this.constraintLabels = const [],
    required this.reason,
  });

  final RecommendationResolutionStatus resolutionStatus;
  final String? primarySource;
  final int recalledCount;
  final List<String> recallLabels;
  final List<String> constraintLabels;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: AppDecorations.nightCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '推荐说明',
            style: TextStyle(
              color: AppPalette.moonlight,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _buildSourceLine(),
            style: TextStyle(
              color: AppPalette.moonlight.withValues(alpha: 0.74),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: TextStyle(
              color: AppPalette.moonlight.withValues(alpha: 0.56),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          if (recallLabels.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '生成信号：${recallLabels.take(4).join('、')}',
              style: TextStyle(
                color: AppPalette.moonlight.withValues(alpha: 0.52),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ],
          if (constraintLabels.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '本轮约束：${constraintLabels.join('、')}',
              style: TextStyle(
                color: AppPalette.moonlight.withValues(alpha: 0.52),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildSourceLine() {
    final candidateCount = recalledCount > 0 ? recalledCount : 0;
    switch (resolutionStatus) {
      case RecommendationResolutionStatus.dbResolved:
        return candidateCount > 0
            ? '本轮先从 $candidateCount 道 HowToCook 候选里收束出这道菜。'
            : '这道菜来自 HowToCook 菜谱的优先召回。';
      case RecommendationResolutionStatus.hybridResolved:
        return candidateCount > 0
            ? '本轮先从 $candidateCount 道本地正式候选中筛选，再由 AI 辅助收束。'
            : '这道菜来自本地正式菜谱，并由 AI 辅助解释。';
      case RecommendationResolutionStatus.localFallback:
        return candidateCount > 0
            ? 'AI 增强暂时不可用，已从 $candidateCount 道本地候选中稳定收束。'
            : 'AI 增强暂时不可用，当前使用本地可靠推荐。';
      case RecommendationResolutionStatus.aiResolved:
        return candidateCount > 0
            ? '本轮由 AI 直接生成 $candidateCount 道候选，HowToCook 只补充图片和做法。'
            : '本轮由 AI 根据口味签名直接生成菜品。';
      case RecommendationResolutionStatus.empty:
        return primarySource == 'empty' ? '本轮没有形成可展示的正式候选。' : '当前结果来源暂不可用。';
    }
  }
}

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
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        decoration: AppDecorations.nightCard(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: 0.7),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: AppPalette.moonlight,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '这轮没有收束出合适的菜',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppPalette.moonlight,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppPalette.moonlight.withValues(alpha: 0.62),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              key: const ValueKey('result-empty-reselect-button'),
              onPressed: onReselect,
              child: const Text('返回重选口味'),
            ),
          ],
        ),
      ),
    );
  }
}
