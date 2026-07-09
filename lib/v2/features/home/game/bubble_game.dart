// ignore_for_file: deprecated_member_use, override_on_non_overriding_member

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';
import 'bubble_body.dart';
import 'wall_body.dart';
import 'bubble_data_manager.dart';

class BubbleGame extends Forge2DGame {
  BubbleGame() : super(gravity: Vector2(0, 10), zoom: 1.0);

  @override
  Color backgroundColor() => const Color(0x00FFFFFF);

  late final BubbleDataManager _dataManager;
  final V2PreferenceFeedbackService _feedback =
      V2PreferenceFeedbackService.instance;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  final ValueNotifier<int> selectionCount = ValueNotifier(0);
  final ValueNotifier<SwipeFeedbackEvent?> swipeFeedback =
      ValueNotifier<SwipeFeedbackEvent?>(null);
  final List<String> selectedItems = [];
  final List<String> selectedTagIds = [];
  final Map<String, String> selectedTagIdToLabel = {};

  void emitSwipeFeedback({
    required String label,
    required bool positive,
  }) {
    swipeFeedback.value = SwipeFeedbackEvent(
      label: label,
      positive: positive,
      nonce: DateTime.now().microsecondsSinceEpoch,
    );
  }

  void toggleSelection(BubbleBody bubble) {
    bubble.isSelected = !bubble.isSelected;
    if (bubble.isSelected) {
      selectionCount.value++;
      selectedItems.add(bubble.text);
      selectedTagIds.add(bubble.data.id);
      selectedTagIdToLabel[bubble.data.id] = bubble.text;
    } else {
      selectionCount.value--;
      selectedItems.remove(bubble.text);
      selectedTagIds.remove(bubble.data.id);
      selectedTagIdToLabel.remove(bubble.data.id);
    }
  }

  // Scale factor: 1 meter = 10 pixels (adjust as needed)
  // Actually, with zoom 1.0, 1 unit = 1 pixel.
  // Box2D works best with objects between 0.1 and 10 meters.
  // So if we have a 300px wide screen, that's 300 meters which is huge for Box2D.
  // We should probably use a zoom of 10 or 20.
  // Let's try zoom 20. So 300px screen width = 15 meters.
  // A 50px bubble = 2.5 meters. That's reasonable.
  static const double worldScale = 20.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize data manager
    _dataManager = BubbleDataManager();
    await _dataManager.initialize();

    // Set camera zoom
    camera.viewfinder.zoom = worldScale;
    camera.viewfinder.anchor = Anchor.topLeft;

    // Add boundaries
    // ...

    // Add some initial bubbles
    _addBubbles();

    // Add "Discard" zone indicator at the bottom (Visual only)
    // We can use a HUD component for this
    add(DiscardZoneIndicator());

