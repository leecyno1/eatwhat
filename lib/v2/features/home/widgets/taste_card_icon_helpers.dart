import 'package:flutter/material.dart';

IconData tasteCardIconFor(String iconName, String category) {
  switch (iconName) {
    case 'local_fire_department':
      return Icons.local_fire_department_rounded;
    case 'cake':
      return Icons.cake_rounded;
    case 'local_bar':
      return Icons.local_bar_rounded;
    case 'spa':
      return Icons.spa_rounded;
    case 'set_meal':
      return Icons.set_meal_rounded;
    case 'celebration':
      return Icons.celebration_rounded;
    case 'wb_sunny':
      return Icons.wb_sunny_rounded;
    case 'nights_stay':
      return Icons.nights_stay_rounded;
    case 'ramen_dining':
      return Icons.ramen_dining_rounded;
    case 'local_pizza':
      return Icons.local_pizza_rounded;
    case 'lunch_dining':
      return Icons.lunch_dining_rounded;
    case 'dinner_dining':
      return Icons.dinner_dining_rounded;
    case 'restaurant':
      return Icons.restaurant_rounded;
    case 'restaurant_menu':
      return Icons.restaurant_menu_rounded;
    case 'favorite':
      return Icons.favorite_rounded;
    case 'bolt':
      return Icons.bolt_rounded;
    case 'savings':
      return Icons.savings_rounded;
    case 'fitness_center':
      return Icons.fitness_center_rounded;
    case 'card_giftcard':
      return Icons.card_giftcard_rounded;
    case 'shuffle':
      return Icons.shuffle_rounded;
    case 'self_improvement':
      return Icons.self_improvement_rounded;
    case 'local_florist':
      return Icons.local_florist_rounded;
    case 'coffee':
      return Icons.coffee_rounded;
    case 'water_drop':
      return Icons.water_drop_rounded;
    case 'egg':
      return Icons.egg_alt_rounded;
    case 'grass':
      return Icons.grass_rounded;
    default:
      switch (category) {
        case 'flavor':
          return Icons.auto_awesome_rounded;
        case 'ingredient':
          return Icons.restaurant_menu_rounded;
        case 'scene':
          return Icons.theater_comedy_rounded;
        case 'cuisine':
          return Icons.room_service_rounded;
        case 'staple':
          return Icons.rice_bowl_rounded;
        case 'fortune':
          return Icons.auto_fix_high_rounded;
        case 'dietary':
          return Icons.eco_rounded;
        case 'meta':
          return Icons.psychology_alt_rounded;
        default:
          return Icons.blur_on_rounded;
      }
  }
}
