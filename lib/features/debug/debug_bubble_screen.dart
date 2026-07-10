import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../bubble/controllers/physical_entity_controller.dart';
import '../../core/debug/bubble_debug_overlay.dart';
import '../bubble/widgets/physical_entity_widget.dart';
import '../../core/models/bubble.dart'; // 添加BubbleGesture导入

/// 调试专用气泡屏幕 - 用于Chrome Web调试
class DebugBubbleScreen extends StatefulWidget {
  const DebugBubbleScreen({super.key});

  @override
  State<DebugBubbleScreen> createState() => _DebugBubbleScreenState();
}

class _DebugBubbleScreenState extends State<DebugBubbleScreen> {
  late PhysicalEntityController _controller;
  final Map<String, List<Offset>> _entityTrails = {};
  Timer? _trailTimer;
  bool _showTrails = true;
  bool _showDebugInfo = true;
  int _frameCount = 0;
  DateTime _lastFrameTime = DateTime.now();
  double _fps = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = PhysicalEntityController();
    _controller.initialize();

    // 启动轨迹记录
    _startTrailRecording();

    // FPS计算
    _startFPSCounter();
  }

  void _startTrailRecording() {
    _trailTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;

      for (final entity in _controller.entities) {
        _entityTrails[entity.id] ??= [];
        _entityTrails[entity.id]!.add(entity.position);

        // 保持轨迹长度
        if (_entityTrails[entity.id]!.length > 20) {
          _entityTrails[entity.id]!.removeAt(0);
        }
      }

      if (_showTrails) {
        setState(() {});
      }
    });
  }

  void _startFPSCounter() {
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;

      _frameCount++;
      final now = DateTime.now();
      final elapsed = now.difference(_lastFrameTime);

      if (elapsed.inMilliseconds >= 1000) {
        _fps = _frameCount / elapsed.inSeconds;
        _frameCount = 0;
        _lastFrameTime = now;

        if (mounted) setState(() {});
      }
    });
  }

  /// 统一手势处理方法
  void _handleGesture(
      PhysicalEntityController controller, entity, BubbleGesture gesture,
      {DragUpdateDetails? details}) {
    switch (gesture) {
      case BubbleGesture.swipeUp:
        controller.likeEntity(entity.id);
        break;
      case BubbleGesture.swipeDown:
        controller.dislikeEntity(entity.id);
        break;
      case BubbleGesture.tap:
        controller.toggleEntity(entity);
        break;
      case BubbleGesture.swipeLeft:
      case BubbleGesture.swipeRight:
      case BubbleGesture.longPress:
      case BubbleGesture.dragStart:
      case BubbleGesture.dragUpdate:
      case BubbleGesture.dragEnd:
        // 其他手势暂不处理
        break;
    }
  }

  @override
  void dispose() {
    _trailTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '🔬 气泡调试器 (FPS: ${_fps.toStringAsFixed(1)})',
          style: const TextStyle(color: Colors.yellow),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showTrails ? Icons.timeline : Icons.timeline_outlined,
              color: _showTrails ? Colors.green : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _showTrails = !_showTrails;
              });
            },
          ),
          IconButton(
            icon: Icon(
              _showDebugInfo ? Icons.info : Icons.info_outline,
              color: _showDebugInfo ? Colors.green : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _showDebugInfo = !_showDebugInfo;
              });
            },
          ),
          IconButton(
            icon: Icon(
              _controller.isPhysicsRunning ? Icons.pause : Icons.play_arrow,
              color: _controller.isPhysicsRunning ? Colors.red : Colors.green,
            ),
            onPressed: () {
              // 暂时禁用物理引擎切换以解决乱窜问题
              // _controller.togglePhysics();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('物理引擎已暂时禁用以解决稳定性问题')),
              );
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: () {
              _controller.resetEntities();
              _entityTrails.clear();
              setState(() {});
            },
          ),
        ],
      ),
      body: ChangeNotifierProvider.value(
        value: _controller,
        child: Consumer<PhysicalEntityController>(
          builder: (context, controller, child) {
            return Stack(
              children: [
                // 主要气泡区域
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      controller.updateContainerSize(constraints.biggest);

                      return Stack(
                        children: [
                          // 轨迹层
                          if (_showTrails)
                            ...controller.entities.map((entity) {
                              final trail = _entityTrails[entity.id] ?? [];
                              if (trail.isEmpty) return const SizedBox.shrink();

                              return EntityTracker(
                                entity: entity,
                                trail: trail,
                              );
                            }),

                          // 气泡层
                          ...controller.entities.map((entity) {
                            return Positioned(
                              left: entity.position.dx - entity.radius,
                              top: entity.position.dy - entity.radius,
                              child: PhysicalEntityWidget(
                                entity: entity,
                                isSelected: controller.isEntitySelected(entity),
                                onTap: () => controller.toggleEntity(entity),
                                onSwipeUp: () => _handleGesture(
                                  controller,
                                  entity,
                                  BubbleGesture.swipeUp,
                                ),
                                onSwipeDown: () => _handleGesture(
                                  controller,
                                  entity,
                                  BubbleGesture.swipeDown,
                                ),
                                onSwipeLeft: () => _handleGesture(
                                  controller,
                                  entity,
                                  BubbleGesture.swipeLeft,
                                ),
                                onSwipeRight: () => _handleGesture(
                                  controller,
                                  entity,
                                  BubbleGesture.swipeRight,
                                ),
                              ),
                            );
                          }),

                          // 网格线
                          CustomPaint(
                            size: constraints.biggest,
                            painter: GridPainter(),
                          ),

                          // 边界标识
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.red.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // 调试信息覆盖层
                if (_showDebugInfo)
                  BubbleDebugOverlay(
                    entities: controller.entities,
                    isPhysicsRunning: controller.isPhysicsRunning,
                    containerSize: MediaQuery.of(context).size,
                  ),

                // 控制面板
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: _buildControlPanel(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                '停止物理',
                Icons.stop,
                Colors.red,
                () => _controller.pausePhysics(),
              ),
              _buildControlButton(
                '启动物理',
                Icons.play_arrow,
                Colors.grey,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('物理引擎已暂时禁用以解决稳定性问题')),
                  );
                },
              ),
              _buildControlButton(
                '重新分布',
                Icons.scatter_plot,
                Colors.blue,
                () => _controller.redistributeEntities(),
              ),
              _buildControlButton(
                '清空轨迹',
                Icons.clear,
                Colors.orange,
                () {
                  _entityTrails.clear();
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '状态: ${_controller.isPhysicsRunning ? "物理引擎运行中" : "物理引擎已停止"}',
            style: TextStyle(
              color: _controller.isPhysicsRunning ? Colors.red : Colors.green,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: color),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// 网格绘制器
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;

    // 绘制垂直线
    for (double x = 0; x <= size.width; x += 50) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // 绘制水平线
    for (double y = 0; y <= size.height; y += 50) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
