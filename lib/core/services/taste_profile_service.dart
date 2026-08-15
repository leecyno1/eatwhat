import 'package:flutter/foundation.dart';

/// 味觉画像服务
/// 负责将46维味觉向量降维到主要维度，用于雷达图可视化展示
class TasteProfileService {
  static final TasteProfileService _instance = TasteProfileService._internal();
  factory TasteProfileService() => _instance;
  TasteProfileService._internal();

  // 主要维度分组（用于雷达图展示）
  static const List<String> primaryDimensions = [
    '辣度', '甜度', '咸度', '酸度', '苦度', '鲜味',
    '油腻度', '清淡度', '香度', '口感',
  ];

  // 维度分组映射（46维 -> 10维）
  static const Map<String, List<String>> dimensionMapping = {
    '辣度': ['辣', '麻辣', '朝天椒辣度', '二荆条辣度'],
    '甜度': ['甜', '糖度', '果糖甜度'],
    '咸度': ['咸', '盐度', '酱油咸度'],
    '酸度': ['酸', '醋酸度', '柠檬酸度'],
    '苦度': ['苦', '咖啡因苦度'],
    '鲜味': ['鲜', '味精鲜度', '海鲜鲜度'],
    '油腻度': ['油腻', '油脂含量', '肥腻'],
    '清淡度': ['清淡', '清汤度', '清爽'],
    '香度': ['香', '香料度', '蒜香', '葱香'],
    '口感': ['脆爽口感', '软糯口感', 'Q弹口感', '绵密口感'],
  };

  // 完整的46维味觉特征列表（对齐TasteMappingAlgorithmService）
  static const List<String> tasteFeatures = [
    '甜', '酸', '苦', '辣', '咸', '鲜', '香', '麻', // 基础口味 8维
    '清淡', '浓郁', '爽脆', '嫩滑', '弹牙', '软糯', // 口感特征 6维
    '温热', '清凉', '滋补', '开胃', '解腻', '下饭', // 功效特征 6维
    '川菜', '粤菜', '湘菜', '鲁菜', '苏菜', '浙菜', '闽菜', '徽菜', // 菜系特征 8维
    '家常', '宴客', '快手', '精致', '素食', '荤菜', // 类型特征 6维
    '早餐', '午餐', '晚餐', '夜宵', '下午茶', '聚餐', // 场景特征 6维
    '春', '夏', '秋', '冬', '节日', '日常', // 时令特征 6维
  ];

  /// 从46维向量提取主要维度
  /// [fullTasteVector] 完整的46维味觉向量，key为口味名称，value为强度(-10到10)
  Map<String, double> extractPrimaryDimensions(
    Map<String, double> fullTasteVector,
  ) {
    final primary = <String, double>{};

    for (final entry in dimensionMapping.entries) {
      double sum = 0;
      int count = 0;
      for (final dim in entry.value) {
        if (fullTasteVector.containsKey(dim)) {
          sum += fullTasteVector[dim]!;
          count++;
        }
      }
      primary[entry.key] = count > 0 ? sum / count : 0;
    }

    debugPrint('🍽️ 味觉画像降维结果: $primary');
    return primary;
  }

  /// 将标准化的0-1向量转换为-10到10的范围
  double normalizeToRange(double value, {double min = -10, double max = 10}) {
    return value.clamp(min, max);
  }

  /// 从用户偏好数据构建味觉画像
  Map<String, double> buildTasteProfileFromPreferences({
    required List<String> likedTastes,
    required List<String> dislikedTastes,
    required Map<String, double> tastePreferences,
  }) {
    final profile = <String, double>{};

    // 初始化所有维度为0
    for (final dim in primaryDimensions) {
      profile[dim] = 0;
    }

    // 从口味偏好填充
    for (final entry in tastePreferences.entries) {
      final primary = _findPrimaryDimension(entry.key);
      if (primary != null) {
        profile[primary] = (profile[primary]! + entry.value) / 2;
      }
    }

    // 从喜欢的口味增加权重
    for (final taste in likedTastes) {
      final primary = _findPrimaryDimension(taste);
      if (primary != null) {
        profile[primary] = (profile[primary]! + 2).clamp(-10, 10);
      }
    }

    // 从不喜欢的口味减少权重
    for (final taste in dislikedTastes) {
      final primary = _findPrimaryDimension(taste);
      if (primary != null) {
        profile[primary] = (profile[primary]! - 2).clamp(-10, 10);
      }
    }

    return profile;
  }

  /// 查找口味所属的主要维度
  String? _findPrimaryDimension(String taste) {
    for (final entry in dimensionMapping.entries) {
      if (entry.value.contains(taste) || entry.key.contains(taste)) {
        return entry.key;
      }
    }
    // 直接匹配
    if (primaryDimensions.contains(taste)) {
      return taste;
    }
    return null;
  }

  /// 计算两个味觉画像的相似度
  double calculateSimilarity(
    Map<String, double> profile1,
    Map<String, double> profile2,
  ) {
    if (profile1.isEmpty || profile2.isEmpty) return 0;

    double dotProduct = 0;
    double norm1 = 0;
    double norm2 = 0;

    for (final key in profile1.keys) {
      if (profile2.containsKey(key)) {
        dotProduct += profile1[key]! * profile2[key]!;
        norm1 += profile1[key]! * profile1[key]!;
        norm2 += profile2[key]! * profile2[key]!;
      }
    }

    if (norm1 == 0 || norm2 == 0) return 0;
    return dotProduct / (norm1 * norm2);
  }

  /// 获取维度的中文标签
  static String getDimensionLabel(String dimension) {
    return dimension;
  }

  /// 获取维度的图标
  static String getDimensionIcon(String dimension) {
    switch (dimension) {
      case '辣度':
        return '🌶️';
      case '甜度':
        return '🍬';
      case '咸度':
        return '🧂';
      case '酸度':
        return '🍋';
      case '苦度':
        return '☕';
      case '鲜味':
        return '🦐';
      case '油腻度':
        return '🥩';
      case '清淡度':
        return '🥬';
      case '香度':
        return '🌾';
      case '口感':
        return '🍜';
      default:
        return '🍽️';
    }
  }
}
