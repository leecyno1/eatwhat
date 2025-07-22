import 'package:flutter/material.dart';
import 'dart:math';
import 'physical_entity.dart';
import '../data/taste_preference_database.dart';

/// 物理实体工厂 - 创建各种口味偏好的形象化实体
class PhysicalEntityFactory {
  static final Random _random = Random();

  /// 创建默认的物理实体集合 - 使用完整的口味偏好数据库
  static List<PhysicalEntity> createDefaultEntities() {
    return TastePreferenceDatabase.getAllTasteEntities();
  }

  /// 获取指定数量的随机实体（用于渐进出现效果）
  static List<PhysicalEntity> getRandomEntities(int count) {
    final allEntities = TastePreferenceDatabase.getAllTasteEntities();
    final shuffled = List<PhysicalEntity>.from(allEntities)..shuffle(_random);
    return shuffled.take(count).toList();
  }

  /// 按类型获取实体
  static List<PhysicalEntity> getEntitiesByType(PhysicalEntityType type) {
    final allEntities = TastePreferenceDatabase.getAllTasteEntities();
    return allEntities.where((entity) => entity.type == type).toList();
  }

  /// 获取平衡的实体集合（每个类型都有代表）
  static List<PhysicalEntity> getBalancedEntities(int totalCount) {
    final allEntities = TastePreferenceDatabase.getAllTasteEntities();
    final entitiesByType = <PhysicalEntityType, List<PhysicalEntity>>{};
    
    // 按类型分组
    for (final entity in allEntities) {
      entitiesByType.putIfAbsent(entity.type, () => []).add(entity);
    }
    
    final result = <PhysicalEntity>[];
    final types = entitiesByType.keys.toList()..shuffle(_random);
    
    // 轮流从每个类型中选择实体
    for (int i = 0; i < totalCount; i++) {
      final typeIndex = i % types.length;
      final type = types[typeIndex];
      final entitiesOfType = entitiesByType[type]!;
      
      if (entitiesOfType.isNotEmpty) {
        final entity = entitiesOfType.removeAt(_random.nextInt(entitiesOfType.length));
        result.add(entity);
      }
    }
    
    return result;
  }

