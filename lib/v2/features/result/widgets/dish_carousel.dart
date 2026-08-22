import 'dart:math' as math;

import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// The 3D dish carousel: candidate dishes ride the rim of a tilted round
/// tray (俯视餐盘). Drag anywhere to spin — the wheel carries inertia and
/// snaps the nearest dish to the front slot; tap the front dish to add or
/// remove it from tonight's menu (multi-select, see the gold check badge).
///
/// Geometry: dishes sit on an ellipse (wide rx, shallow ry) so the plate
/// reads as viewed from above at an angle — matching the top-down dish
/// photography in the prebuilt image library. The front slot (θ = π/2)
/// gets the largest card with a lit gold rim; dishes behind the plate
/// shrink, dim, and sink behind it.
class DishCarousel extends StatefulWidget {
  const DishCarousel({
    super.key,
    required this.dishes,
    required this.thumbUrlByRecipeId,
    required this.selectedIds,
    required this.onToggleSelect,
    this.focusedIndex = 0,
    this.onFocusedChanged,
  });

  final List<RecipeModel> dishes;

  /// Prebuilt-library thumbnail per recipe id (may be empty while loading).
  final Map<String, String> thumbUrlByRecipeId;

  /// Ids currently on tonight's menu.
  final Set<String> selectedIds;

  /// Tap on the front dish toggles its membership in the menu.
  final ValueChanged<RecipeModel> onToggleSelect;

  final int focusedIndex;
  final ValueChanged<int>? onFocusedChanged;

  @override
  State<DishCarousel> createState() => DishCarouselState();
}

class DishCarouselState extends State<DishCarousel>
    with TickerProviderStateMixin {
  /// Current wheel rotation in radians; dish i rests at
  /// `_angle + i * _step` around the ellipse. Starts aligned so the first
  /// dish sits in the front slot (θ = π/2).
  double _angle = math.pi / 2;
  AnimationController? _snapController;
  Animation<double>? _snapAnimation;

  int get _count => widget.dishes.length;
  double get _step => _count == 0 ? 0 : (2 * math.pi) / _count;

  /// Index of the dish currently sitting in the front slot.
  int get focusedIndex {
    if (_count == 0) return 0;
    // Front slot is at θ = π/2; solve _angle + i·step ≡ π/2 (mod 2π).
    final raw = ((math.pi / 2 - _angle) / _step).round() % _count;
    return (raw + _count) % _count;
  }

  @override
  void dispose() {
    _snapController?.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _snapController?.stop();
    setState(() {
      _angle += details.delta.dx * 0.012;
    });
    widget.onFocusedChanged?.call(focusedIndex);
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    // Fling distance first (clamped), then snap the nearest dish to front.
    final fling = (velocity * 0.012 * 0.35).clamp(-_step * 1.5, _step * 1.5);
    final predicted = _angle + fling;
    // Target: the angle whose nearest dish lands on the front slot.
    final front = math.pi / 2;
    final nearest =
        ((front - predicted) / _step).roundToDouble() * _step;
    final target = front - nearest;

    _snapController?.dispose();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _snapAnimation = Tween<double>(begin: _angle, end: target).animate(
      CurvedAnimation(parent: _snapController!, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() => _angle = _snapAnimation!.value);
      });
    _snapController!.forward().whenComplete(() {
      widget.onFocusedChanged?.call(focusedIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cx = w / 2;
        final cy = h / 2;
        // Ellipse: wide and shallow, so the plate reads as seen from above.
        final rx = w * 0.40;
        final ry = h * 0.30;

        final cards = <_CarouselEntry>[];
        for (var i = 0; i < _count; i++) {
          final theta = _angle + i * _step;
          final x = cx + math.cos(theta) * rx;
          final y = cy + math.sin(theta) * ry;
          // Depth: 1.0 at the front slot, 0.0 at the very back.
          final depth = (math.sin(theta) + 1) / 2;
          final scale = 0.55 + depth * 0.65; // back 55% → front 120%
          final opacity = 0.35 + depth * 0.65;
          final isFront = i == focusedIndex;
          final isSelected =
              widget.selectedIds.contains(widget.dishes[i].id);

          cards.add(
            _CarouselEntry(
              // Back dishes render first so the front card stays on top.
              sortKey: depth,
              child: Positioned(
                left: x - 52,
                top: y - 52,
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: _DishCard(
                      key: ValueKey(
                        'carousel-dish-${widget.dishes[i].id}',
                      ),
                      dish: widget.dishes[i],
                      thumbUrl:
                          widget.thumbUrlByRecipeId[widget.dishes[i].id],
                      front: isFront,
                      selected: isSelected,
                      onTap: () {
                        if (isFront) {
                          widget.onToggleSelect(widget.dishes[i]);
                        } else {
                          _spinTo(i);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        cards.sort((a, b) => a.sortKey.compareTo(b.sortKey));

        return GestureDetector(
          key: const ValueKey('result-dish-carousel'),
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The plate itself: a gold-rimmed ellipse under the dishes.
              Positioned(
                left: cx - rx - 14,
                top: cy - ry - 14,
                child: Container(
                  width: (rx + 14) * 2,
                  height: (ry + 14) * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: GoldPalette.goldHairline,
                      width: 1.2,
                    ),
                    gradient: RadialGradient(
                      colors: [
                        GoldPalette.gold.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              ...cards.map((e) => e.child),
            ],
          ),
        );
      },
    );
  }

  void _spinTo(int index) {
    final front = math.pi / 2;
    // Rotate so dish i lands exactly in the front slot, shortest way.
    final targetTheta = front - index * _step;
    var delta = targetTheta - _angle;
    while (delta > math.pi) {
      delta -= 2 * math.pi;
    }
    while (delta < -math.pi) {
      delta += 2 * math.pi;
    }
    final target = _angle + delta;

    _snapController?.dispose();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _snapAnimation = Tween<double>(begin: _angle, end: target).animate(
      CurvedAnimation(parent: _snapController!, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() => _angle = _snapAnimation!.value);
      });
    _snapController!.forward().whenComplete(() {
      widget.onFocusedChanged?.call(focusedIndex);
    });
  }
}

class _CarouselEntry {
  const _CarouselEntry({required this.sortKey, required this.child});
  final double sortKey;
  final Widget child;
}

class _DishCard extends StatelessWidget {
  const _DishCard({
    super.key,
    required this.dish,
    required this.thumbUrl,
    required this.front,
    required this.selected,
    required this.onTap,
  });

  final RecipeModel dish;
  final String? thumbUrl;
  final bool front;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: front
                ? GoldPalette.gold
                : (selected
                    ? GoldPalette.gold.withValues(alpha: 0.75)
                    : GoldPalette.goldHairline),
            width: front ? 2.2 : 1.2,
          ),
          boxShadow: front
              ? [
                  BoxShadow(
                    color: GoldPalette.gold.withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbUrl != null && thumbUrl!.isNotEmpty)
                Image.asset(
                  thumbUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(),
                )
              else
                _fallback(),
              // Dim non-front dishes slightly so the front dish pops.
              if (!front)
                Container(color: Colors.black.withValues(alpha: 0.28)),
              if (selected)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: GoldPalette.gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: GoldPalette.nightDeep,
                    ),
                  ),
                ),
              if (front)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    color: Colors.black.withValues(alpha: 0.55),
                    child: Text(
                      dish.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: GoldPalette.creamText,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: GoldPalette.panel,
      alignment: Alignment.center,
      child: Text(
        dish.name.characters.isEmpty ? '菜' : dish.name.characters.first,
        style: const TextStyle(
          color: GoldPalette.goldSoft,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
