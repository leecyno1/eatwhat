import 'package:flutter/material.dart';
import '../models/physical_entity.dart';

/// 气泡调试覆盖层 - 实时监控气泡状态
class BubbleDebugOverlay extends StatelessWidget {
  final List<PhysicalEntity> entities;
  final bool isPhysicsRunning;
  final Size? containerSize;

  const BubbleDebugOverlay({
    super.key,
    required this.entities,
    required this.isPhysicsRunning,
    this.containerSize,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🔬 气泡调试器',
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '物理引擎: ${isPhysicsRunning ? "运行中" : "已停止"}',
              style: TextStyle(
                color: isPhysicsRunning ? Colors.red : Colors.green,
                fontSize: 12,
              ),
            ),
            Text(
              '容器尺寸: ${containerSize?.width.toInt() ?? 0} x ${containerSize?.height.toInt() ?? 0}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              '实体数量: ${entities.length}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              '实体状态:',
              style: const TextStyle(color: Colors.yellow, fontSize: 12),
            ),
            ...entities.take(5).map((entity) => Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                '${entity.name}: V(${entity.velocity.dx.toStringAsFixed(2)}, ${entity.velocity.dy.toStringAsFixed(2)}) '
                'R=${entity.rotation.toStringAsFixed(2)} '
                'AV=${entity.angularVelocity.toStringAsFixed(3)}',
                style: TextStyle(
                  color: _getEntityStatusColor(entity),
                  fontSize: 10,
                ),
              ),
            )),
            if (entities.length > 5)
              Text(
                '... 和其他 ${entities.length - 5} 个实体',
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            const SizedBox(height: 8),
            Text(
              '总动能: ${_calculateTotalKineticEnergy().toStringAsFixed(2)}',
              style: TextStyle(
                color: _calculateTotalKineticEnergy() > 1 ? Colors.red : Colors.green,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEntityStatusColor(PhysicalEntity entity) {
    final speed = entity.velocity.distance;
    if (speed > 1.0) return Colors.red;
    if (speed > 0.1) return Colors.orange;
    return Colors.green;
  }

  double _calculateTotalKineticEnergy() {
    return entities.fold(0.0, (sum, entity) {
      final speed = entity.velocity.distance;
      return sum + (0.5 * entity.mass * speed * speed);
    });
  }
}

/// 实体轨迹追踪器
class EntityTracker extends StatelessWidget {
  final PhysicalEntity entity;
  final List<Offset> trail;

  const EntityTracker({
    super.key,
    required this.entity,
    required this.trail,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TrailPainter(trail, entity.primaryColor),
      child: Container(),
    );
  }
}

class TrailPainter extends CustomPainter {
  final List<Offset> trail;
  final Color color;

  TrailPainter(this.trail, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (trail.length < 2) return;

    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(trail.first.dx, trail.first.dy);

    for (int i = 1; i < trail.length; i++) {
      path.lineTo(trail[i].dx, trail[i].dy);
    }

    canvas.drawPath(path, paint);

    // 绘制点
    for (int i = 0; i < trail.length; i++) {
      final alpha = (i / trail.length * 255).toInt();
      final pointPaint = Paint()
        ..color = color.withAlpha(alpha)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(trail[i], 2.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}