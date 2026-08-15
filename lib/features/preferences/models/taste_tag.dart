/// 模型：口味标签
/// 说明：用于“口味偏好选择”瀑布流气泡页面中的基础数据结构。
class TasteTag {
  TasteTag({
    required this.id,
    required this.name,
    required this.category, // taste | method | ingredient | texture | avoid
    this.weight = 0,
    this.disliked = false,
    this.emoji,
  });

  final String id;
  final String name;
  final String category;
  double weight; // 0..5，表示偏好强度，后续可允许 -5..0 作为负偏好
  bool disliked; // true 表示不吃/过敏
  final String? emoji; // 可选 Emoji 展示

  bool get isSelected => !disliked && weight > 0;

  TasteTag copyWith({
    String? id,
    String? name,
    String? category,
    double? weight,
    bool? disliked,
    String? emoji,
  }) {
    return TasteTag(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      weight: weight ?? this.weight,
      disliked: disliked ?? this.disliked,
      emoji: emoji ?? this.emoji,
    );
  }
}
