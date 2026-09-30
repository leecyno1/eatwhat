import 'package:eatwhat_app/v2/core/services/v2_recommendation_funnel_insights.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

typedef WeeklyReportLoader = Future<RecommendationFunnelReport> Function();

/// 一周饮食报告：把近 7 天的推荐漏斗数据（浏览/定下/开吃/做完/收藏）
/// 汇总成一屏回顾，附一句判词。
class WeeklyReportSheet extends StatefulWidget {
  const WeeklyReportSheet({
    super.key,
    this.reportLoader,
  });

  final WeeklyReportLoader? reportLoader;

  static Future<RecommendationFunnelReport> _defaultLoader() async {
    final insights = V2RecommendationFunnelInsights.instance;
    return insights.loadReport(
      since: DateTime.now().subtract(const Duration(days: 7)),
    );
  }

  /// 判词：按整体漏斗数据给一句话回顾。
  static String weeklyVerdict(RecommendationFunnelReport report) {
    final overall = report.overall;
    if (overall.exposures == 0) {
      return '这周还没让主厨帮你选过菜，摇一摇开始吧';
    }
    if (overall.executionCompletionRate >= 0.6 && overall.executionStarts > 0) {
      return '这周说到做到，定了就做，做完的比率很高';
    }
    if (overall.rerollsPerExposure > 1) {
      return '这周选择困难了一点，主厨继续加油';
    }
    if (overall.confirmations == 0) {
      return '这周看了不少，但还没定下一道——明天试试就吃这个';
    }
    return '吃得明白的一周';
  }

  @override
  State<WeeklyReportSheet> createState() => _WeeklyReportSheetState();
}

class _WeeklyReportSheetState extends State<WeeklyReportSheet> {
  RecommendationFunnelReport? _report;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final loader = widget.reportLoader ?? WeeklyReportSheet._defaultLoader;
      final report = await loader();
      if (mounted) {
        setState(() => _report = report);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = '报告加载失败，稍后再试');
      }
    }
  }

  String _formatPeriod(RecommendationFunnelReport report) {
    final start = report.periodStart;
    final end = report.periodEnd;
    if (start == null || end == null) return '近 7 天';
    return '${start.month}月${start.day}日 - ${end.month}月${end.day}日';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('一周饮食报告', style: AppType.section)),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppPalette.moonMuted),
                ),
              )
            else if (_report == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else ..._buildReport(_report!),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReport(RecommendationFunnelReport report) {
    final overall = report.overall;
    return [
      Text(
        _formatPeriod(report),
        style: TextStyle(color: AppPalette.moonMuted, fontSize: 12.5),
      ),
      const SizedBox(height: AppSpacing.md),
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppDecorations.card(
          color: AppPalette.nightElevated.withValues(alpha: 0.82),
          borderColor: AppPalette.nightDivider,
        ),
        child: Column(
          children: [
            _StatRow(
              icon: Icons.visibility_outlined,
              label: '主厨推荐',
              value: '${overall.exposures} 次',
            ),
            _StatRow(
              icon: Icons.restaurant_menu_rounded,
              label: '定下这道',
              value: '${overall.confirmations} 道',
            ),
            _StatRow(
              icon: Icons.local_fire_department_outlined,
              label: '开吃',
              value: '${overall.executionStarts} 顿',
            ),
            _StatRow(
              icon: Icons.task_alt_rounded,
              label: '做完',
              value: '${overall.executionCompletions} 顿',
            ),
            _StatRow(
              icon: Icons.favorite_rounded,
              label: '新收藏',
              value: '${overall.favoriteAdds} 道',
            ),
            _StatRow(
              icon: Icons.refresh_rounded,
              label: '换一换',
              value: '${overall.rerolls} 次',
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppDecorations.card(
          color: AppPalette.leaf.withValues(alpha: 0.12),
          borderColor: AppPalette.leaf.withValues(alpha: 0.4),
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: AppPalette.leaf,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                WeeklyReportSheet.weeklyVerdict(report),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.moonlight,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppPalette.moonMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppPalette.moonlight,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppPalette.leaf,
            ),
          ),
        ],
      ),
    );
  }
}
