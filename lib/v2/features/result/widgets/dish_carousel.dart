import 'dart:math' as math;

import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// The 3D dish carousel: candidate dishes sit in recessed wells around a
/// large tilted serving plate (俯视餐桌上的圆盘). The plate itself is a
/// physical object — dark ceramic with a gold rim and a soft inner shadow —
/// and each dish photo is elliptically compressed into its well so it reads
/// at the same top-down angle as the prebuilt library photography.
///
/// Drag anywhere to spin with inertia; the nearest dish snaps to the front
/// where it lifts off the plate (larger, lit gold ring, drop shadow on the
/// plate). Tap the front dish to add or remove it from tonight's menu.
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
    final fling = (velocity * 0.012 * 0.35).clamp(-_step * 1.5, _step * 1.5);
    final predicted = _angle + fling;
    final front = math.pi / 2;
    final nearest =
        ((front - predicted) / _step).roundToDouble() * _step;
    final target = front - nearest;
    _animateTo(target);
  }

  void _spinTo(int index) {
    final front = math.pi / 2;
    final targetTheta = front - index * _step;
    var delta = targetTheta - _angle;
    while (delta > math.pi) {
      delta -= 2 * math.pi;
    }
    while (delta < -math.pi) {
      delta += 2 * math.pi;
    }
    _animateTo(_angle + delta);
  }

  void _animateTo(double target, {int durationMs = 400}) {
    _snapController?.dispose();
    _snapController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
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
        final rx = w * 0.42;
        final ry = h * 0.32;

        final wells = <_CarouselEntry>[];
        for (var i = 0; i < _count; i++) {
          final theta = _angle + i * _step;
          final x = cx + math.cos(theta) * rx;
          final y = cy + math.sin(theta) * ry;
          // Depth: 1.0 at the front slot, 0.0 at the very back.
          final depth = (math.sin(theta) + 1) / 2;
          final isFront = i == focusedIndex;
          final isSelected =
              widget.selectedIds.contains(widget.dishes[i].id);

          wells.add(
            _CarouselEntry(
              sortKey: depth,
              child: Positioned(
                left: x - 56,
                top: y - 40,
                child: isFront
                    ? _FrontDishCard(
                        key: ValueKey(
                          'carousel-dish-${widget.dishes[i].id}',
                        ),
                        dish: widget.dishes[i],
                        thumbUrl:
                            widget.thumbUrlByRecipeId[widget.dishes[i].id],
                        selected: isSelected,
                        onTap: () => widget.onToggleSelect(widget.dishes[i]),
                      )
                    : Transform.scale(
                        scale: 0.62 + depth * 0.33,
                        child: Opacity(
                          opacity: 0.45 + depth * 0.55,
                          child: _WellDishCard(
                            key: ValueKey(
                              'carousel-dish-${widget.dishes[i].id}',
                            ),
                            dish: widget.dishes[i],
                            thumbUrl: widget
                                .thumbUrlByRecipeId[widget.dishes[i].id],
                            selected: isSelected,
                            onTap: () => _spinTo(i),
                          ),
                        ),
                      ),
              ),
            ),
          );
        }

        wells.sort((a, b) => a.sortKey.compareTo(b.sortKey));

        return GestureDetector(
          key: const ValueKey('result-dish-carousel'),
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The plate: layered ellipses read as a ceramic dish seen from
              // above — outer gold rim, dark ceramic body, recessed center.
              Positioned(
                left: cx - rx - 26,
                top: cy - ry - 20,
                child: _PlateBody(width: (rx + 26) * 2, height: (ry + 20) * 2),
              ),
              ...wells.map((e) => e.child),
            ],
          ),
        );
      },
    );
  }
}

class _CarouselEntry {
  const _CarouselEntry({required this.sortKey, required this.child});
  final double sortKey;
  final Widget child;
}

/// The physical plate: an outer gold-lipped rim, a ceramic body with a
/// vertical sheen, and an inset center shadow that reads as depth.
class _PlateBody extends StatelessWidget {
  const _PlateBody({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Outer rim (gold lip).
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  GoldPalette.gold.withValues(alpha: 0.55),
                  GoldPalette.goldDim.withValues(alpha: 0.35),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
          ),
          // Ceramic body.
          Positioned.fill(
            left: 3,
            right: 3,
            top: 3,
            bottom: 3,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF26262A),
                    const Color(0xFF17171A),
                    const Color(0xFF101012),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          // Recessed center: inner shadow ring reads as the plate's bowl.
          Positioned.fill(
            left: 16,
            right: 16,
            top: 12,
            bottom: 12,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.65),
                  width: 2,
                ),
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.72],
                ),
              ),
            ),
          ),
          // Top sheen: a soft light catching the far rim.
          Positioned(
            left: width * 0.18,
            right: width * 0.18,
            top: height * 0.06,
            child: Container(
              height: height * 0.16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A dish seated in its well: the photo is vertically compressed into an
/// ellipse so it shares the plate's viewing angle, ringed by a dark groove
/// that reads as a recess in the ceramic.
class _WellDishCard extends StatelessWidget {
  const _WellDishCard({
    super.key,
    required this.dish,
    required this.thumbUrl,
    required this.selected,
    required this.onTap,
  });

  final RecipeModel dish;
  final String? thumbUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 112,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The groove: dark ring + soft inner shadow.
            Container(
              width: 108,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.5),
                border: Border.all(
                  color: selected
                      ? GoldPalette.gold.withValues(alpha: 0.8)
                      : GoldPalette.goldHairline,
                  width: selected ? 1.6 : 1,
                ),
              ),
            ),
            // The photo, elliptically compressed to the plate's angle.
            ClipOval(
              child: SizedBox(
                width: 100,
                height: 68,
                child: Transform.scale(
                  scaleY: 0.68 / 1.0,
                  scaleX: 1.0,
                  child: thumbUrl != null && thumbUrl!.isNotEmpty
                      ? Image.asset(
                          thumbUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallback(),
                        )
                      : _fallback(),
                ),
              ),
            ),
            if (selected)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: GoldPalette.gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: GoldPalette.nightDeep,
                  ),
                ),
              ),
          ],
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
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// The front dish lifted off the plate: full-size round photo, lit gold
/// ring, and a drop shadow cast back onto the ceramic. Tapping toggles its
/// place on tonight's menu.
class _FrontDishCard extends StatelessWidget {
  const _FrontDishCard({
    super.key,
    required this.dish,
    required this.thumbUrl,
    required this.selected,
    required this.onTap,
  });

  final RecipeModel dish;
  final String? thumbUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 112,
        height: 92,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Shadow cast on the plate under the lifted dish.
            Positioned(
              bottom: 2,
              child: Container(
                width: 84,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GoldPalette.gold,
                    width: 2.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GoldPalette.gold.withValues(alpha: 0.30),
                      blurRadius: 22,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: thumbUrl != null && thumbUrl!.isNotEmpty
                      ? Image.asset(
                          thumbUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallback(),
                        )
                      : _fallback(),
                ),
              ),
            ),
            if (selected)
              Positioned(
                right: 8,
                bottom: 14,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: GoldPalette.gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: GoldPalette.nightDeep,
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: IgnorePointer(
                child: Text(
                  dish.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: GoldPalette.creamText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    shadows: [
                      Shadow(color: Colors.black87, blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
