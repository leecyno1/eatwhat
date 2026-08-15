import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import '../../../core/utils/performance_optimizer.dart';

/// 性能监控面板组件
/// 在 DEBUG 模式下显示 FPS、帧时间等性能指标
class PerformanceMonitorOverlay extends StatefulWidget {
  final Widget child;

  const PerformanceMonitorOverlay({
    super.key,
    required this.child,
  });

  @override
  State<PerformanceMonitorOverlay> createState() => _PerformanceMonitorOverlayState();
}

class _PerformanceMonitorOverlayState extends State<PerformanceMonitorOverlay> with TickerProviderStateMixin {
  bool _showPanel = false;
  double _fps = 60.0;
  int _droppedFrames = 0;
  final List<Duration> _frameDurations = [];
  Duration _lastFrameTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startFpsMonitoring();
    // 初始化性能优化器
    PerformanceOptimizer().initialize();
  }

  void _startFpsMonitoring() {
    final ticker = createTicker(_onTick);
    ticker.start();
  }

  void _onTick(Duration elapsed) {
    final frameDuration = elapsed - _lastFrameTime;
    _lastFrameTime = elapsed;

    if (frameDuration.inMicroseconds > 0) {
      _frameDurations.add(frameDuration);

      // 保持最近60帧的数据
      if (_frameDurations.length > 60) {
        _frameDurations.removeAt(0);
      }

      // 计算FPS
      if (_frameDurations.isNotEmpty) {
        final avgFrameTime = _frameDurations
            .map((d) => d.inMicroseconds)
            .reduce((a, b) => a + b) / _frameDurations.length;

        _fps = 1000000 / avgFrameTime;

        // 检测掉帧
        if (frameDuration.inMilliseconds > 20) {
          _droppedFrames++;
        }
      }

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 仅在 DEBUG 模式下显示
    const bool isDebugMode = bool.fromEnvironment('DEBUG_MODE', defaultValue: true);

    return Stack(
      children: [
        widget.child,
        if (isDebugMode) ...[
          // FPS 指示器
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _showPanel = !_showPanel),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _fps < 50 ? Colors.red.withValues(alpha: 0.8) : Colors.green.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_fps.toStringAsFixed(0)} FPS',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // 性能详情面板
          if (_showPanel) _buildPerformancePanel(),
        ],
      ],
    );
  }

  Widget _buildPerformancePanel() {
    final stats = PerformanceOptimizer().getPerformanceStats();
    final suggestions = PerformanceOptimizer().getOptimizationSuggestions();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 50,
      right: 8,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '性能监控',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow('FPS', _fps.toStringAsFixed(1)),
            _buildStatRow('掉帧', '$_droppedFrames'),
            _buildStatRow('平均帧时间', '${(stats['avgFrameTime'] ?? 0).toStringAsFixed(2)}ms'),
            _buildStatRow('最大帧时间', '${(stats['maxFrameTime'] ?? 0).toStringAsFixed(2)}ms'),
            _buildStatRow('活跃动画Widget', '${PerformanceOptimizer().animatedWidgetCount}'),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              const Text(
                '优化建议',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
              const SizedBox(height: 4),
              ...suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• $s',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// 性能测试工具
class PerformanceTester {
  static void logMemoryUsage(String tag) {
    developer.log('Memory check: $tag', name: 'Performance');
  }

  static void measureExecutionTime(String operation, Function() function) {
    final stopwatch = Stopwatch()..start();
    function();
    stopwatch.stop();

    developer.log(
      '$operation took ${stopwatch.elapsedMilliseconds}ms',
      name: 'Performance',
    );
  }

  static Future<void> measureAsyncExecutionTime(
    String operation,
    Future<void> Function() function,
  ) async {
    final stopwatch = Stopwatch()..start();
    await function();
    stopwatch.stop();

    developer.log(
      '$operation took ${stopwatch.elapsedMilliseconds}ms',
      name: 'Performance',
    );
  }
}
