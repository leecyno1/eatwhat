// ignore_for_file: unused_field, unused_local_variable, unused_element, unused_element_parameter, deprecated_member_use, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';

import 'bubble_data_manager.dart';
import 'bubble_game.dart';
import 'taste_entity_visual_catalog.dart';

enum _BubbleVisualLayer { foreground, middle, background }

class BubbleBody extends BodyComponent<BubbleGame>
    with TapCallbacks, DragCallbacks {
  static const _malformedAssetIds = {
    'c_american',
    'c_bbq',
    'c_halal',
    'c_hotpot',
    'c_italian',
    'c_mexican',
  };

  final BubbleData data;
  final double radius;
  final Vector2 initialPosition;

  bool isSelected = false;
  bool isRejected = false; // For swipe down

  // Drag handling
  Vector2? _dragStartPos;
  final Vector2 _dragDistance = Vector2.zero();
  bool _isDragging = false;
  bool _isCollecting = false;
  double _collectionElapsed = 0;
  Vector2? _collectionStart;
  Vector2? _collectionTarget;
  Sprite? _entitySprite;
  TextPaint? _entityLabelPaint;
  late final double _depthFactor = (radius / 2.2).clamp(0.58, 1.0);
  late final double _driftPhase = (data.id.hashCode.abs() % 360) * (pi / 180.0);

  String get text => data.label;

  _BubbleVisualLayer get _visualLayer {
    if (radius >= 1.85) return _BubbleVisualLayer.foreground;
    if (radius >= 1.48) return _BubbleVisualLayer.middle;
    return _BubbleVisualLayer.background;
  }

  BubbleBody({
    required this.data,
    required this.radius,
    required this.initialPosition,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    priority = (radius * 100).round();
    _entityLabelPaint = TextPaint(
      style: GoogleFonts.notoSansSc(
        color: const Color(0xFF173D2A),
        fontSize: radius * 0.27 + 0.08,
        fontWeight: FontWeight.w800,
        height: 1,
        letterSpacing: 0.04,
      ),
    );
    if (_malformedAssetIds.contains(data.id)) return;
    try {
      final image = await game.images.load(data.assetName);
      final region = await _centeredEntityRegion(image);
      _entitySprite = Sprite(
        image,
        srcPosition: region.position,
        srcSize: region.size,
      );
    } catch (error) {
      debugPrint('Preference entity asset failed: ${data.assetName}: $error');
    }
  }

  Future<({Vector2 position, Vector2 size})> _centeredEntityRegion(
    ui.Image image,
  ) async {
    final byteData = await image.toByteData();
    final width = image.width;
    final height = image.height;
    var cropBottom = height.toDouble();

    if (byteData != null) {
      final pixels = byteData.buffer.asUint8List();
      final opaqueByRow = List<int>.filled(height, 0);
      for (var index = 0; index < width * height; index++) {
        if (pixels[index * 4 + 3] > 28) {
          opaqueByRow[index ~/ width]++;
        }
      }

      final valleyStart = (height * 0.55).round();
      final valleyEnd = (height * 0.93).round();
      var valleyY = valleyStart;
      for (var y = valleyStart + 1; y <= valleyEnd; y++) {
        if (opaqueByRow[y] < opaqueByRow[valleyY]) valleyY = y;
      }
      var maxAfterValley = 0;
      for (var y = valleyY + 1; y < height; y++) {
        maxAfterValley = max(maxAfterValley, opaqueByRow[y]);
      }
      final hasTrailingEntity = opaqueByRow[valleyY] < width * 0.45 &&
          maxAfterValley > opaqueByRow[valleyY] + width * 0.16;
      if (hasTrailingEntity) cropBottom = valleyY + 1.0;
    }

    final baseSide = min(width.toDouble(), cropBottom);
    const cropRatio = 0.72;
    const cropTopRatio = 0.05;
    final cropSide = baseSide * cropRatio;
    final baseLeft = (width - baseSide) / 2;
    final baseTop = (cropBottom - baseSide) / 2;
    return (
      position: Vector2(
        baseLeft + (baseSide - cropSide) / 2,
        baseTop + baseSide * cropTopRatio,
      ),
      size: Vector2.all(cropSide),
    );
  }

  @override
  Body createBody() {
    // Use CircleShape for physics collision to keep it smooth
    // Even if visual is hexagon/star, circle physics feels better for bubbles
    final shape = CircleShape()..radius = radius;

    final fixtureDef = FixtureDef(shape)
      ..restitution = 0.42
      ..density = 0.88 + _depthFactor * 0.28
      ..friction = 0.18;

    final bodyDef = BodyDef(
      position: initialPosition,
      type: BodyType.dynamic,
      angularDamping: 4.2,
      linearDamping: 1.15,
    );

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  // Animation state
  double _animationTime = 0;
  double _jellyScale = 1.0;
  double _jellyVelocity = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _animationTime += dt;

    // Jelly physics simulation (spring)
    // Target scale is 1.0.
    // Force = -k * (current - target) - damping * velocity
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
        final eased = 1 - pow(1 - t, 3).toDouble();
        body.setTransform(
            start + (target - start) * eased, body.angle * (1 - t));
        if (t >= 1) {
          game.handleBubbleExplosion(this);
          removeFromParent();
        }
      }
    }
    // Logic for "Rejected" (Heavy gravity / Falling)
    else if (isRejected) {
      body.applyForce(Vector2(0, 80) * body.mass); // Heavy downward force
      body.linearDamping = 0.5; // Less friction to fall faster

      // Check if off-screen (bottom)
      final screenHeight = game.camera.visibleWorldRect.bottom;
      if (body.position.y > screenHeight + 5) {
        game.handleBubbleRejection(this); // Notify game to replenish
        removeFromParent(); // Remove when off screen
      }
    } else {
      body.linearDamping = 1.15;
      final drift = sin(_animationTime * 0.72 + _driftPhase) * body.mass * 0.24;
      final displacement =
          (initialPosition.y - body.position.y).clamp(-7.0, 7.0).toDouble();
      final buoyancyRatio = 0.62 + (1 - _depthFactor) * 0.20;
      final verticalForce =
          -world.gravity.y * buoyancyRatio + displacement * 0.52;
      body.applyForce(Vector2(drift, verticalForce) * body.mass);
    }

    if (!_isDragging && !isRejected) {
      final uprightAngle = atan2(sin(body.angle), cos(body.angle));
      body.angularVelocity +=
          (-uprightAngle * 8.5 - body.angularVelocity * 2.4) * dt;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    _handleSelection();
  }

  void _handleSelection() {
    game.toggleSelection(this);
    game.emitSwipeFeedback(label: text, positive: isSelected);
    _collectToTray();

    // Trigger Jelly effect
    _jellyVelocity = 15.0; // Initial impulse for scale

    // Haptic feedback
    HapticFeedback.mediumImpact();
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      unawaited(
        Vibration.vibrate(duration: 50).catchError((Object _) {}),
      );
    }

    // Update usage count for memory system
    if (isSelected) {
      data.usageCount++;
    }
  }

  void _collectToTray() {
    if (_isCollecting) return;
    final viewport = game.camera.visibleWorldRect;
    _isCollecting = true;
    _collectionElapsed = 0;
    _collectionStart = body.position.clone();
    _collectionTarget = Vector2(
      viewport.right - radius - 1.1,
      viewport.top + radius + 0.8,
    );
    body
      ..setType(BodyType.kinematic)
      ..linearVelocity = Vector2.zero()
      ..angularVelocity = 0;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _dragStartPos = event.localPosition;
    _dragDistance.setZero();
    _isDragging = true;
    body
      ..setType(BodyType.kinematic)
      ..linearVelocity = Vector2.zero()
      ..angularVelocity = 0;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _isDragging = false;

    if (_dragStartPos == null) return;
    body.setType(BodyType.dynamic);

    if (_dragDistance.y < -54) {
      if (!isSelected) _handleSelection();
    } else if (_dragDistance.y > 54) {
      game.rejectBubble(this);
      game.emitSwipeFeedback(label: text, positive: false);
      HapticFeedback.heavyImpact();
    } else {
      final throwVelocity = event.velocity / BubbleGame.worldScale;
      if (throwVelocity.length > 18) {
        throwVelocity.normalize();
        throwVelocity.scale(18);
      }
      body
        ..linearVelocity = throwVelocity
        ..angularVelocity = (_dragDistance.x / 42).clamp(-4.5, 4.5);
    }
    _dragStartPos = null;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_isDragging) return;

    _dragDistance.add(event.canvasDelta);
    final worldDelta = event.canvasDelta / BubbleGame.worldScale;
    body.setTransform(
      body.position + worldDelta,
      body.angle + event.canvasDelta.x * 0.006,
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.save();

    if (isRejected) {
      canvas.scale(0.8, 1.2);
    } else if (_isCollecting) {
      final t = (_collectionElapsed / 0.36).clamp(0.0, 1.0);
      final scale = 1 - t * 0.38;
      canvas.scale(scale, scale);
    } else {
      canvas.scale(_jellyScale, _jellyScale);
    }

    canvas.translate(
      sin(_animationTime * (0.55 + _depthFactor * 0.15) + _driftPhase) *
          radius *
          0.035,
      cos(_animationTime * (0.40 + _depthFactor * 0.10) + _driftPhase) *
          radius *
          0.028,
    );

    _drawFreshEntity(canvas);

    canvas.restore();
  }

  void _drawFreshEntity(Canvas canvas) {
    final r = radius;
    final sprite = _entitySprite;
    final layerAlpha = switch (_visualLayer) {
      _BubbleVisualLayer.foreground => 1.0,
      _BubbleVisualLayer.middle => 0.94,
      _BubbleVisualLayer.background => 0.90,
    };
    final shellColor = _entityShellColor;
    final shadowPaint = Paint()
      ..color = const Color(0xFF173D25).withValues(alpha: 0.14 * layerAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, r * 0.72),
        width: r * 1.44,
        height: r * 0.34,
      ),
      shadowPaint,
    );

    final shellRect = Rect.fromCircle(center: Offset.zero, radius: r * 0.93);
    canvas.drawCircle(
      Offset.zero,
      r * 0.93,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.42, -0.56),
          radius: 1.12,
          colors: [
            Colors.white.withValues(alpha: 0.96 * layerAlpha),
            shellColor.withValues(alpha: 0.31 * layerAlpha),
            shellColor.withValues(alpha: 0.15 * layerAlpha),
          ],
          stops: const [0, 0.62, 1],
        ).createShader(shellRect),
    );

    final artworkCenter = Offset(0, -r * 0.07);
    final artworkRadius = r * 0.66;
    canvas.save();
    canvas.clipPath(
      Path()
        ..addOval(
            Rect.fromCircle(center: artworkCenter, radius: artworkRadius)),
    );
    if (sprite != null) {
      sprite.render(
        canvas,
        position: Vector2(artworkCenter.dx, artworkCenter.dy),
        size: Vector2.all(artworkRadius * 1.98),
        anchor: Anchor.center,
        overridePaint: Paint()
          ..color = Colors.white.withValues(
            alpha: (isRejected ? 0.42 : 1) * layerAlpha,
          ),
      );
    } else {
      canvas.translate(artworkCenter.dx, artworkCenter.dy);
      canvas.scale(0.72);
      if (_malformedAssetIds.contains(data.id)) {
        _drawMalformedArtwork(canvas, r);
      } else if (!_drawSpecificFood(canvas)) {
        _drawConceptGlyph(canvas, r);
      }
    }
    canvas.restore();

    canvas.drawCircle(
      artworkCenter,
      artworkRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.025
        ..color = Colors.white.withValues(alpha: 0.78 * layerAlpha),
    );

    if (sprite == null) {
      _drawEntityLabel(canvas, r, layerAlpha);
    }

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? r * 0.075 : r * 0.025
      ..color = (isSelected ? const Color(0xFF2F9848) : Colors.white)
          .withValues(alpha: isSelected ? 0.98 : 0.72 * layerAlpha);
    canvas.drawCircle(Offset.zero, r * 0.93, rimPaint);

    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.84),
      pi * 1.06,
      pi * 0.62,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.045
        ..color = Colors.white.withValues(alpha: 0.52 * layerAlpha),
    );

    if (isSelected) _drawSelectionBadge(canvas, r);
  }

  Color get _entityShellColor => switch (data.type) {
        BubbleType.ingredient => const Color(0xFF8ACB87),
        BubbleType.flavor => const Color(0xFFF3A86A),
        BubbleType.cuisine => const Color(0xFF78B7A0),
        BubbleType.scene => const Color(0xFF91AEDD),
        BubbleType.staple => const Color(0xFFE8C576),
        BubbleType.dietary => const Color(0xFF73BE91),
        BubbleType.fortune => const Color(0xFFE9A4B2),
        BubbleType.meta => const Color(0xFFC7A6DB),
      };

  void _drawMalformedArtwork(Canvas canvas, double r) {
    final glyph = switch (data.id) {
      'c_american' => '🍔',
      'c_bbq' => '🍢',
      'c_halal' => '☪',
      'c_hotpot' => '🍲',
      'c_italian' => '🍕',
      'c_mexican' => '🌮',
      _ => '🍽️',
    };
    final painter = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          fontSize: r * (data.id == 'c_halal' ? 0.84 : 0.96),
          height: 1,
          color: data.id == 'c_halal' ? const Color(0xFF176B43) : null,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(-painter.width / 2, -painter.height / 2),
    );
  }

  void _drawEntityLabel(Canvas canvas, double r, double alpha) {
    final compact = _compactLabel;
    final textPaint = _entityLabelPaint;
    if (textPaint == null) return;
    final labelWidth = (textPaint.toTextPainter(compact).width + r * 0.32)
        .clamp(r * 0.92, r * 1.48)
        .toDouble();
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, r * 0.59),
        width: labelWidth,
        height: r * 0.38,
      ),
      Radius.circular(r * 0.19),
    );
    canvas.drawRRect(
      labelRect.shift(Offset(0, r * 0.035)),
      Paint()..color = const Color(0xFF173D25).withValues(alpha: 0.08 * alpha),
    );
    canvas.drawRRect(
      labelRect,
      Paint()..color = Colors.white.withValues(alpha: 0.90 * alpha),
    );
    textPaint.render(
      canvas,
      compact,
      Vector2(0, labelRect.outerRect.center.dy),
      anchor: Anchor.center,
    );
  }

  void _drawSelectionBadge(Canvas canvas, double r) {
    final badgeCenter = Offset(r * 0.62, -r * 0.62);
    canvas.drawCircle(
      badgeCenter,
      r * 0.22,
      Paint()..color = const Color(0xFF2F9848),
    );
    final checkPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.check_rounded.codePoint),
        style: TextStyle(
          fontSize: r * 0.27,
          fontFamily: Icons.check_rounded.fontFamily,
          package: Icons.check_rounded.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    checkPainter.paint(
      canvas,
      badgeCenter - Offset(checkPainter.width / 2, checkPainter.height / 2),
    );
  }

  void _drawConceptGlyph(Canvas canvas, double r) {
    final concept = TasteEntityVisualCatalog.conceptFor(text);
    final painter = TextPainter(
      text: TextSpan(
        text: concept.glyph,
        style: TextStyle(fontSize: r * 1.16, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(-painter.width / 2, -painter.height / 2),
    );
  }

  void _drawClayBubble(Canvas canvas) {
    final r = radius;
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    final path = _getShapePath();
    final useLegacyArtwork = data.id == '__legacy_artwork__';
    final shellAlpha = switch (_visualLayer) {
      _BubbleVisualLayer.foreground => 1.0,
      _BubbleVisualLayer.middle => 0.88,
      _BubbleVisualLayer.background => 0.72,
    };
    final hazeAlpha = switch (_visualLayer) {
      _BubbleVisualLayer.foreground => 1.0,
      _BubbleVisualLayer.middle => 0.82,
      _BubbleVisualLayer.background => 0.62,
    };
    if (useLegacyArtwork && _drawSpecificFood(canvas)) return;

    final shadowPaint = Paint()
      ..color = data.secondaryColor.withValues(
        alpha: (isSelected ? 0.22 : 0.14) * shellAlpha,
      )
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        _visualLayer == _BubbleVisualLayer.background ? 20 : 16,
      );
    canvas.save();
    canvas.translate(0, r * 0.18);
    _drawShape(canvas, shadowPaint);
    canvas.restore();

    final outerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white
              .withValues(alpha: (isSelected ? 0.5 : 0.36) * shellAlpha),
          data.primaryColor.withValues(
            alpha: (isSelected ? 0.28 : 0.18) * shellAlpha,
          ),
          data.secondaryColor.withValues(
            alpha: (isSelected ? 0.34 : 0.24) * shellAlpha,
          ),
        ],
      ).createShader(rect);
    canvas.drawPath(path, outerPaint);

    canvas.save();
    _clipShape(canvas);

    final hazePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.38),
        radius: 1.0,
        colors: [
          Colors.white.withValues(alpha: 0.72 * hazeAlpha),
          Colors.white.withValues(alpha: 0.08 * hazeAlpha),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.34, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect.inflate(r * 0.24), hazePaint);

    final innerGlowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          data.primaryColor.withValues(alpha: 0.03 * shellAlpha),
          data.secondaryColor.withValues(
            alpha: (isSelected ? 0.2 : 0.12) * shellAlpha,
          ),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, innerGlowPaint);

    final bottomFogPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0),
          const Color(0xFFFDEBE4).withValues(alpha: 0.12 * shellAlpha),
          data.secondaryColor.withValues(
            alpha: (isSelected ? 0.18 : 0.1) * shellAlpha,
          ),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bottomFogPaint);

    _drawInteriorDetail(canvas, rect);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.055
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.95 * shellAlpha),
          Colors.white.withValues(alpha: 0.28 * shellAlpha),
        ],
      ).createShader(rect);
    canvas.drawPath(path, rimPaint);

    final cutLightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.38 * hazeAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-r * 0.26, -r * 0.36),
        width: r * 0.72,
        height: r * 0.34,
      ),
      cutLightPaint,
    );
    canvas.drawCircle(
      Offset(r * 0.16, -r * 0.18),
      r * 0.12,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22 * hazeAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.restore();

    if (isSelected) {
      final selectionRing = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.08
        ..color = Colors.white.withValues(alpha: 0.74)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawPath(path, selectionRing);
    }
  }

  void _drawInteriorDetail(Canvas canvas, Rect rect) {
    final r = radius;
    final pulse = 0.5 + 0.5 * sin(_animationTime * 2.1 + _driftPhase);
    final drift = sin(_animationTime * 1.4 + _driftPhase);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.18 + pulse * 0.08)
      ..strokeWidth = r * 0.045;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = data.primaryColor.withValues(alpha: 0.07 + pulse * 0.04);

    switch (data.shapeType) {
      case 'pot':
        canvas.drawLine(
          Offset(-r * 0.34, -r * 0.14),
          Offset(r * 0.34, -r * 0.14),
          strokePaint,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(0, r * 0.04),
            width: r * 1.05,
            height: r * 0.82,
          ),
          0,
          pi,
          false,
          strokePaint,
        );
        for (final x in [-0.18, 0.0, 0.18]) {
          final steamPath = Path()
            ..moveTo(r * x, -r * 0.24)
            ..quadraticBezierTo(
              r * (x + 0.05),
              -r * (0.44 + pulse * 0.06),
              r * x,
              -r * (0.60 + pulse * 0.08),
            );
          canvas.drawPath(
            steamPath,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.03
              ..strokeCap = StrokeCap.round
              ..color = Colors.white.withValues(alpha: 0.18 + pulse * 0.10),
          );
        }
        canvas.drawCircle(Offset(-r * 0.72, 0), r * 0.11, strokePaint);
        canvas.drawCircle(Offset(r * 0.72, 0), r * 0.11, strokePaint);
        break;
      case 'moon':
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: r * 0.58),
          -0.8,
          2.7,
          false,
          strokePaint,
        );
        canvas.drawCircle(
          Offset(r * 0.18, -r * 0.32),
          r * (0.04 + pulse * 0.02),
          fillPaint,
        );
        canvas.drawCircle(
          Offset(r * 0.34, -r * 0.10),
          r * (0.025 + pulse * 0.015),
          fillPaint,
        );
        break;
      case 'shield':
        final shieldPath = Path()
          ..moveTo(0, -r * 0.42)
          ..lineTo(0, r * 0.32);
        canvas.drawPath(shieldPath, strokePaint);
        canvas.drawLine(
          Offset(-r * 0.22, -r * 0.08),
          Offset(r * 0.22, -r * 0.08),
          strokePaint,
        );
        canvas.drawLine(
          Offset(-r * 0.18, r * 0.18),
          Offset(-r * 0.02, r * (0.05 + drift * 0.03)),
          strokePaint,
        );
        canvas.drawLine(
          Offset(-r * 0.02, r * (0.05 + drift * 0.03)),
          Offset(r * 0.20, r * (-0.16 + drift * 0.02)),
          strokePaint,
        );
        break;
      case 'petal':
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: r * 0.58,
            height: r * (0.86 + pulse * 0.10),
          ),
          strokePaint,
        );
        canvas.drawLine(
          Offset(0, -r * 0.36),
          Offset(0, r * 0.34),
          strokePaint,
        );
        canvas.drawCircle(
          Offset(0, -r * 0.04),
          r * (0.03 + pulse * 0.02),
          fillPaint,
        );
        break;
      case 'leaf':
        canvas.drawLine(
          Offset(0, -r * 0.46),
          Offset(0, r * 0.46),
          strokePaint,
        );
        canvas.drawLine(
          Offset(0, -r * 0.12),
          Offset(r * 0.24, -r * (0.26 - drift * 0.05)),
          strokePaint,
        );
        canvas.drawLine(
          Offset(0, r * 0.08),
          Offset(-r * 0.24, r * (0.22 + drift * 0.05)),
          strokePaint,
        );
        break;
      case 'ticket':
        canvas.drawLine(
          Offset(0, -r * 0.34),
          Offset(0, r * 0.34),
          strokePaint..strokeWidth = r * 0.03,
        );
        break;
      case 'capsule':
        canvas.drawLine(
          Offset(0, -r * 0.42),
          Offset(0, r * 0.42),
          strokePaint,
        );
        canvas.drawCircle(
          Offset(r * (0.18 * drift), 0),
          r * 0.06,
          fillPaint,
        );
        break;
      case 'chili':
        final chiliPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = r * 0.05
          ..color = Colors.white.withValues(alpha: 0.18 + pulse * 0.10);
        final path = Path()
          ..moveTo(-r * 0.26, -r * 0.26)
          ..quadraticBezierTo(
            r * (0.08 + drift * 0.08),
            0,
            r * 0.02,
            r * 0.42,
          );
        canvas.drawPath(path, chiliPaint);
        break;
      default:
        break;
    }
  }

  void _drawGhostGlyph(Canvas canvas) {
    final glyph = _displayGlyph;
    final glyphAlpha = switch (_visualLayer) {
      _BubbleVisualLayer.foreground => isSelected ? 0.24 : 0.16,
      _BubbleVisualLayer.middle => isSelected ? 0.18 : 0.12,
      _BubbleVisualLayer.background => isSelected ? 0.14 : 0.08,
    };
    final painter = TextPainter(
      text: TextSpan(
        text: glyph,
        style: GoogleFonts.notoSerifSc(
          color: const Color(0xFF7B584A).withValues(alpha: glyphAlpha),
          fontSize: radius * (text.length > 2 ? 0.92 : 1.05),
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.rotate(sin(_driftPhase) * 0.08);
    painter.paint(
      canvas,
      Offset(-painter.width / 2, -painter.height / 2 - radius * 0.06),
    );
    canvas.restore();
  }

  void _drawLabelGlassTag(Canvas canvas) {
    if (_visualLayer == _BubbleVisualLayer.background &&
        !isSelected &&
        !_malformedAssetIds.contains(data.id)) {
      return;
    }

    final tagLabel = _compactLabel;
    final density = switch (_visualLayer) {
      _BubbleVisualLayer.foreground => 1.0,
      _BubbleVisualLayer.middle => 0.92,
      _BubbleVisualLayer.background => 0.82,
    };
    final textPainter = TextPainter(
      text: TextSpan(
        text: tagLabel,
        style: GoogleFonts.notoSansSc(
          color: const Color(0xFF173D25).withValues(
            alpha: (isSelected ? 0.92 : 0.82) * density,
          ),
          fontSize: radius * 0.19 * density,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: radius * 1.18);

    final tagWidth = max(radius * 0.92, textPainter.width + radius * 0.34);
    final tagHeight = radius * 0.42 * density;
    final tagRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, radius * 0.38),
        width: tagWidth,
        height: tagHeight,
      ),
      Radius.circular(radius * 0.24),
    );

    canvas.drawRRect(
      tagRect.shift(Offset(0, radius * 0.05)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08 * density)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawRRect(
      tagRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white
                .withValues(alpha: (isSelected ? 0.92 : 0.82) * density),
            const Color(0xFFDFF1DC)
                .withValues(alpha: (isSelected ? 0.72 : 0.48) * density),
          ],
        ).createShader(tagRect.outerRect),
    );

    canvas.drawRRect(
      tagRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.03
        ..color = Colors.white.withValues(alpha: 0.68 * density),
    );

    textPainter.paint(
      canvas,
      Offset(
        -textPainter.width / 2,
        radius * 0.38 - textPainter.height / 2 - radius * 0.015,
      ),
    );
  }

  void _drawSignatureSeal(Canvas canvas) {
    if (_visualLayer == _BubbleVisualLayer.background && !isSelected) {
      return;
    }

    final spec = data.visualSpec;
    final r = radius;
    final sealCenter = Offset(r * 0.48, -r * 0.52);
    final scale = switch (_visualLayer) {
      _BubbleVisualLayer.foreground => 1.0,
      _BubbleVisualLayer.middle => 0.86,
      _BubbleVisualLayer.background => 0.76,
    };

    final basePaint = Paint()
      ..color = spec.color.withValues(
        alpha: (isSelected ? 0.92 : 0.78) * scale,
      );
    canvas.drawCircle(sealCenter, r * 0.24 * scale, basePaint);

    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7 * scale)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.03 * scale;
    canvas.drawCircle(sealCenter, r * 0.24 * scale, ringPaint);

    final icon = spec.materialIcon;
    if (icon != null) {
      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: r * 0.24 * scale,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      iconPainter.paint(
        canvas,
        sealCenter - Offset(iconPainter.width / 2, iconPainter.height / 2),
      );
    }

    switch (data.particleEffect) {
      case 'steam':
        _drawSteamAccent(canvas, sealCenter, r);
        break;
      case 'sparkle':
        _drawSparkleAccent(canvas, sealCenter, r);
        break;
      case 'bubble':
        _drawBubbleAccent(canvas, sealCenter, r);
        break;
      case 'glow':
        _drawGlowAccent(canvas, sealCenter, r);
        break;
      case 'none':
      default:
        break;
    }
  }

  void _drawSteamAccent(Canvas canvas, Offset center, double r) {
    final steamPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.035
      ..strokeCap = StrokeCap.round;

    for (final dx in [-0.10, 0.0, 0.10]) {
      final path = Path()
        ..moveTo(center.dx + r * dx, center.dy - r * 0.33)
        ..quadraticBezierTo(
          center.dx + r * (dx + 0.04),
          center.dy - r * 0.48,
          center.dx + r * dx,
          center.dy - r * 0.62,
        );
      canvas.drawPath(path, steamPaint);
    }
  }

  void _drawSparkleAccent(Canvas canvas, Offset center, double r) {
    final sparklePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = r * 0.03
      ..strokeCap = StrokeCap.round;

    final sparkleCenter = Offset(center.dx + r * 0.28, center.dy - r * 0.22);
    canvas.drawLine(
      Offset(sparkleCenter.dx, sparkleCenter.dy - r * 0.10),
      Offset(sparkleCenter.dx, sparkleCenter.dy + r * 0.10),
      sparklePaint,
    );
    canvas.drawLine(
      Offset(sparkleCenter.dx - r * 0.10, sparkleCenter.dy),
      Offset(sparkleCenter.dx + r * 0.10, sparkleCenter.dy),
      sparklePaint,
    );
  }

  void _drawBubbleAccent(Canvas canvas, Offset center, double r) {
    final bubblePaint = Paint()..color = Colors.white.withValues(alpha: 0.45);
    canvas.drawCircle(
      Offset(center.dx + r * 0.27, center.dy - r * 0.20),
      r * 0.07,
      bubblePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + r * 0.38, center.dy - r * 0.34),
      r * 0.045,
      bubblePaint,
    );
  }

  void _drawGlowAccent(Canvas canvas, Offset center, double r) {
    final glowPaint = Paint()
      ..color = data.secondaryColor.withValues(alpha: 0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, r * 0.32, glowPaint);
  }

  String get _displayGlyph {
    if (text.isEmpty) return '味';
    if (text.length == 1) return text;
    if (text.contains('火锅')) return '锅';
    if (text.contains('夜')) return '夜';
    if (text.contains('辣')) return '辣';
    if (text.contains('鲜')) return '鲜';
    if (text.contains('清')) return '清';
    if (text.contains('甜')) return '甜';
    return text.substring(0, 1);
  }

  String get _compactLabel {
    if (text.length <= 4) return text;
    return '${text.substring(0, 3)}…';
  }

  bool _drawSpecificFood(Canvas canvas) {
    final r = radius;
    switch (data.label) {
      // --- Flavors ---
      case '辣':
        _drawChili(canvas, r);
        return true;
      case '甜':
        _drawSweet(canvas, r);
        return true;
      case '酸':
        _drawLemon(canvas, r);
        return true;
      case '咸':
        _drawSaltShaker(canvas, r);
        return true;
      case '鲜':
        _drawFish(canvas, r);
        return true;
      case '麻':
        _drawPeppercorn(canvas, r);
        return true;
      case '蒜香':
        _drawGarlic(canvas, r);
        return true;
      case '苦':
        _drawCoffee(canvas, r);
        return true;
      case '奶香':
        _drawMilk(canvas, r);
        return true;
      case '酥脆':
        _drawCookie(canvas, r);
        return true;
      case '清淡':
        _drawLeaf(canvas, r);
        return true;
      case '浓郁':
        _drawSoup(canvas, r);
        return true;
      case '烟熏':
        _drawBacon(canvas, r);
        return true;
      case '药膳':
        _drawHerb(canvas, r);
        return true;
      case '咖喱':
        _drawCurry(canvas, r);
        return true;

      // --- Ingredients ---
      case '牛肉':
        _drawSteak(canvas, r);
        return true;
      case '猪肉':
        _drawPork(canvas, r);
        return true;
      case '鸡肉':
        _drawChickenLeg(canvas, r);
        return true;
      case '羊肉':
        _drawSteak(canvas, r);
        return true;
      case '鸭肉':
        _drawChickenLeg(canvas, r);
        return true;
      case '鹅肉':
        _drawChickenLeg(canvas, r);
        return true;
      case '内脏':
        _drawSausage(canvas, r);
        return true;
      case '海鲜':
        _drawShrimp(canvas, r);
        return true;
      case '鱼':
        _drawFish(canvas, r);
        return true;
      case '虾':
        _drawShrimp(canvas, r);
        return true;
      case '蟹':
        _drawCrab(canvas, r);
        return true;
      case '贝类':
        _drawShell(canvas, r);
        return true;
      case '蔬菜':
        _drawVegetable(canvas, r);
        return true;
      case '菌菇':
        _drawMushroom(canvas, r);
        return true;
      case '豆腐':
        _drawTofu(canvas, r);
        return true;
      case '土豆':
        _drawPotato(canvas, r);
        return true;
      case '番茄':
        _drawTomato(canvas, r);
        return true;
      case '玉米':
        _drawCorn(canvas, r);
        return true;
      case '茄子':
        _drawEggplant(canvas, r);
        return true;
      case '黄瓜':
        _drawCucumber(canvas, r);
        return true;
      case '南瓜':
        _drawPumpkin(canvas, r);
        return true;
      case '萝卜':
        _drawCarrot(canvas, r);
        return true;
      case '豆类':
        _drawBeans(canvas, r);
        return true;
      case '鸡蛋':
        _drawEgg(canvas, r);
        return true;
      case '芝士':
        _drawCheese(canvas, r);
        return true;

      // --- Staples ---
      case '米饭':
        _drawRiceBowl(canvas, r);
        return true;
      case '面条':
        _drawNoodleBowl(canvas, r);
        return true;
      case '馒头':
        _drawBun(canvas, r);
        return true;
      case '包子':
        _drawBun(canvas, r);
        return true;
      case '饺子':
        _drawDumpling(canvas, r);
        return true;
      case '披萨':
        _drawPizza(canvas, r);
        return true;
      case '汉堡':
        _drawBurger(canvas, r);
        return true;
      case '面包':
        _drawBread(canvas, r);
        return true;
      case '意面':
        _drawPasta(canvas, r);
        return true;
      case '粥':
        _drawPorridge(canvas, r);
        return true;

      // --- Cuisines ---
      case '火锅':
        _drawHotpot(canvas, r);
        return true;
      case '川菜':
        _drawChili(canvas, r);
        return true;
      case '湘菜':
        _drawChili(canvas, r);
        return true;
      case '粤菜':
        _drawDimSum(canvas, r);
        return true;
      case '日料':
        _drawSushi(canvas, r);
        return true;
      case '韩餐':
        _drawBibimbap(canvas, r);
        return true;
      case '西餐':
        _drawSteak(canvas, r);
        return true;
      case '法餐':
        _drawCroissant(canvas, r);
        return true;
      case '意餐':
        _drawPizza(canvas, r);
        return true;
      case '泰餐':
        _drawTomYum(canvas, r);
        return true;
      case '越南菜':
        _drawPho(canvas, r);
        return true;
      case '印度菜':
        _drawCurry(canvas, r);
        return true;
      case '烧烤':
        _drawSkewer(canvas, r);
        return true;
      case '清真':
        _drawKebab(canvas, r);
        return true;
      case '东北菜':
        _drawDumpling(canvas, r);
        return true;
      case '西北菜':
        _drawNoodleBowl(canvas, r);
        return true;
      case '鲁菜':
        _drawFish(canvas, r);
        return true;
      case '苏菜':
        _drawFish(canvas, r);
        return true;
      case '浙菜':
        _drawFish(canvas, r);
        return true;
      case '闽菜':
        _drawSoup(canvas, r);
        return true;
      case '徽菜':
        _drawMushroom(canvas, r);
        return true;
      case '云南菜':
        _drawMushroom(canvas, r);
        return true;
      case '京菜':
        _drawDuck(canvas, r);
        return true;
      case '本帮菜':
        _drawPork(canvas, r);
        return true;
      case '台湾菜':
        _drawBubbleTea(canvas, r);
        return true;
      case '港式':
        _drawDimSum(canvas, r);
        return true;
      case '东南亚':
        _drawCoconut(canvas, r);
        return true;
      case '美式':
        _drawBurger(canvas, r);
        return true;
      case '墨西哥':
        _drawTaco(canvas, r);
        return true;

      // --- Scenes ---
      case '早餐':
        _drawToast(canvas, r);
        return true;
      case '午餐':
        _drawRiceBowl(canvas, r);
        return true;
      case '晚餐':
        _drawSteak(canvas, r);
        return true;
      case '夜宵':
        _drawSkewer(canvas, r);
        return true;
      case '早午餐':
        _drawPancake(canvas, r);
        return true;
      case '下午茶':
        _drawCake(canvas, r);
        return true;
      case '聚餐':
        _drawCheers(canvas, r);
        return true;
      case '一人食':
        _drawNoodleBowl(canvas, r);
        return true;
      case '约会':
        _drawHeart(canvas, r);
        return true;
      case '商务':
        _drawCoffee(canvas, r);
        return true;
      case '健康':
        _drawSalad(canvas, r);
        return true;
      case '治愈':
        _drawSoup(canvas, r);
        return true;
      case '路边摊':
        _drawSkewer(canvas, r);
        return true;
      case '自助':
        _drawPlate(canvas, r);
        return true;

      // --- Dietary ---
      case '素食':
        _drawLeaf(canvas, r);
        return true;
      case '轻食':
        _drawSalad(canvas, r);
        return true;
      case '低碳':
        _drawAvocado(canvas, r);
        return true;
      case '高蛋白':
        _drawEgg(canvas, r);
        return true;

      // --- Meta ---
      case '随便':
        _drawDice(canvas, r);
        return true;
      case '惊喜':
        _drawGift(canvas, r);
        return true;
      case '便宜':
        _drawCoin(canvas, r);
        return true;

      // --- Fortune ---
      case '恋爱运':
        _drawHeart(canvas, r);
        return true;
      case '财运':
        _drawCoin(canvas, r);
        return true;
      case '事业运':
        _drawGift(canvas, r);
        return true;
      case '健康运':
        _drawLeaf(canvas, r);
        return true;
      case '社交运':
        _drawCheers(canvas, r);
        return true;
      case '奇遇运':
        _drawDice(canvas, r);
        return true;
      case '专注运':
        _drawCoin(canvas, r);
        return true;
      case '平静运':
        _drawLeaf(canvas, r);
        return true;
    }
    return false;
  }

  // --- Drawing Implementations ---

  void _drawSweet(Canvas canvas, double r) {
    // Lollipop swirl
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.15
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;

    final bgPaint = Paint()..color = const Color(0xFFFF4081);
    canvas.drawCircle(Offset.zero, r * 0.8, bgPaint);

    final path = Path();
    // Simple spiral
    for (double i = 0; i < 3 * pi; i += 0.1) {
      final radius = i * r * 0.08;
      final x = radius * cos(i);
      final y = radius * sin(i);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  void _drawLemon(Canvas canvas, double r) {
    // Lemon slice
    final rindPaint = Paint()..color = const Color(0xFFFFEB3B); // Yellow rind
    final pithPaint = Paint()..color = const Color(0xFFFFF9C4); // White pith
    final fleshPaint = Paint()
      ..color = const Color(0xFFFDD835); // Darker yellow flesh

    canvas.drawCircle(Offset.zero, r * 0.9, rindPaint);
    canvas.drawCircle(Offset.zero, r * 0.8, pithPaint);

    // Segments
    for (int i = 0; i < 8; i++) {
      final angle = i * (pi / 4);
      final path = Path();
      path.moveTo(0, 0);
      path.arcTo(Rect.fromCircle(center: Offset.zero, radius: r * 0.75),
          angle + 0.1, (pi / 4) - 0.2, false);
      path.close();
      canvas.drawPath(path, fleshPaint);
    }
  }

  void _drawSaltShaker(Canvas canvas, double r) {
    // Salt Shaker
    final bodyPaint = Paint()..color = const Color(0xFFE0E0E0);
    final capPaint = Paint()..color = const Color(0xFF9E9E9E); // Metal cap

    final path = Path();
    path.moveTo(-r * 0.4, -r * 0.6);
    path.lineTo(r * 0.4, -r * 0.6);
    path.lineTo(r * 0.5, r * 0.6);
    path.quadraticBezierTo(0, r * 0.7, -r * 0.5, r * 0.6);
    path.close();

    canvas.drawShadow(path, Colors.black, 4.0, true);
    canvas.drawPath(path, bodyPaint);

    // Cap
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, -r * 0.6), width: r * 0.8, height: r * 0.2),
        capPaint);

    // Salt grains (dots)
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(-r * 0.2, -r * 0.6), r * 0.05, dotPaint);
    canvas.drawCircle(Offset(0, -r * 0.6), r * 0.05, dotPaint);
    canvas.drawCircle(Offset(r * 0.2, -r * 0.6), r * 0.05, dotPaint);
  }

  void _drawFresh(Canvas canvas, double r) {
    // Water drop / Fish
    final dropPaint = Paint()..color = const Color(0xFF03A9F4);
    final path = Path();
    path.moveTo(0, -r * 0.8);
    path.quadraticBezierTo(r * 0.8, 0, r * 0.8, r * 0.4);
    path.arcToPoint(Offset(-r * 0.8, r * 0.4),
        radius: Radius.circular(r * 0.8), clockwise: true);
    path.quadraticBezierTo(-r * 0.8, 0, 0, -r * 0.8);
    path.close();

    canvas.drawShadow(path, Colors.black, 4.0, true);
    canvas.drawPath(path, dropPaint);

    // Shine
    final shinePaint = Paint()..color = Colors.white.withOpacity(0.4);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(r * 0.3, -r * 0.2), width: r * 0.2, height: r * 0.4),
        shinePaint);
  }

  void _drawPeppercorn(Canvas canvas, double r) {
    // Peppercorns (Cluster of small circles)
    final pepperPaint = Paint()
      ..color = const Color(0xFF673AB7); // Purple/Brown
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.3);

    final positions = [
      Offset(0, 0),
      Offset(r * 0.4, 0),
      Offset(-r * 0.4, 0),
      Offset(0, r * 0.4),
      Offset(0, -r * 0.4),
      Offset(r * 0.3, r * 0.3),
      Offset(-r * 0.3, -r * 0.3),
    ];

    for (final pos in positions) {
      canvas.drawCircle(pos, r * 0.25, pepperPaint);
      canvas.drawCircle(
          pos + Offset(-r * 0.05, -r * 0.05), r * 0.08, highlightPaint);
    }
  }

  void _drawGarlic(Canvas canvas, double r) {
    // Garlic Bulb
    final garlicPaint = Paint()..color = const Color(0xFFEEEEEE);
    final linePaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    path.moveTo(0, -r * 0.6);
    path.quadraticBezierTo(r * 0.8, -r * 0.2, r * 0.6, r * 0.5);
    path.quadraticBezierTo(0, r * 0.8, -r * 0.6, r * 0.5);
    path.quadraticBezierTo(-r * 0.8, -r * 0.2, 0, -r * 0.6);
    path.close();

    canvas.drawShadow(path, Colors.black, 4.0, true);
    canvas.drawPath(path, garlicPaint);

    // Lines
    canvas.drawLine(Offset(0, -r * 0.6), Offset(0, r * 0.7), linePaint);
    canvas.drawLine(Offset(0, -r * 0.6), Offset(r * 0.3, r * 0.6), linePaint);
    canvas.drawLine(Offset(0, -r * 0.6), Offset(-r * 0.3, r * 0.6), linePaint);
  }

  void _drawPork(Canvas canvas, double r) {
    // Pork Chop / Meat with bone
    final meatPaint = Paint()..color = const Color(0xFFF48FB1); // Pink
    final bonePaint = Paint()..color = const Color(0xFFFFF8E1); // Bone white

    // Bone
    final bonePath = Path();
    bonePath.moveTo(-r * 0.6, -r * 0.2);
    bonePath.lineTo(-r * 0.9, -r * 0.5);
    bonePath.addOval(Rect.fromCenter(
        center: Offset(-r * 0.9, -r * 0.5), width: r * 0.3, height: r * 0.3));
    canvas.drawPath(bonePath, bonePaint);

    // Meat
    final meatPath = Path();
    meatPath.addOval(
        Rect.fromCenter(center: Offset(0, 0), width: r * 1.4, height: r * 1.0));
    canvas.drawShadow(meatPath, Colors.black, 4.0, true);
    canvas.drawPath(meatPath, meatPaint);
  }

  void _drawChickenLeg(Canvas canvas, double r) {
    // Drumstick
    final meatPaint = Paint()..color = const Color(0xFFFFB74D); // Golden brown
    final bonePaint = Paint()..color = Colors.white;

    canvas.save();
    canvas.rotate(-pi / 4);

    // Bone end
    canvas.drawCircle(Offset(-r * 0.6, 0), r * 0.15, bonePaint);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(-r * 0.4, 0), width: r * 0.4, height: r * 0.15),
        bonePaint);

    // Meat
    final meatPath = Path();
    meatPath.moveTo(-r * 0.2, 0);
    meatPath.quadraticBezierTo(r * 0.6, -r * 0.6, r * 0.8, 0);
    meatPath.quadraticBezierTo(r * 0.6, r * 0.6, -r * 0.2, 0);
    canvas.drawShadow(meatPath, Colors.black, 4.0, true);
    canvas.drawPath(meatPath, meatPaint);

    canvas.restore();
  }

  void _drawShrimp(Canvas canvas, double r) {
    // Shrimp
    final shrimpPaint = Paint()..color = const Color(0xFFFF7043); // Orange/Red

    final path = Path();
    // Curved body
    path.moveTo(-r * 0.4, r * 0.4);
    path.quadraticBezierTo(-r * 0.6, -r * 0.2, 0, -r * 0.6);
    path.quadraticBezierTo(r * 0.6, -r * 0.2, r * 0.4, r * 0.4);
    // Tail
    path.lineTo(r * 0.6, r * 0.6);
    path.lineTo(r * 0.3, r * 0.5);

    // Inner curve to close
    path.quadraticBezierTo(0, 0, -r * 0.4, r * 0.4);
    path.close();

    canvas.drawShadow(path, Colors.black, 4.0, true);
    canvas.drawPath(path, shrimpPaint);

    // Segments lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(
        Offset(-r * 0.2, -r * 0.2), Offset(r * 0.2, -r * 0.2), linePaint);
    canvas.drawLine(Offset(-r * 0.1, 0), Offset(r * 0.1, 0), linePaint);
  }

  void _drawMushroom(Canvas canvas, double r) {
    // Mushroom
    final capPaint = Paint()..color = const Color(0xFF8D6E63); // Brown
    final stemPaint = Paint()..color = const Color(0xFFFFF3E0); // Off-white

    // Stem
    final stemPath = Path();
    stemPath.addRect(Rect.fromCenter(
        center: Offset(0, r * 0.3), width: r * 0.4, height: r * 0.6));
    canvas.drawPath(stemPath, stemPaint);

    // Cap
    final capPath = Path();
    capPath.moveTo(-r * 0.7, 0);
    capPath.quadraticBezierTo(0, -r * 1.0, r * 0.7, 0);
    capPath.close();

    canvas.drawShadow(capPath, Colors.black, 4.0, true);
    canvas.drawPath(capPath, capPaint);

    // Spots
    final spotPaint = Paint()..color = Colors.white.withOpacity(0.4);
    canvas.drawCircle(Offset(-r * 0.3, -r * 0.3), r * 0.1, spotPaint);
    canvas.drawCircle(Offset(r * 0.2, -r * 0.4), r * 0.08, spotPaint);
  }

  void _drawEgg(Canvas canvas, double r) {
    // Fried Egg
    final whitePaint = Paint()..color = Colors.white;
    final yolkPaint = Paint()..color = const Color(0xFFFFC107); // Yolk yellow

    // White (irregular)
    final whitePath = Path();
    whitePath.moveTo(-r * 0.6, -r * 0.5);
    whitePath.quadraticBezierTo(0, -r * 0.8, r * 0.7, -r * 0.4);
    whitePath.quadraticBezierTo(r * 0.9, 0, r * 0.5, r * 0.6);
    whitePath.quadraticBezierTo(0, r * 0.9, -r * 0.7, r * 0.5);
    whitePath.quadraticBezierTo(-r * 0.9, 0, -r * 0.6, -r * 0.5);
    whitePath.close();

    canvas.drawShadow(whitePath, Colors.black, 3.0, true);
    canvas.drawPath(whitePath, whitePaint);

    // Yolk
    canvas.drawCircle(Offset(r * 0.1, r * 0.1), r * 0.35, yolkPaint);

    // Yolk shine
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(r * 0.0, 0), width: r * 0.1, height: r * 0.05),
        Paint()..color = Colors.white.withOpacity(0.6));
  }

  void _drawSichuan(Canvas canvas, double r) {
    // Spicy Bowl
    final bowlPaint = Paint()..color = const Color(0xFFD32F2F); // Red bowl
    final contentPaint = Paint()..color = const Color(0xFFFF5252); // Spicy oil

    canvas.drawArc(Rect.fromCircle(center: Offset(0, 0), radius: r * 0.8), 0,
        pi, true, bowlPaint);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(0, 0), width: r * 1.6, height: r * 0.4),
        contentPaint);

    // Chilies floating
    final chiliPaint = Paint()..color = const Color(0xFFB71C1C);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(-r * 0.3, 0), width: r * 0.3, height: r * 0.1),
        chiliPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(r * 0.2, r * 0.1), width: r * 0.3, height: r * 0.1),
        chiliPaint);
  }

  void _drawDimSum(Canvas canvas, double r) {
    // Dim Sum Steamer
    final bambooColor = const Color(0xFFFFE082);
    final rimColor = const Color(0xFFFFD54F);

    final bambooPaint = Paint()..color = bambooColor;

    canvas.drawCircle(Offset.zero, r * 0.8, bambooPaint);

    // Rim
    canvas.drawCircle(
        Offset.zero,
        r * 0.8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = rimColor);

    // Slats
    final linePaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = 2;
    canvas.drawLine(
        Offset(-r * 0.8, -r * 0.3), Offset(r * 0.8, -r * 0.3), linePaint);
    canvas.drawLine(
        Offset(-r * 0.8, r * 0.3), Offset(r * 0.8, r * 0.3), linePaint);

    // Dumpling inside
    final dumplingPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(0, 0), r * 0.25, dumplingPaint);
  }

  void _drawSushi(Canvas canvas, double r) {
    // Sushi Roll
    final noriPaint = Paint()..color = const Color(0xFF212121); // Black seaweed
    final ricePaint = Paint()..color = Colors.white;
    final fillingPaint = Paint()..color = const Color(0xFFF44336); // Red fish

    // Outer Nori
    canvas.drawCircle(Offset.zero, r * 0.7, noriPaint);
    // Rice
    canvas.drawCircle(Offset.zero, r * 0.6, ricePaint);
    // Filling
    canvas.drawCircle(Offset.zero, r * 0.25, fillingPaint);
  }

  void _drawBibimbap(Canvas canvas, double r) {
    // Bibimbap Bowl
    final bowlPaint = Paint()..color = const Color(0xFF5D4037); // Stone bowl
    final ricePaint = Paint()..color = Colors.white;
    final toppingPaint = Paint()..color = const Color(0xFFEF5350); // Gochujang

    canvas.drawArc(Rect.fromCircle(center: Offset(0, 0), radius: r * 0.8), 0,
        pi, true, bowlPaint);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(0, 0), width: r * 1.6, height: r * 0.4),
        ricePaint);

    // Toppings
    canvas.drawCircle(Offset(0, 0), r * 0.2, toppingPaint);
    canvas.drawCircle(
        Offset(-r * 0.3, 0), r * 0.15, Paint()..color = Colors.green); // Veg
    canvas.drawCircle(
        Offset(r * 0.3, 0), r * 0.15, Paint()..color = Colors.yellow); // Egg
  }

  void _drawBurger(Canvas canvas, double r) {
    // Burger
    final bunPaint = Paint()..color = const Color(0xFFFFB74D);
    final meatPaint = Paint()..color = const Color(0xFF795548);
    final lettucePaint = Paint()..color = const Color(0xFF4CAF50);

    // Bottom Bun
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(0, r * 0.3), width: r * 1.4, height: r * 0.6),
        0,
        pi,
        true,
        bunPaint);

    // Meat
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, r * 0.1), width: r * 1.4, height: r * 0.2),
        meatPaint);

    // Lettuce
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, -r * 0.05), width: r * 1.5, height: r * 0.1),
        lettucePaint);

    // Top Bun
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(0, -r * 0.2), width: r * 1.4, height: r * 0.8),
        pi,
        pi,
        true,
        bunPaint);
  }

  void _drawSkewer(Canvas canvas, double r) {
    // Skewer
    final stickPaint = Paint()
      ..color = const Color(0xFFD7CCC8)
      ..strokeWidth = 3;
    final meatPaint = Paint()..color = const Color(0xFF8D6E63);

    canvas.save();
    canvas.rotate(-pi / 4);

    // Stick
    canvas.drawLine(Offset(0, -r * 0.9), Offset(0, r * 0.9), stickPaint);

    // Meat chunks
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, -r * 0.4), width: r * 0.5, height: r * 0.4),
        meatPaint);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, 0.1), width: r * 0.5, height: r * 0.4),
        meatPaint);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, r * 0.5), width: r * 0.5, height: r * 0.3),
        meatPaint);

    canvas.restore();
  }

  void _drawToast(Canvas canvas, double r) {
    // Toast
    final crustPaint = Paint()..color = const Color(0xFF8D6E63);
    final breadPaint = Paint()..color = const Color(0xFFFFF3E0);

    final path = Path();
    path.moveTo(-r * 0.5, -r * 0.4);
    path.quadraticBezierTo(0, -r * 0.7, r * 0.5, -r * 0.4);
    path.lineTo(r * 0.5, r * 0.5);
    path.lineTo(-r * 0.5, r * 0.5);
    path.close();

    canvas.drawPath(path, crustPaint);
    canvas.drawRect(
        Rect.fromCenter(center: Offset(0, 0), width: r * 0.8, height: r * 0.8),
        breadPaint);
  }

  void _drawLunch(Canvas canvas, double r) {
    // Rice Bowl
    final bowlPaint = Paint()..color = const Color(0xFF2196F3);
    final ricePaint = Paint()..color = Colors.white;

    canvas.drawArc(Rect.fromCircle(center: Offset(0, r * 0.2), radius: r * 0.6),
        0, pi, true, bowlPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, r * 0.2), width: r * 1.2, height: r * 0.4),
        ricePaint);

    // Chopsticks
    final stickPaint = Paint()
      ..color = const Color(0xFF795548)
      ..strokeWidth = 2;
    canvas.drawLine(
        Offset(r * 0.2, -r * 0.4), Offset(r * 0.4, r * 0.2), stickPaint);
    canvas.drawLine(
        Offset(r * 0.3, -r * 0.4), Offset(r * 0.5, r * 0.2), stickPaint);
  }

  void _drawDinner(Canvas canvas, double r) {
    // Plate + Wine
    final platePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(-r * 0.2, 0), r * 0.5, platePaint);

    // Wine glass
    final glassPaint = Paint()
      ..color = const Color(0xFFAB47BC).withOpacity(0.6);
    final path = Path();
    path.moveTo(r * 0.4, -r * 0.3);
    path.lineTo(r * 0.4, 0);
    path.quadraticBezierTo(r * 0.4, r * 0.2, r * 0.6, r * 0.2);
    path.quadraticBezierTo(r * 0.8, r * 0.2, r * 0.8, 0);
    path.lineTo(r * 0.8, -r * 0.3);
    path.close();
    canvas.drawPath(path, glassPaint);

    // Stem
    canvas.drawLine(
        Offset(r * 0.6, r * 0.2),
        Offset(r * 0.6, r * 0.5),
        Paint()
          ..color = Colors.grey
          ..strokeWidth = 2);
  }

  void _drawSnack(Canvas canvas, double r) {
    // Cup Noodle
    final cupPaint = Paint()..color = const Color(0xFFFFECB3);
    final lidPaint = Paint()..color = const Color(0xFFD32F2F);

    final path = Path();
    path.moveTo(-r * 0.4, -r * 0.4);
    path.lineTo(r * 0.4, -r * 0.4);
    path.lineTo(r * 0.3, r * 0.5);
    path.lineTo(-r * 0.3, r * 0.5);
    path.close();
    canvas.drawPath(path, cupPaint);

    // Lid
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, -r * 0.4), width: r * 0.8, height: r * 0.2),
        lidPaint);
  }

  void _drawCheers(Canvas canvas, double r) {
    // Confetti / Cheers
    final glassPaint = Paint()
      ..color = const Color(0xFFFFC107).withOpacity(0.8);

    // Glass 1
    canvas.save();
    canvas.rotate(-pi / 6);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(-r * 0.2, 0), width: r * 0.3, height: r * 0.5),
        glassPaint);
    canvas.restore();

    // Glass 2
    canvas.save();
    canvas.rotate(pi / 6);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(r * 0.2, 0), width: r * 0.3, height: r * 0.5),
        glassPaint);
    canvas.restore();

    // Confetti dots
    canvas.drawCircle(
        Offset(0, -r * 0.5), r * 0.05, Paint()..color = Colors.red);
    canvas.drawCircle(
        Offset(-r * 0.4, -r * 0.4), r * 0.05, Paint()..color = Colors.blue);
    canvas.drawCircle(
        Offset(r * 0.4, -r * 0.4), r * 0.05, Paint()..color = Colors.green);
  }

  void _drawSolo(Canvas canvas, double r) {
    // Single Bowl
    final bowlPaint = Paint()..color = const Color(0xFF9E9E9E);
    canvas.drawArc(Rect.fromCircle(center: Offset(0, r * 0.1), radius: r * 0.6),
        0, pi, true, bowlPaint);

    // Steam
    final steamPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(0, -r * 0.4), width: r * 0.2, height: r * 0.4),
        -pi / 2,
        pi,
        false,
        steamPaint);
  }

  void _drawSalad(Canvas canvas, double r) {
    // Salad Bowl
    final bowlPaint = Paint()..color = const Color(0xFF8BC34A);
    canvas.drawArc(Rect.fromCircle(center: Offset(0, r * 0.1), radius: r * 0.7),
        0, pi, true, bowlPaint);

    // Leaves
    final leafPaint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawCircle(Offset(-r * 0.2, -r * 0.1), r * 0.2, leafPaint);
    canvas.drawCircle(Offset(r * 0.2, -r * 0.1), r * 0.2, leafPaint);
    canvas.drawCircle(Offset(0, -r * 0.2), r * 0.2, leafPaint);
  }

  void _drawHeart(Canvas canvas, double r) {
    // Heart / Warm Soup
    final heartPaint = Paint()..color = const Color(0xFFFFAB91);

    final path = Path();
    path.moveTo(0, r * 0.5);
    path.quadraticBezierTo(r * 0.8, 0, r * 0.5, -r * 0.5);
    path.quadraticBezierTo(0, -r * 0.5, 0, -r * 0.2);
    path.quadraticBezierTo(0, -r * 0.5, -r * 0.5, -r * 0.5);
    path.quadraticBezierTo(-r * 0.8, 0, 0, r * 0.5);
    path.close();

    canvas.drawShadow(path, Colors.black, 4.0, true);
    canvas.drawPath(path, heartPaint);
  }

  void _drawDice(Canvas canvas, double r) {
    // Dice
    final dicePaint = Paint()..color = Colors.white;
    final dotPaint = Paint()..color = Colors.black;

    final rect =
        Rect.fromCenter(center: Offset.zero, width: r * 1.0, height: r * 1.0);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(r * 0.2)), dicePaint);

    // Dots (5)
    canvas.drawCircle(Offset(0, 0), r * 0.1, dotPaint);
    canvas.drawCircle(Offset(-r * 0.25, -r * 0.25), r * 0.1, dotPaint);
    canvas.drawCircle(Offset(r * 0.25, -r * 0.25), r * 0.1, dotPaint);
    canvas.drawCircle(Offset(-r * 0.25, r * 0.25), r * 0.1, dotPaint);
    canvas.drawCircle(Offset(r * 0.25, r * 0.25), r * 0.1, dotPaint);
  }

  void _drawGift(Canvas canvas, double r) {
    // Gift Box
    final boxPaint = Paint()..color = const Color(0xFFFF4081);
    final ribbonPaint = Paint()..color = const Color(0xFFFFEB3B);

    canvas.drawRect(
        Rect.fromCenter(center: Offset(0, 0), width: r * 1.0, height: r * 1.0),
        boxPaint);

    // Ribbon
    canvas.drawRect(
        Rect.fromCenter(center: Offset(0, 0), width: r * 0.2, height: r * 1.0),
        ribbonPaint);
    canvas.drawRect(
        Rect.fromCenter(center: Offset(0, 0), width: r * 1.0, height: r * 0.2),
        ribbonPaint);
  }

  void _drawHotpot(Canvas canvas, double r) {
    // Pot Body (Bronze/Metal)
    final potPaint = Paint()..color = const Color(0xFF8D6E63);
    final potPath = Path();
    potPath.moveTo(-r * 0.8, -r * 0.2);
    potPath.lineTo(r * 0.8, -r * 0.2);
    potPath.quadraticBezierTo(r * 0.7, r * 0.8, 0, r * 0.9);
    potPath.quadraticBezierTo(-r * 0.7, r * 0.8, -r * 0.8, -r * 0.2);
    potPath.close();

    // Shadow
    canvas.drawShadow(potPath, Colors.black, 4.0, true);
    canvas.drawPath(potPath, potPaint);

    // Soup (Red/Spicy)
    final soupPaint = Paint()..color = const Color(0xFFD32F2F);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, -r * 0.2), width: r * 1.6, height: r * 0.6),
        soupPaint);

    // Inner Soup (Lighter)
    final innerSoupPaint = Paint()..color = const Color(0xFFFF5252);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, -r * 0.2), width: r * 1.2, height: r * 0.4),
        innerSoupPaint);

    // Handles
    final handlePaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(-r * 0.9, -r * 0.2),
            width: r * 0.2,
            height: r * 0.1),
        handlePaint);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(r * 0.9, -r * 0.2), width: r * 0.2, height: r * 0.1),
        handlePaint);

    // Steam
    final steamPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path1 = Path();
    path1.moveTo(-r * 0.3, -r * 0.5);
    path1.quadraticBezierTo(-r * 0.1, -r * 0.8, -r * 0.3, -r * 1.1);
    canvas.drawPath(path1, steamPaint);

    final path2 = Path();
    path2.moveTo(r * 0.3, -r * 0.5);
    path2.quadraticBezierTo(r * 0.1, -r * 0.8, r * 0.3, -r * 1.1);
    canvas.drawPath(path2, steamPaint);
  }

  void _drawBeef(Canvas canvas, double r) {
    // Meat Slab (Red)
    final meatPaint = Paint()..color = const Color(0xFFD32F2F);
    final meatPath = Path();
    meatPath.moveTo(-r * 0.7, -r * 0.5);
    meatPath.quadraticBezierTo(0, -r * 0.8, r * 0.7, -r * 0.4);
    meatPath.quadraticBezierTo(r * 0.9, 0, r * 0.6, r * 0.6);
    meatPath.quadraticBezierTo(0, r * 0.9, -r * 0.6, r * 0.5);
    meatPath.quadraticBezierTo(-r * 0.9, 0, -r * 0.7, -r * 0.5);
    meatPath.close();

    canvas.drawShadow(meatPath, Colors.black, 4.0, true);
    canvas.drawPath(meatPath, meatPaint);

    // Marbling (White fat lines)
    final fatPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.05
      ..strokeCap = StrokeCap.round;

    final fatPath = Path();
    fatPath.moveTo(-r * 0.4, -r * 0.2);
    fatPath.quadraticBezierTo(-r * 0.1, 0, -r * 0.3, r * 0.3);

    fatPath.moveTo(r * 0.1, -r * 0.4);
    fatPath.quadraticBezierTo(r * 0.4, -r * 0.1, r * 0.2, r * 0.2);

    fatPath.moveTo(-r * 0.5, r * 0.1);
    fatPath.quadraticBezierTo(-r * 0.2, r * 0.4, 0, r * 0.1);

    canvas.drawPath(fatPath, fatPaint);
  }

  void _drawVegetable(Canvas canvas, double r) {
    // Leaves (Green)
    final leafPaint = Paint()..color = const Color(0xFF4CAF50);
    final leafPath = Path();

    // Center leaf
    leafPath.moveTo(0, r * 0.8);
    leafPath.quadraticBezierTo(r * 0.6, 0, 0, -r * 0.9);
    leafPath.quadraticBezierTo(-r * 0.6, 0, 0, r * 0.8);

    // Left leaf
    leafPath.moveTo(0, r * 0.8);
    leafPath.quadraticBezierTo(-r * 0.8, 0, -r * 0.6, -r * 0.6);
    leafPath.quadraticBezierTo(-r * 0.2, -r * 0.4, 0, r * 0.8);

    // Right leaf
    leafPath.moveTo(0, r * 0.8);
    leafPath.quadraticBezierTo(r * 0.8, 0, r * 0.6, -r * 0.6);
    leafPath.quadraticBezierTo(r * 0.2, -r * 0.4, 0, r * 0.8);

    canvas.drawShadow(leafPath, Colors.black, 4.0, true);
    canvas.drawPath(leafPath, leafPaint);

    // Veins
    final veinPaint = Paint()
      ..color = const Color(0xFF81C784)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.03;

    canvas.drawLine(Offset(0, r * 0.8), Offset(0, -r * 0.8), veinPaint);
  }

  void _drawTofu(Canvas canvas, double r) {
    // Tofu Block (Cube-ish)
    final tofuPaint = Paint()..color = const Color(0xFFF5F5F5);
    final shadowSidePaint = Paint()..color = const Color(0xFFE0E0E0);
    final darkSidePaint = Paint()..color = const Color(0xFFBDBDBD);

    // Top face
    final topPath = Path();
    topPath.moveTo(-r * 0.5, -r * 0.6);
    topPath.lineTo(r * 0.5, -r * 0.6);
    topPath.lineTo(r * 0.3, -r * 0.3);
    topPath.lineTo(-r * 0.7, -r * 0.3);
    topPath.close();

    // Front face
    final frontPath = Path();
    frontPath.moveTo(-r * 0.7, -r * 0.3);
    frontPath.lineTo(r * 0.3, -r * 0.3);
    frontPath.lineTo(r * 0.3, r * 0.5);
    frontPath.lineTo(-r * 0.7, r * 0.5);
    frontPath.close();

    // Side face
    final sidePath = Path();
    sidePath.moveTo(r * 0.3, -r * 0.3);
    sidePath.lineTo(r * 0.5, -r * 0.6);
    sidePath.lineTo(r * 0.5, r * 0.2);
    sidePath.lineTo(r * 0.3, r * 0.5);
    sidePath.close();

    canvas.drawPath(topPath, tofuPaint);
    canvas.drawPath(frontPath, shadowSidePaint);
    canvas.drawPath(sidePath, darkSidePaint);
  }

  void _drawChili(Canvas canvas, double r) {
    // Chili Body (Red)
    final chiliPaint = Paint()..color = const Color(0xFFD32F2F);
    final chiliPath = Path();
    chiliPath.moveTo(-r * 0.2, -r * 0.6);
    chiliPath.quadraticBezierTo(r * 0.5, -r * 0.4, r * 0.4, 0);
    chiliPath.quadraticBezierTo(r * 0.3, r * 0.6, -r * 0.1, r * 0.9);
    chiliPath.quadraticBezierTo(0, r * 0.2, -r * 0.4, -r * 0.6);
    chiliPath.close();

    canvas.drawShadow(chiliPath, Colors.black, 4.0, true);
    canvas.drawPath(chiliPath, chiliPaint);

    // Stem (Green)
    final stemPaint = Paint()..color = const Color(0xFF4CAF50);
    final stemPath = Path();
    stemPath.moveTo(-r * 0.2, -r * 0.6);
    stemPath.lineTo(-r * 0.4, -r * 0.6);
    stemPath.lineTo(-r * 0.35, -r * 0.8);
    stemPath.lineTo(-r * 0.15, -r * 0.8);
    stemPath.close();
    canvas.drawPath(stemPath, stemPaint);
  }

  void _clipShape(Canvas canvas) {
    canvas.clipPath(_getShapePath());
  }

  Path _getShapePath() {
    final r = radius;
    final path = Path();
    switch (data.shapeType) {
      case 'squircle':
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: r * 1.7, height: r * 1.7),
            Radius.circular(r * 0.4),
          ),
        );
        break;
      case 'hexagon':
        for (int i = 0; i < 6; i++) {
          final angle = i * 60 * (pi / 180);
          final point = Offset(r * cos(angle), r * sin(angle));
          if (i == 0)
            path.moveTo(point.dx, point.dy);
          else
            path.lineTo(point.dx, point.dy);
        }
        path.close();
        break;
      case 'star':
        final double innerRadius = r * 0.5;
        for (int i = 0; i < 10; i++) {
          final double angle = i * 36 * (pi / 180) - pi / 2;
          final double currentR = (i % 2 == 0) ? r : innerRadius;
          final point = Offset(currentR * cos(angle), currentR * sin(angle));
          if (i == 0)
            path.moveTo(point.dx, point.dy);
          else
            path.lineTo(point.dx, point.dy);
        }
        path.close();
        break;
      case 'chili':
        path.moveTo(r * 0.2, -r * 0.8);
        path.quadraticBezierTo(r * 0.8, -r * 0.2, r * 0.1, r * 0.9);
        path.quadraticBezierTo(-r * 0.6, r * 0.2, -r * 0.2, -r * 0.8);
        path.close();
        break;
      case 'leaf':
        path.moveTo(0, -r);
        path.quadraticBezierTo(r, -r * 0.5, r, 0);
        path.quadraticBezierTo(r, r * 0.5, 0, r);
        path.quadraticBezierTo(-r, r * 0.5, -r, 0);
        path.quadraticBezierTo(-r, -r * 0.5, 0, -r);
        path.close();
        break;
      case 'fire':
        path.moveTo(0, r);
        path.quadraticBezierTo(r, r * 0.5, r, 0);
        path.quadraticBezierTo(r, -r * 0.5, 0, -r);
        path.quadraticBezierTo(-r, -r * 0.5, -r, 0);
        path.quadraticBezierTo(-r, r * 0.5, 0, r);
        path.moveTo(0, -r);
        path.quadraticBezierTo(r * 0.3, -r * 1.3, 0, -r * 1.5);
        path.quadraticBezierTo(-r * 0.3, -r * 1.3, 0, -r);
        path.close();
        break;
      case 'drop':
        path.moveTo(0, -r);
        path.quadraticBezierTo(r, 0, r, r * 0.5);
        path.arcToPoint(Offset(-r, r * 0.5),
            radius: Radius.circular(r), clockwise: true);
        path.quadraticBezierTo(-r, 0, 0, -r);
        path.close();
        break;
      case 'capsule':
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: r * 2.0,
              height: r * 1.25,
            ),
            Radius.circular(r * 0.62),
          ),
        );
        break;
      case 'shield':
        path.moveTo(0, -r);
        path.quadraticBezierTo(r * 0.78, -r * 0.82, r * 0.82, -r * 0.10);
        path.quadraticBezierTo(r * 0.86, r * 0.58, 0, r);
        path.quadraticBezierTo(-r * 0.86, r * 0.58, -r * 0.82, -r * 0.10);
        path.quadraticBezierTo(-r * 0.78, -r * 0.82, 0, -r);
        path.close();
        break;
      case 'moon':
        path.addOval(Rect.fromCircle(center: Offset.zero, radius: r));
        path.addOval(
          Rect.fromCircle(
              center: Offset(r * 0.38, -r * 0.06), radius: r * 0.82),
        );
        path.fillType = PathFillType.evenOdd;
        break;
      case 'petal':
        path.moveTo(0, -r);
        path.cubicTo(r * 0.88, -r * 0.92, r * 0.96, r * 0.28, 0, r);
        path.cubicTo(-r * 0.96, r * 0.28, -r * 0.88, -r * 0.92, 0, -r);
        path.close();
        break;
      case 'ticket':
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: r * 1.95,
              height: r * 1.30,
            ),
            Radius.circular(r * 0.30),
          ),
        );
        path.addOval(
          Rect.fromCircle(center: Offset(-r * 0.98, 0), radius: r * 0.18),
        );
        path.addOval(
          Rect.fromCircle(center: Offset(r * 0.98, 0), radius: r * 0.18),
        );
        path.fillType = PathFillType.evenOdd;
        break;
      case 'pot':
        path.moveTo(-r * 0.92, -r * 0.12);
        path.quadraticBezierTo(-r * 0.86, r * 0.72, 0, r * 0.76);
        path.quadraticBezierTo(r * 0.86, r * 0.72, r * 0.92, -r * 0.12);
        path.lineTo(r * 0.58, -r * 0.12);
        path.lineTo(r * 0.42, -r * 0.50);
        path.lineTo(-r * 0.42, -r * 0.50);
        path.lineTo(-r * 0.58, -r * 0.12);
        path.close();
        break;
      case 'circle':
      default:
        path.addOval(Rect.fromCircle(center: Offset.zero, radius: r));
        break;
    }
    return path;
  }

  void _drawShape(Canvas canvas, Paint paint, {double scale = 1.0}) {
    // Legacy method, now just draws the path
    // Scale is handled by canvas.scale in render() now
    canvas.drawPath(_getShapePath(), paint);
  }

  IconData _getIconData(String name) {
    return _iconMap[name] ?? Icons.restaurant;
  }

  static const Map<String, IconData> _iconMap = {
    'local_fire_department': Icons.local_fire_department,
    'restaurant': Icons.restaurant,
    'whatshot': Icons.whatshot,
    'dinner_dining': Icons.dinner_dining,
    'water_drop': Icons.water_drop,
    'waves': Icons.waves,
    'soup_kitchen': Icons.soup_kitchen,
    'landscape': Icons.landscape,
    'bento': Icons.bento,
    'rice_bowl': Icons.rice_bowl,
    'local_dining': Icons.local_dining,
    'spa': Icons.spa,
    'grass': Icons.grass,
    'emoji_food_beverage': Icons.emoji_food_beverage,
    'local_pizza': Icons.local_pizza,
    'lunch_dining': Icons.lunch_dining,
    'kebab_dining': Icons.kebab_dining,
    'set_meal': Icons.set_meal,
    'eco': Icons.eco,
    'savings': Icons.savings,
    'egg': Icons.egg,
    'pets': Icons.pets,
    'water': Icons.water,
    'bug_report': Icons.bug_report,
    'egg_alt': Icons.egg_alt,
    'crop_square': Icons.crop_square,
    'circle': Icons.circle,
    'horizontal_rule': Icons.horizontal_rule,
    'umbrella': Icons.umbrella,
    'ramen_dining': Icons.ramen_dining,
    'bakery_dining': Icons.bakery_dining,
    'category': Icons.category,
    'cookie': Icons.cookie,
    'apple': Icons.apple,
    'cake': Icons.cake,
    'local_bar': Icons.local_bar,
    'grain': Icons.grain,
    'coffee': Icons.coffee,
    'bolt': Icons.bolt,
    'local_florist': Icons.local_florist,
    'broken_image': Icons.broken_image,
    'cloud': Icons.cloud,
    'opacity': Icons.opacity,
    'cloud_queue': Icons.cloud_queue,
    'kitchen': Icons.kitchen,
    'fastfood': Icons.fastfood,
    'breakfast_dining': Icons.breakfast_dining,
    'ac_unit': Icons.ac_unit,
    'local_cafe': Icons.local_cafe,
    'wb_sunny': Icons.wb_sunny,
    'wb_twilight': Icons.wb_twilight,
    'nights_stay': Icons.nights_stay,
    'bedtime': Icons.bedtime,
    'celebration': Icons.celebration,
    'person': Icons.person,
    'favorite': Icons.favorite,
    'speed': Icons.speed,
    'fitness_center': Icons.fitness_center,
    'self_improvement': Icons.self_improvement,
    'local_drink': Icons.local_drink,
    'shuffle': Icons.shuffle,
    'card_giftcard': Icons.card_giftcard,
  };

  void _drawBitter(Canvas canvas, double r) {
    final skinPaint = Paint()..color = const Color(0xFF4CAF50);
    final fleshPaint = Paint()..color = const Color(0xFFC8E6C9);
    final mainPath = Path()
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: r * 0.8));
    canvas.drawShadow(mainPath, Colors.black, 4.0, true);
    canvas.drawPath(mainPath, skinPaint);
    canvas.drawCircle(Offset.zero, r * 0.6, fleshPaint);
    for (int i = 0; i < 8; i++) {
      final angle = i * (pi / 4);
      canvas.drawCircle(Offset(r * 0.85 * cos(angle), r * 0.85 * sin(angle)),
          r * 0.15, skinPaint);
    }
  }

  void _drawCreamy(Canvas canvas, double r) {
    final cheesePaint = Paint()..color = const Color(0xFFFFEB3B);
    final holePaint = Paint()..color = const Color(0xFFFBC02D);
    final path = Path();
    path.moveTo(-r * 0.6, -r * 0.4);
    path.lineTo(r * 0.6, -r * 0.4);
    path.lineTo(r * 0.6, r * 0.6);
    path.lineTo(0, r * 0.8);
    path.lineTo(-r * 0.6, r * 0.6);
    path.close();
    canvas.drawShadow(path, Colors.black, 4.0, true);
    canvas.drawPath(path, cheesePaint);
    canvas.drawCircle(Offset(-r * 0.2, 0), r * 0.15, holePaint);
    canvas.drawCircle(Offset(r * 0.3, r * 0.2), r * 0.1, holePaint);
    canvas.drawCircle(Offset(0, -r * 0.2), r * 0.08, holePaint);
  }

  void _drawFish(Canvas canvas, double r) {
    final fishPaint = Paint()..color = const Color(0xFF42A5F5);
    final path = Path();
    path.moveTo(-r * 0.8, 0);
    path.quadraticBezierTo(-r * 0.4, -r * 0.6, r * 0.4, -r * 0.4);
    path.lineTo(r * 0.8, 0);
    path.lineTo(r * 0.4, r * 0.4);
    path.quadraticBezierTo(-r * 0.4, r * 0.6, -r * 0.8, 0);
    path.close();
    final tailPath = Path();
    tailPath.moveTo(r * 0.8, 0);
    tailPath.lineTo(r * 1.0, -r * 0.3);
    tailPath.lineTo(r * 1.0, r * 0.3);
    tailPath.close();
    canvas.drawShadow(path, Colors.black, 4.0, true);
    canvas.drawPath(tailPath, fishPaint);
    canvas.drawPath(path, fishPaint);
    canvas.drawCircle(
        Offset(-r * 0.5, -r * 0.15), r * 0.08, Paint()..color = Colors.white);
  }

  void _drawCrab(Canvas canvas, double r) {
    final bodyPaint = Paint()..color = const Color(0xFFFF5252);
    final bodyPath = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(0, 0), width: r * 1.4, height: r * 0.9));
    canvas.drawShadow(bodyPath, Colors.black, 4.0, true);
    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawCircle(Offset(-r * 0.8, -r * 0.4), r * 0.25, bodyPaint);
    canvas.drawCircle(Offset(r * 0.8, -r * 0.4), r * 0.25, bodyPaint);
    final legPaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawLine(Offset(-r * 0.6, 0), Offset(-r * 0.9, r * 0.3), legPaint);
    canvas.drawLine(Offset(r * 0.6, 0), Offset(r * 0.9, r * 0.3), legPaint);
  }

  void _drawShellfish(Canvas canvas, double r) {
    final shellPaint = Paint()..color = const Color(0xFFFFCC80);
    final path = Path();
    path.moveTo(0, r * 0.6);
    for (int i = 0; i <= 10; i++) {
      final angle = -pi + (i * pi / 5);
      path.lineTo(r * 0.8 * cos(angle), r * 0.8 * sin(angle) - r * 0.2);
    }
    path.close();
    canvas.drawShadow(path, Colors.black, 4.0, true);
    canvas.drawPath(path, shellPaint);
  }

  void _drawPotato(Canvas canvas, double r) {
    final skinPaint = Paint()..color = const Color(0xFFD7CCC8);
    final spotPaint = Paint()..color = const Color(0xFFA1887F);
    final path = Path();
    path.moveTo(-r * 0.7, 0);
    path.quadraticBezierTo(-r * 0.5, -r * 0.7, 0, -r * 0.6);
    path.quadraticBezierTo(r * 0.6, -r * 0.5, r * 0.7, 0);
    path.quadraticBezierTo(r * 0.5, r * 0.7, 0, r * 0.6);
    path.quadraticBezierTo(-r * 0.6, r * 0.5, -r * 0.7, 0);
    path.close();
    canvas.drawShadow(path, Colors.black, 4.0, true);
    canvas.drawPath(path, skinPaint);
    canvas.drawCircle(Offset(-r * 0.3, -r * 0.2), r * 0.05, spotPaint);
    canvas.drawCircle(Offset(r * 0.2, r * 0.3), r * 0.08, spotPaint);
  }

  void _drawTomato(Canvas canvas, double r) {
    final bodyPaint = Paint()..color = const Color(0xFFF44336);
    final leafPaint = Paint()..color = const Color(0xFF4CAF50);
    final bodyPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, r * 0.1), radius: r * 0.7));
    canvas.drawShadow(bodyPath, Colors.black, 4.0, true);
    canvas.drawPath(bodyPath, bodyPaint);
    final path = Path();
    path.moveTo(0, -r * 0.6);
    path.lineTo(-r * 0.2, -r * 0.4);
    path.lineTo(0, -r * 0.3);
    path.lineTo(r * 0.2, -r * 0.4);
    path.close();
    canvas.drawPath(path, leafPaint);
  }

  void _drawCorn(Canvas canvas, double r) {
    final kernelPaint = Paint()..color = const Color(0xFFFFEB3B);
    final huskPaint = Paint()..color = const Color(0xFF8BC34A);
    final bodyPath = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(0, 0), width: r * 0.6, height: r * 1.4));
    canvas.drawShadow(bodyPath, Colors.black, 4.0, true);
    canvas.drawPath(bodyPath, kernelPaint);
    final path = Path();
    path.moveTo(0, r * 0.8);
    path.quadraticBezierTo(-r * 0.6, r * 0.4, -r * 0.4, -r * 0.2);
    path.close();
    canvas.drawPath(path, huskPaint);
    final path2 = Path();
    path2.moveTo(0, r * 0.8);
    path2.quadraticBezierTo(r * 0.6, r * 0.4, r * 0.4, -r * 0.2);
    path2.close();
    canvas.drawPath(path2, huskPaint);
  }

  void _drawRiceBowl(Canvas canvas, double r) {
    final bowlPaint = Paint()..color = const Color(0xFF2196F3);
    final ricePaint = Paint()..color = Colors.white;
    final bowlPath = Path()
      ..addArc(
          Rect.fromCircle(center: Offset(0, r * 0.2), radius: r * 0.7), 0, pi)
      ..close();
    canvas.drawShadow(bowlPath, Colors.black, 4.0, true);
    canvas.drawPath(bowlPath, bowlPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, r * 0.2), width: r * 1.4, height: r * 0.5),
        ricePaint);
  }

  void _drawNoodleBowl(Canvas canvas, double r) {
    final bowlPaint = Paint()..color = const Color(0xFFFF9800);
    final soupPaint = Paint()..color = const Color(0xFFFFE0B2);
    final noodlePaint = Paint()
      ..color = const Color(0xFFFFF3E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final bowlPath = Path()
      ..addArc(
          Rect.fromCircle(center: Offset(0, r * 0.2), radius: r * 0.7), 0, pi)
      ..close();
    canvas.drawShadow(bowlPath, Colors.black, 4.0, true);
    canvas.drawPath(bowlPath, bowlPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, r * 0.2), width: r * 1.4, height: r * 0.5),
        soupPaint);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(0, r * 0.2), width: r * 1.0, height: r * 0.3),
        0,
        pi,
        false,
        noodlePaint);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(0, r * 0.1), width: r * 0.8, height: r * 0.3),
        0,
        pi,
        false,
        noodlePaint);
  }

  void _drawPizza(Canvas canvas, double r) {
    final crustPaint = Paint()..color = const Color(0xFFFFB74D);
    final cheesePaint = Paint()..color = const Color(0xFFFFEB3B);
    final pepperoniPaint = Paint()..color = const Color(0xFFD32F2F);
    canvas.save();
    canvas.rotate(-pi / 4);
    canvas.translate(-r * 0.2, r * 0.2);
    final slicePath = Path();
    slicePath.moveTo(0, -r * 0.8);
    slicePath.lineTo(r * 0.6, r * 0.6);
    slicePath.lineTo(-r * 0.6, r * 0.6);
    slicePath.close();
    canvas.drawShadow(slicePath, Colors.black, 4.0, true);
    canvas.drawPath(slicePath, cheesePaint);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, -r * 0.8), width: r * 1.2, height: r * 0.2),
        crustPaint);
    canvas.drawCircle(Offset(0, 0), r * 0.15, pepperoniPaint);
    canvas.drawCircle(Offset(-r * 0.2, r * 0.3), r * 0.15, pepperoniPaint);
    canvas.restore();
  }

  void _drawCroissant(Canvas canvas, double r) {
    final pastryPaint = Paint()..color = const Color(0xFFFFB74D);
    final path = Path();
    path.moveTo(-r * 0.8, 0);
    path.quadraticBezierTo(0, -r * 0.6, r * 0.8, 0);
    path.quadraticBezierTo(r * 0.4, r * 0.4, 0, r * 0.2);
    path.quadraticBezierTo(-r * 0.4, r * 0.4, -r * 0.8, 0);
    path.close();
    canvas.drawShadow(path, Colors.black, 4.0, true);
    canvas.drawPath(path, pastryPaint);
    final linePaint = Paint()
      ..color = const Color(0xFFE65100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(-r * 0.2, -r * 0.2), Offset(-r * 0.2, r * 0.2), linePaint);
    canvas.drawLine(
        Offset(r * 0.2, -r * 0.2), Offset(r * 0.2, r * 0.2), linePaint);
  }

  void _drawTomYum(Canvas canvas, double r) {
    final soupPaint = Paint()..color = const Color(0xFFFF7043);
    final bowlPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, 0), radius: r * 0.8));
    canvas.drawShadow(bowlPath, Colors.black, 4.0, true);
    canvas.drawPath(bowlPath, soupPaint);
    final shrimpPaint = Paint()..color = const Color(0xFFFFAB91);
    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(r * 0.4, -r * 0.4, r * 0.6, 0);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = shrimpPaint.color);
  }

  void _drawCoffee(Canvas canvas, double r) {
    final cupPaint = Paint()..color = Colors.white;
    final coffeePaint = Paint()..color = const Color(0xFF3E2723);
    canvas.drawCircle(Offset(0, 0), r * 0.7, cupPaint);
    canvas.drawCircle(Offset(0, 0), r * 0.6, coffeePaint);
    final steamPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(0, -r * 0.5), width: r * 0.3, height: r * 0.3),
        -pi / 2,
        pi,
        false,
        steamPaint);
  }

  void _drawMilk(Canvas canvas, double r) {
    final cartonPaint = Paint()..color = Colors.blue[100]!;
    final path = Path();
    path.moveTo(-r * 0.4, -r * 0.6);
    path.lineTo(r * 0.4, -r * 0.6);
    path.lineTo(r * 0.4, r * 0.6);
    path.lineTo(-r * 0.4, r * 0.6);
    path.close();
    canvas.drawPath(path, cartonPaint);
    canvas.drawRect(
        Rect.fromCenter(center: Offset(0, 0), width: r * 0.6, height: r * 0.4),
        Paint()..color = Colors.white);
  }

  void _drawCookie(Canvas canvas, double r) {
    final cookiePaint = Paint()..color = const Color(0xFFD7CCC8);
    final chipPaint = Paint()..color = const Color(0xFF3E2723);
    canvas.drawCircle(Offset(0, 0), r * 0.8, cookiePaint);
    canvas.drawCircle(Offset(-r * 0.3, -r * 0.3), r * 0.1, chipPaint);
    canvas.drawCircle(Offset(r * 0.2, -r * 0.1), r * 0.1, chipPaint);
    canvas.drawCircle(Offset(0, r * 0.4), r * 0.1, chipPaint);
  }

  void _drawLeaf(Canvas canvas, double r) {
    final leafPaint = Paint()..color = Colors.green;
    final path = Path();
    path.moveTo(0, -r * 0.8);
    path.quadraticBezierTo(r * 0.8, 0, 0, r * 0.8);
    path.quadraticBezierTo(-r * 0.8, 0, 0, -r * 0.8);
    canvas.drawPath(path, leafPaint);
  }

  void _drawSoup(Canvas canvas, double r) {
    final bowlPaint = Paint()..color = Colors.brown[300]!;
    final soupPaint = Paint()..color = Colors.orange[200]!;
    canvas.drawCircle(Offset(0, 0), r * 0.8, bowlPaint);
    canvas.drawCircle(Offset(0, 0), r * 0.7, soupPaint);
  }

  void _drawBacon(Canvas canvas, double r) {
    final meatPaint = Paint()..color = const Color(0xFFD32F2F);
    final fatPaint = Paint()..color = const Color(0xFFFFCDD2);
    final path = Path();
    path.moveTo(-r * 0.6, -r * 0.3);
    path.quadraticBezierTo(0, -r * 0.6, r * 0.6, -r * 0.3);
    path.lineTo(r * 0.6, r * 0.3);
    path.quadraticBezierTo(0, 0, -r * 0.6, r * 0.3);
    path.close();
    canvas.drawPath(path, meatPaint);
    canvas.drawLine(
        Offset(-r * 0.6, 0),
        Offset(r * 0.6, 0),
        Paint()
          ..color = fatPaint.color
          ..strokeWidth = r * 0.1);
  }

  void _drawHerb(Canvas canvas, double r) {
    final stemPaint = Paint()..color = Colors.green[800]!;
    final leafPaint = Paint()..color = Colors.green;
    canvas.drawLine(
        Offset(0, r * 0.8),
        Offset(0, -r * 0.8),
        Paint()
          ..color = stemPaint.color
          ..strokeWidth = 2);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(-r * 0.3, 0), width: r * 0.4, height: r * 0.2),
        leafPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(r * 0.3, -r * 0.3), width: r * 0.4, height: r * 0.2),
        leafPaint);
  }

  void _drawCurry(Canvas canvas, double r) {
    final bowlPaint = Paint()..color = Colors.grey[300]!;
    final curryPaint = Paint()..color = const Color(0xFFFFC107);
    canvas.drawCircle(Offset(0, 0), r * 0.8, bowlPaint);
    canvas.drawCircle(Offset(0, 0), r * 0.7, curryPaint);
  }

  void _drawSteak(Canvas canvas, double r) {
    final meatPaint = Paint()..color = const Color(0xFF5D4037);
    final path = Path();
    path.moveTo(-r * 0.6, -r * 0.4);
    path.quadraticBezierTo(0, -r * 0.6, r * 0.6, -r * 0.4);
    path.lineTo(r * 0.6, r * 0.4);
    path.quadraticBezierTo(0, r * 0.6, -r * 0.6, r * 0.4);
    path.close();
    canvas.drawPath(path, meatPaint);
    final markPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 2;
    canvas.drawLine(
        Offset(-r * 0.4, -r * 0.4), Offset(-r * 0.2, r * 0.4), markPaint);
    canvas.drawLine(Offset(0, -r * 0.5), Offset(0.2, r * 0.4), markPaint);
    canvas.drawLine(
        Offset(r * 0.4, -r * 0.4), Offset(r * 0.6, r * 0.4), markPaint);
  }

  void _drawSausage(Canvas canvas, double r) {
    final sausagePaint = Paint()..color = const Color(0xFFD32F2F);
    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: r * 1.4, height: r * 0.5),
        Radius.circular(r * 0.25)));
    canvas.drawPath(path, sausagePaint);
  }

  void _drawShell(Canvas canvas, double r) {
    final shellPaint = Paint()..color = Colors.orange[100]!;
    final path = Path();
    path.moveTo(0, r * 0.6);
    for (int i = 0; i <= 5; i++) {
      path.lineTo(
          r * 0.8 * cos(pi + i * pi / 5), r * 0.8 * sin(pi + i * pi / 5));
    }
    path.close();
    canvas.drawPath(path, shellPaint);
  }

  void _drawEggplant(Canvas canvas, double r) {
    final skinPaint = Paint()..color = Colors.purple;
    final stemPaint = Paint()..color = Colors.green;
    final path = Path();
    path.moveTo(0, -r * 0.8);
    path.quadraticBezierTo(r * 0.5, 0, 0, r * 0.8);
    path.quadraticBezierTo(-r * 0.5, 0, 0, -r * 0.8);
    canvas.drawPath(path, skinPaint);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, -r * 0.8), width: r * 0.3, height: r * 0.1),
        stemPaint);
  }

  void _drawCucumber(Canvas canvas, double r) {
    final skinPaint = Paint()..color = Colors.green[700]!;
    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: r * 1.4, height: r * 0.4),
        Radius.circular(r * 0.2)));
    canvas.drawPath(path, skinPaint);
  }

  void _drawPumpkin(Canvas canvas, double r) {
    final skinPaint = Paint()..color = Colors.orange;
    canvas.drawOval(
        Rect.fromCenter(center: Offset(0, 0), width: r * 1.4, height: r * 1.0),
        skinPaint);
    final linePaint = Paint()
      ..color = Colors.orange[800]!
      ..style = PaintingStyle.stroke;
    canvas.drawOval(
        Rect.fromCenter(center: Offset(0, 0), width: r * 1.0, height: r * 1.0),
        linePaint);
  }

  void _drawCarrot(Canvas canvas, double r) {
    final bodyPaint = Paint()..color = Colors.orange;
    final leafPaint = Paint()..color = Colors.green;
    final path = Path();
    path.moveTo(-r * 0.2, -r * 0.8);
    path.lineTo(r * 0.2, -r * 0.8);
    path.lineTo(0, r * 0.8);
    path.close();
    canvas.drawPath(path, bodyPaint);
    canvas.drawCircle(Offset(0, -r * 0.8), r * 0.1, leafPaint);
  }

  void _drawBeans(Canvas canvas, double r) {
    final beanPaint = Paint()..color = Colors.green;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(-r * 0.3, 0), width: r * 0.4, height: r * 0.2),
        beanPaint);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(0, 0), width: r * 0.4, height: r * 0.2),
        beanPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(r * 0.3, 0), width: r * 0.4, height: r * 0.2),
        beanPaint);
  }

  void _drawCheese(Canvas canvas, double r) {
    final cheesePaint = Paint()..color = const Color(0xFFFFEB3B);
    final path = Path();
    path.moveTo(-r * 0.5, r * 0.5);
    path.lineTo(r * 0.5, r * 0.5);
    path.lineTo(0, -r * 0.5);
    path.close();
    canvas.drawPath(path, cheesePaint);
    final holePaint = Paint()..color = const Color(0xFFFBC02D);
    canvas.drawCircle(Offset(0, 0), r * 0.1, holePaint);
  }

  void _drawBun(Canvas canvas, double r) {
    final bunPaint = Paint()..color = const Color(0xFFFFF9C4);
    canvas.drawCircle(Offset(0, 0), r * 0.7, bunPaint);
  }

  void _drawDumpling(Canvas canvas, double r) {
    final skinPaint = Paint()..color = Colors.white;
    final path = Path();
    path.addArc(Rect.fromCircle(center: Offset(0, 0), radius: r * 0.7), 0, -pi);
    path.close();
    canvas.drawPath(path, skinPaint);
  }

  void _drawBread(Canvas canvas, double r) {
    final crustPaint = Paint()..color = const Color(0xFF8D6E63);
    final path = Path();
    path.moveTo(-r * 0.6, -r * 0.4);
    path.quadraticBezierTo(0, -r * 0.8, r * 0.6, -r * 0.4);
    path.lineTo(r * 0.6, r * 0.4);
    path.lineTo(-r * 0.6, r * 0.4);
    path.close();
    canvas.drawPath(path, crustPaint);
  }

  void _drawPasta(Canvas canvas, double r) {
    final pastaPaint = Paint()
      ..color = const Color(0xFFFFE0B2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(0, 0), r * 0.6, pastaPaint);
    canvas.drawCircle(Offset(0, 0), r * 0.4, pastaPaint);
  }

  void _drawPorridge(Canvas canvas, double r) {
    final bowlPaint = Paint()..color = Colors.grey;
    final porridgePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(0, 0), r * 0.8, bowlPaint);
    canvas.drawCircle(Offset(0, 0), r * 0.7, porridgePaint);
  }

  void _drawPho(Canvas canvas, double r) {
    final bowlPaint = Paint()..color = Colors.white;
    final soupPaint = Paint()..color = Colors.brown[200]!;
    canvas.drawCircle(Offset(0, 0), r * 0.8, bowlPaint);
    canvas.drawCircle(Offset(0, 0), r * 0.7, soupPaint);
    final noodlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(Offset(-r * 0.3, 0), Offset(r * 0.3, 0), noodlePaint);
  }

  void _drawKebab(Canvas canvas, double r) {
    final meatPaint = Paint()..color = const Color(0xFF5D4037);
    final stickPaint = Paint()..color = Colors.brown;
    canvas.drawLine(
        Offset(0, -r * 0.8),
        Offset(0, r * 0.8),
        Paint()
          ..color = stickPaint.color
          ..strokeWidth = 2);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, -r * 0.3), width: r * 0.4, height: r * 0.3),
        meatPaint);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, 0.3), width: r * 0.4, height: r * 0.3),
        meatPaint);
  }

  void _drawDuck(Canvas canvas, double r) {
    final skinPaint = Paint()..color = const Color(0xFFBF360C);
    final path = Path();
    path.addOval(
        Rect.fromCenter(center: Offset(0, 0), width: r * 1.2, height: r * 0.8));
    canvas.drawPath(path, skinPaint);
  }

  void _drawBubbleTea(Canvas canvas, double r) {
    final cupPaint = Paint()..color = const Color(0xFFEFEBE9);
    final teaPaint = Paint()..color = const Color(0xFFD7CCC8);
    canvas.drawRect(
        Rect.fromCenter(center: Offset(0, 0), width: r * 0.8, height: r * 1.2),
        cupPaint);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, 0.2), width: r * 0.7, height: r * 0.8),
        teaPaint);
    // Pearls
    final pearlPaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(-r * 0.2, r * 0.4), r * 0.1, pearlPaint);
    canvas.drawCircle(Offset(r * 0.2, r * 0.4), r * 0.1, pearlPaint);
    canvas.drawCircle(Offset(0, r * 0.3), r * 0.1, pearlPaint);
    // Straw
    canvas.drawLine(
        Offset(0, -r * 0.6),
        Offset(r * 0.3, -r * 0.9),
        Paint()
          ..color = Colors.purple
          ..strokeWidth = 4);
  }

  void _drawCoconut(Canvas canvas, double r) {
    final shellPaint = Paint()..color = const Color(0xFF5D4037);
    final meatPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(0, 0), r * 0.8, shellPaint);
    canvas.drawCircle(Offset(0, 0), r * 0.6, meatPaint);
    // Water
    canvas.drawArc(Rect.fromCircle(center: Offset(0, 0), radius: r * 0.5), 0,
        pi, false, Paint()..color = Colors.blue[100]!);
  }

  void _drawTaco(Canvas canvas, double r) {
    final shellPaint = Paint()..color = const Color(0xFFFFD54F);
    final meatPaint = Paint()..color = const Color(0xFF5D4037);
    final lettucePaint = Paint()..color = Colors.green;
    canvas.drawArc(
        Rect.fromCenter(center: Offset(0, 0), width: r * 1.6, height: r * 1.2),
        0,
        pi,
        true,
        shellPaint);
    canvas.drawRect(
        Rect.fromCenter(center: Offset(0, 0), width: r * 1.2, height: r * 0.2),
        meatPaint);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, -r * 0.1), width: r * 1.2, height: r * 0.1),
        lettucePaint);
  }

  void _drawPancake(Canvas canvas, double r) {
    final pancakePaint = Paint()..color = const Color(0xFFFFE082);
    final syrupPaint = Paint()..color = const Color(0xFFE65100);
    canvas.drawCircle(Offset(0, 0.1), r * 0.8, pancakePaint);
    canvas.drawCircle(Offset(0, -0.1), r * 0.7, pancakePaint);
    canvas.drawCircle(Offset(0, -0.3), r * 0.6, pancakePaint);
    // Syrup
    canvas.drawCircle(Offset(0, -0.3), r * 0.3, syrupPaint);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, -0.4), width: r * 0.2, height: r * 0.2),
        Paint()..color = Colors.yellow); // Butter
  }

  void _drawCake(Canvas canvas, double r) {
    final cakePaint = Paint()..color = const Color(0xFFF48FB1);
    final frostingPaint = Paint()..color = Colors.white;
    canvas.drawRect(
        Rect.fromCenter(center: Offset(0, 0), width: r * 1.0, height: r * 0.8),
        cakePaint);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, -r * 0.4), width: r * 1.0, height: r * 0.2),
        frostingPaint);
    // Candle
    canvas.drawLine(
        Offset(0, -r * 0.4),
        Offset(0, -r * 0.7),
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 3);
    canvas.drawCircle(
        Offset(0, -r * 0.8), r * 0.1, Paint()..color = Colors.orange);
  }

  void _drawPlate(Canvas canvas, double r) {
    final platePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(0, 0), r * 0.9, platePaint);
    canvas.drawCircle(
        Offset(0, 0), r * 0.6, Paint()..color = Colors.grey[200]!);
  }

  void _drawAvocado(Canvas canvas, double r) {
    final skinPaint = Paint()..color = const Color(0xFF2E7D32);
    final fleshPaint = Paint()..color = const Color(0xFFC5E1A5);
    final seedPaint = Paint()..color = const Color(0xFF795548);
    final path = Path();
    path.moveTo(0, -r * 0.8);
    path.quadraticBezierTo(r * 0.7, -r * 0.6, r * 0.7, r * 0.4);
    path.quadraticBezierTo(0, r * 0.9, -r * 0.7, r * 0.4);
    path.quadraticBezierTo(-r * 0.7, -r * 0.6, 0, -r * 0.8);
    canvas.drawPath(path, skinPaint);
    canvas.drawCircle(Offset(0, r * 0.1), r * 0.6, fleshPaint);
    canvas.drawCircle(Offset(0, r * 0.3), r * 0.25, seedPaint);
  }

  void _drawCoin(Canvas canvas, double r) {
    final coinPaint = Paint()..color = const Color(0xFFFFD700);
    final symbolPaint = Paint()
      ..color = const Color(0xFFF57F17)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(0, 0), r * 0.8, coinPaint);
    canvas.drawCircle(Offset(0, 0), r * 0.6, symbolPaint);
    // $ symbol approximation
    canvas.drawLine(Offset(0, -r * 0.3), Offset(0, r * 0.3), symbolPaint);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(0, -r * 0.15), width: r * 0.3, height: r * 0.3),
        -pi / 2,
        pi * 1.5,
        false,
        symbolPaint);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(0, r * 0.15), width: r * 0.3, height: r * 0.3),
        pi / 2,
        pi * 1.5,
        false,
        symbolPaint);
  }
}
