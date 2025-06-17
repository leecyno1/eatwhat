import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'performance_test.dart';
import '../utils/ui_optimizer.dart';
import '../config/performance_config.dart';

/// 性能测试运行器，用于在应用中执行性能测试
class PerformanceTestRunner extends StatefulWidget {
  final Widget child;
  final bool showOverlay;
  final VoidCallback? onTestsComplete;

  const PerformanceTestRunner({
    Key? key,
    required this.child,
    this.showOverlay = false,
    this.onTestsComplete,
  }) : super(key: key);

  @override
  State<PerformanceTestRunner> createState() => _PerformanceTestRunnerState();
}

class _PerformanceTestRunnerState extends State<PerformanceTestRunner> {
  final PerformanceTest _performanceTest = PerformanceTest();
  bool _isRunningTests = false;
  String _testResults = '';
  bool _showResults = false;
  PerformanceTestSuite? _testSuite;

  @override
  void initState() {
    super.initState();
    // 注册快捷键
    _registerKeyHandlers();
  }

  @override
  void dispose() {
    // 取消快捷键注册
    _unregisterKeyHandlers();
    super.dispose();
  }

  void _registerKeyHandlers() {
    // 使用 RawKeyboard 监听器来捕获键盘事件
    RawKeyboard.instance.addListener(_handleKeyPress);
  }

  void _unregisterKeyHandlers() {
    RawKeyboard.instance.removeListener(_handleKeyPress);
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // 检测 Ctrl+Shift+P 组合键来运行性能测试
      if (event.isControlPressed && 
          event.isShiftPressed && 
          event.logicalKey == LogicalKeyboardKey.keyP) {
        _runPerformanceTests();
      }
      
      // 检测 Ctrl+Shift+H 组合键来隐藏/显示测试结果
      if (event.isControlPressed && 
          event.isShiftPressed && 
          event.logicalKey == LogicalKeyboardKey.keyH) {
        setState(() {
          _showResults = !_showResults;
        });
      }
    }
  }

  Future<void> _runPerformanceTests() async {
    if (_isRunningTests) return;

    setState(() {
      _isRunningTests = true;
      _testResults = '正在运行性能测试...';
      _showResults = true;
    });

    try {
      final testSuite = await _performanceTest.runTestSuite();
      setState(() {
        _testSuite = testSuite;
        _testResults = _performanceTest.generateReport();
        _isRunningTests = false;
      });

      if (widget.onTestsComplete != null) {
        widget.onTestsComplete!();
      }
    } catch (e) {
      setState(() {
        _testResults = '测试运行失败: $e';
        _isRunningTests = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showOverlay)
          Positioned(
            top: 0,
            right: 0,
            child: _buildPerformanceOverlay(),
          ),
        if (_showResults)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildTestResultsPanel(),
          ),
      ],
    );
  }

  Widget _buildPerformanceOverlay() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black.withOpacity(0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'FPS: ${UIOptimizer().currentFPS.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '内存: ${_formatMemory(UIOptimizer().currentMemoryUsage)}',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 4),
          ElevatedButton(
            onPressed: _isRunningTests ? null : _runPerformanceTests,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 0),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: Text(_isRunningTests ? '测试中...' : '运行性能测试'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResultsPanel() {
    return Container(
      height: 300,
      color: Colors.black.withOpacity(0.8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.blue,
            child: Row(
              children: [
                const Text(
                  '性能测试结果',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_testSuite != null)
                  Text(
                    '通过率: ${(_testSuite!.passRate * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: _testSuite!.allTestsPassed ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 16),
                  onPressed: () => setState(() => _showResults = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SelectableText(
                  _testResults,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
          if (_testSuite != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[900],
              child: Row(
                children: [
                  _buildResultSummaryItem(
                    '总测试数',
                    _testSuite!.totalTests.toString(),
                    Colors.blue,
                  ),
                  _buildResultSummaryItem(
                    '通过',
                    _testSuite!.passedTests.toString(),
                    Colors.green,
                  ),
                  _buildResultSummaryItem(
                    '失败',
                    _testSuite!.failedTests.toString(),
                    Colors.red,
                  ),
                  _buildResultSummaryItem(
                    '平均执行时间',
                    '${_testSuite!.averageExecutionTime.toStringAsFixed(1)}ms',
                    Colors.orange,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatMemory(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 性能测试页面，用于单独运行性能测试
class PerformanceTestPage extends StatefulWidget {
  const PerformanceTestPage({Key? key}) : super(key: key);

  @override
  State<PerformanceTestPage> createState() => _PerformanceTestPageState();
}

class _PerformanceTestPageState extends State<PerformanceTestPage> {
  final PerformanceTest _performanceTest = PerformanceTest();
  bool _isRunningTests = false;
  String _testResults = '';
  PerformanceTestSuite? _testSuite;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('性能测试'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildControlPanel(),
          Expanded(
            child: _buildResultsPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          ElevatedButton(
            onPressed: _isRunningTests ? null : _runPerformanceTests,
            child: Text(_isRunningTests ? '测试中...' : '运行性能测试'),
          ),
          const SizedBox(width: 16),
          if (_testSuite != null)
            Text(
              '通过率: ${(_testSuite!.passRate * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: _testSuite!.allTestsPassed ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          const Spacer(),
          OutlinedButton(
            onPressed: _testResults.isEmpty ? null : _copyResultsToClipboard,
            child: const Text('复制结果'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel() {
    if (_testResults.isEmpty) {
      return const Center(
        child: Text('点击"运行性能测试"按钮开始测试'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_testSuite != null)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildResultSummaryItem(
                      '总测试数',
                      _testSuite!.totalTests.toString(),
                      Colors.blue,
                    ),
                    _buildResultSummaryItem(
                      '通过',
                      _testSuite!.passedTests.toString(),
                      Colors.green,
                    ),
                    _buildResultSummaryItem(
                      '失败',
                      _testSuite!.failedTests.toString(),
                      Colors.red,
                    ),
                    _buildResultSummaryItem(
                      '平均执行时间',
                      '${_testSuite!.averageExecutionTime.toStringAsFixed(1)}ms',
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
          SelectableText(
            _testResults,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Future<void> _runPerformanceTests() async {
    if (_isRunningTests) return;

    setState(() {
      _isRunningTests = true;
      _testResults = '正在运行性能测试...';
    });

    try {
      final testSuite = await _performanceTest.runTestSuite();
      setState(() {
        _testSuite = testSuite;
        _testResults = _performanceTest.generateReport();
        _isRunningTests = false;
      });
    } catch (e) {
      setState(() {
        _testResults = '测试运行失败: $e';
        _isRunningTests = false;
      });
    }
  }

  void _copyResultsToClipboard() {
    Clipboard.setData(ClipboardData(text: _testResults));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('测试结果已复制到剪贴板')),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('性能测试设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('启用高级测试'),
              subtitle: const Text('包括内存和CPU使用率测试'),
              trailing: Switch(
                value: PerformanceConfig.enableAdvancedTesting,
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() {
                    PerformanceConfig.enableAdvancedTesting = value;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('测试迭代次数'),
              subtitle: Text('当前: ${PerformanceConfig.testIterations}'),
              trailing: DropdownButton<int>(
                value: PerformanceConfig.testIterations,
                items: [1, 3, 5, 10].map((value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    Navigator.pop(context);
                    setState(() {
                      PerformanceConfig.testIterations = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}