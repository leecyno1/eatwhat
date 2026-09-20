import 'package:eatwhat_app/v2/core/data/schema/unified_tag_model.dart';

class TagRepositoryV2 {
  List<UnifiedTagModel> getAllTags() {
    return [
      // --- Flavors (口味) ---
      _buildTag(
          'f_spicy',
          '辣',
          'flavor',
          'local_fire_department',
          const VisualConfig(
              shapeType: 'chili',
              colors: ['0xFFFF5252', '0xFFD32F2F'],
              particleEffect: 'steam')),
      _buildTag(
          'f_sweet',
          '甜',
          'flavor',
          'cake',
          const VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFF4081', '0xFFF50057'],
              particleEffect: 'sparkle')),
      _buildTag(
          'f_sour',
          '酸',
          'flavor',
          'local_bar',
          const VisualConfig(
              shapeType: 'drop',
              colors: ['0xFFCDDC39', '0xFFAFB42B'],
              particleEffect: 'bubble')),
      _buildTag(
          'f_salty',
          '咸',
          'flavor',
          'grain',
          const VisualConfig(
              shapeType: 'hexagon', colors: ['0xFF9E9E9E', '0xFF616161'])),
      _buildTag(
          'f_fresh',
          '鲜',
          'flavor',
          'water_drop',
          const VisualConfig(
              shapeType: 'drop',
              colors: ['0xFF03A9F4', '0xFF0288D1'],
              particleEffect: 'bubble')),
      _buildTag(
          'f_numbing',
          '麻',
          'flavor',
          'bolt',
          const VisualConfig(
              shapeType: 'star',
              colors: ['0xFF673AB7', '0xFF512DA8'],
              particleEffect: 'sparkle')),
      _buildTag(
          'f_garlic',
          '蒜香',
          'flavor',
          'circle',
          const VisualConfig(
              shapeType: 'squircle', colors: ['0xFFEEEEEE', '0xFFBDBDBD'])),
      _buildTag(
          'f_bitter',
          '苦',
          'flavor',
          'coffee',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFF3E2723', '0xFF5D4037'])),
      _buildTag(
          'f_creamy',
          '奶香',
          'flavor',
          'icecream',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFFF9C4', '0xFFFFF176'])),
      _buildTag(
          'f_crispy',
          '酥脆',
          'flavor',
          'cookie',
          const VisualConfig(
              shapeType: 'hexagon',
              colors: ['0xFFFFD54F', '0xFFFFCA28'],
              particleEffect: 'sparkle')),
      _buildTag(
          'f_light',
          '清淡',
          'flavor',
          'spa',
          const VisualConfig(
              shapeType: 'leaf', colors: ['0xFF81C784', '0xFF66BB6A'])),
      _buildTag(
          'f_rich',
          '浓郁',
          'flavor',
          'soup_kitchen',
          const VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF795548', '0xFF5D4037'],
              particleEffect: 'steam')),
      _buildTag(
          'f_smoky',
          '烟熏',
          'flavor',
          'smoking_rooms',
          const VisualConfig(
              shapeType: 'cloud',
              colors: ['0xFF607D8B', '0xFF455A64'],
              particleEffect: 'steam')),
      _buildTag(
          'f_herbal',
          '药膳',
          'flavor',
          'medication',
          const VisualConfig(
              shapeType: 'leaf', colors: ['0xFF558B2F', '0xFF33691E'])),
      _buildTag(
          'f_curry',
          '咖喱',
          'flavor',
          'restaurant',
          const VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFC107', '0xFFFFB300'],
              particleEffect: 'steam')),

      // --- Ingredients (食材) ---
      // Meats
      _buildTag(
          'i_beef',
          '牛肉',
          'ingredient',
          'restaurant',
          const VisualConfig(
              shapeType: 'squircle', colors: ['0xFFD32F2F', '0xFFB71C1C'])),
      _buildTag(
          'i_pork',
          '猪肉',
          'ingredient',
          'savings',
          const VisualConfig(
              shapeType: 'squircle', colors: ['0xFFF48FB1', '0xFFF06292'])),
      _buildTag(
          'i_chicken',
          '鸡肉',
          'ingredient',
          'egg',
          const VisualConfig(
              shapeType: 'squircle', colors: ['0xFFFFB74D', '0xFFFFA726'])),
      _buildTag(
          'i_lamb',
          '羊肉',
          'ingredient',
          'restaurant',
          const VisualConfig(
              shapeType: 'squircle', colors: ['0xFFE57373', '0xFFEF5350'])),
      _buildTag(
          'i_duck',
          '鸭肉',
          'ingredient',
          'restaurant',
          const VisualConfig(
              shapeType: 'squircle', colors: ['0xFF8D6E63', '0xFF795548'])),
      _buildTag(
          'i_goose',
          '鹅肉',
          'ingredient',
          'restaurant',
          const VisualConfig(
              shapeType: 'squircle', colors: ['0xFFA1887F', '0xFF8D6E63'])),
      _buildTag(
          'i_offal',
          '内脏',
          'ingredient',
          'favorite',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFF880E4F', '0xFFAD1457'])),

      // Seafood
      _buildTag(
          'i_seafood',
          '海鲜',
          'ingredient',
          'set_meal',
          const VisualConfig(
              shapeType: 'drop',
              colors: ['0xFF29B6F6', '0xFF0288D1'],
              particleEffect: 'bubble')),
      _buildTag(
          'i_fish',
          '鱼',
          'ingredient',
          'set_meal',
          const VisualConfig(
              shapeType: 'drop',
              colors: ['0xFF4FC3F7', '0xFF29B6F6'],
              particleEffect: 'bubble')),
      _buildTag(
          'i_shrimp',
          '虾',
          'ingredient',
          'set_meal',
          const VisualConfig(
              shapeType: 'chili', colors: ['0xFFFFAB91', '0xFFFF8A65'])),
      _buildTag(
          'i_crab',
          '蟹',
          'ingredient',
          'bug_report',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFF7043', '0xFFF4511E'])),
      _buildTag(
          'i_shellfish',
          '贝类',
          'ingredient',
          'donut_small',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFE0E0E0', '0xFFBDBDBD'])),

      // Veg
      _buildTag(
          'i_vegetable',
          '蔬菜',
          'ingredient',
          'grass',
          const VisualConfig(
              shapeType: 'leaf', colors: ['0xFF66BB6A', '0xFF43A047'])),
      _buildTag(
          'i_mushroom',
          '菌菇',
          'ingredient',
          'umbrella',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFF8D6E63', '0xFF6D4C41'])),
      _buildTag(
          'i_tofu',
          '豆腐',
          'ingredient',
          'crop_square',
          const VisualConfig(
              shapeType: 'squircle', colors: ['0xFFF5F5F5', '0xFFE0E0E0'])),
      _buildTag(
          'i_potato',
          '土豆',
          'ingredient',
          'circle',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFFE0B2', '0xFFFFCC80'])),
      _buildTag(
          'i_tomato',
          '番茄',
          'ingredient',
          'circle',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFF5252', '0xFFFF1744'])),
      _buildTag(
          'i_eggplant',
          '茄子',
          'ingredient',
          'circle',
          const VisualConfig(
              shapeType: 'chili', colors: ['0xFF7E57C2', '0xFF673AB7'])),
      _buildTag(
          'i_corn',
          '玉米',
          'ingredient',
          'circle',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFFF176', '0xFFFFEE58'])),

      // Other
      _buildTag(
          'i_egg',
          '鸡蛋',
          'ingredient',
          'egg_alt',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFFEE58', '0xFFFDD835'])),
      _buildTag(
          'i_cheese',
          '芝士',
          'ingredient',
          'circle',
          const VisualConfig(
              shapeType: 'squircle', colors: ['0xFFFFD54F', '0xFFFFCA28'])),

      // --- Staples (主食) ---
      _buildTag(
          'st_rice',
          '米饭',
          'staple',
          'rice_bowl',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFFFFFF', '0xFFF5F5F5'])),
      _buildTag(
          'st_noodle',
          '面条',
          'staple',
          'ramen_dining',
          const VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFE0B2', '0xFFFFCC80'],
              particleEffect: 'steam')),
      _buildTag(
          'st_bread',
          '面包',
          'staple',
          'bakery_dining',
          const VisualConfig(
              shapeType: 'squircle', colors: ['0xFFD7CCC8', '0xFFBCAAA4'])),
      _buildTag(
          'st_dumpling',
          '饺子',
          'staple',
          'circle',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFF5F5F5', '0xFFEEEEEE'])),
      _buildTag(
          'st_pasta',
          '意面',
          'staple',
          'dinner_dining',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFFE0B2', '0xFFFFCC80'])),
      _buildTag(
          'st_pizza',
          '披萨',
          'staple',
          'local_pizza',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFFAB91', '0xFFFF8A65'])),
      _buildTag(
          'st_burger',
          '汉堡',
          'staple',
          'lunch_dining',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFFCC80', '0xFFFFB74D'])),
      _buildTag(
          'st_porridge',
          '粥',
          'staple',
          'soup_kitchen',
          const VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFF5F5F5', '0xFFEEEEEE'],
              particleEffect: 'steam')),

      // --- Cuisines (菜系) ---
      // Chinese
      _buildTag(
          'c_sichuan',
          '川菜',
          'cuisine',
          'whatshot',
          const VisualConfig(
              shapeType: 'fire',
              colors: ['0xFFFF5722', '0xFFE64A19'],
              particleEffect: 'steam')),
      _buildTag(
          'c_cantonese',
          '粤菜',
          'cuisine',
          'restaurant',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFF4CAF50', '0xFF388E3C'])),
      _buildTag(
          'c_hunan',
          '湘菜',
          'cuisine',
          'local_fire_department',
          const VisualConfig(
              shapeType: 'chili',
              colors: ['0xFFD32F2F', '0xFFB71C1C'],
              particleEffect: 'steam')),
      _buildTag(
          'c_shandong',
          '鲁菜',
          'cuisine',
          'restaurant',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFF795548', '0xFF5D4037'])),
      _buildTag(
          'c_jiangsu',
          '苏菜',
          'cuisine',
          'water',
          const VisualConfig(
              shapeType: 'drop', colors: ['0xFF4FC3F7', '0xFF29B6F6'])),
      _buildTag(
          'c_zhejiang',
          '浙菜',
          'cuisine',
          'water',
          const VisualConfig(
              shapeType: 'drop', colors: ['0xFF81C784', '0xFF66BB6A'])),
      _buildTag(
          'c_fujian',
          '闽菜',
          'cuisine',
          'restaurant',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFFF176', '0xFFFFEE58'])),
      _buildTag(
          'c_anhui',
          '徽菜',
          'cuisine',
          'landscape',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFF5D4037', '0xFF4E342E'])),
      _buildTag(
          'c_northeast',
          '东北菜',
          'cuisine',
          'kitchen',
          const VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF8D6E63', '0xFF795548'],
              particleEffect: 'steam')),
      _buildTag(
          'c_northwest',
          '西北菜',
          'cuisine',
          'restaurant',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFFB74D', '0xFFFFA726'])),
      _buildTag(
          'c_yunnan',
          '云南菜',
          'cuisine',
          'local_florist',
          const VisualConfig(
              shapeType: 'leaf', colors: ['0xFF66BB6A', '0xFF43A047'])),
      _buildTag(
          'c_beijing',
          '京菜',
          'cuisine',
          'restaurant',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFB71C1C', '0xFF880E4F'])),
      _buildTag(
          'c_shanghai',
          '本帮菜',
          'cuisine',
          'restaurant',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFD32F2F', '0xFFC62828'])),
      _buildTag(
          'c_taiwan',
          '台湾菜',
          'cuisine',
          'restaurant',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFFCC80', '0xFFFFB74D'])),
      _buildTag(
          'c_hongkong',
          '港式',
          'cuisine',
          'local_cafe',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFFAB91', '0xFFFF8A65'])),

      // Asian
      _buildTag(
          'c_japanese',
          '日料',
          'cuisine',
          'bento',
          const VisualConfig(
              shapeType: 'squircle', colors: ['0xFFFFCDD2', '0xFFEF9A9A'])),
      _buildTag(
          'c_korean',
          '韩餐',
          'cuisine',
          'rice_bowl',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFEF5350', '0xFFE53935'])),
      _buildTag(
          'c_thai',
          '泰餐',
          'cuisine',
          'spa',
          const VisualConfig(
              shapeType: 'leaf', colors: ['0xFF009688', '0xFF00796B'])),
      _buildTag(
          'c_vietnamese',
          '越南菜',
          'cuisine',
          'grass',
          const VisualConfig(
              shapeType: 'leaf', colors: ['0xFF8BC34A', '0xFF7CB342'])),
      _buildTag(
          'c_indian',
          '印度菜',
          'cuisine',
          'restaurant',
          const VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFF9800', '0xFFF57C00'],
              particleEffect: 'steam')),

      // Western
      _buildTag(
          'c_western',
          '西餐',
          'cuisine',
          'local_dining',
          const VisualConfig(
              shapeType: 'hexagon', colors: ['0xFFAB47BC', '0xFF8E24AA'])),
      _buildTag(
          'c_french',
          '法餐',
          'cuisine',
          'wine_bar',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFF5C6BC0', '0xFF3F51B5'])),
      _buildTag(
          'c_mexican',
          '墨西哥',
          'cuisine',
          'restaurant',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFF5722', '0xFFE64A19'])),

      // Other
      _buildTag(
          'c_hotpot',
          '火锅',
          'cuisine',
          'soup_kitchen',
          const VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFF7043', '0xFFF4511E'],
              particleEffect: 'steam')),
      _buildTag(
          'c_bbq',
          '烧烤',
          'cuisine',
          'kebab_dining',
          const VisualConfig(
              shapeType: 'chili',
              colors: ['0xFF5D4037', '0xFF4E342E'],
              particleEffect: 'sparkle')),
      _buildTag(
          'c_halal',
          '清真',
          'cuisine',
          'restaurant',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFF009688', '0xFF00796B'])),

      // --- Scenes (场景) ---
      _buildTag(
          's_lunch',
          '午餐',
          'scene',
          'wb_twilight',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFFCC80', '0xFFFFB74D'])),
      _buildTag(
          's_dinner',
          '晚餐',
          'scene',
          'nights_stay',
          const VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF5C6BC0', '0xFF3949AB'],
              particleEffect: 'glow')),
      _buildTag(
          's_snack',
          '夜宵',
          'scene',
          'bedtime',
          const VisualConfig(
              shapeType: 'star',
              colors: ['0xFF3F51B5', '0xFF303F9F'],
              particleEffect: 'sparkle')),
      _buildTag(
          's_brunch',
          '早午餐',
          'scene',
          'local_cafe',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFFCCBC', '0xFFFFAB91'])),
      _buildTag(
          's_afternoon_tea',
          '下午茶',
          'scene',
          'coffee',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFF8BBD0', '0xFFF48FB1'])),
      _buildTag(
          's_party',
          '聚餐',
          'scene',
          'celebration',
          const VisualConfig(
              shapeType: 'hexagon',
              colors: ['0xFFEC407A', '0xFFD81B60'],
              particleEffect: 'sparkle')),
      _buildTag(
          's_solo',
          '一人食',
          'scene',
          'person',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFBDBDBD', '0xFF9E9E9E'])),
      _buildTag(
          's_date',
          '约会',
          'scene',
          'favorite',
          const VisualConfig(
              shapeType: 'heart',
              colors: ['0xFFE91E63', '0xFFC2185B'],
              particleEffect: 'sparkle')),
      _buildTag(
          's_business',
          '商务',
          'scene',
          'work',
          const VisualConfig(
              shapeType: 'squircle', colors: ['0xFF607D8B', '0xFF455A64'])),
      _buildTag(
          's_healthy',
          '健康',
          'scene',
          'fitness_center',
          const VisualConfig(
              shapeType: 'leaf', colors: ['0xFF9CCC65', '0xFF7CB342'])),
      _buildTag(
          's_comfort',
          '治愈',
          'scene',
          'self_improvement',
          const VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFCCBC', '0xFFFFAB91'],
              particleEffect: 'glow')),
      _buildTag(
          's_street',
          '路边摊',
          'scene',
          'storefront',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFF7043', '0xFFF4511E'])),
      _buildTag(
          's_buffet',
          '自助',
          'scene',
          'restaurant_menu',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFAB47BC', '0xFF8E24AA'])),

      // --- Dietary (饮食习惯) ---
      _buildTag(
          'd_vegetarian',
          '素食',
          'dietary',
          'spa',
          const VisualConfig(
              shapeType: 'leaf', colors: ['0xFF81C784', '0xFF66BB6A'])),
      _buildTag(
          'd_light',
          '轻食',
          'dietary',
          'local_florist',
          const VisualConfig(
              shapeType: 'leaf', colors: ['0xFFAED581', '0xFF9CCC65'])),
      _buildTag(
          'd_low_carb',
          '低碳',
          'dietary',
          'fitness_center',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFF4DB6AC', '0xFF26A69A'])),

      // --- Meta/Fun (趣味) ---
      _buildTag(
          'm_random',
          '随便',
          'meta',
          'shuffle',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFF9E9E9E', '0xFF616161'])),
      _buildTag(
          'm_surprise',
          '惊喜',
          'meta',
          'card_giftcard',
          const VisualConfig(
              shapeType: 'star',
              colors: ['0xFFFF4081', '0xFFC51162'],
              particleEffect: 'sparkle')),
      _buildTag(
          'm_cheap',
          '便宜',
          'meta',
          'savings',
          const VisualConfig(
              shapeType: 'circle', colors: ['0xFFFFD54F', '0xFFFFCA28'])),

      // --- Fortune (占卜) ---
      _buildTag(
          'ft_wealth',
          '财运',
          'fortune',
          'savings',
          const VisualConfig(
              shapeType: 'hexagon',
              colors: ['0xFFFFD54F', '0xFFFFB300'],
              particleEffect: 'glow')),
      _buildTag(
          'ft_career',
          '事业运',
          'fortune',
          'speed',
          const VisualConfig(
              shapeType: 'squircle',
              colors: ['0xFF42A5F5', '0xFF1E88E5'],
              particleEffect: 'glow')),
      _buildTag(
          'ft_social',
          '社交运',
          'fortune',
          'person',
          const VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF4DB6AC', '0xFF26A69A'],
              particleEffect: 'bubble')),
      _buildTag(
          'ft_surprise',
          '奇遇运',
          'fortune',
          'celebration',
          const VisualConfig(
              shapeType: 'star',
              colors: ['0xFFFF7043', '0xFFFF5722'],
              particleEffect: 'sparkle')),
      _buildTag(
          'ft_focus',
          '专注运',
          'fortune',
          'bolt',
          const VisualConfig(
              shapeType: 'drop',
              colors: ['0xFF7E57C2', '0xFF5E35B1'],
              particleEffect: 'glow')),
    ];
  }

  UnifiedTagModel _buildTag(String id, String label, String category,
      String icon, VisualConfig visual) {
    return UnifiedTagModel(
      id: id,
      label: label,
      category: category,
      iconAsset: icon,
      visual: visual,
    );
  }
}
