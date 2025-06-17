import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/performance_optimizer.dart';
import '../utils/memory_manager.dart';
import '../utils/ui_optimizer.dart';
import '../config/performance_config.dart';

/// 性能监控仪表板
class PerformanceDashboard extends StatefulWidget {
  final bool showAsOverlay;
  final Widget? child;

  const PerformanceDashboard({
    Key? key,
    this.showAsOverlay = false,
    this.child,
  }) : super(key: key);

  @override
  State<PerformanceDashboard> createState() => _PerformanceDashboardState();
}

class _PerformanceDashboardState extends State<PerformanceDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Timer _updateTimer;
  
  final List<double> _fpsHistory = [];
  final List<double> _memoryHistory = [];
  final List<double> _cpuHistory = [];
  
  double _currentFPS = 0;
  int _currentMemory = 0;
  double _currentCPU = 0;
  
  bool _isVisible = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _startMonitoring();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _updateTimer.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        _updateMetrics();
      }
    });
  }

  void _updateMetrics() {
    setState(() {
      // 获取当前性能指标
      _currentFPS = UIOptimizer().currentFPS;
      _currentMemory = UIOptimizer().currentMemoryUsage;
      _currentCPU = _simulateCPUUsage(); // 模拟CPU使用率
      
      // 更新历史数据
      _fpsHistory.add(_currentFPS);
      _memoryHistory.add(_currentMemory.toDouble());
      _cpuHistory.add(_currentCPU);
      
      // 保持历史数据在合理范围内
      const maxHistoryLength = 60; // 30秒的数据
      if (_fpsHistory.length > maxHistoryLength) {
        _fpsHistory.removeAt(0);
      }
      if (_memoryHistory.length > maxHistoryLength) {
        _memoryHistory.removeAt(0);
      }
      if (_cpuHistory.length > maxHistoryLength) {
        _cpuHistory.removeAt(0);
      }
    });
  }

  double _simulateCPUUsage() {
    // 这里模拟CPU使用率，实际应用中需要使用平台特定的代码获取
    return math.Random().nextDouble() * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showAsOverlay) {
      return Stack(
        children: [
          if (widget.child != null) widget.child!,
          if (_isVisible)
            Positioned(
              top: 50,
              right: 10,
              child: _buildOverlayDashboard(),
            ),
        ],
      );
    }
    
    return _buildFullDashboard();
  }

  Widget _buildOverlayDashboard() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                '性能监控',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _isVisible = false),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildMetricRow('FPS', _currentFPS.toStringAsFixed(1), _getFPSColor()),
          _buildMetricRow('内存', _formatMemory(_currentMemory), _getMemoryColor()),
          _buildMetricRow('CPU', '${_currentCPU.toStringAsFixed(1)}%', _getCPUColor()),
          const SizedBox(height: 8),
          _buildMiniChart('FPS', _fpsHistory, Colors.green),
        ],
      ),
    );
  }

  Widget _buildFullDashboard() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('性能监控仪表板'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '概览', icon: Icon(Icons.dashboard)),
            Tab(text: '性能', icon: Icon(Icons.speed)),
            Tab(text: '内存', icon: Icon(Icons.memory)),
            Tab(text: '设置', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPerformanceTab(),
          _buildMemoryTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'FPS',
                  _currentFPS.toStringAsFixed(1),
                  Icons.speed,
                  _getFPSColor(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  '内存使用',
                  _formatMemory(_currentMemory),
                  Icons.memory,
                  _getMemoryColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'CPU使用率',
                  '${_currentCPU.toStringAsFixed(1)}%',
                  Icons.computer,
                  _getCPUColor(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  '优化状态',
                  PerformanceConfig.isOptimizationEnabled ? '已启用' : '已禁用',
                  Icons.tune,
                  PerformanceConfig.isOptimizationEnabled ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '性能趋势',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildChart('FPS', _fpsHistory, Colors.green, 0, 60),
          const SizedBox(height: 16),
          _buildChart('内存使用 (MB)', _memoryHistory.map((e) => e / (1024 * 1024)).toList(), Colors.blue, 0, null),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '性能详情',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildChart('FPS', _fpsHistory, Colors.green, 0, 60),
          const SizedBox(height: 16),
          _buildChart('CPU使用率 (%)', _cpuHistory, Colors.orange, 0, 100),
          const SizedBox(height: 24),
          _buildPerformanceStats(),
        ],
      ),
    );
  }

  Widget _buildMemoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '内存使用详情',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildChart('内存使用 (MB)', _memoryHistory.map((e) => e / (1024 * 1024)).toList(), Colors.blue, 0, null),
          const SizedBox(height: 24),
          _buildMemoryStats(),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '性能设置',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            '启用性能优化',
            '自动优化应用性能',
            PerformanceConfig.isOptimizationEnabled,
            (value) => PerformanceConfig.isOptimizationEnabled = value,
          ),
          _buildSettingItem(
            '启用内存管理',
            '自动管理内存使用',
            PerformanceConfig.enableMemoryManagement,
            (value) => PerformanceConfig.enableMemoryManagement = value,
          ),
          _buildSettingItem(
            '启用UI优化',
            '优化用户界面性能',
            PerformanceConfig.enableUIOptimization,
            (value) => PerformanceConfig.enableUIOptimization = value,
          ),
          _buildSettingItem(
            '启用性能监控',
            '监控应用性能指标',
            PerformanceConfig.enablePerformanceMonitoring,
            (value) => PerformanceConfig.enablePerformanceMonitoring = value,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _resetSettings,
            child: const Text('重置为默认设置'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart(String title, List<double> data, Color color) {
    if (data.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Container(
          height: 30,
          child: CustomPaint(
            painter: MiniChartPainter(data, color),
            size: const Size(double.infinity, 30),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(String title, List<double> data, Color color, double minY, double? maxY) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: CustomPaint(
                painter: ChartPainter(data, color, minY, maxY),
                size: const Size(double.infinity, 200),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceStats() {
    final avgFPS = _fpsHistory.isEmpty ? 0 : _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
    final minFPS = _fpsHistory.isEmpty ? 0 : _fpsHistory.reduce(math.min);
    final maxFPS = _fpsHistory.isEmpty ? 0 : _fpsHistory.reduce(math.max);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '性能统计',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow('平均FPS', avgFPS.toStringAsFixed(1)),
            _buildStatRow('最低FPS', minFPS.toStringAsFixed(1)),
            _buildStatRow('最高FPS', maxFPS.toStringAsFixed(1)),
            _buildStatRow('目标FPS', '60.0'),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryStats() {
    final memoryManager = MemoryManager();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '内存统计',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow('图片缓存', '${memoryManager.getImageCacheSize()} 项'),
            _buildStatRow('数据缓存', '${memoryManager.getDataCacheSize()} 项'),
            _buildStatRow('当前内存', _formatMemory(_currentMemory)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: value,
          onChanged: (newValue) {
            setState(() {
              onChanged(newValue);
            });
          },
        ),
      ),
    );
  }

  Color _getFPSColor() {
    if (_currentFPS >= 55) return Colors.green;
    if (_currentFPS >= 30) return Colors.orange;
    return Colors.red;
  }

  Color _getMemoryColor() {
    final memoryMB = _currentMemory / (1024 * 1024);
    if (memoryMB < 100) return Colors.green;
    if (memoryMB < 200) return Colors.orange;
    return Colors.red;
  }

  Color _getCPUColor() {
    if (_currentCPU < 50) return Colors.green;
    if (_currentCPU < 80) return Colors.orange;
    return Colors.red;
  }

  String _formatMemory(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _resetSettings() {
    setState(() {
      PerformanceConfig.resetToDefaults();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设置已重置为默认值')),
    );
  }
}

/// 迷你图表绘制器
class MiniChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  MiniChartPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();
    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
    final range = maxValue - minValue;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = range == 0 ? size.height / 2 : size.height - ((data[i] - minValue) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 图表绘制器
class ChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double minY;
  final double? maxY;

  ChartPainter(this.data, this.color, this.minY, this.maxY);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    
    final actualMaxY = maxY ?? data.reduce(math.max);
    final range = actualMaxY - minY;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = range == 0 ? size.height / 2 : size.height - ((data[i] - minY) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}