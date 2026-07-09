/// 购物车商品模型
class CartItem {
  final String id;
  final String foodId;
  final String name;
  final String? imageUrl;
  final double price;
  int quantity;
  final Map<String, String> specs; // 规格选项，如 {'辣度': '微辣', '份量': '大份'}
  final String? recipeId; // 关联的菜谱ID

  CartItem({
    required this.id,
    required this.foodId,
    required this.name,
    this.imageUrl,
    required this.price,
    this.quantity = 1,
    this.specs = const {},
    this.recipeId,
  });

  /// 商品总价
  double get totalPrice => price * quantity;

  /// 规格描述文本
  String get specsText {
    if (specs.isEmpty) return '';
    return specs.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }

  /// 复制并修改属性
  CartItem copyWith({
    String? id,
    String? foodId,
    String? name,
    String? imageUrl,
    double? price,
    int? quantity,
    Map<String, String>? specs,
    String? recipeId,
  }) {
    return CartItem(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      specs: specs ?? Map.from(this.specs),
      recipeId: recipeId ?? this.recipeId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'foodId': foodId,
        'name': name,
        'imageUrl': imageUrl,
        'price': price,
        'quantity': quantity,
        'specs': specs,
        'recipeId': recipeId,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'] as String,
        foodId: json['foodId'] as String,
        name: json['name'] as String,
        imageUrl: json['imageUrl'] as String?,
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'] as int? ?? 1,
        specs: json['specs'] != null
            ? Map<String, String>.from(json['specs'])
            : {},
        recipeId: json['recipeId'] as String?,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CartItem(id: $id, name: $name, quantity: $quantity, totalPrice: $totalPrice)';
}
