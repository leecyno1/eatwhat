class RecipePairingModel {
  const RecipePairingModel({
    required this.id,
    required this.dishId,
    required this.type,
    required this.name,
    required this.description,
    required this.strength,
    required this.source,
  });

  factory RecipePairingModel.fromDbRow(Map<String, Object?> row) {
    final rawStrength = row['strength'];
    final strength = rawStrength is num
        ? rawStrength.toDouble()
        : double.tryParse(rawStrength?.toString() ?? '') ?? 0;

    return RecipePairingModel(
      id: row['id']?.toString() ?? '',
      dishId: row['dish_id']?.toString() ?? '',
      type: row['type']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      strength: strength,
      source: row['source']?.toString() ?? '',
    );
  }

  final String id;
  final String dishId;
  final String type;
  final String name;
  final String description;
  final double strength;
  final String source;
}