  /// 创建传统的口味类实体（保留用于兼容性）
  static List<PhysicalEntity> _createTasteEntities() {
    const double unifiedRadius = 80.0; // 统一固定框体尺寸
    
    return [
      // 辣
      PhysicalEntity(
        id: 'taste_spicy',
        name: '辣',
        description: '爱吃辣的，川菜湘菜都不怕',
        type: PhysicalEntityType.taste,
        emoji: '辣',
        primaryColor: const Color(0xFFFF4444),
        secondaryColor: const Color(0xFFFF8888),
        mass: 1.2,
        radius: unifiedRadius,
        bounciness: 0.9,
        friction: 0.01,
      ),
      
      // 甜
      PhysicalEntity(
        id: 'taste_sweet',
        name: '甜',
        description: '甜蜜滋味，温暖心扉',
        type: PhysicalEntityType.taste,
        emoji: '甜',
        primaryColor: const Color(0xFFFFB347),
        secondaryColor: const Color(0xFFFFF4E6),
        mass: 0.9,
        radius: unifiedRadius,
        bounciness: 0.7,
        friction: 0.03,
      ),
      
      // 酸
      PhysicalEntity(
        id: 'taste_sour',
        name: '酸',
        description: '酸甜可口，开胃解腻',
        type: PhysicalEntityType.taste,
        emoji: '酸',
        primaryColor: const Color(0xFFFFD700),
        secondaryColor: const Color(0xFFFFF8DC),
        mass: 1.1,
        radius: unifiedRadius,
        bounciness: 0.8,
        friction: 0.02,
      ),
      
      // 咸
      PhysicalEntity(
        id: 'taste_salty',
        name: '咸',
        description: '重口味，咸香下饭',
        type: PhysicalEntityType.taste,
        emoji: '咸',
        primaryColor: const Color(0xFF9E9E9E),
        secondaryColor: const Color(0xFFE0E0E0),
        mass: 1.3,
        radius: unifiedRadius,
        bounciness: 0.6,
        friction: 0.04,
      ),
      
      // 鲜
      PhysicalEntity(
        id: 'taste_umami',
        name: '鲜',
        description: '鲜美可口，回味无穷',
        type: PhysicalEntityType.taste,
        emoji: '鲜',
        primaryColor: const Color(0xFF4A90E2),
        secondaryColor: const Color(0xFFB3D9FF),
        mass: 1.0,
        radius: unifiedRadius,
        bounciness: 0.85,
        friction: 0.015,
      ),
      
      // 香
      PhysicalEntity(
        id: 'taste_aromatic',
        name: '香',
        description: '香气扑鼻，食欲大增',
        type: PhysicalEntityType.taste,
        emoji: '香',
        primaryColor: const Color(0xFF228B22),
        secondaryColor: const Color(0xFF90EE90),
        mass: 0.8,
        radius: unifiedRadius,
        bounciness: 0.9,
        friction: 0.01,
      ),
      
      // 苦
      PhysicalEntity(
        id: 'taste_bitter',
        name: '苦',
        description: '苦尽甘来，清热降火',
        type: PhysicalEntityType.taste,
        emoji: '苦',
        primaryColor: const Color(0xFF8B4513),
        secondaryColor: const Color(0xFFDEB887),
        mass: 1.1,
        radius: unifiedRadius,
        bounciness: 0.7,
        friction: 0.025,
      ),
      
      // 麻
      PhysicalEntity(
        id: 'taste_numbing',
        name: '麻',
        description: '麻辣带劲，川菜之魂',
        type: PhysicalEntityType.taste,
        emoji: '麻',
        primaryColor: const Color(0xFF800080),
        secondaryColor: const Color(0xFFDDA0DD),
        mass: 1.0,
        radius: unifiedRadius,
        bounciness: 0.95,
        friction: 0.008,
      ),
      
      // 清淡
      PhysicalEntity(
        id: 'taste_light',
        name: '清淡',
        description: '清爽淡雅，健康养生',
        type: PhysicalEntityType.taste,
        emoji: '清淡',
        primaryColor: const Color(0xFF98FB98),
        secondaryColor: const Color(0xFFF0FFF0),
        mass: 0.7,
        radius: unifiedRadius,
        bounciness: 0.8,
        friction: 0.02,
      ),
      
      // 浓郁
      PhysicalEntity(
        id: 'taste_rich',
        name: '浓郁',
        description: '口感丰富，层次分明',
        type: PhysicalEntityType.taste,
        emoji: '浓郁',
        primaryColor: const Color(0xFF8B0000),
        secondaryColor: const Color(0xFFDC143C),
        mass: 1.4,
        radius: unifiedRadius,
        bounciness: 0.6,
        friction: 0.03,
      ),
      
      // 爽口
      PhysicalEntity(
        id: 'taste_crisp',
        name: '爽口',
        description: '脆嫩爽口，清脆怡人',
        type: PhysicalEntityType.taste,
        emoji: '爽口',
        primaryColor: const Color(0xFF00CED1),
        secondaryColor: const Color(0xFFAFEEEE),
        mass: 0.9,
        radius: unifiedRadius,
        bounciness: 0.85,
        friction: 0.015,
      ),
      
      // 滑嫩
      PhysicalEntity(
        id: 'taste_tender',
        name: '滑嫩',
        description: '滑嫩可口，入口即化',
        type: PhysicalEntityType.taste,
        emoji: '滑嫩',
        primaryColor: const Color(0xFFFFC0CB),
        secondaryColor: const Color(0xFFFFE4E1),
        mass: 0.8,
        radius: unifiedRadius,
        bounciness: 0.9,
        friction: 0.01,
      ),
    ];
  }

  /// 创建菜系类实体
  static List<PhysicalEntity> _createCuisineEntities() {
    return [
      // 川菜 - 熊猫
      PhysicalEntity(
        id: 'cuisine_sichuan',
        name: '川菜',
        description: '麻辣鲜香，四川风味',
        type: PhysicalEntityType.cuisine,
        emoji: '川菜',
        primaryColor: const Color(0xFFFF6B6B),
        secondaryColor: const Color(0xFFFFB3B3),
        mass: 1.4,
        radius: 38.0,
        bounciness: 0.8,
        friction: 0.02,
      ),
      
      // 粤菜 - 茶壶
      PhysicalEntity(
        id: 'cuisine_cantonese',
        name: '粤菜',
        description: '清淡鲜美，广式风情',
        type: PhysicalEntityType.cuisine,
        emoji: '粤菜',
        primaryColor: const Color(0xFF87CEEB),
        secondaryColor: const Color(0xFFE0F6FF),
        mass: 1.1,
        radius: 36.0,
        bounciness: 0.75,
        friction: 0.025,
      ),
      
      // 鲁菜 - 麦穗
      PhysicalEntity(
        id: 'cuisine_shandong',
        name: '鲁菜',
        description: '醇厚实在，北方风味',
        type: PhysicalEntityType.cuisine,
        emoji: '鲁菜',
        primaryColor: const Color(0xFFDEB887),
        secondaryColor: const Color(0xFFF5DEB3),
        mass: 1.5,
        radius: 37.0,
        bounciness: 0.7,
        friction: 0.03,
      ),
      
      // 湘菜 - 辣椒串
      PhysicalEntity(
        id: 'cuisine_hunan',
        name: '湘菜',
        description: '香辣过瘾，湖南特色',
        type: PhysicalEntityType.cuisine,
        emoji: '湘菜',
        primaryColor: const Color(0xFFFF4500),
        secondaryColor: const Color(0xFFFF7F50),
        mass: 1.3,
        radius: 35.0,
        bounciness: 0.9,
        friction: 0.01,
      ),
      
      // 西餐 - 刀叉
      PhysicalEntity(
        id: 'cuisine_western',
        name: '西餐',
        description: '精致优雅，异国风情',
        type: PhysicalEntityType.cuisine,
        emoji: '西餐',
        primaryColor: const Color(0xFF6A5ACD),
        secondaryColor: const Color(0xFFDDA0DD),
        mass: 1.0,
        radius: 34.0,
        bounciness: 0.8,
        friction: 0.02,
      ),
      
      // 日料 - 寿司
      PhysicalEntity(
        id: 'cuisine_japanese',
        name: '日料',
        description: '清雅精致，和风料理',
        type: PhysicalEntityType.cuisine,
        emoji: '日料',
        primaryColor: const Color(0xFFFF69B4),
        secondaryColor: const Color(0xFFFFB6C1),
        mass: 0.9,
        radius: 33.0,
        bounciness: 0.85,
        friction: 0.015,
      ),
    ];
  }

