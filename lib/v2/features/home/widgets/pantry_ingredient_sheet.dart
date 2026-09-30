import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 冰箱找菜：录入家里现有的食材，反查能做的菜。
class PantryIngredientSheet extends StatefulWidget {
  const PantryIngredientSheet({
    super.key,
    required this.onConfirm,
    this.initialIngredients = const [],
  });

  final ValueChanged<List<String>> onConfirm;
  final List<String> initialIngredients;

  @override
  State<PantryIngredientSheet> createState() => _PantryIngredientSheetState();
}

class _PantryIngredientSheetState extends State<PantryIngredientSheet> {
  static const List<String> _quickAdds = [
    '鸡蛋',
    '番茄',
    '土豆',
    '青椒',
    '豆腐',
    '猪肉',
    '牛肉',
    '面条',
    '米饭',
    '葱',
  ];

  final TextEditingController _controller = TextEditingController();
  late final Set<String> _selected = Set<String>.from(widget.initialIngredients);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final item = raw.trim();
    if (item.isEmpty) return;
    setState(() => _selected.add(item));
    _controller.clear();
  }

  void _toggle(String item) {
    setState(() {
      if (!_selected.remove(item)) {
        _selected.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected.toList();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('冰箱找菜', style: AppType.section),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '写下家里有的食材，看看现在就能做什么',
              style: TextStyle(
                color: AppPalette.moonMuted,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('pantry-ingredient-input'),
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _add,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '输入食材，如：鸡翅',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filled(
                  key: const ValueKey('pantry-ingredient-add'),
                  onPressed: () => _add(_controller.text),
                  icon: const Icon(Icons.add_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final item in _quickAdds)
                  _PantryChip(
                    label: item,
                    selected: _selected.contains(item),
                    onTap: () => _toggle(item),
                  ),
                for (final item in selected.where((e) => !_quickAdds.contains(e)))
                  _PantryChip(
                    label: item,
                    selected: true,
                    onTap: () => _toggle(item),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              key: const ValueKey('pantry-ingredient-confirm'),
              onPressed: selected.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      widget.onConfirm(selected);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.leaf,
                foregroundColor: AppPalette.night,
              ),
              icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
              label: Text(selected.isEmpty ? '先加一样食材' : '用这些找菜 · ${selected.length} 样'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PantryChip extends StatelessWidget {
  const _PantryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('pantry-chip-$label'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppPalette.leaf : AppPalette.nightElevated,
          borderRadius: AppRadii.capsule,
          border: Border.all(
            color: selected ? AppPalette.leaf : AppPalette.nightDivider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? AppPalette.night : AppPalette.moonlight,
          ),
        ),
      ),
    );
  }
}
