import 'package:eatwhat_app/v2/core/data/models/tag_art_spec.dart';

class TagArtRegistryV2 {
  const TagArtRegistryV2._();

  static const Map<String, TagArtSpec> _coreSpecs = {
    'f_spicy': TagArtSpec(
      artKey: 'pepper-flare',
      surfacePattern: 'ember',
      motionPreset: 'flare',
      symbolLayout: 'crest',
      headlineStyle: 'poster',
    ),
    'f_fresh': TagArtSpec(
      artKey: 'tidal-mist',
      surfacePattern: 'ripples',
      motionPreset: 'drift',
      symbolLayout: 'orbit',
      headlineStyle: 'airy',
    ),
    'f_sweet': TagArtSpec(
      artKey: 'sugar-ribbon',
      surfacePattern: 'confetti',
      motionPreset: 'shimmer',
      symbolLayout: 'medallion',
      headlineStyle: 'signature',
    ),
    'f_numbing': TagArtSpec(
      artKey: 'electric-pepper',
      surfacePattern: 'zigzag',
      motionPreset: 'pulse',
      symbolLayout: 'corner',
      headlineStyle: 'stencil',
    ),
    'f_light': TagArtSpec(
      artKey: 'dew-note',
      surfacePattern: 'petals',
      motionPreset: 'float',
      symbolLayout: 'orbit',
      headlineStyle: 'airy',
    ),
    'f_rich': TagArtSpec(
      artKey: 'velvet-broth',
      surfacePattern: 'velvet',
      motionPreset: 'settle',
      symbolLayout: 'crest',
      headlineStyle: 'poster',
    ),
    'i_beef': TagArtSpec(
      artKey: 'butcher-ledger',
      surfacePattern: 'marble',
      motionPreset: 'settle',
      symbolLayout: 'vertical',
      headlineStyle: 'stencil',
    ),
    'i_seafood': TagArtSpec(
      artKey: 'harbor-glass',
      surfacePattern: 'ripples',
      motionPreset: 'drift',
      symbolLayout: 'orbit',
      headlineStyle: 'editorial',
    ),
    'i_tomato': TagArtSpec(
      artKey: 'tomato-pop',
      surfacePattern: 'seed',
      motionPreset: 'pulse',
      symbolLayout: 'medallion',
      headlineStyle: 'poster',
    ),
    'i_mushroom': TagArtSpec(
      artKey: 'forest-spore',
      surfacePattern: 'grain',
      motionPreset: 'float',
      symbolLayout: 'vertical',
      headlineStyle: 'serif',
    ),
    'i_tofu': TagArtSpec(
      artKey: 'porcelain-block',
      surfacePattern: 'grid',
      motionPreset: 'breathe',
      symbolLayout: 'corner',
      headlineStyle: 'minimal',
    ),
    'i_chicken': TagArtSpec(
      artKey: 'golden-pan',
      surfacePattern: 'feather',
      motionPreset: 'glow',
      symbolLayout: 'crest',
      headlineStyle: 'editorial',
    ),
    's_dinner': TagArtSpec(
      artKey: 'night-table',
      surfacePattern: 'moon-arc',
      motionPreset: 'settle',
      symbolLayout: 'crest',
      headlineStyle: 'serif',
    ),
    's_snack': TagArtSpec(
      artKey: 'midnight-snack',
      surfacePattern: 'constellation',
      motionPreset: 'twinkle',
      symbolLayout: 'orbit',
      headlineStyle: 'signature',
    ),
    's_party': TagArtSpec(
      artKey: 'table-toast',
      surfacePattern: 'confetti',
      motionPreset: 'shimmer',
      symbolLayout: 'medallion',
      headlineStyle: 'poster',
    ),
    'c_sichuan': TagArtSpec(
      artKey: 'sichuan-seal',
      surfacePattern: 'ember',
      motionPreset: 'flare',
      symbolLayout: 'crest',
      headlineStyle: 'seal',
    ),
    'c_cantonese': TagArtSpec(
      artKey: 'canton-porcelain',
      surfacePattern: 'porcelain',
      motionPreset: 'drift',
      symbolLayout: 'vertical',
      headlineStyle: 'serif',
    ),
    'c_japanese': TagArtSpec(
      artKey: 'zen-tray',
      surfacePattern: 'paper',
      motionPreset: 'settle',
      symbolLayout: 'corner',
      headlineStyle: 'minimal',
    ),
    'c_hotpot': TagArtSpec(
      artKey: 'boiling-ring',
      surfacePattern: 'steam-ring',
      motionPreset: 'pulse',
      symbolLayout: 'medallion',
      headlineStyle: 'poster',
    ),
    'ft_wealth': TagArtSpec(
      artKey: 'gold-altar',
      surfacePattern: 'coin',
      motionPreset: 'glow',
      symbolLayout: 'crest',
      headlineStyle: 'seal',
    ),
    'ft_career': TagArtSpec(
      artKey: 'blueprint-rise',
      surfacePattern: 'grid',
      motionPreset: 'rise',
      symbolLayout: 'vertical',
      headlineStyle: 'stencil',
    ),
  };

  static TagArtSpec specFor(String tagId) {
    return _coreSpecs[tagId] ?? TagArtSpec.fallback;
  }

  static Set<String> get coreTagIds => _coreSpecs.keys.toSet();
}
