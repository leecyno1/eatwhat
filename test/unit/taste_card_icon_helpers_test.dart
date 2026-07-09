import 'package:eatwhat_app/v2/features/home/widgets/taste_card_icon_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('taste card icon helpers', () {
    test('maps explicit icon names to rounded Material icons', () {
      expect(
        tasteCardIconFor('local_fire_department', 'flavor'),
        Icons.local_fire_department_rounded,
      );
      expect(tasteCardIconFor('ramen_dining', 'cuisine'), Icons.ramen_dining_rounded);
      expect(tasteCardIconFor('water_drop', 'dietary'), Icons.water_drop_rounded);
    });

    test('falls back to category icons for unknown icon names', () {
      expect(tasteCardIconFor('unknown', 'flavor'), Icons.auto_awesome_rounded);
      expect(
        tasteCardIconFor('unknown', 'ingredient'),
        Icons.restaurant_menu_rounded,
      );
      expect(tasteCardIconFor('unknown', 'fortune'), Icons.auto_fix_high_rounded);
      expect(tasteCardIconFor('unknown', 'meta'), Icons.psychology_alt_rounded);
    });

    test('uses neutral fallback when both icon name and category are unknown', () {
      expect(tasteCardIconFor('unknown', 'other'), Icons.blur_on_rounded);
    });
  });
}
