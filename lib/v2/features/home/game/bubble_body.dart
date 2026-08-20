import 'dart:async';
import 'dart:math';
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
import 'grab_controller.dart';
import 'taste_entity_visual_catalog.dart';

/// A physical preference entity on the home stage.
///
/// The artwork itself is the body: the sprite is rendered as-is (no bubble
/// shell, no circular clip) and the collision shape is decomposed from the
/// sprite's alpha silhouette so entities fall, collide, and stack like real
/// objects under gravity. The stage is a pot: entities live on one of three
/// overlapping depth layers. Entities on the same layer collide with each
/// other (preserving the size-tier physics), while different layers pass
/// through each other and render on top of one another, so the pot stacks
/// several visible layers deep. Selection happens through taps or the
/// stage-level grab gesture (see [GrabGestureHandler]).
class BubbleBody extends BodyComponent<BubbleGame> with TapCallbacks {
  BubbleBody({
    required this.data,
    required this.targetLongSide,
    required this.initialPosition,
    required this.layerIndex,
    this.isGolden = false,
    this.initialHorizontalImpulse = 0,
  });

  final BubbleData data;

  /// Desired long-side length of the entity in world meters. The sprite and
  /// the collision fixtures are scaled from the artwork proportionally.
  final double targetLongSide;
  final Vector2 initialPosition;

  /// Depth layer in the pot, 0 (back) to [BubbleGame.potLayerCount] - 1
  /// (front). Entities only collide with the walls and with entities on
  /// the same layer; other layers overlap visually.
  final int layerIndex;

  /// A rare golden entity (see [BubbleGame.goldenEntityChance]). Pulses
  /// with a gold halo and weighs the preference more heavily when
  /// collected — buried treasure hidden in the pot.
  final bool isGolden;

  /// Small random sideways velocity for replenished entities so they drift
  /// naturally as they fall from the top.
  final double initialHorizontalImpulse;

  bool isSelected = false;
  bool isRejected = false;

  /// Held by the finger: follows the pointer while the pile collapses
  /// behind it (see GrabGestureHandler).
  bool isGrabbed = false;

  /// Which release zone the grabbed entity is currently hovering over,
  /// so the player sees what releasing will do before lifting.
  GrabReleaseOutcome grabZoneHint = GrabReleaseOutcome.drop;

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

  // Idle breathing: sleeping entities occasionally wobble a touch so the
  // pile reads as alive rather than a frozen screenshot.
  double _nextWobbleIn = _randomIdleWobbleDelay();
  static double _randomIdleWobbleDelay() => 3 + Random().nextDouble() * 6;

  // Golden halo breathing phase.
  double _goldenPhase = Random().nextDouble() * 6.28;

  String get text => data.label;
  double get _halfSpan => targetLongSide * 0.5;

  /// Opacity by depth layer: back layers fade slightly so the pot reads as
  /// having depth while every entity stays visible underneath.
  double get _layerAlpha => switch (layerIndex) {
        0 => 0.72,
        1 => 0.87,
        _ => 1.0,
      };

  /// Hit radius (world meters) used by the grab gesture's tap testing:
  /// the entity's own radius plus a finger tolerance.
  double get reach => targetLongSide * 0.5 + 0.18;

