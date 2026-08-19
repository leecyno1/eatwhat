// ignore_for_file: deprecated_member_use, override_on_non_overriding_member

import 'dart:async' as async;
import 'dart:io';
import 'dart:math';

import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'bubble_body.dart';
import 'bubble_data_manager.dart';
import 'sweep_controller.dart';
import 'wall_body.dart';

class BubbleGame extends Forge2DGame {
  /// Entities the stage carries once fully populated. The pile is built
  /// by the replenish stream (see [update]) instead of one giant drop, so
  /// oversized entities never spawn overlapped.
  static const int visibleBubbleCount = 40;

  /// Entities dropped in each opening wave.
  static const int _initialDropWaveSize = 10;

  /// Seconds between the two opening waves, and between replenish drops.
  static const double _initialWaveGapSec = 0.5;
  static const double _replenishIntervalSec = 0.45;

  /// Realistic downward gravity in world units so entities pile up and
  /// settle like real objects instead of floating like bubbles.
  static const double gravityY = 9.8;

  BubbleGame({
    String? initialCategory,
    Map<String, String> initialLikedTags = const {},
    Map<String, String> initialBlockedTags = const {},
  })  : _category = initialCategory,
        super(gravity: Vector2(0, gravityY), zoom: 1.0) {
    _replaceSelections(
      likedTags: initialLikedTags,
      blockedTags: initialBlockedTags,
    );
  }

  @override
  Color backgroundColor() => const Color(0x00FFFFFF);

  late final BubbleDataManager _dataManager;
  final V2PreferenceFeedbackService _feedback =
      V2PreferenceFeedbackService.instance;
  async.StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  /// Replenish scheduling, driven by the game clock in [update] so no dart
  /// timers leak into widget tests or outlive the component.
  double _replenishClock = 0;
  double? _pendingWaveDelay;
  final ValueNotifier<int> selectionCount = ValueNotifier(0);
  final ValueNotifier<int> selectionRevision = ValueNotifier(0);
  final ValueNotifier<SwipeFeedbackEvent?> swipeFeedback =
      ValueNotifier<SwipeFeedbackEvent?>(null);
  final List<String> selectedItems = [];
  final List<String> selectedTagIds = [];
  final Map<String, String> selectedTagIdToLabel = {};
  final List<String> blockedItems = [];
  final List<String> blockedTagIds = [];
  final Map<String, String> blockedTagIdToLabel = {};
  String? _category;
  bool _isLoaded = false;
  double _gravityX = 0;
  double _gravityY = gravityY;

  String? get category => _category;
  int get totalTagCount => _dataManager.totalTagCount;
  int get visibleCategoryCount => _dataManager.countForCategory(_category);

  /// Every live preference entity on the stage (used by the sweep gesture
  /// to hit-test the finger path).
  Iterable<BubbleBody> get entities => world.children.whereType<BubbleBody>();

  void syncSelections({
    required Map<String, String> likedTags,
    required Map<String, String> blockedTags,
  }) {
    final unchanged = selectedTagIds.length == likedTags.length &&
        blockedTagIds.length == blockedTags.length &&
        selectedTagIds.every(
          (id) => likedTags[id] == selectedTagIdToLabel[id],
        ) &&
        blockedTagIds.every(
          (id) => blockedTags[id] == blockedTagIdToLabel[id],
        );
    if (unchanged) return;

    _replaceSelections(likedTags: likedTags, blockedTags: blockedTags);
    selectionCount.value = selectedTagIds.length;
    if (_isLoaded) _reloadBubbles();
  }

