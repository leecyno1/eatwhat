import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/services/metrics_service.dart';
import '../../../core/models/metric_event.dart';
import '../../../core/theme/glassmorphism_theme.dart';

/// 运营数据看板页面
class MetricsDashboardScreen extends StatefulWidget {
  const MetricsDashboardScreen({super.key});

  @override
  State<MetricsDashboardScreen> createState() => _MetricsDashboardScreenState();
}

class _MetricsDashboardScreenState extends State<MetricsDashboardScreen> {
  final MetricsService _metricsService = MetricsService();
  MetricSummary? _summary;
  Map<String, int> _eventCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _metricsService.init();
      final summary = await _metricsService.getSummary();
      final eventCounts = _metricsService.getEventCounts();
      setState(() {
        _summary = summary;
        _eventCounts = eventCounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 动画背景
          _buildAnimatedBackground(),
          // 主内容
          _buildMainContent(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return GlassmorphismTheme.animatedGradientBackground(
      gradientSets: [
        GlassmorphismTheme.primaryGradients,
        GlassmorphismTheme.secondaryGradients,
      ],
      duration: const Duration(seconds: 20),
      child: Container(),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GlassmorphismTheme.floatingCard(
      margin: EdgeInsets.all(16.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: GlassmorphismTheme.glassContainer(
              padding: EdgeInsets.all(12.w),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              '运营数据',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: _loadData,
            child: GlassmorphismTheme.glassContainer(
              padding: EdgeInsets.all(12.w),
              child: Icon(
                Icons.refresh,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_summary == null) {
      return Center(
        child: Text(
          '暂无数据',
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 核心指标卡片
            _buildCoreMetricsSection(),
            SizedBox(height: 24.h),

            // 转化率指标
            _buildConversionMetricsSection(),
            SizedBox(height: 24.h),

            // 留存率图表
            _buildRetentionSection(),
            SizedBox(height: 24.h),

            // 事件统计
            _buildEventStatsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCoreMetricsSection() {
    return GlassmorphismTheme.floatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Icon(Icons.analytics, color: Colors.white, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  '核心指标',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'DAU',
                  _summary!.dau.toString(),
                  Icons.today,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  'MAU',
                  _summary!.mau.toString(),
                  Icons.calendar_month,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: EdgeInsets.all(8.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionMetricsSection() {
    return GlassmorphismTheme.floatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: Colors.white, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  '转化率指标',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildConversionBar(
            '推荐转化率',
            _summary!.recommendationConversionRate,
            Colors.green,
          ),
          _buildConversionBar(
            '气泡互动率',
            _summary!.bubbleInteractionRate,
            Colors.orange,
          ),
          _buildConversionBar(
            '订单完成率',
            _summary!.orderCompletionRate,
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildConversionBar(String label, double rate, Color color) {
    final percentage = (rate * 100).toStringAsFixed(1);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  color: color,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: rate.clamp(0, 1),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8.h,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionSection() {
    final retentionRates = _summary!.retentionRates;
    if (retentionRates.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassmorphismTheme.floatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.white, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  '留存率',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200.h,
            child: _buildRetentionChart(retentionRates),
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionChart(Map<int, double> retentionRates) {
    final spots = <FlSpot>[];
    retentionRates.entries.forEach((entry) {
      spots.add(FlSpot(entry.key.toDouble(), entry.value * 100));
    });

    // 排序
    spots.sort((a, b) => a.x.compareTo(b.x));

    if (spots.isEmpty) {
      return Center(
        child: Text(
          '暂无留存数据',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12.sp,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    'D${value.toInt()}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12.sp,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.pinkAccent,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: Colors.pinkAccent,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.pinkAccent.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventStatsSection() {
    if (_eventCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassmorphismTheme.floatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Icon(Icons.event_note, color: Colors.white, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  '事件统计（近7天）',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ..._eventCounts.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    entry.value.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