    // Listen to accelerometer with error handling
    // Use default gravity first, then try to listen to accelerometer
    world.gravity = Vector2(0, 10);
    _initAccelerometer();
  }

  void _initAccelerometer() {
    // Skip accelerometer on platforms that don't support it
    if (kIsWeb) {
      debugPrint('Accelerometer not supported on web');
      return;
    }

    // Only try to use accelerometer on mobile platforms
    if (!Platform.isIOS && !Platform.isAndroid) {
      debugPrint('Accelerometer not supported on ${Platform.operatingSystem}');
      return;
    }

    try {
      _accelerometerSubscription = accelerometerEventStream().listen(
        (event) {
          // Update gravity based on tilt
          final clampedX = event.x.clamp(-10.0, 10.0);
          final clampedY = event.y.clamp(-10.0, 10.0);

          if (clampedX.abs() < 0.1 && clampedY.abs() < 0.1) {
            world.gravity = Vector2(0, 10);
          } else {
            world.gravity = Vector2(-clampedX * 2, clampedY * 2);
          }
        },
        onError: (error) {
          // Accelerometer not available
          debugPrint('Accelerometer error: $error');
        },
      );
    } catch (e) {
      // Accelerometer stream creation failed (e.g., macOS, iOS simulator)
      debugPrint('Failed to initialize accelerometer: $e');
    }
  }

  void _addBubbles({int count = 22}) {
    final rand = Random();
    final bubbles = _dataManager.getInitialBubbles(count);

    for (var i = 0; i < bubbles.length; i++) {
      final data = bubbles[i];

      final tier = i % 5;
      final baseRadius = switch (tier) {
        0 => 2.55 + rand.nextDouble() * 0.35,
        1 => 2.15 + rand.nextDouble() * 0.30,
        2 => 1.90 + rand.nextDouble() * 0.24,
        3 => 1.60 + rand.nextDouble() * 0.22,
        _ => 1.35 + rand.nextDouble() * 0.18,
      };
      final radius = baseRadius * data.sizeMultiplier;

      final x = 1.4 + rand.nextDouble() * 11.6;
      final y = 1.6 + rand.nextDouble() * 12.8;

      world.add(BubbleBody(
        data: data,
        radius: radius,
        initialPosition: Vector2(x, y),
      ));
    }
  }

  void handleBubbleExplosion(BubbleBody bubble) {
    unawaited(_feedback.recordPositiveTag(bubble.data.id, delta: 2));
    // 1. Remove the exploded bubble (already handled in body, but safe to ensure)
    if (bubble.parent != null) bubble.removeFromParent();

    // 2. Spawn related bubbles (Explosion effect)
    // Get 5-8 new bubbles related to this one
    final relatedBubbles =
        _dataManager.getRelatedBubbles(bubble.data, count: 6);

    final rand = Random();
    for (var data in relatedBubbles) {
      // Spawn at the top, raining down
      final x = 2.0 + rand.nextDouble() * 10.0;
      final y = 0.0; // Top of screen

      // Slightly smaller for sub-bubbles
      final radius = (1.5 + rand.nextDouble() * 0.5) * data.sizeMultiplier;

      final newBody = BubbleBody(
        data: data,
        radius: radius,
        initialPosition: Vector2(x, y),
      );

      world.add(newBody);

      // Give them a downward impulse
      // We can't apply impulse immediately before body is created in world,
      // but BubbleBody.createBody handles creation.
      // We can add a post-add callback or just let gravity do it.
    }
  }

  void handleBubbleRejection(BubbleBody bubble) {
    unawaited(_feedback.recordNegativeTag(bubble.data.id, delta: 2));
    // Just ensure replenishment happens
    // The update loop handles this automatically when count drops
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Replenishment Logic
    // Check if we need to add more bubbles
    final currentBubbleCount = world.children.whereType<BubbleBody>().length;
    if (currentBubbleCount < 18) {
      _addBubbles(count: 4);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateBoundaries(size);
  }

  void _updateBoundaries(Vector2 size) {
    // Remove old boundaries
    world.children
        .whereType<WallBody>()
        .forEach((wall) => wall.removeFromParent());

    // Calculate world size in meters
    // Since zoom is applied by camera, the "screen size" passed here is in pixels.
    // We need to convert pixels to world coordinates.
    // But wait, if we use camera zoom, the viewport size is still pixels.
    // The visible world area is size / zoom.

    final visibleWorldSize = size / worldScale;
    final width = visibleWorldSize.x;
    final height = visibleWorldSize.y;

    final topLeft = Vector2.zero();
    final topRight = Vector2(width, 0);
    final bottomRight = Vector2(width, height);
    final bottomLeft = Vector2(0, height);

    world.addAll([
      WallBody(topLeft, topRight),
      WallBody(topRight, bottomRight),
      WallBody(bottomRight, bottomLeft),
      WallBody(bottomLeft, topLeft),
    ]);
  }

  @override
  void onRemove() {
    _accelerometerSubscription?.cancel();
    super.onRemove();
  }

  @override
  void onDispose() {
    _accelerometerSubscription?.cancel();
    selectionCount.dispose();
    swipeFeedback.dispose();
  }
}

class SwipeFeedbackEvent {
  const SwipeFeedbackEvent({
    required this.label,
    required this.positive,
    required this.nonce,
  });

  final String label;
  final bool positive;
  final int nonce;
}

class DiscardZoneIndicator extends PositionComponent
    with HasGameRef<BubbleGame> {
  @override
  bool get isHud => true;

  @override
  void render(Canvas canvas) {
    final width = gameRef.size.x;
    final height = gameRef.size.y;

    // Draw gradient at bottom
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE8DCC6).withOpacity(0.0),
          const Color(0xFFE8DCC6).withOpacity(0.8),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, height - 150, width, 150));

    canvas.drawRect(Rect.fromLTWH(0, height - 150, width, 150), paint);

    // Draw "discard" text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'discard',
        style: TextStyle(
          color: const Color(0xFF8D7B68).withOpacity(0.6),
          fontSize: 18,
          fontWeight: FontWeight.w500,
          fontFamily: 'Rounded',
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((width - textPainter.width) / 2, height - 40),
    );
  }
}
