class DishImageVariant {
  const DishImageVariant({
    required this.url,
    required this.kind,
  });

  final String url;
  final String kind;
}

class DishImageManifestEntry {
  const DishImageManifestEntry({
    required this.dishId,
    required this.dishName,
    required this.aliases,
    required this.heroUrl,
    required this.thumbUrl,
    required this.styleTag,
    required this.updatedAt,
    this.sourceType = '',
    this.sourceProject = '',
    this.sourcePath = '',
    this.sourceRecipeName = '',
  });

  factory DishImageManifestEntry.fromJson(Map<String, dynamic> json) {
    return DishImageManifestEntry(
      dishId: json['dishId']?.toString() ?? '',
      dishName: json['dishName']?.toString() ?? '',
      aliases: (json['aliases'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      heroUrl: json['heroUrl']?.toString() ?? '',
      thumbUrl: json['thumbUrl']?.toString() ?? '',
      styleTag: json['styleTag']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      sourceType: json['sourceType']?.toString() ?? '',
      sourceProject: json['sourceProject']?.toString() ?? '',
      sourcePath: json['sourcePath']?.toString() ?? '',
      sourceRecipeName: json['sourceRecipeName']?.toString() ?? '',
    );
  }

  final String dishId;
  final String dishName;
  final List<String> aliases;
  final String heroUrl;
  final String thumbUrl;
  final String styleTag;
  final String updatedAt;
  final String sourceType;
  final String sourceProject;
  final String sourcePath;
  final String sourceRecipeName;

  Map<String, dynamic> toJson() {
    return {
      'dishId': dishId,
      'dishName': dishName,
      'aliases': aliases,
      'heroUrl': heroUrl,
      'thumbUrl': thumbUrl,
      'styleTag': styleTag,
      'updatedAt': updatedAt,
      'sourceType': sourceType,
      'sourceProject': sourceProject,
      'sourcePath': sourcePath,
      'sourceRecipeName': sourceRecipeName,
    };
  }
}
