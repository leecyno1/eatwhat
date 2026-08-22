import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'bubble_body.dart';
import 'bubble_game.dart';

/// Stage-level grab controller: a tap collects a single entity (the entity
/// handles it on release), while pressing on an entity and dragging picks
/// it up out of the pile.
///
/// - Dragging past a small threshold, or resting the finger on an entity
///   for a beat, engages the grab: the entity follows the finger while the
///   pile collapses behind it.
/// - Releasing inside the top tray zone collects the entity, inside the
///   bottom discard zone blocks it, anywhere else drops it back with a
///   fling.
/// - The retired path-sweep multi-select is deliberately gone: it misfired
///   too easily, so selection is back to one deliberate gesture at a time.
class GrabGestureHandler extends PositionComponent
    with HasGameReference<BubbleGame>, DragCallbacks {
  GrabGestureHandler() : super(position: Vector2.zero(), priority: 50);

  /// Movement (screen px) past which a press on an entity engages the
  /// grab. Below this the gesture is still a tap-in-progress.
  static const double _grabEngageDistance = 12;

  /// How long the finger may rest on an entity before the grab engages
  /// without any movement.
  static const double _grabEngageSeconds = 0.15;

  _GesturePhase _phase = _GesturePhase.idle;
  double _holdElapsed = 0;
  Vector2 _pressStart = Vector2.zero();
  Vector2 _fingerScreen = Vector2.zero();
  BubbleBody? _grabCandidate;
  bool _dragging = false;

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
    _dragging = true;
    _pressStart = event.canvasPosition.clone();
    _fingerScreen = event.canvasPosition.clone();
    _holdElapsed = 0;
    _grabCandidate = _entityAt(_fingerScreen);
    _phase = _GesturePhase.pressing;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_dragging) return;
    _fingerScreen = event.canvasEndPosition.clone();

    if (_phase == _GesturePhase.pressing) {
      if (_pressStart.distanceTo(_fingerScreen) > _grabEngageDistance) {
        _engageGrab();
      }
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _dragging = false;
    if (_phase == _GesturePhase.grabbing) {
      _releaseGrab(event.velocity);
    }
    // A press that never engaged the grab is a plain tap; the entity
    // collects itself on release.
    _phase = _GesturePhase.idle;
    _grabCandidate = null;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _dragging = false;
    if (_phase == _GesturePhase.grabbing) {
      _releaseGrab(null);
    }
    _phase = _GesturePhase.idle;
    _grabCandidate = null;
  }

  void _engageGrab() {
    final candidate = _grabCandidate;
    if (candidate == null || candidate.isRemoved || candidate.isRejected) {
      _phase = _GesturePhase.idle;
      return;
    }
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

  @override
  void update(double dt) {
    super.update(dt);

    if (_dragging && _phase == _GesturePhase.pressing) {
      _holdElapsed += dt;
      if (_holdElapsed >= _grabEngageSeconds) {
        _engageGrab();
      }
    }

    if (_dragging && _phase == _GesturePhase.grabbing) {
      _grabCandidate?.updateGrab(
        game.camera.globalToLocal(_fingerScreen.clone()),
        _fingerScreen.y,
        size.y,
      );
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
        entity.rejectNow();
        break;
      case GrabReleaseOutcome.drop:
        entity.endGrab(flingVelocity: fling);
        break;
    }
  }

  /// Finds the entity under the finger. When the pot's overlapping layers
  /// stack several entities under one point, the front layer wins so the
  /// player always grabs what they can actually see on top.
  BubbleBody? _entityAt(Vector2 screenPosition) {
    final world = game.camera.globalToLocal(screenPosition.clone());
    BubbleBody? best;
    var bestDistance = double.infinity;
    for (final entity in game.entities) {
      if (entity.isRemoved || entity.isRejected) continue;
      final distance = world.distanceTo(entity.body.position);
      if (distance > entity.reach) continue;
      if (best == null ||
          entity.layerIndex > best.layerIndex ||
          (entity.layerIndex == best.layerIndex && distance < bestDistance)) {
        best = entity;
        bestDistance = distance;
      }
    }
    return best;
  }
}

enum _GesturePhase { idle, pressing, grabbing }

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

/// A short splash of particles spawned when an entity is collected or
/// blocked, giving the gesture an immediate cause-and-effect punch.
/// Golden entities burst into a shower of gold.
class SelectionBurst extends PositionComponent {
  SelectionBurst({
    required Vector2 position,
    required this.positive,
    required Color accent,
    this.golden = false,
  }) : super(position: position.clone(), priority: 600) {
    final rand = math.Random();
    for (var i = 0; i < (golden ? 24 : 16); i++) {
      final angle = rand.nextDouble() * math.pi * 2;
      final speed = 1.6 + rand.nextDouble() * (golden ? 3.4 : 2.6);
      _particles.add(
        _BurstParticle(
          velocity: Vector2(
            math.cos(angle) * speed,
            math.sin(angle) * speed - 1.4,
          ),
          life: 0.4 + rand.nextDouble() * (golden ? 0.45 : 0.3),
          radius: 0.065 + rand.nextDouble() * 0.098,
          color: golden
              ? _goldSpark(rand)
              : (positive
                  ? (rand.nextBool() ? const Color(0xFF7ABF88) : accent)
                  : (rand.nextBool() ? const Color(0xFFE4513F) : accent)),
        ),
      );
    }
  }

  final bool positive;
  final bool golden;
  final List<_BurstParticle> _particles = [];

  static Color _goldSpark(math.Random rand) {
    const sparks = [
      Color(0xFFFFD54F),
      Color(0xFFFFB300),
      Color(0xFFF59E0B),
      Color(0xFFFFE082),
    ];
    return sparks[rand.nextInt(sparks.length)];
  }

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
