import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import 'bubble_data_manager.dart';
import 'bubble_game.dart';
import 'entity_geometry.dart';
import 'taste_entity_visual_catalog.dart';

/// A physical preference entity on the home stage.
///
/// The artwork itself is the body: the sprite is rendered as-is (no bubble
/// shell, no circular clip) and the collision shape is decomposed from the
/// sprite's alpha silhouette so entities fall, collide, and stack like real
/// objects under gravity. Selection happens through taps or the stage-level
/// sweep gesture (see [SweepGestureHandler]).
class BubbleBody extends BodyComponent<BubbleGame> with TapCallbacks {
  BubbleBody({
    required this.data,
    required this.targetLongSide,
    required this.initialPosition,
    this.initialHorizontalImpulse = 0,
  });

  final BubbleData data;

  /// Desired long-side length of the entity in world meters. The sprite and
  /// the collision fixtures are scaled from the artwork proportionally.
  final double targetLongSide;
  final Vector2 initialPosition;

  /// Small random sideways velocity for replenished entities so they drift
  /// naturally as they fall from the top.
  final double initialHorizontalImpulse;

  bool isSelected = false;
  bool isRejected = false; // For swipe down

  /// Highlighted by the sweep gesture and awaiting the final flick to decide
  /// between collecting and blocking.
  bool sweepPending = false;

  bool _isCollecting = false;
  double _collectionElapsed = 0;
  Vector2? _collectionStart;
  Vector2? _collectionTarget;

  EntityGeometry? _geometry;
  Sprite? _entitySprite;
  bool _loadFailed = false;

  // Sprite placement relative to the body origin (the silhouette centroid).
  Vector2 _spriteOffset = Vector2.zero();
  Vector2 _spriteSize = Vector2.zero();

  // Soft squash-and-stretch response when tapped.
  double _jellyScale = 1.0;
  double _jellyVelocity = 0.0;

  String get text => data.label;
  double get _halfSpan => targetLongSide * 0.5;

  /// Sweep hit radius (world meters), slightly padded so the finger path
  /// does not have to be pixel-perfect.
  double get reach => targetLongSide * 0.55 + 0.22;

  @override
  Future<void> onLoad() async {
    // Load the silhouette geometry before the body is created so the
    // fixtures can follow the artwork's true outline.
    final geometry =
        await EntityGeometry.load(data.assetName, data.assetPath);
    if (isRemoved) return;
    _geometry = geometry;
    if (geometry != null) {
      final scale = targetLongSide / geometry.longSidePixels;
      _spriteOffset = geometry.boundsCenterOffset * scale;
      _spriteSize = geometry.boundsSize * scale;
      _entitySprite = geometry.buildSprite();
    } else {
      _loadFailed = true;
      _spriteSize = Vector2.all(targetLongSide);
    }

    await super.onLoad(); // Creates the body via createBody().
    // Larger entities render above smaller ones for a natural depth feel.
    priority = (1000 - targetLongSide * 24).round();
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: initialPosition,
      type: BodyType.dynamic,
      angularDamping: 0.45,
      linearDamping: 0.08,
      linearVelocity: Vector2(initialHorizontalImpulse, 0),
    );
    final body = world.createBody(bodyDef);

    final geometry = _geometry;
    if (geometry == null) {
      // Fallback: asset missing or fully transparent.
      _createCircleFixture(body, radius: targetLongSide * 0.5);
      return body;
    }

