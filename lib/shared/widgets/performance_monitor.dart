import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:developer' as developer;

/// 性能监控组件
/// 监控FPS、内存使用等性能指标
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool showOverlay;
  final VoidCallback? onPerformanceIssue;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.showOverlay = false,
    this.onPerformanceIssue,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor>
    with TickerProviderStateMixin {
  late Ticker _ticker;
  final List<Duration> _frameDurations = [];
  double _currentFps = 0.0;
  int _droppedFrames = 0;
  Duration _lastFrameTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _startMonitoring() {
    _ticker = createTicker(_onTick);
    _ticker.start();
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
        
        _currentFps = 1000000 / avgFrameTime;

        // 检测掉帧
        if (frameDuration.inMilliseconds > 20) {  // 超过20ms算掉帧
          _droppedFrames++;
          
          // 性能问题回调
          if (_droppedFrames > 5 && widget.onPerformanceIssue != null) {
            widget.onPerformanceIssue!();
            _droppedFrames = 0;  // 重置计数
          }
        }
      }

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showOverlay) _buildPerformanceOverlay(),
      ],
    );
  }

  Widget _buildPerformanceOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FPS: ${_currentFps.toStringAsFixed(1)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              'Dropped: $_droppedFrames',
              style: TextStyle(
                color: _droppedFrames > 0 ? Colors.red : Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
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
