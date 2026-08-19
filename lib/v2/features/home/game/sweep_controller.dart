import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'bubble_body.dart';
import 'bubble_game.dart';

/// Stage-level gesture controller, borrowing the tactile core of
/// pick-up games: the finger path selects entities (sweep), and pressing
/// down on one entity lets the player pull it out of the pile (grab).
///
/// - A drag that moves quickly becomes a sweep: entities touched by the
///   path light up, and the final flick decides collect (up) or block
///   (down); anything ambiguous cancels.
/// - Holding still on an entity for a beat grabs it: the entity follows
///   the finger while the pile collapses behind it. Releasing inside the
///   top tray zone collects it, inside the bottom discard zone blocks it,
///   anywhere else drops it back with a fling.
/// - A quick tap never reaches this handler; entities collect it on
///   release themselves.
///
/// The sweep trail renders as a fading neon streak on the HUD layer.
class SweepGestureHandler extends PositionComponent
    with HasGameReference<BubbleGame>, DragCallbacks {
  SweepGestureHandler() : super(position: Vector2.zero(), priority: 50);

  static const int _maxTrailPoints = 220;

  /// Movement (screen px) past which a press stops being a grab-in-waiting
  /// and becomes a sweep.
  static const double _sweepEngageDistance = 12;

  /// How long the finger must rest on an entity before the grab engages.
  static const double _grabEngageSeconds = 0.15;

  final List<Vector2> _points = [];
  final Set<BubbleBody> _pending = {};
  bool _dragging = false;
  double _fade = 0;

  _GesturePhase _phase = _GesturePhase.idle;
  double _holdElapsed = 0;
  BubbleBody? _grabCandidate;
  Vector2 _fingerScreen = Vector2.zero();

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
    _fingerScreen = event.canvasPosition.clone();
    _holdElapsed = 0;
    _grabCandidate = _entityAt(_fingerScreen);
    _phase = _GesturePhase.deciding;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_dragging) return;

    if (_phase == _GesturePhase.grabbing) {
      _fingerScreen = event.canvasEndPosition.clone();
      return;
    }

    final previous = _points.last;
    final current = event.canvasEndPosition.clone();

    if (_phase == _GesturePhase.deciding) {
      if (_points.first.distanceTo(current) > _sweepEngageDistance) {
        _phase = _GesturePhase.sweeping;
      } else {
        // Micro-jitter while waiting: keep the trail anchored so the sweep
        // doesn't light up from tremor alone.
        return;
      }
    }

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

    if (_phase == _GesturePhase.grabbing) {
      _releaseGrab(event.velocity);
    } else if (_phase == _GesturePhase.sweeping) {
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
    // A press that never moved and never engaged the grab is a tap; the
    // entity handles collection itself on release.
    _phase = _GesturePhase.idle;
    _grabCandidate = null;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _dragging = false;
    if (_phase == _GesturePhase.grabbing) {
      _releaseGrab(null);
    } else {
      _cancelPending();
    }
    _pending.clear();
    _phase = _GesturePhase.idle;
    _grabCandidate = null;
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

  BubbleBody? _entityAt(Vector2 screenPosition) {
    final world = game.camera.globalToLocal(screenPosition.clone());
    BubbleBody? closest;
    var best = double.infinity;
    for (final entity in game.entities) {
      if (entity.isRemoved || entity.isRejected) continue;
      final distance = world.distanceTo(entity.body.position);
      if (distance <= entity.reach && distance < best) {
        best = distance;
        closest = entity;
      }
    }
    return closest;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_dragging && _phase == _GesturePhase.deciding) {
      _holdElapsed += dt;
      final candidate = _grabCandidate;
      if (_holdElapsed >= _grabEngageSeconds &&
          candidate != null &&
          !candidate.isRemoved &&
          !candidate.isRejected) {
        _phase = _GesturePhase.grabbing;
        // A grabbed release also fires a tap on the entity; suppress it so
        // dropping the entity back doesn't double-collect it.
        game.suppressTapFor(const Duration(milliseconds: 450));
        candidate.beginGrab();
        candidate.updateGrab(
          game.camera.globalToLocal(_fingerScreen.clone()),
          _fingerScreen.y,
          size.y,
        );
      }
    }

    if (_dragging && _phase == _GesturePhase.grabbing) {
      _grabCandidate?.updateGrab(
        game.camera.globalToLocal(_fingerScreen.clone()),
        _fingerScreen.y,
        size.y,
      );
    }

    if (!_dragging) {
      _fade -= dt * 3.2;
      if (_fade <= 0 && _points.isNotEmpty) {
        _points.clear();
        _fade = 0;
      }
    }
  }

  void _releaseGrab(Vector2? screenVelocity) {
    final entity = _grabCandidate;
    if (entity == null || entity.isRemoved) return;

    final outcome = resolveGrabOutcome(
      releaseY: _fingerScreen.y,
      stageHeight: size.y,
    );

    Vector2? fling;
    if (screenVelocity != null && screenVelocity.length > 40) {
      fling = screenVelocity / BubbleGame.worldScale;
    }

    switch (outcome) {
      case GrabReleaseOutcome.collect:
        entity.endGrab(flingVelocity: null);
        entity.collect(withFeedback: true);
        break;
      case GrabReleaseOutcome.reject:
        entity.endGrab(flingVelocity: fling);
        entity.sweepReject();
        break;
      case GrabReleaseOutcome.drop:
        entity.endGrab(flingVelocity: fling);
        break;
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

enum _GesturePhase { idle, deciding, sweeping, grabbing }

/// What happens to a grabbed entity when the finger lifts, decided by
/// where on the stage it is released.
enum GrabReleaseOutcome { collect, reject, drop }

/// Depth of the tray zone at the top of the stage (screen px): releasing a
/// grabbed entity here collects it into the taste tray.
const double grabTrayZoneDepth = 84;

/// Depth of the discard zone at the bottom of the stage (screen px):
/// releasing a grabbed entity here blocks it.
const double grabDiscardZoneDepth = 96;

GrabReleaseOutcome resolveGrabOutcome({
  required double releaseY,
  required double stageHeight,
}) {
  if (releaseY <= grabTrayZoneDepth) return GrabReleaseOutcome.collect;
  if (releaseY >= stageHeight - grabDiscardZoneDepth) {
    return GrabReleaseOutcome.reject;
  }
  return GrabReleaseOutcome.drop;
}

/// Outcome of a finished sweep gesture, decided by the flick right before
/// the finger lifts.
enum SweepFlickIntent { up, down, cancel }

/// Minimum final-flick length (screen px) that counts as an intent.
const double sweepMinFlickLength = 26;

/// Distance looked back from the release point when measuring the flick.
const double sweepFlickLookback = 110;

/// Vertical dominance required: |dy| must be at least this fraction of
/// |dx| for the flick to read as up/down rather than sideways. Kept low so
/// diagonal flicks still register.
const double sweepVerticalDominance = 0.36;

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
          radius: 0.065 + rand.nextDouble() * 0.098,
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
