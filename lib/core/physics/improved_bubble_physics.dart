import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bubble.dart';

/// 改进的气泡物理引擎
class ImprovedBubblePhysics {
  static const double _minBubbleDistance = 20.0; // 气泡之间最小距离
  static const double _maxAttempts = 100; // 最大尝试次数
  static const double _edgeMargin = 30.0; // 边缘边距

  /// 智能分布气泡位置，避免堆叠
  static void distributeeBubbles(List<Bubble> bubbles, Size screenSize) {
    if (bubbles.isEmpty || screenSize.width <= 0 || screenSize.height <= 0) {
      return;
    }

    final random = Random();
    final placedPositions = <Offset>[];

    // 计算有效区域
    final effectiveWidth = screenSize.width - (2 * _edgeMargin);
    final effectiveHeight = screenSize.height - (2 * _edgeMargin);

    for (int i = 0; i < bubbles.length; i++) {
      final bubble = bubbles[i];
      Offset? validPosition;

      // 尝试找到一个不与其他气泡重叠的位置
      for (int attempt = 0; attempt < _maxAttempts; attempt++) {
        final x = _edgeMargin + random.nextDouble() * effectiveWidth;
        final y = _edgeMargin + random.nextDouble() * effectiveHeight;
        final candidatePosition = Offset(x, y);

        // 检查是否与已放置的气泡重叠
        bool hasConflict = false;
        for (final placedPosition in placedPositions) {
          final distance = (candidatePosition - placedPosition).distance;
          if (distance < bubble.size + _minBubbleDistance) {
            hasConflict = true;
            break;
          }
        }

        if (!hasConflict) {
          validPosition = candidatePosition;
          break;
        }
      }

      // 如果找不到合适位置，使用网格布局作为备选
      validPosition ??= _getGridPosition(i, bubbles.length, screenSize);

      bubble.position = validPosition;
      placedPositions.add(validPosition);
    }
  }

  /// 网格布局作为备选方案
  static Offset _getGridPosition(int index, int totalCount, Size screenSize) {
    // 计算网格尺寸
    final columns = (sqrt(totalCount)).ceil();
    final rows = (totalCount / columns).ceil();

    final cellWidth = (screenSize.width - 2 * _edgeMargin) / columns;
    final cellHeight = (screenSize.height - 2 * _edgeMargin) / rows;

    final row = index ~/ columns;
    final col = index % columns;

    final x = _edgeMargin + col * cellWidth + cellWidth / 2;
    final y = _edgeMargin + row * cellHeight + cellHeight / 2;

    return Offset(x, y);
  }

  /// 应用物理运动效果
  static void applyPhysics(List<Bubble> bubbles, Size screenSize, Offset? repelPoint) {
    if (repelPoint != null) {
      _applyRepelForce(bubbles, repelPoint, screenSize);
    }

    _applyBoundaryConstraints(bubbles, screenSize);
    _applySeparationForce(bubbles);
  }

  /// 应用排斥力
  static void _applyRepelForce(List<Bubble> bubbles, Offset repelPoint, Size screenSize) {
    const repelRadius = 80.0;
    const repelStrength = 15.0;

    for (final bubble in bubbles) {
      final distance = (bubble.position - repelPoint).distance;
      if (distance < repelRadius && distance > 0) {
        final direction = (bubble.position - repelPoint).normalize();
        final force = (repelRadius - distance) / repelRadius * repelStrength;

        bubble.position += direction * force;
      }
    }
  }

  /// 应用边界约束
  static void _applyBoundaryConstraints(List<Bubble> bubbles, Size screenSize) {
    for (final bubble in bubbles) {
      final radius = bubble.size / 2;
      bubble.position = Offset(
        bubble.position.dx.clamp(radius + _edgeMargin, screenSize.width - radius - _edgeMargin),
        bubble.position.dy.clamp(radius + _edgeMargin, screenSize.height - radius - _edgeMargin),
      );
    }
  }

  /// 应用分离力防止气泡重叠
  static void _applySeparationForce(List<Bubble> bubbles) {
    const separationDistance = 80.0;
    const separationStrength = 2.0;

    for (int i = 0; i < bubbles.length; i++) {
      for (int j = i + 1; j < bubbles.length; j++) {
        final bubble1 = bubbles[i];
        final bubble2 = bubbles[j];

        final distance = (bubble1.position - bubble2.position).distance;
        if (distance < separationDistance && distance > 0) {
          final direction = (bubble1.position - bubble2.position).normalize();
          final force = (separationDistance - distance) / separationDistance * separationStrength;

          bubble1.position += direction * force / 2;
          bubble2.position -= direction * force / 2;
        }
      }
    }
  }

  /// 平滑位置变化
  static void smoothPositionChange(Bubble bubble, Offset targetPosition, double factor) {
    bubble.position = Offset.lerp(bubble.position, targetPosition, factor) ?? bubble.position;
  }

  /// 添加轻微的浮动效果
  static void addFloatingEffect(List<Bubble> bubbles, double time) {
    for (int i = 0; i < bubbles.length; i++) {
      final bubble = bubbles[i];
      final phase = time + i * 0.5; // 每个气泡有不同的相位

      // 添加轻微的sin波动
      final floatOffsetX = sin(phase) * 2.0;
      final floatOffsetY = cos(phase * 0.7) * 1.5;

      bubble.position = bubble.position + Offset(floatOffsetX, floatOffsetY);
    }
  }
}

/// 扩展Offset类添加normalize方法
extension OffsetExtension on Offset {
  Offset normalize() {
    final magnitude = distance;
    if (magnitude == 0) return Offset.zero;
    return this / magnitude;
  }
}
