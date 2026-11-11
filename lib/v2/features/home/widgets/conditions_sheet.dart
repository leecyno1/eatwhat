import 'package:flutter/material.dart';

import '../../../core/data/models/taste_selection_models.dart';
import '../../../core/theme/app_tokens.dart';

/// Compact sheet that folds budget, party size and execution mode into one
/// entry point, so the home header only needs a single “条件” control.
Future<void> showHomeConditionsSheet({
  required BuildContext context,
  required TasteStructuredConstraints constraints,
  required ValueChanged<TasteStructuredConstraints> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _HomeConditionsSheet(
      initial: constraints,
      onChanged: onChanged,
    ),
  );
}

class _HomeConditionsSheet extends StatefulWidget {
  const _HomeConditionsSheet({
    required this.initial,
    required this.onChanged,
  });

  final TasteStructuredConstraints initial;
  final ValueChanged<TasteStructuredConstraints> onChanged;

  @override
  State<_HomeConditionsSheet> createState() => _HomeConditionsSheetState();
}

class _HomeConditionsSheetState extends State<_HomeConditionsSheet> {
  late TasteStructuredConstraints _constraints = widget.initial;

  void _update(TasteStructuredConstraints next) {
    setState(() => _constraints = next);
    widget.onChanged(next);
  }

  void _reset() {
    _update(
      _constraints.copyWith(
        clearMaxBudgetYuan: true,
        clearPartySize: true,
        executionPreference: TasteExecutionPreference.any,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('home-conditions-sheet'),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.lg),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppPalette.divider,
                borderRadius: AppRadii.capsule,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('用餐条件', style: AppTypeNight.section),
              ),
              TextButton(
                key: const ValueKey('home-conditions-reset'),
                onPressed: _reset,
                child: const Text('清空'),
              ),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close_rounded,
                  color: AppPalette.inkSoft,
                  size: 20,
                ),
              ),
            ],
          ),
          Text(
            '预算、人数和做法只影响推荐。',
            style: AppTypeNight.body.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 14),
          _ConditionGroup(
            label: '预算',
            children: [
              for (final yuan in const [0, 30, 60, 100])
                _ConditionChip(
                  key: ValueKey('condition-budget-$yuan'),
                  label: yuan == 0 ? '不限' : '$yuan 元内',
                  selected: (yuan == 0 && _constraints.maxBudgetYuan == null) ||
                      _constraints.maxBudgetYuan == yuan,
                  onTap: () => _update(
                    _constraints.copyWith(
                      maxBudgetYuan: yuan == 0 ? null : yuan,
                      clearMaxBudgetYuan: yuan == 0,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _ConditionGroup(
            label: '人数',
            children: [
              for (final size in const [0, 1, 2, 4])
                _ConditionChip(
                  key: ValueKey('condition-party-$size'),
                  label: size == 0 ? '不限' : '$size 人',
                  selected: (size == 0 && _constraints.partySize == null) ||
                      _constraints.partySize == size,
                  onTap: () => _update(
                    _constraints.copyWith(
                      partySize: size == 0 ? null : size,
                      clearPartySize: size == 0,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _ConditionGroup(
            label: '方式',
            children: [
              for (final preference in TasteExecutionPreference.values)
                _ConditionChip(
                  key: ValueKey('condition-execution-${preference.name}'),
                  label: preference.label,
                  selected: _constraints.executionPreference == preference,
                  onTap: () => _update(
                    _constraints.copyWith(executionPreference: preference),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }
}

class _ConditionGroup extends StatelessWidget {
  const _ConditionGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: TextStyle(
              color: AppPalette.inkSoft,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: children.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (_, index) => children[index],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConditionChip extends StatelessWidget {
  const _ConditionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.capsule,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppPalette.leaf : AppPalette.surface,
            borderRadius: AppRadii.capsule,
            border: Border.all(
              color: selected ? AppPalette.leaf : AppPalette.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppPalette.night : AppPalette.ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