  /// 创建食材类实体
  static List<PhysicalEntity> _createIngredientEntities() {
    return [
      // 肉类 - 牛肉
      PhysicalEntity(
        id: 'ingredient_meat',
        name: '肉类',
        description: '蛋白质丰富，营养满分',
        type: PhysicalEntityType.ingredient,
        emoji: '🥩',
        primaryColor: const Color(0xFF8B4513),
        secondaryColor: const Color(0xFFD2B48C),
        mass: 1.6,
        radius: 40.0,
        bounciness: 0.6,
        friction: 0.04,
      ),
      
      // 海鲜 - 虾
      PhysicalEntity(
        id: 'ingredient_seafood',
        name: '海鲜',
        description: '鲜美Q弹，海洋风味',
        type: PhysicalEntityType.ingredient,
        emoji: '🦐',
        primaryColor: const Color(0xFFFF7F50),
        secondaryColor: const Color(0xFFFFA07A),
        mass: 1.2,
        radius: 36.0,
        bounciness: 0.9,
        friction: 0.01,
      ),
      
      // 蔬菜 - 西兰花
      PhysicalEntity(
        id: 'ingredient_vegetable',
        name: '蔬菜',
        description: '清爽健康，维生素丰富',
        type: PhysicalEntityType.ingredient,
        emoji: '🥦',
        primaryColor: const Color(0xFF32CD32),
        secondaryColor: const Color(0xFF98FB98),
        mass: 0.7,
        radius: 32.0,
        bounciness: 0.85,
        friction: 0.02,
      ),
      
      // 豆腐 - 豆腐块
      PhysicalEntity(
        id: 'ingredient_tofu',
        name: '豆腐',
        description: '嫩滑可口，蛋白佳品',
        type: PhysicalEntityType.ingredient,
        emoji: '🧈',
        primaryColor: const Color(0xFFFFFACD),
        secondaryColor: const Color(0xFFFFFFF0),
        mass: 0.8,
        radius: 30.0,
        bounciness: 0.7,
        friction: 0.03,
      ),
    ];
  }

  /// 创建场景类实体
  static List<PhysicalEntity> _createScenarioEntities() {
    return [
      // 聚餐 - 人群
      PhysicalEntity(
        id: 'scenario_gathering',
        name: '聚餐',
        description: '朋友聚会，热闹分享',
        type: PhysicalEntityType.scenario,
        emoji: '👥',
        primaryColor: const Color(0xFFFF6347),
        secondaryColor: const Color(0xFFFFE4E1),
        mass: 1.4,
        radius: 38.0,
        bounciness: 0.8,
        friction: 0.02,
      ),
      
      // 约会 - 爱心
      PhysicalEntity(
        id: 'scenario_date',
        name: '约会',
        description: '浪漫二人世界',
        type: PhysicalEntityType.scenario,
        emoji: '💕',
        primaryColor: const Color(0xFFFF1493),
        secondaryColor: const Color(0xFFFFB6C1),
        mass: 1.0,
        radius: 34.0,
        bounciness: 0.9,
        friction: 0.01,
      ),
      
      // 加班 - 咖啡
      PhysicalEntity(
        id: 'scenario_overtime',
        name: '加班',
        description: '深夜能量补充',
        type: PhysicalEntityType.scenario,
        emoji: '☕',
        primaryColor: const Color(0xFF8B4513),
        secondaryColor: const Color(0xFFDEB887),
        mass: 1.1,
        radius: 32.0,
        bounciness: 0.7,
        friction: 0.025,
      ),
      
      // 健身 - 肌肉
      PhysicalEntity(
        id: 'scenario_fitness',
        name: '健身',
        description: '营养补充，增肌减脂',
        type: PhysicalEntityType.scenario,
        emoji: '💪',
        primaryColor: const Color(0xFF4169E1),
        secondaryColor: const Color(0xFFB0C4DE),
        mass: 1.3,
        radius: 36.0,
        bounciness: 0.85,
        friction: 0.015,
      ),
    ];
  }