  /// Collision bits: walls live on bit 0, layer i owns bit i+1. Each entity
  /// collides with the walls and its own layer only, so overlapping layers
  /// never push each other around.
  int get _collisionCategory => 1 << (layerIndex + 1);
  int get _collisionMask => 0x0001 | (1 << (layerIndex + 1));

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
    // Front layers render above back layers (pot depth); within a layer,
    // larger entities render above smaller ones for a natural depth feel.
    priority =
        layerIndex * 400 + (1000 - targetLongSide * 24).round();
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
      final filter = Filter()
        ..categoryBits = _collisionCategory
        ..maskBits = _collisionMask;
      body.createFixture(
        FixtureDef(shape, filter: filter)
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
    final filter = Filter()
      ..categoryBits = _collisionCategory
      ..maskBits = _collisionMask;
    body.createFixture(
      FixtureDef(shape, filter: filter)
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

    if (isGolden) {
      _goldenPhase = (_goldenPhase + dt * 3.2) % (2 * pi);
    }

    // Spring simulation for the tap squash effect.
    const k = 150.0;
    const damping = 10.0;
    final force = -k * (_jellyScale - 1.0) - damping * _jellyVelocity;
    _jellyVelocity += force * dt;
    _jellyScale += _jellyVelocity * dt;

    // Idle breathing: every few seconds a sleeping entity wobbles a touch
    // so a settled pile still feels alive. Purely visual — the physics body
    // stays asleep.
    if (!_isCollecting && !isGrabbed && !isRejected) {
      _nextWobbleIn -= dt;
      if (_nextWobbleIn <= 0) {
        _nextWobbleIn = _randomIdleWobbleDelay();
        if (!body.isAwake) {
          _jellyVelocity = 0.45 + Random().nextDouble() * 0.3;
        }
      }
    }

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
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    // Collect on release, not on press: a finger that lands on an entity
    // and then sweeps away must not accidentally collect it. A grabbed
    // gesture suppresses the tap so dropping an entity doesn't double-fire.
    if (game.isTapSuppressed) return;
    collect(withFeedback: true);
  }

  /// Pins the entity to the finger as a kinematic body. The pile it was
  /// supporting collapses on its own — that collapse is the whole point of
  /// the grab.
  void beginGrab() {
    if (isRemoved || isRejected) return;
    isGrabbed = true;
    grabZoneHint = GrabReleaseOutcome.drop;
    body
      ..setType(BodyType.kinematic)
      ..linearVelocity = Vector2.zero()
      ..angularVelocity = 0;
    _jellyVelocity = 4.5;
    HapticFeedback.selectionClick();
  }

  /// Moves the grabbed entity toward the finger with a little lag, slowly
  /// righting its rotation, and previews which release zone it hovers in.
  void updateGrab(Vector2 fingerWorld, double fingerScreenY, double stageHeight) {
    if (!isGrabbed) return;
    final target = body.position + (fingerWorld - body.position) * 0.35;
    body.setTransform(target, body.angle * 0.90);
    grabZoneHint = resolveGrabOutcome(
      releaseY: fingerScreenY,
      stageHeight: stageHeight,
    );
  }

  /// Lets go: the entity becomes dynamic again, optionally inheriting the
  /// finger's fling velocity.
  void endGrab({Vector2? flingVelocity}) {
    if (!isGrabbed) return;
    isGrabbed = false;
    grabZoneHint = GrabReleaseOutcome.drop;
    if (body.bodyType != BodyType.dynamic) {
      body.setType(BodyType.dynamic);
    }
    final fling = flingVelocity;
    if (fling != null && fling.length > 0.5) {
      final capped = fling.clone();
      if (capped.length > 14) {
        capped.scale(14 / capped.length);
      }
      body
        ..linearVelocity = capped
        ..angularVelocity = (fling.x * 0.15).clamp(-4.0, 4.0);
    }
    _jellyVelocity = -3.0;
  }

  /// Collects this entity into the taste tray. Golden entities land with a
  /// heavier haptic and a rare-find chip so the treasure moment is felt.
  void collect({bool withFeedback = true}) {
    game.spawnSelectionBurst(this, positive: true);
    game.toggleSelection(this);
    game.emitSwipeFeedback(
      label: isGolden ? '✨ 稀有偏好 · $text' : text,
      positive: true,
    );
    _collectToTray();

    if (withFeedback) {
      _jellyVelocity = 9.0;
      if (isGolden) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        unawaited(
          Vibration.vibrate(duration: isGolden ? 90 : 40)
              .catchError((Object _) {}),
        );
      }
    } else {
      _jellyVelocity = 6.0;
    }

    if (isSelected) {
      data.usageCount++;
    }
  }

  /// Marks the entity as rejected: it sinks through the pile and off the
  /// stage while fading out.
  void rejectNow() {
    if (isRejected || _isCollecting) return;
    game.spawnSelectionBurst(this, positive: false);
    game.rejectBubble(this);
  }

  /// Shake-to-stir: fling the entity upward with a random spin so shaking
  /// the phone re-arranges the whole pot and every entity lands at a new
  /// angle for inspection.
  void stirUp(Random rand) {
    if (isRemoved || isRejected || isGrabbed || _isCollecting) return;
    if (body.bodyType != BodyType.dynamic) {
      body.setType(BodyType.dynamic);
    }
    body
      ..setAwake(true)
      ..linearVelocity = Vector2(
        (rand.nextDouble() - 0.5) * 6.0,
        -(3.6 + rand.nextDouble() * 3.4),
      )
      ..angularVelocity = (rand.nextDouble() - 0.5) * 9.0;
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

    if (isGolden && !_isCollecting) {
      // Golden rare: a breathing gold halo marks the buried treasure,
      // visible even through the pot's overlapping layers.
      final pulse = 0.5 + 0.5 * sin(_goldenPhase);
      final haloRadius = _halfSpan * (1.08 + pulse * 0.16);
      final haloPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.34 + pulse * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(Offset.zero, haloRadius, haloPaint);
      canvas.drawCircle(
        Offset.zero,
        _halfSpan * 0.96,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.06
          ..color = const Color(0xFFFFD54F)
            .withValues(alpha: 0.55 + pulse * 0.4),
      );
    }

    if (isGrabbed) {
      // Held by the finger: a stronger halo, a bigger lift, and a zone
      // hint ring that turns leaf-green over the tray and tomato-red over
      // the discard zone so the release outcome is always visible.
      final hintColor = switch (grabZoneHint) {
        GrabReleaseOutcome.collect => const Color(0xFF9FD8AC),
        GrabReleaseOutcome.reject => const Color(0xFFE4513F),
        GrabReleaseOutcome.drop => const Color(0xFF7ABF88),
      };
      final glowPaint = Paint()
        ..color = hintColor.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawCircle(Offset.zero, _halfSpan * 1.15, glowPaint);
      canvas.drawCircle(
        Offset.zero,
        _halfSpan * 0.98,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.06
          ..color = hintColor,
      );
      canvas.scale(1.10, 1.10);
    }

    if (_isCollecting) {
      final t = (_collectionElapsed / 0.36).clamp(0.0, 1.0);
      final scale = 1 - t * 0.34;
      canvas.scale(scale, scale);
    } else {
      canvas.scale(_jellyScale, _jellyScale);
    }

    final opacity = _layerAlpha * (isRejected ? 0.42 : 1.0);
    sprite.render(
      canvas,
      position: _spriteOffset,
      size: _spriteSize,
      anchor: Anchor.center,
      overridePaint: Paint()
        ..color = Colors.white.withValues(alpha: opacity),
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
