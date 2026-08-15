import 'dart:ui';

import 'package:eatwhat_app/v2/core/data/models/meal_planning_direction.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/services/v2_meal_habit_learning_service.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

import 'bubble_ocean.dart';

class FreshPhysicalPreferenceStage extends StatelessWidget {
  const FreshPhysicalPreferenceStage({
    super.key,
    required this.session,
    required this.isLoading,
    required this.planningDirection,
    required this.habitSnapshot,
    required this.category,
    required this.structuredConstraints,
    required this.onPlanningDirectionChanged,
    required this.onCategoryChanged,
    required this.onStructuredConstraintsChanged,
    required this.onSelectionChanged,
  });

  final TasteDeckSessionState? session;
  final bool isLoading;
  final MealPlanningDirection planningDirection;
  final MealHabitSnapshot? habitSnapshot;
  final String? category;
  final TasteStructuredConstraints structuredConstraints;
  final ValueChanged<MealPlanningDirection> onPlanningDirectionChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<TasteStructuredConstraints> onStructuredConstraintsChanged;
  final ValueChanged<BubbleSelectionState> onSelectionChanged;

  static const _categories = <({String label, String? value, IconData icon})>[
    (label: '全部', value: null, icon: Icons.grid_view_rounded),
    (
      label: '食材健康',
      value: 'ingredient_dietary',
      icon: Icons.eco_rounded,
    ),
    (
      label: '口味主食',
      value: 'flavor_staple',
      icon: Icons.local_fire_department_rounded,
    ),
    (label: '菜系', value: 'cuisine', icon: Icons.ramen_dining_rounded),
    (
      label: '场景趣味',
      value: 'scene_fun',
      icon: Icons.wb_sunny_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final current = session;
    final likedTags = _zipTags(
      current?.likedTagIds ?? const [],
      current?.likedTagLabels ?? const [],
    );
    final blockedTags = _zipTags(
      current?.dislikedTagIds ?? const [],
      current?.dislikedTagLabels ?? const [],
    );
    return Column(
      children: [
        _CompactFilterStrip(
          planningDirection: planningDirection,
          habitSnapshot: habitSnapshot,
          category: category,
          constraints: structuredConstraints,
          categories: _categories,
          onPlanningDirectionChanged: onPlanningDirectionChanged,
          onCategoryChanged: onCategoryChanged,
          onConstraintsChanged: onStructuredConstraintsChanged,
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _PhysicalTasteHabitat(
            isLoading: isLoading || current == null,
            category: category,
            initialLikedTags: likedTags,
            initialBlockedTags: blockedTags,
            onSelectionChanged: onSelectionChanged,
          ),
        ),
      ],
    );
  }

  Map<String, String> _zipTags(List<String> ids, List<String> labels) {
    return {
      for (var index = 0; index < ids.length; index++)
        ids[index]: index < labels.length ? labels[index] : ids[index],
    };
  }
}

class _CompactFilterStrip extends StatefulWidget {
  const _CompactFilterStrip({
    required this.planningDirection,
    required this.habitSnapshot,
    required this.category,
    required this.constraints,
    required this.categories,
    required this.onPlanningDirectionChanged,
    required this.onCategoryChanged,
    required this.onConstraintsChanged,
  });

  final MealPlanningDirection planningDirection;
  final MealHabitSnapshot? habitSnapshot;
  final String? category;
  final TasteStructuredConstraints constraints;
  final List<({String label, String? value, IconData icon})> categories;
  final ValueChanged<MealPlanningDirection> onPlanningDirectionChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<TasteStructuredConstraints> onConstraintsChanged;

