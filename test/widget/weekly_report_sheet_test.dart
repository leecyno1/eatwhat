import 'package:eatwhat_app/v2/core/services/v2_recommendation_funnel_insights.dart';
import 'package:eatwhat_app/v2/features/home/widgets/weekly_report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeeklyReportSheet.weeklyVerdict', () {
    test('没有曝光时引导开始使用', () {
      expect(
        WeeklyReportSheet.weeklyVerdict(_report()),
        contains('还没让主厨帮你选过菜'),
      );
    });

    test('做完比率高时表扬说到做到', () {
      final verdict = WeeklyReportSheet.weeklyVerdict(_report(
        exposures: 10,
        confirmations: 6,
        executionStarts: 5,
        executionCompletions: 4,
      ));
      expect(verdict, contains('说到做到'));
    });

    test('换一换频繁时体谅选择困难', () {
      final verdict = WeeklyReportSheet.weeklyVerdict(_report(
        exposures: 5,
        confirmations: 2,
        executionStarts: 1,
        rerolls: 8,
      ));
      expect(verdict, contains('选择困难'));
    });

    test('只看不定时鼓励明天试试', () {
      final verdict = WeeklyReportSheet.weeklyVerdict(_report(
        exposures: 6,
      ));
      expect(verdict, contains('明天试试'));
    });
  });

  group('WeeklyReportSheet', () {
    testWidgets('渲染周期、统计与判词', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyReportSheet(
              reportLoader: () async => _report(
                exposures: 12,
                confirmations: 5,
                executionStarts: 4,
                executionCompletions: 3,
                favoriteAdds: 1,
                rerolls: 2,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('一周饮食报告'), findsOneWidget);
      expect(find.text('9月23日 - 9月30日'), findsOneWidget);
      expect(find.text('12 次'), findsOneWidget);
      expect(find.text('5 道'), findsOneWidget);
      expect(find.text('4 顿'), findsOneWidget);
      expect(find.text('3 顿'), findsOneWidget);
      expect(find.textContaining('说到做到'), findsOneWidget);
    });

    testWidgets('加载失败时给出提示', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyReportSheet(
              reportLoader: () async => throw StateError('store unavailable'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('报告加载失败'), findsOneWidget);
    });
  });
}

RecommendationFunnelReport _report({
  int exposures = 0,
  int confirmations = 0,
  int executionStarts = 0,
  int executionCompletions = 0,
  int rerolls = 0,
  int favoriteAdds = 0,
}) {
  return RecommendationFunnelReport(
    periodStart: DateTime(2026, 9, 23),
    periodEnd: DateTime(2026, 9, 30),
    overall: RecommendationFunnelSummary(
      label: 'overall',
      exposures: exposures,
      candidateSelections: confirmations,
      confirmations: confirmations,
      rerolls: rerolls,
      favoriteAdds: favoriteAdds,
      favoriteRemovals: 0,
      positiveFeedback: 0,
      negativeFeedback: 0,
      executionStarts: executionStarts,
      executionCompletions: executionCompletions,
      executionDeferrals: 0,
    ),
    byAlgorithm: const [],
    byPrimarySource: const [],
    byResolutionStatus: const [],
  );
}
