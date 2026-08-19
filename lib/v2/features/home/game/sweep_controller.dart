import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'bubble_body.dart';
import 'bubble_game.dart';

/// Stage-level sweep gesture, inspired by slice games: the finger path
/// itself selects entities, and the direction of the final flick decides
/// what happens to them.
///
/// - Entities touched by the drag path light up as pending.
/// - Releasing with an upward flick collects every pending entity.
/// - Releasing with a downward flick blocks them.
/// - Any other ending (horizontal drift, tiny movement, ambiguous flick)
///   cancels the sweep so sloppy gestures never misfire.
///
/// The trail renders as a fading neon streak on the HUD layer.
class SweepGestureHandler extends PositionComponent
    with HasGameReference<BubbleGame>, DragCallbacks {
  SweepGestureHandler() : super(position: Vector2.zero(), priority: 50);

  static const int _maxTrailPoints = 220;

  final List<Vector2> _points = [];
  final Set<BubbleBody> _pending = {};
  bool _dragging = false;
  double _fade = 0;

  @override
  bool containsPoint(Vector2 point) => true;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size.clone();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _points
      ..clear()
      ..add(event.canvasPosition.clone());
    _pending.clear();
    _dragging = true;
    _fade = 1;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_dragging) return;
    final previous = _points.last;
    final current = event.canvasEndPosition.clone();
    _points.add(current);
    if (_points.length > _maxTrailPoints) {
      _points.removeAt(0);
    }

    // Hit-test the fresh segment against every entity in world space.
    final from = game.camera.globalToLocal(previous.clone());
    final to = game.camera.globalToLocal(current.clone());
    for (final entity in game.entities) {
      if (entity.isRemoved || entity.isRejected) continue;
      if (_pending.contains(entity)) continue;
      final distance = _distanceToSegment(entity.body.position, from, to);
      if (distance <= entity.reach) {
        entity.sweepPending = true;
        _pending.add(entity);
      }
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _dragging = false;
    final intent = _resolveFlickIntent();
    if (intent == SweepFlickIntent.up) {
      game.collectEntities(_pending);
    } else if (intent == SweepFlickIntent.down) {
      game.rejectEntities(_pending);
    } else {
      _cancelPending();
    }
    _pending.clear();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _dragging = false;
    _cancelPending();
    _pending.clear();
  }

  void _cancelPending() {
    for (final entity in _pending) {
      if (!entity.isRemoved) entity.sweepPending = false;
    }
  }

  /// Measures only the tail of the path: mid-sweep wiggles never count,
  /// only the motion right before release does.
  SweepFlickIntent _resolveFlickIntent() =>
      resolveSweepFlickIntent(_points);

  @override
  void update(double dt) {
    super.update(dt);
    if (!_dragging) {
      _fade -= dt * 3.2;
      if (_fade <= 0 && _points.isNotEmpty) {
        _points.clear();
        _fade = 0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_points.length < 2) return;
    final alpha = _dragging ? 1.0 : _fade.clamp(0.0, 1.0);
    if (alpha <= 0) return;

    final path = Path()..moveTo(_points.first.x, _points.first.y);
    for (var i = 1; i < _points.length; i++) {
      path.lineTo(_points[i].x, _points[i].y);
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 9
        ..color = const Color(0xFF7ABF88).withValues(alpha: 0.30 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 3.5
        ..color = const Color(0xFFB8E8C2).withValues(alpha: 0.85 * alpha),
    );
  }

  static double _distanceToSegment(
    Vector2 point,
    Vector2 from,
    Vector2 to,
  ) {
    final ab = to - from;
    final abLengthSquared = ab.length2;
    if (abLengthSquared < 1e-9) {
      return point.distanceTo(from);
    }
    var t = (point - from).dot(ab) / abLengthSquared;
    t = t.clamp(0.0, 1.0);
    final projected = from + ab * t;
    return point.distanceTo(projected);
  }
}

/// Outcome of a finished sweep gesture, decided by the flick right before
/// the finger lifts.
enum SweepFlickIntent { up, down, cancel }

/// Minimum final-flick length (screen px) that counts as an intent.
const double sweepMinFlickLength = 30;

/// Distance looked back from the release point when measuring the flick.
const double sweepFlickLookback = 110;

/// Vertical dominance required: |dy| must be at least this fraction of
/// |dx| for the flick to read as up/down rather than sideways.
const double sweepVerticalDominance = 0.45;

/// Decides what a finished sweep means from its screen-space trail.
///
/// Only the tail of the path (roughly the last [sweepFlickLookback] px)
/// counts: a path that wanders up and down mid-sweep is judged by the
/// motion right before release, never by the whole path. An ambiguous or
/// lazy ending cancels the sweep so sloppy gestures never misfire.
SweepFlickIntent resolveSweepFlickIntent(List<Vector2> points) {
  if (points.length < 2) return SweepFlickIntent.cancel;

  var index = points.length - 1;
  var distance = 0.0;
  while (index > 0) {
    distance += points[index].distanceTo(points[index - 1]);
    if (distance >= sweepFlickLookback) break;
    index--;
  }

  final start = points[index];
  final end = points.last;
  final dx = end.x - start.x;
  final dy = end.y - start.y;
  final length = math.sqrt(dx * dx + dy * dy);
  if (length < sweepMinFlickLength) return SweepFlickIntent.cancel;

  if (dy < 0 && -dy >= dx.abs() * sweepVerticalDominance) {
    return SweepFlickIntent.up;
  }
  if (dy > 0 && dy >= dx.abs() * sweepVerticalDominance) {
    return SweepFlickIntent.down;
  }
  return SweepFlickIntent.cancel;
}

/// A short splash of particles spawned when an entity is collected or
/// blocked, giving the gesture an immediate cause-and-effect punch.
class SelectionBurst extends PositionComponent {
  SelectionBurst({
    required Vector2 position,
    required this.positive,
    required Color accent,
  }) : super(position: position.clone(), priority: 600) {
    final rand = math.Random();
    for (var i = 0; i < 16; i++) {
      final angle = rand.nextDouble() * math.pi * 2;
      final speed = 1.6 + rand.nextDouble() * 2.6;
      _particles.add(
        _BurstParticle(
          velocity: Vector2(
            math.cos(angle) * speed,
            math.sin(angle) * speed - 1.4,
          ),
          life: 0.4 + rand.nextDouble() * 0.3,
          radius: 0.05 + rand.nextDouble() * 0.075,
          color: positive
              ? (rand.nextBool() ? const Color(0xFF7ABF88) : accent)
              : (rand.nextBool() ? const Color(0xFFE4513F) : accent),
        ),
      );
    }
  }

  final bool positive;
  final List<_BurstParticle> _particles = [];

  @override
  void update(double dt) {
    super.update(dt);
    var alive = false;
    for (final particle in _particles) {
      if (particle.life <= 0) continue;
      particle
        ..position.add(particle.velocity * dt)
        ..velocity.y += 5.5 * dt
        ..life -= dt;
      alive = true;
    }
    if (!alive) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    for (final particle in _particles) {
      if (particle.life <= 0) continue;
      final alpha = particle.life.clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(particle.position.x, particle.position.y),
        particle.radius,
        Paint()..color = particle.color.withValues(alpha: alpha),
      );
    }
  }
}

class _BurstParticle {
  _BurstParticle({
    required this.velocity,
    required this.life,
    required this.radius,
    required this.color,
  });

  final Vector2 velocity;
  final Vector2 position = Vector2.zero();
  final double radius;
  final Color color;
  double life;
}
