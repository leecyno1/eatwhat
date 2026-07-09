class TagArtSpec {
  const TagArtSpec({
    required this.artKey,
    required this.surfacePattern,
    required this.motionPreset,
    required this.symbolLayout,
    required this.headlineStyle,
  });

  static const fallback = TagArtSpec(
    artKey: 'default',
    surfacePattern: 'category',
    motionPreset: 'breathe',
    symbolLayout: 'stamp',
    headlineStyle: 'editorial',
  );

  final String artKey;
  final String surfacePattern;
  final String motionPreset;
  final String symbolLayout;
  final String headlineStyle;
}