  @override
  State<_CompactFilterStrip> createState() => _CompactFilterStripState();
}

class _CompactFilterStripState extends State<_CompactFilterStrip> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollHint = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollHint);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollHint());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateScrollHint)
      ..dispose();
    super.dispose();
  }

  void _updateScrollHint() {
    if (!_scrollController.hasClients || !mounted) return;
    final shouldShow = _scrollController.position.extentAfter > 8;
    if (shouldShow != _showScrollHint) {
      setState(() => _showScrollHint = shouldShow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryLabel = widget.categories
        .firstWhere(
          (item) => item.value == widget.category,
          orElse: () => widget.categories.first,
        )
        .label;
    final historyDirection = widget.habitSnapshot?.recommendedDirection;
    return SizedBox(
      key: const ValueKey('taste-entity-category-tabs'),
      height: 42,
      child: Stack(
        children: [
          ListView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 28),
            children: [
              _CompactFilterMenu<MealPlanningDirection>(
                key: const ValueKey('meal-planning-direction-selector'),
                icon: historyDirection == widget.planningDirection
                    ? Icons.auto_awesome_rounded
                    : Icons.psychology_alt_rounded,
                label: '习惯',
                valueLabel: widget.planningDirection.label,
                value: widget.planningDirection,
                options: [
                  for (final direction in MealPlanningDirection.values)
                    _FilterOption(
                      key: 'meal-direction-${direction.name}',
                      label: direction.label,
                      value: direction,
                    ),
                ],
                onSelected: widget.onPlanningDirectionChanged,
              ),
              const SizedBox(width: 6),
              _CompactFilterMenu<String>(
                key: const ValueKey('filter-type'),
                icon: Icons.category_rounded,
                label: '类型',
                valueLabel: categoryLabel,
                value: widget.category ?? '__all__',
                options: [
                  for (final item in widget.categories)
                    _FilterOption(
                      key: 'taste-category-${item.label}',
                      label: item.label,
                      value: item.value ?? '__all__',
                    ),
                ],
                onSelected: (value) =>
                    widget.onCategoryChanged(value == '__all__' ? null : value),
              ),
              const SizedBox(width: 6),
              _CompactFilterMenu<int>(
                key: const ValueKey('filter-budget'),
                icon: Icons.payments_outlined,
                label: '预算',
                valueLabel: widget.constraints.maxBudgetYuan == null
                    ? '不限'
                    : '${widget.constraints.maxBudgetYuan}元',
                value: widget.constraints.maxBudgetYuan ?? 0,
                options: const [
                  _FilterOption(
                      key: 'filter-budget-any', label: '不限', value: 0),
                  _FilterOption(
                      key: 'filter-budget-30', label: '30 元内', value: 30),
                  _FilterOption(
                      key: 'filter-budget-60', label: '60 元内', value: 60),
                  _FilterOption(
                      key: 'filter-budget-100', label: '100 元内', value: 100),
                ],
                onSelected: (value) => widget.onConstraintsChanged(
                  widget.constraints.copyWith(
                    maxBudgetYuan: value == 0 ? null : value,
                    clearMaxBudgetYuan: value == 0,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _CompactFilterMenu<int>(
                key: const ValueKey('filter-party'),
                icon: Icons.group_outlined,
                label: '人数',
                valueLabel: widget.constraints.partySize == null
                    ? '不限'
                    : '${widget.constraints.partySize}人',
                value: widget.constraints.partySize ?? 0,
                options: const [
                  _FilterOption(key: 'filter-party-any', label: '不限', value: 0),
                  _FilterOption(key: 'filter-party-1', label: '1 人', value: 1),
                  _FilterOption(key: 'filter-party-2', label: '2 人', value: 2),
                  _FilterOption(key: 'filter-party-4', label: '4 人', value: 4),
                ],
                onSelected: (value) => widget.onConstraintsChanged(
                  widget.constraints.copyWith(
                    partySize: value == 0 ? null : value,
                    clearPartySize: value == 0,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _CompactFilterMenu<TasteExecutionPreference>(
                key: const ValueKey('filter-execution'),
                icon: Icons.restaurant_rounded,
                label: '方式',
                valueLabel: widget.constraints.executionPreference.label,
                value: widget.constraints.executionPreference,
                options: [
                  for (final preference in TasteExecutionPreference.values)
                    _FilterOption(
                      key: 'filter-execution-${preference.name}',
                      label: preference.label,
                      value: preference,
                    ),
                ],
                onSelected: (value) => widget.onConstraintsChanged(
                  widget.constraints.copyWith(executionPreference: value),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                key: const ValueKey('filter-strip-scroll-hint'),
                opacity: _showScrollHint ? 1 : 0,
                duration: AppMotion.fast,
                child: Container(
                  width: 34,
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        AppPalette.gardenSoft,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.keyboard_double_arrow_right_rounded,
                    size: 18,
                    color: AppPalette.herb,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption<T> {
  const _FilterOption({
    required this.key,
    required this.label,
    required this.value,
  });

  final String key;
  final String label;
  final T value;
}

class _CompactFilterMenu<T> extends StatelessWidget {
  const _CompactFilterMenu({
    super.key,
    required this.icon,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final String valueLabel;
  final T value;
  final List<_FilterOption<T>> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      constraints: const BoxConstraints(minWidth: 156, maxWidth: 220),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem<T>(
            key: ValueKey(option.key),
            value: option.value,
            height: 42,
            child: Row(
              children: [
                Icon(
                  option.value == value
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 17,
                  color: option.value == value
                      ? AppPalette.herb
                      : AppPalette.inkMuted,
                ),
                const SizedBox(width: 9),
                Text(
                  option.label,
                  style: const TextStyle(
                    color: AppPalette.gardenInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: AppRadii.capsule,
          border: Border.all(color: AppPalette.gardenBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppPalette.herb),
            const SizedBox(width: 5),
            Text(
              '$label · $valueLabel',
              style: const TextStyle(
                color: AppPalette.gardenInk,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: AppPalette.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _MealDirectionSelector extends StatelessWidget {
  const _MealDirectionSelector({
    required this.value,
    required this.onChanged,
  });

  final MealPlanningDirection value;
  final ValueChanged<MealPlanningDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('meal-planning-direction-selector'),
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: AppRadii.capsule,
        border: Border.all(color: AppPalette.gardenBorder),
      ),
      child: Row(
        children: [
          for (final direction in MealPlanningDirection.values)
            Expanded(
              child: _DirectionButton(
                direction: direction,
                selected: direction == value,
                onTap: () => onChanged(direction),
              ),
            ),
        ],
      ),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  const _DirectionButton({
    required this.direction,
    required this.selected,
    required this.onTap,
  });

  final MealPlanningDirection direction;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (direction) {
      MealPlanningDirection.balanced => Icons.balance_rounded,
      MealPlanningDirection.health => Icons.favorite_rounded,
      MealPlanningDirection.experience => Icons.auto_awesome_rounded,
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('meal-direction-${direction.name}'),
        onTap: onTap,
        borderRadius: AppRadii.capsule,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          decoration: BoxDecoration(
            color: selected ? AppPalette.herb : Colors.transparent,
            borderRadius: AppRadii.capsule,
            boxShadow: selected
                ? AppSurfaces.softShadow(
                    AppPalette.herb.withValues(alpha: 0.18),
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? Colors.white : AppPalette.gardenInk,
              ),
              const SizedBox(width: 5),
              Text(
                direction.label,
                style: TextStyle(
                  color: selected ? Colors.white : AppPalette.gardenInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _HabitInsightBand extends StatelessWidget {
  const _HabitInsightBand({
    required this.snapshot,
    required this.direction,
  });

  final MealHabitSnapshot? snapshot;
  final MealPlanningDirection direction;

  @override
  Widget build(BuildContext context) {
    final insight = snapshot?.insight ?? '正在读取历史饮食习惯';
    final matchesHistory = snapshot?.recommendedDirection == direction;
    return Container(
      key: const ValueKey('meal-habit-insight'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: matchesHistory
            ? AppPalette.gardenSoft
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: AppRadii.capsule,
        border: Border.all(color: AppPalette.gardenBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights_rounded,
            size: 15,
            color: matchesHistory ? AppPalette.herb : AppPalette.inkMuted,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              insight,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    matchesHistory ? AppPalette.gardenInk : AppPalette.inkSoft,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('taste-category-$label'),
        onTap: onTap,
        borderRadius: AppRadii.capsule,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: selected
                ? AppPalette.herb
                : Colors.white.withValues(alpha: 0.78),
            borderRadius: AppRadii.capsule,
            border: Border.all(
              color: selected ? AppPalette.herb : AppPalette.gardenBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : AppPalette.herb,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppPalette.gardenInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhysicalTasteHabitat extends StatefulWidget {
  const _PhysicalTasteHabitat({
    required this.isLoading,
    required this.category,
    required this.initialLikedTags,
    required this.initialBlockedTags,
    required this.onSelectionChanged,
  });

  final bool isLoading;
  final String? category;
  final Map<String, String> initialLikedTags;
  final Map<String, String> initialBlockedTags;
  final ValueChanged<BubbleSelectionState> onSelectionChanged;

  @override
  State<_PhysicalTasteHabitat> createState() => _PhysicalTasteHabitatState();
}

class _PhysicalTasteHabitatState extends State<_PhysicalTasteHabitat> {
  bool _showGestureHint = true;

  void _handleInteraction() {
    if (!_showGestureHint) return;
    setState(() => _showGestureHint = false);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          key: const ValueKey('taste-physical-habitat'),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.76),
                const Color(0xFFEAF5E7).withValues(alpha: 0.68),
                const Color(0xFFD9EED5).withValues(alpha: 0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.92),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppPalette.herb.withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: widget.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppPalette.herb,
                        ),
                      )
                    : BubbleOcean(
                        showDecisionButton: false,
                        category: widget.category,
                        initialLikedTags: widget.initialLikedTags,
                        initialBlockedTags: widget.initialBlockedTags,
                        onSelectionChanged: widget.onSelectionChanged,
                        onInteracted: _handleInteraction,
                      ),
              ),
              Positioned(
                left: 56,
                right: 56,
                bottom: 16,
                child: IgnorePointer(
                  child: AnimatedSlide(
                    offset:
                        _showGestureHint ? Offset.zero : const Offset(0, 0.35),
                    duration: AppMotion.fast,
                    child: AnimatedOpacity(
                      key: const ValueKey('taste-gesture-hint'),
                      opacity: _showGestureHint ? 1 : 0,
                      duration: AppMotion.fast,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.gardenInk.withValues(alpha: 0.82),
                          borderRadius: AppRadii.capsule,
                          boxShadow: AppSurfaces.softShadow(
                            AppPalette.gardenInk.withValues(alpha: 0.16),
                          ),
                        ),
                        child: const Text(
                          '点选喜欢 · 上滑收下 · 下滑拉黑 · 拖动抛掷',
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
}

// ignore: unused_element
class _SelectionGroup extends StatelessWidget {
  const _SelectionGroup({
    required this.icon,
    required this.color,
    required this.label,
    required this.ids,
    required this.values,
  });

  final IconData icon;
  final Color color;
  final String label;
  final List<String> ids;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppPalette.gardenInk,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (values.isNotEmpty) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: 54,
            height: 25,
            child: Stack(
              children: [
                for (var index = 0;
                    index < (ids.length > 3 ? 3 : ids.length);
                    index++)
                  Positioned(
                    left: index * 15,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/preference_entities/${ids[index]}.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