    final scale = targetLongSide / geometry.longSidePixels;
    var fixtureCount = 0;
    for (final part in geometry.convexParts) {
      final vertices = _scaledAndWelded(part, scale);
      if (vertices.length < 3) continue;
      // Skip slivers that would degenerate inside Forge2D's own vertex
      // welding (its tolerance is 0.05m between adjacent vertices).
      if (polygonSignedArea(vertices).abs() < 0.01) continue;
      final shape = PolygonShape()..set(vertices);
      body.createFixture(
        FixtureDef(shape)
          ..density = 1.0
          ..friction = 0.55
          ..restitution = 0.02,
      );
      fixtureCount++;
    }
    if (fixtureCount == 0) {
      // Every part was too thin to survive welding; use a simple disc.
      _createCircleFixture(body, radius: targetLongSide * 0.5);
    }
    return body;
  }

  void _createCircleFixture(Body body, {required double radius}) {
    final shape = CircleShape()..radius = radius;
    body.createFixture(
      FixtureDef(shape)
        ..density = 1.0
        ..friction = 0.55
        ..restitution = 0.02,
    );
  }

  /// Scales pixel-space vertices into world meters and pre-welds vertices
  /// closer than Forge2D's own welding tolerance so [PolygonShape.set] never
  /// receives input that collapses below three vertices.
  List<Vector2> _scaledAndWelded(List<Vector2> part, double scale) {
    const weldDistance = 0.051; // Just above Forge2D's 0.05m tolerance.
    final points = <Vector2>[];
    for (final vertex in part) {
      final scaled = vertex * scale;
      var unique = true;
      for (final existing in points) {
        if (scaled.distanceToSquared(existing) <
            weldDistance * weldDistance) {
          unique = false;
          break;
        }
      }
      if (unique) points.add(scaled);
    }
    return points;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Spring simulation for the tap squash effect.
    const k = 150.0;
    const damping = 10.0;
    final force = -k * (_jellyScale - 1.0) - damping * _jellyVelocity;
    _jellyVelocity += force * dt;
    _jellyScale += _jellyVelocity * dt;

    if (_isCollecting) {
      _collectionElapsed += dt;
      final start = _collectionStart;
      final target = _collectionTarget;
      if (start != null && target != null) {
        final t = (_collectionElapsed / 0.36).clamp(0.0, 1.0);
        final eased = 1 - (1 - t) * (1 - t) * (1 - t);
        body.setTransform(start + (target - start) * eased, body.angle * (1 - t));
        if (t >= 1) {
          game.handleBubbleExplosion(this);
          removeFromParent();
        }
      }
    } else if (isRejected) {
      // Shove the rejected entity off the bottom of the stage.
      body.applyForce(Vector2(0, 90) * body.mass);
      body.linearDamping = 0.1;

      final screenHeight = game.camera.visibleWorldRect.bottom;
      if (body.position.y > screenHeight + 5) {
        game.handleBubbleRejection(this);
        removeFromParent();
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    collect(withFeedback: true);
  }

  /// Collects this entity into the taste tray. [withFeedback] controls the
  /// local haptics/jelly response; batch sweeps trigger it once for the
  /// whole gesture instead of once per entity.
  void collect({bool withFeedback = true}) {
    game.toggleSelection(this);
    game.emitSwipeFeedback(label: text, positive: true);
    _collectToTray();

    if (withFeedback) {
      _jellyVelocity = 9.0;
      HapticFeedback.mediumImpact();
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        unawaited(
          Vibration.vibrate(duration: 40).catchError((Object _) {}),
        );
      }
    } else {
      _jellyVelocity = 6.0;
    }

    if (isSelected) {
      data.usageCount++;
    }
    sweepPending = false;
  }

  /// Marks the entity as rejected: it sinks through the pile and off the
  /// stage while fading out.
  void sweepReject() {
    if (isRejected || _isCollecting) return;
    game.rejectBubble(this);
    sweepPending = false;
  }

  void _collectToTray() {
    if (_isCollecting) return;
    final viewport = game.camera.visibleWorldRect;
    _isCollecting = true;
    _collectionElapsed = 0;
    _collectionStart = body.position.clone();
    _collectionTarget = Vector2(
      viewport.right - _halfSpan - 1.1,
      viewport.top + _halfSpan + 0.8,
    );
    body
      ..setType(BodyType.kinematic)
      ..linearVelocity = Vector2.zero()
      ..angularVelocity = 0;
  }

  @override
  void render(Canvas canvas) {
    final sprite = _entitySprite;
    if (sprite == null) {
      if (_loadFailed) _drawGlyphFallback(canvas);
      return;
    }

    canvas.save();

    if (sweepPending && !_isCollecting) {
      // Pending sweep highlight: a soft halo behind the artwork plus a
      // gentle enlarge so the player sees exactly what a flick will commit.
      final glowPaint = Paint()
        ..color = const Color(0xFF7ABF88).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset.zero, _halfSpan * 1.05, glowPaint);
      canvas.drawCircle(
        Offset.zero,
        _halfSpan * 0.92,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.05
          ..color = const Color(0xFF7ABF88).withValues(alpha: 0.85),
      );
      canvas.scale(1.06, 1.06);
    }

    if (_isCollecting) {
      final t = (_collectionElapsed / 0.36).clamp(0.0, 1.0);
      final scale = 1 - t * 0.34;
      canvas.scale(scale, scale);
    } else {
      canvas.scale(_jellyScale, _jellyScale);
    }

    sprite.render(
      canvas,
      position: _spriteOffset,
      size: _spriteSize,
      anchor: Anchor.center,
      overridePaint: Paint()
        ..color = Colors.white.withValues(alpha: isRejected ? 0.42 : 1.0),
    );

    canvas.restore();
  }

  void _drawGlyphFallback(Canvas canvas) {
    final concept = TasteEntityVisualCatalog.conceptFor(text);
    final painter = TextPainter(
      text: TextSpan(
        text: concept.glyph,
        style: TextStyle(fontSize: targetLongSide * 0.62, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(-painter.width / 2, -painter.height / 2),
    );
  }
}