  /// 创建营养类实体
  static List<PhysicalEntity> _createNutritionEntities() {
    return [
      // 高蛋白 - 鸡蛋
      PhysicalEntity(
        id: 'nutrition_protein',
        name: '高蛋白',
        description: '增肌必备，营养之王',
        type: PhysicalEntityType.nutrition,
        emoji: '🥚',
        primaryColor: const Color(0xFFFFF8DC),
        secondaryColor: const Color(0xFFFFFFE0),
        mass: 1.2,
        radius: 33.0,
        bounciness: 0.8,
        friction: 0.02,
      ),
      
      // 低卡路里 - 苹果
      PhysicalEntity(
        id: 'nutrition_low_cal',
        name: '低卡',
        description: '减脂首选，健康轻食',
        type: PhysicalEntityType.nutrition,
        emoji: '🍎',
        primaryColor: const Color(0xFFFF6347),
        secondaryColor: const Color(0xFFFFB3B3),
        mass: 0.8,
        radius: 31.0,
        bounciness: 0.9,
        friction: 0.01,
      ),
      
      // 维生素 - 胡萝卜
      PhysicalEntity(
        id: 'nutrition_vitamin',
        name: '维生素',
        description: '营养丰富，健康之选',
        type: PhysicalEntityType.nutrition,
        emoji: '🥕',
        primaryColor: const Color(0xFFFF8C00),
        secondaryColor: const Color(0xFFFFE4B5),
        mass: 0.9,
        radius: 32.0,
        bounciness: 0.85,
        friction: 0.015,
      ),
    ];
  }

  /// 为实体分配随机位置 (避免重叠)
  static void distributeEntities(List<PhysicalEntity> entities, Size containerSize) {
    const double minDistance = 120.0; // 增加最小间距，防止重叠
    const int maxAttempts = 100; // 增加尝试次数
    
    final placedPositions = <Offset>[];
    
    for (int i = 0; i < entities.length; i++) {
      bool positioned = false;
      int attempts = 0;
      
      while (!positioned && attempts < maxAttempts) {
        final x = entities[i].radius + _random.nextDouble() * 
                 (containerSize.width - 2 * entities[i].radius);
        final y = entities[i].radius + _random.nextDouble() * 
                 (containerSize.height - 2 * entities[i].radius);
        final newPosition = Offset(x, y);
        
        // 检查是否与已放置的实体重叠
        bool overlapping = false;
        for (final placedPos in placedPositions) {
          if ((newPosition - placedPos).distance < minDistance) {
            overlapping = true;
            break;
          }
        }
        
        if (!overlapping) {
          entities[i] = entities[i].copyWith(position: newPosition);
          placedPositions.add(newPosition);
          positioned = true;
        }
        
        attempts++;
      }
      
      // 如果尝试次数超限，随机放置
      if (!positioned) {
        final x = entities[i].radius + _random.nextDouble() * 
                 (containerSize.width - 2 * entities[i].radius);
        final y = entities[i].radius + _random.nextDouble() * 
                 (containerSize.height - 2 * entities[i].radius);
        entities[i] = entities[i].copyWith(position: Offset(x, y));
      }
    }
  }

  /// 为实体添加随机初始速度
  static void addRandomVelocity(List<PhysicalEntity> entities) {
    for (int i = 0; i < entities.length; i++) {
      final velocity = Offset(
        (_random.nextDouble() - 0.5) * 0.1, // 极小的初始速度，几乎静止
        (_random.nextDouble() - 0.5) * 0.1,
      );
      final angularVelocity = (_random.nextDouble() - 0.5) * 0.005; // 极小的角速度
      
      entities[i] = entities[i].copyWith(
        velocity: velocity,
        angularVelocity: angularVelocity,
      );
    }
  }

  /// 创建特定类型的实体
  static PhysicalEntity createEntity({
    required String id,
    required String name,
    required String description,
    required PhysicalEntityType type,
    required String emoji,
    String? icon,
    required Color primaryColor,
    required Color secondaryColor,
    double mass = 1.0,
    double radius = 50.0,
    double bounciness = 0.8,
    double friction = 0.02,
  }) {
    return PhysicalEntity(
      id: id,
      name: name,
      description: description,
      type: type,
      emoji: emoji,
      icon: icon,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      mass: mass,
      radius: radius,
      bounciness: bounciness,
      friction: friction,
    );
  }
}