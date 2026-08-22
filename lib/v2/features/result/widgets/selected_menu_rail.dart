import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Tonight's menu as a compact rail of round dish thumbnails. Each carries
/// a small gold × to remove — the carousel above adds, this rail trims.
/// Hidden entirely when nothing is selected.
class SelectedMenuRail extends StatelessWidget {
  const SelectedMenuRail({
    super.key,
    required this.selected,
    required this.thumbUrlByRecipeId,
    required this.onRemove,
  });

  final List<RecipeModel> selected;
  final Map<String, String> thumbUrlByRecipeId;
  final ValueChanged<RecipeModel> onRemove;

  @override
  Widget build(BuildContext context) {
    if (selected.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      key: const ValueKey('selected-menu-rail'),
      height: 58,
      child: Row(
        children: [
          Text(
            '本餐 ${selected.length} 道',
            style: const TextStyle(
              color: GoldPalette.goldSoft,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selected.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final dish = selected[index];
                final thumb = thumbUrlByRecipeId[dish.id];
                return SizedBox(
                  key: ValueKey('selected-menu-item-${dish.id}'),
                  width: 52,
                  height: 58,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: GoldPalette.goldHairline,
                          ),
                        ),
                        child: ClipOval(
                          child: thumb != null && thumb.isNotEmpty
                              ? Image.asset(
                                  thumb,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _fallback(dish),
                                )
                              : _fallback(dish),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        top: -2,
                        child: GestureDetector(
                          key: ValueKey('selected-menu-remove-${dish.id}'),
                          onTap: () => onRemove(dish),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: GoldPalette.nightDeep,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: GoldPalette.gold,
                                width: 1.1,
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 11,
                              color: GoldPalette.gold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback(RecipeModel dish) {
    return Container(
      color: GoldPalette.panel,
      alignment: Alignment.center,
      child: Text(
        dish.name.characters.isEmpty ? '菜' : dish.name.characters.first,
        style: const TextStyle(
          color: GoldPalette.goldSoft,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
