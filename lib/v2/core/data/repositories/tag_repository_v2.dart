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
          VisualConfig(
              shapeType: 'chili',
              colors: ['0xFFFF5252', '0xFFD32F2F'],
              particleEffect: 'steam')),
      _buildTag(
          'f_sweet',
          '甜',
          'flavor',
          'cake',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFF4081', '0xFFF50057'],
              particleEffect: 'sparkle')),
      _buildTag(
          'f_sour',
          '酸',
          'flavor',
          'local_bar',
          VisualConfig(
              shapeType: 'drop',
              colors: ['0xFFCDDC39', '0xFFAFB42B'],
              particleEffect: 'bubble')),
      _buildTag(
          'f_salty',
          '咸',
          'flavor',
          'grain',
          VisualConfig(
              shapeType: 'hexagon',
              colors: ['0xFF9E9E9E', '0xFF616161'],
              particleEffect: 'none')),
      _buildTag(
          'f_fresh',
          '鲜',
          'flavor',
          'water_drop',
          VisualConfig(
              shapeType: 'drop',
              colors: ['0xFF03A9F4', '0xFF0288D1'],
              particleEffect: 'bubble')),
      _buildTag(
          'f_numbing',
          '麻',
          'flavor',
          'bolt',
          VisualConfig(
              shapeType: 'star',
              colors: ['0xFF673AB7', '0xFF512DA8'],
              particleEffect: 'sparkle')),
      _buildTag(
          'f_garlic',
          '蒜香',
          'flavor',
          'circle',
          VisualConfig(
              shapeType: 'squircle',
              colors: ['0xFFEEEEEE', '0xFFBDBDBD'],
              particleEffect: 'none')),
      _buildTag(
          'f_bitter',
          '苦',
          'flavor',
          'coffee',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF3E2723', '0xFF5D4037'],
              particleEffect: 'none')),
      _buildTag(
          'f_creamy',
          '奶香',
          'flavor',
          'icecream',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFF9C4', '0xFFFFF176'],
              particleEffect: 'none')),
      _buildTag(
          'f_crispy',
          '酥脆',
          'flavor',
          'cookie',
          VisualConfig(
              shapeType: 'hexagon',
              colors: ['0xFFFFD54F', '0xFFFFCA28'],
              particleEffect: 'sparkle')),
      _buildTag(
          'f_light',
          '清淡',
          'flavor',
          'spa',
          VisualConfig(
              shapeType: 'leaf',
              colors: ['0xFF81C784', '0xFF66BB6A'],
              particleEffect: 'none')),
      _buildTag(
          'f_rich',
          '浓郁',
          'flavor',
          'soup_kitchen',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF795548', '0xFF5D4037'],
              particleEffect: 'steam')),
      _buildTag(
          'f_smoky',
          '烟熏',
          'flavor',
          'smoking_rooms',
          VisualConfig(
              shapeType: 'cloud',
              colors: ['0xFF607D8B', '0xFF455A64'],
              particleEffect: 'steam')),
      _buildTag(
          'f_herbal',
          '药膳',
          'flavor',
          'medication',
          VisualConfig(
              shapeType: 'leaf',
              colors: ['0xFF558B2F', '0xFF33691E'],
              particleEffect: 'none')),
      _buildTag(
          'f_curry',
          '咖喱',
          'flavor',
          'restaurant',
          VisualConfig(
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
          VisualConfig(
              shapeType: 'squircle',
              colors: ['0xFFD32F2F', '0xFFB71C1C'],
              particleEffect: 'none')),
      _buildTag(
          'i_pork',
          '猪肉',
          'ingredient',
          'savings',
          VisualConfig(
              shapeType: 'squircle',
              colors: ['0xFFF48FB1', '0xFFF06292'],
              particleEffect: 'none')),
      _buildTag(
          'i_chicken',
          '鸡肉',
          'ingredient',
          'egg',
          VisualConfig(
              shapeType: 'squircle',
              colors: ['0xFFFFB74D', '0xFFFFA726'],
              particleEffect: 'none')),
      _buildTag(
          'i_lamb',
          '羊肉',
          'ingredient',
          'restaurant',
          VisualConfig(
              shapeType: 'squircle',
              colors: ['0xFFE57373', '0xFFEF5350'],
              particleEffect: 'none')),
      _buildTag(
          'i_duck',
          '鸭肉',
          'ingredient',
          'restaurant',
          VisualConfig(
              shapeType: 'squircle',
              colors: ['0xFF8D6E63', '0xFF795548'],
              particleEffect: 'none')),
      _buildTag(
          'i_goose',
          '鹅肉',
          'ingredient',
          'restaurant',
          VisualConfig(
              shapeType: 'squircle',
              colors: ['0xFFA1887F', '0xFF8D6E63'],
              particleEffect: 'none')),
      _buildTag(
          'i_offal',
          '内脏',
          'ingredient',
          'favorite',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF880E4F', '0xFFAD1457'],
              particleEffect: 'none')),

      // Seafood
      _buildTag(
          'i_seafood',
          '海鲜',
          'ingredient',
          'set_meal',
          VisualConfig(
              shapeType: 'drop',
              colors: ['0xFF29B6F6', '0xFF0288D1'],
              particleEffect: 'bubble')),
      _buildTag(
          'i_fish',
          '鱼',
          'ingredient',
          'set_meal',
          VisualConfig(
              shapeType: 'drop',
              colors: ['0xFF4FC3F7', '0xFF29B6F6'],
              particleEffect: 'bubble')),
      _buildTag(
          'i_shrimp',
          '虾',
          'ingredient',
          'set_meal',
          VisualConfig(
              shapeType: 'chili',
              colors: ['0xFFFFAB91', '0xFFFF8A65'],
              particleEffect: 'none')),
      _buildTag(
          'i_crab',
          '蟹',
          'ingredient',
          'bug_report',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFF7043', '0xFFF4511E'],
              particleEffect: 'none')),
      _buildTag(
          'i_shellfish',
          '贝类',
          'ingredient',
          'donut_small',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFE0E0E0', '0xFFBDBDBD'],
              particleEffect: 'none')),

      // Veg
      _buildTag(
          'i_vegetable',
          '蔬菜',
          'ingredient',
          'grass',
          VisualConfig(
              shapeType: 'leaf',
              colors: ['0xFF66BB6A', '0xFF43A047'],
              particleEffect: 'none')),
      _buildTag(
          'i_mushroom',
          '菌菇',
          'ingredient',
          'umbrella',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF8D6E63', '0xFF6D4C41'],
              particleEffect: 'none')),
      _buildTag(
          'i_tofu',
          '豆腐',
          'ingredient',
          'crop_square',
          VisualConfig(
              shapeType: 'squircle',
              colors: ['0xFFF5F5F5', '0xFFE0E0E0'],
              particleEffect: 'none')),
      _buildTag(
          'i_potato',
          '土豆',
          'ingredient',
          'circle',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFE0B2', '0xFFFFCC80'],
              particleEffect: 'none')),
      _buildTag(
          'i_tomato',
          '番茄',
          'ingredient',
          'circle',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFF5252', '0xFFFF1744'],
              particleEffect: 'none')),
      _buildTag(
          'i_eggplant',
          '茄子',
          'ingredient',
          'circle',
          VisualConfig(
              shapeType: 'chili',
              colors: ['0xFF7E57C2', '0xFF673AB7'],
              particleEffect: 'none')),
      _buildTag(
          'i_corn',
          '玉米',
          'ingredient',
          'circle',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFF176', '0xFFFFEE58'],
              particleEffect: 'none')),

      // Other
      _buildTag(
          'i_egg',
          '鸡蛋',
          'ingredient',
          'egg_alt',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFEE58', '0xFFFDD835'],
              particleEffect: 'none')),
      _buildTag(
          'i_cheese',
          '芝士',
          'ingredient',
          'circle',
          VisualConfig(
              shapeType: 'squircle',
              colors: ['0xFFFFD54F', '0xFFFFCA28'],
              particleEffect: 'none')),

      // --- Staples (主食) ---
      _buildTag(
          'st_rice',
          '米饭',
          'staple',
          'rice_bowl',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFFFFF', '0xFFF5F5F5'],
              particleEffect: 'none')),
      _buildTag(
          'st_noodle',
          '面条',
          'staple',
          'ramen_dining',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFE0B2', '0xFFFFCC80'],
              particleEffect: 'steam')),
      _buildTag(
          'st_bread',
          '面包',
          'staple',
          'bakery_dining',
          VisualConfig(
              shapeType: 'squircle',
              colors: ['0xFFD7CCC8', '0xFFBCAAA4'],
              particleEffect: 'none')),
      _buildTag(
          'st_dumpling',
          '饺子',
          'staple',
          'circle',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFF5F5F5', '0xFFEEEEEE'],
              particleEffect: 'none')),
      _buildTag(
          'st_pasta',
          '意面',
          'staple',
          'dinner_dining',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFE0B2', '0xFFFFCC80'],
              particleEffect: 'none')),
      _buildTag(
          'st_pizza',
          '披萨',
          'staple',
          'local_pizza',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFAB91', '0xFFFF8A65'],
              particleEffect: 'none')),
      _buildTag(
          'st_burger',
          '汉堡',
          'staple',
          'lunch_dining',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFCC80', '0xFFFFB74D'],
              particleEffect: 'none')),
      _buildTag(
          'st_porridge',
          '粥',
          'staple',
          'soup_kitchen',
          VisualConfig(
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
          VisualConfig(
              shapeType: 'fire',
              colors: ['0xFFFF5722', '0xFFE64A19'],
              particleEffect: 'steam')),
      _buildTag(
          'c_cantonese',
          '粤菜',
          'cuisine',
          'restaurant',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF4CAF50', '0xFF388E3C'],
              particleEffect: 'none')),
      _buildTag(
          'c_hunan',
          '湘菜',
          'cuisine',
          'local_fire_department',
          VisualConfig(
              shapeType: 'chili',
              colors: ['0xFFD32F2F', '0xFFB71C1C'],
              particleEffect: 'steam')),
      _buildTag(
          'c_shandong',
          '鲁菜',
          'cuisine',
          'restaurant',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF795548', '0xFF5D4037'],
              particleEffect: 'none')),
      _buildTag(
          'c_jiangsu',
          '苏菜',
          'cuisine',
          'water',
          VisualConfig(
              shapeType: 'drop',
              colors: ['0xFF4FC3F7', '0xFF29B6F6'],
              particleEffect: 'none')),
      _buildTag(
          'c_zhejiang',
          '浙菜',
          'cuisine',
          'water',
          VisualConfig(
              shapeType: 'drop',
              colors: ['0xFF81C784', '0xFF66BB6A'],
              particleEffect: 'none')),
      _buildTag(
          'c_fujian',
          '闽菜',
          'cuisine',
          'restaurant',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFF176', '0xFFFFEE58'],
              particleEffect: 'none')),
      _buildTag(
          'c_anhui',
          '徽菜',
          'cuisine',
          'landscape',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF5D4037', '0xFF4E342E'],
              particleEffect: 'none')),
      _buildTag(
          'c_northeast',
          '东北菜',
          'cuisine',
          'kitchen',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF8D6E63', '0xFF795548'],
              particleEffect: 'steam')),
      _buildTag(
          'c_northwest',
          '西北菜',
          'cuisine',
          'restaurant',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFB74D', '0xFFFFA726'],
              particleEffect: 'none')),
      _buildTag(
          'c_yunnan',
          '云南菜',
          'cuisine',
          'local_florist',
          VisualConfig(
              shapeType: 'leaf',
              colors: ['0xFF66BB6A', '0xFF43A047'],
              particleEffect: 'none')),
      _buildTag(
          'c_beijing',
          '京菜',
          'cuisine',
          'restaurant',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFB71C1C', '0xFF880E4F'],
              particleEffect: 'none')),
      _buildTag(
          'c_shanghai',
          '本帮菜',
          'cuisine',
          'restaurant',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFD32F2F', '0xFFC62828'],
              particleEffect: 'none')),
      _buildTag(
          'c_taiwan',
          '台湾菜',
          'cuisine',
          'restaurant',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFCC80', '0xFFFFB74D'],
              particleEffect: 'none')),
      _buildTag(
          'c_hongkong',
          '港式',
          'cuisine',
          'local_cafe',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFAB91', '0xFFFF8A65'],
              particleEffect: 'none')),

      // Asian
      _buildTag(
          'c_japanese',
          '日料',
          'cuisine',
          'bento',
          VisualConfig(
              shapeType: 'squircle',
              colors: ['0xFFFFCDD2', '0xFFEF9A9A'],
              particleEffect: 'none')),
      _buildTag(
          'c_korean',
          '韩餐',
          'cuisine',
          'rice_bowl',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFEF5350', '0xFFE53935'],
              particleEffect: 'none')),
      _buildTag(
          'c_thai',
          '泰餐',
          'cuisine',
          'spa',
          VisualConfig(
              shapeType: 'leaf',
              colors: ['0xFF009688', '0xFF00796B'],
              particleEffect: 'none')),
      _buildTag(
          'c_vietnamese',
          '越南菜',
          'cuisine',
          'grass',
          VisualConfig(
              shapeType: 'leaf',
              colors: ['0xFF8BC34A', '0xFF7CB342'],
              particleEffect: 'none')),
      _buildTag(
          'c_indian',
          '印度菜',
          'cuisine',
          'restaurant',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFF9800', '0xFFF57C00'],
              particleEffect: 'steam')),
      _buildTag(
          'c_southeast_asia',
          '东南亚',
          'cuisine',
          'wb_sunny',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFEB3B', '0xFFFDD835'],
              particleEffect: 'none')),

      // Western
      _buildTag(
          'c_western',
          '西餐',
          'cuisine',
          'local_dining',
          VisualConfig(
              shapeType: 'hexagon',
              colors: ['0xFFAB47BC', '0xFF8E24AA'],
              particleEffect: 'none')),
      _buildTag(
          'c_french',
          '法餐',
          'cuisine',
          'wine_bar',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF5C6BC0', '0xFF3F51B5'],
              particleEffect: 'none')),
      _buildTag(
          'c_italian',
          '意餐',
          'cuisine',
          'local_pizza',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF4CAF50', '0xFF388E3C'],
              particleEffect: 'none')),
      _buildTag(
          'c_american',
          '美式',
          'cuisine',
          'fastfood',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFF44336', '0xFFD32F2F'],
              particleEffect: 'none')),
      _buildTag(
          'c_mexican',
          '墨西哥',
          'cuisine',
          'restaurant',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFF5722', '0xFFE64A19'],
              particleEffect: 'none')),

      // Other
      _buildTag(
          'c_hotpot',
          '火锅',
          'cuisine',
          'soup_kitchen',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFF7043', '0xFFF4511E'],
              particleEffect: 'steam')),
      _buildTag(
          'c_bbq',
          '烧烤',
          'cuisine',
          'kebab_dining',
          VisualConfig(
              shapeType: 'chili',
              colors: ['0xFF5D4037', '0xFF4E342E'],
              particleEffect: 'sparkle')),
      _buildTag(
          'c_halal',
          '清真',
          'cuisine',
          'restaurant',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF009688', '0xFF00796B'],
              particleEffect: 'none')),

      // --- Scenes (场景) ---
      _buildTag(
          's_breakfast',
          '早餐',
          'scene',
          'wb_sunny',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFE082', '0xFFFFD54F'],
              particleEffect: 'glow')),
      _buildTag(
          's_lunch',
          '午餐',
          'scene',
          'wb_twilight',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFCC80', '0xFFFFB74D'],
              particleEffect: 'none')),
      _buildTag(
          's_dinner',
          '晚餐',
          'scene',
          'nights_stay',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF5C6BC0', '0xFF3949AB'],
              particleEffect: 'glow')),
      _buildTag(
          's_snack',
          '夜宵',
          'scene',
          'bedtime',
          VisualConfig(
              shapeType: 'star',
              colors: ['0xFF3F51B5', '0xFF303F9F'],
              particleEffect: 'sparkle')),
      _buildTag(
          's_brunch',
          '早午餐',
          'scene',
          'local_cafe',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFCCBC', '0xFFFFAB91'],
              particleEffect: 'none')),
      _buildTag(
          's_afternoon_tea',
          '下午茶',
          'scene',
          'coffee',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFF8BBD0', '0xFFF48FB1'],
              particleEffect: 'none')),
      _buildTag(
          's_party',
          '聚餐',
          'scene',
          'celebration',
          VisualConfig(
              shapeType: 'hexagon',
              colors: ['0xFFEC407A', '0xFFD81B60'],
              particleEffect: 'sparkle')),
      _buildTag(
          's_solo',
          '一人食',
          'scene',
          'person',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFBDBDBD', '0xFF9E9E9E'],
              particleEffect: 'none')),
      _buildTag(
          's_date',
          '约会',
          'scene',
          'favorite',
          VisualConfig(
              shapeType: 'heart',
              colors: ['0xFFE91E63', '0xFFC2185B'],
              particleEffect: 'sparkle')),
      _buildTag(
          's_business',
          '商务',
          'scene',
          'work',
          VisualConfig(
              shapeType: 'squircle',
              colors: ['0xFF607D8B', '0xFF455A64'],
              particleEffect: 'none')),
      _buildTag(
          's_healthy',
          '健康',
          'scene',
          'fitness_center',
          VisualConfig(
              shapeType: 'leaf',
              colors: ['0xFF9CCC65', '0xFF7CB342'],
              particleEffect: 'none')),
      _buildTag(
          's_comfort',
          '治愈',
          'scene',
          'self_improvement',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFCCBC', '0xFFFFAB91'],
              particleEffect: 'glow')),
      _buildTag(
          's_street',
          '路边摊',
          'scene',
          'storefront',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFF7043', '0xFFF4511E'],
              particleEffect: 'none')),
      _buildTag(
          's_buffet',
          '自助',
          'scene',
          'restaurant_menu',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFAB47BC', '0xFF8E24AA'],
              particleEffect: 'none')),

      // --- Dietary (饮食习惯) ---
      _buildTag(
          'd_vegetarian',
          '素食',
          'dietary',
          'spa',
          VisualConfig(
              shapeType: 'leaf',
              colors: ['0xFF81C784', '0xFF66BB6A'],
              particleEffect: 'none')),
      _buildTag(
          'd_light',
          '轻食',
          'dietary',
          'local_florist',
          VisualConfig(
              shapeType: 'leaf',
              colors: ['0xFFAED581', '0xFF9CCC65'],
              particleEffect: 'none')),
      _buildTag(
          'd_low_carb',
          '低碳',
          'dietary',
          'fitness_center',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF4DB6AC', '0xFF26A69A'],
              particleEffect: 'none')),
      _buildTag(
          'd_high_protein',
          '高蛋白',
          'dietary',
          'fitness_center',
          VisualConfig(
              shapeType: 'squircle',
              colors: ['0xFFE57373', '0xFFEF5350'],
              particleEffect: 'none')),

      // --- Meta/Fun (趣味) ---
      _buildTag(
          'm_random',
          '随便',
          'meta',
          'shuffle',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF9E9E9E', '0xFF616161'],
              particleEffect: 'none')),
      _buildTag(
          'm_surprise',
          '惊喜',
          'meta',
          'card_giftcard',
          VisualConfig(
              shapeType: 'star',
              colors: ['0xFFFF4081', '0xFFC51162'],
              particleEffect: 'sparkle')),
      _buildTag(
          'm_cheap',
          '便宜',
          'meta',
          'savings',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFFFFD54F', '0xFFFFCA28'],
              particleEffect: 'none')),

      // --- Fortune (占卜) ---
      _buildTag(
          'ft_love',
          '恋爱运',
          'fortune',
          'favorite',
          VisualConfig(
              shapeType: 'star',
              colors: ['0xFFFF80AB', '0xFFFF4081'],
              particleEffect: 'sparkle')),
      _buildTag(
          'ft_wealth',
          '财运',
          'fortune',
          'savings',
          VisualConfig(
              shapeType: 'hexagon',
              colors: ['0xFFFFD54F', '0xFFFFB300'],
              particleEffect: 'glow')),
      _buildTag(
          'ft_career',
          '事业运',
          'fortune',
          'speed',
          VisualConfig(
              shapeType: 'squircle',
              colors: ['0xFF42A5F5', '0xFF1E88E5'],
              particleEffect: 'glow')),
      _buildTag(
          'ft_health',
          '健康运',
          'fortune',
          'self_improvement',
          VisualConfig(
              shapeType: 'leaf',
              colors: ['0xFF66BB6A', '0xFF43A047'],
              particleEffect: 'none')),
      _buildTag(
          'ft_social',
          '社交运',
          'fortune',
          'person',
          VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF4DB6AC', '0xFF26A69A'],
              particleEffect: 'bubble')),
      _buildTag(
          'ft_surprise',
          '奇遇运',
          'fortune',
          'celebration',
          VisualConfig(
              shapeType: 'star',
              colors: ['0xFFFF7043', '0xFFFF5722'],
              particleEffect: 'sparkle')),
      _buildTag(
          'ft_focus',
          '专注运',
          'fortune',
          'bolt',
          VisualConfig(
              shapeType: 'drop',
              colors: ['0xFF7E57C2', '0xFF5E35B1'],
              particleEffect: 'glow')),
      _buildTag(
          'ft_calm',
          '平静运',
          'fortune',
          'spa',
          VisualConfig(
              shapeType: 'drop',
              colors: ['0xFF81D4FA', '0xFF4FC3F7'],
              particleEffect: 'bubble')),
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