  void _replaceSelections({
    required Map<String, String> likedTags,
    required Map<String, String> blockedTags,
  }) {
    selectedTagIds
      ..clear()
      ..addAll(likedTags.keys);
    selectedItems
      ..clear()
      ..addAll(likedTags.values);
    selectedTagIdToLabel
      ..clear()
      ..addAll(likedTags);
    blockedTagIds
      ..clear()
      ..addAll(blockedTags.keys);
    blockedItems
      ..clear()
      ..addAll(blockedTags.values);
    blockedTagIdToLabel
      ..clear()
      ..addAll(blockedTags);
  }

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
    if (bubble.isSelected) return;
    bubble.isSelected = true;
    blockedItems.remove(bubble.text);
    blockedTagIds.remove(bubble.data.id);
    blockedTagIdToLabel.remove(bubble.data.id);
    if (!selectedItems.contains(bubble.text)) {
      selectedItems.add(bubble.text);
    }
    if (!selectedTagIds.contains(bubble.data.id)) {
      selectedTagIds.add(bubble.data.id);
    }
    selectedTagIdToLabel[bubble.data.id] = bubble.text;
    async.unawaited(_feedback.recordPositiveTag(bubble.data.id, delta: 2));
    _notifySelectionChanged();
  }

  void rejectBubble(BubbleBody bubble) {
    bubble.isSelected = false;
    bubble.isRejected = true;
    selectedItems.remove(bubble.text);
    selectedTagIds.remove(bubble.data.id);
    selectedTagIdToLabel.remove(bubble.data.id);
    if (!blockedItems.contains(bubble.text)) {
      blockedItems.add(bubble.text);
    }
    if (!blockedTagIds.contains(bubble.data.id)) {
      blockedTagIds.add(bubble.data.id);
    }
    blockedTagIdToLabel[bubble.data.id] = bubble.text;
    async.unawaited(_feedback.recordNegativeTag(bubble.data.id, delta: 2));
    _notifySelectionChanged();
  }

  void _notifySelectionChanged() {
    selectionCount.value = selectedTagIds.length;
    selectionRevision.value += 1;
  }

  /// Collects a batch of swept entities. Each entity flies to the tray with
  /// a small stagger so a big sweep reads as a satisfying wave, but haptics
  /// and the feedback chip fire once for the whole gesture.
  void collectEntities(Iterable<BubbleBody> swept) {
    final batch = swept
        .where((entity) => !entity.isRemoved && !entity.isRejected)
        .toList()
      ..sort((a, b) => a.body.position.x.compareTo(b.body.position.x));
    if (batch.isEmpty) return;

    emitSwipeFeedback(label: '${batch.length} 个偏好', positive: true);
    HapticFeedback.mediumImpact();

    for (var i = 0; i < batch.length; i++) {
      final entity = batch[i];
      final delay = Duration(milliseconds: 45 * i);
      Future.delayed(delay, () {
        if (entity.isRemoved || entity.isRejected) return;
        entity.collect(withFeedback: false, emitChip: false);
      });
    }
  }

  /// Blocks a batch of swept entities: all of them sink out at once with a
  /// single heavy haptic thud.
  void rejectEntities(Iterable<BubbleBody> swept) {
    final batch = swept
        .where((entity) => !entity.isRemoved && !entity.isRejected)
        .toList();
    if (batch.isEmpty) return;

    emitSwipeFeedback(label: '${batch.length} 个不想要', positive: false);
    HapticFeedback.heavyImpact();

    for (final entity in batch) {
      entity.sweepReject();
    }
  }

  /// Splash of particles at an entity's position, spawned by both taps and
  /// sweeps so every collect/block lands with the same visual punch.
  void spawnSelectionBurst(BubbleBody entity, {required bool positive}) {
    if (entity.isRemoved) return;
    world.add(SelectionBurst(
      position: entity.body.position,
      positive: positive,
      accent: entity.data.primaryColor,
    ));
  }

  // Scale factor: 1 meter = 32 pixels. Box2D works best with objects
  // between 0.1 and 10 meters, and this zoom keeps the entity pile large
  // enough to fill a satisfying share of the stage.
  static const double worldScale = 32.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize data manager
    _dataManager = BubbleDataManager();
    await _dataManager.initialize();
    _isLoaded = true;

    // Set camera zoom
    camera.viewfinder.zoom = worldScale;
    camera.viewfinder.anchor = Anchor.topLeft;

    // Add boundaries
    // ...

    // Add some initial bubbles
    _addBubbles(count: _initialDropWaveSize);
    _pendingWaveDelay = _initialWaveGapSec;

    // Add "Discard" zone indicator at the bottom (Visual only)
    // We can use a HUD component for this
    add(DiscardZoneIndicator());

    // Stage-level sweep gesture: drag through entities, flick up to
    // collect, flick down to block.
    add(SweepGestureHandler());

    // Set realistic gravity; entities fall and stack on the stage floor.
    world.gravity = Vector2(0, gravityY);
    _initAccelerometer();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isLoaded || isRemoved) return;

    // Opening waves: pour the second drop in after the first has begun to
    // separate mid-air.
    final pendingWave = _pendingWaveDelay;
    if (pendingWave != null) {
      final remaining = pendingWave - dt;
      if (remaining <= 0) {
        _pendingWaveDelay = null;
        _addBubbles(count: _initialDropWaveSize);
      } else {
        _pendingWaveDelay = remaining;
      }
    }

    // Replenish stream: builds the pile up to a full population and keeps
    // it topped up with a gentle drop from the top, one entity at a time.
    _replenishClock += dt;
    if (_replenishClock >= _replenishIntervalSec) {
      _replenishClock = 0;
      if (entities.length < visibleBubbleCount) {
        _addBubbles(count: 1, replenish: true);
      }
    }
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
          // Tilt the gravity vector so piled entities roll around naturally.
          final targetX = (-event.x * 4.4).clamp(-5.6, 5.6);
          final targetY = (gravityY + event.y * 1.5).clamp(4.0, 15.0);
          final nextX = _gravityX + (targetX - _gravityX) * 0.14;
          final nextY = _gravityY + (targetY - _gravityY) * 0.14;
          // Only poke the world when gravity actually shifts: rewriting the
          // vector on every sensor tick keeps stacked bodies awake and
          // makes them jitter forever.
          if ((nextX - _gravityX).abs() < 0.02 &&
              (nextY - _gravityY).abs() < 0.02) {
            return;
          }
          _gravityX = nextX;
          _gravityY = nextY;
          world.gravity = Vector2(_gravityX, _gravityY);
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

  void _addBubbles({int count = visibleBubbleCount, bool replenish = false}) {
    final rand = Random();
    final existingIds = world.children
        .whereType<BubbleBody>()
        .map((bubble) => bubble.data.id)
        .toSet();
    final bubbles = _dataManager.getInitialBubbles(
      count,
      category: _category,
      excludedTagIds: {
        ...existingIds,
        ...selectedTagIds,
        ...blockedTagIds,
      },
    );

    final visibleWidth = max(size.x / worldScale, 8.0);
    final visibleHeight = max(size.y / worldScale, 12.0);
    final placements = <({Vector2 center, double span})>[];

    // Scatter entities across the upper region so they rain down and settle
    // into a natural pile instead of hovering like bubbles. Replenished
    // entities spawn from a narrow band at the very top and drift in with
    // a little sideways velocity so they visibly fall onto the pile.
    final spawnBandTop = 1.1;
    final spawnBandHeight = replenish
        ? 0.4
        : max(1.0, visibleHeight * 0.42 - spawnBandTop - 2.4);

    for (var i = 0; i < bubbles.length; i++) {
      final data = bubbles[i];
      // Size tiers keep the pile varied, and history-driven sizeMultiplier
      // makes frequently chosen preferences visibly larger over time. The
      // whole scale was bumped ~30% so entities read clearly and are easy
      // to sweep with a finger path.
      final tierSpan = switch (i % 8) {
        0 || 5 => 3.45 + rand.nextDouble() * 0.65,
        1 || 3 || 6 => 2.8 + rand.nextDouble() * 0.65,
        _ => 2.41 + rand.nextDouble() * 0.59,
      };
      final span = (tierSpan * data.sizeMultiplier)
          .clamp(2.28, 4.42)
          .toDouble();
      final reach = span * 0.55;

      Vector2? chosen;
      var bestClearance = -double.infinity;
      Vector2? bestCandidate;
      for (var attempt = 0; attempt < 72; attempt++) {
        final candidate = Vector2(
          reach +
              0.3 +
              rand.nextDouble() * max(0.1, visibleWidth - reach * 2 - 0.6),
          spawnBandTop +
              reach +
              rand.nextDouble() * spawnBandHeight,
        );
        var clearance = double.infinity;
        for (final placed in placements) {
          final gap =
              candidate.distanceTo(placed.center) - (reach + placed.span) * 0.82;
          clearance = min(clearance, gap);
        }
        if (clearance > bestClearance) {
          bestClearance = clearance;
          bestCandidate = candidate;
        }
        if (clearance >= 0) {
          chosen = candidate;
          break;
        }
      }
      chosen ??= bestCandidate ?? Vector2(visibleWidth / 2, spawnBandTop + reach);
      placements.add((center: chosen, span: reach));

      world.add(BubbleBody(
        data: data,
        targetLongSide: span,
        initialPosition: chosen,
        initialHorizontalImpulse:
            replenish ? (rand.nextDouble() - 0.5) * 2.4 : 0,
      ));
    }
  }

  void handleBubbleExplosion(BubbleBody bubble) {
    // The replenish stream tops the population back up; no instant refill
    // here so a batch collect reads as a visible dip in the pile.
    if (bubble.parent != null) bubble.removeFromParent();
  }

  void handleBubbleRejection(BubbleBody bubble) {
    // Handled by the replenish stream (see [_replenishTimer]).
  }

  void setCategory(String? category) {
    if (_category == category) return;
    _category = category;
    if (!_isLoaded) return;
    _reloadBubbles();
  }

  void _reloadBubbles() {
    for (final bubble in world.children.whereType<BubbleBody>().toList()) {
      bubble.removeFromParent();
    }
    // Same wave pattern as the opening: drop a first wave, let the
    // replenish stream pour the rest in without overlaps.
    _addBubbles(count: _initialDropWaveSize);
    _pendingWaveDelay = _initialWaveGapSec;
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
        .toList()
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
    selectionRevision.dispose();
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
          const Color(0xFF1C1C1E).withOpacity(0.0),
          const Color(0xFF101012).withOpacity(0.72),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, height - 150, width, 150));

    canvas.drawRect(Rect.fromLTWH(0, height - 150, width, 150), paint);

    // Draw "discard" text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '下滑拉黑',
        style: TextStyle(
          color: const Color(0xFF9B9691).withOpacity(0.66),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
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
