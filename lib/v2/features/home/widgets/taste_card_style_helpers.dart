import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:flutter/material.dart';

typedef TasteCardSignatureConfig = ({
  String glyph,
  String code,
  double angle,
  double radius,
  double top,
  double right,
});

FontWeight tasteCardHeadlineWeight(String style) {
  switch (style) {
    case 'minimal':
      return FontWeight.w800;
    case 'signature':
      return FontWeight.w700;
    case 'serif':
      return FontWeight.w800;
    case 'stencil':
      return FontWeight.w900;
    case 'seal':
      return FontWeight.w900;
    case 'airy':
      return FontWeight.w800;
    case 'poster':
      return FontWeight.w900;
    case 'editorial':
    default:
      return FontWeight.w900;
  }
}

double tasteCardHeadlineSpacing(String style) {
  switch (style) {
    case 'minimal':
      return -0.1;
    case 'signature':
      return 0.18;
    case 'seal':
      return 0.08;
    case 'airy':
      return 0.22;
    case 'stencil':
      return 0.02;
    default:
      return -0.2;
  }
}

bool tasteCardHeadlineItalic(String style) {
  return style == 'signature' || style == 'serif';
}

double tasteCardHeadlineBarWidth(String style, bool ultraCompact) {
  final base = ultraCompact ? 0.42 : 0.52;
  switch (style) {
    case 'minimal':
      return base - 0.06;
    case 'seal':
      return base + 0.1;
    case 'poster':
      return base + 0.06;
    case 'airy':
      return base - 0.02;
    default:
      return base;
  }
}

Offset tasteCardSymbolIconOffset(String layout, bool compact) {
  switch (layout) {
    case 'corner':
      return Offset(compact ? 10 : 14, compact ? 24 : 30);
    case 'orbit':
      return Offset(compact ? 14 : 18, compact ? 42 : 48);
    case 'vertical':
      return Offset(compact ? 8 : 12, compact ? 34 : 40);
    case 'medallion':
      return Offset(compact ? 16 : 20, compact ? 38 : 46);
    case 'crest':
      return Offset(compact ? 12 : 16, compact ? 22 : 28);
    default:
      return Offset(compact ? 10 : 14, compact ? 34 : 42);
  }
}

double tasteCardIconOpacity(String motionPreset, bool compact) {
  final base = compact ? 0.1 : 0.12;
  switch (motionPreset) {
    case 'flare':
    case 'glow':
      return base + 0.05;
    case 'rise':
    case 'float':
      return base + 0.02;
    default:
      return base;
  }
}

TasteCardSignatureConfig tasteCardSignatureConfigForCard(TasteDeckCard card) {
  final base = tasteCardSignatureConfigFor(card.category);
  switch (card.symbolLayout) {
    case 'crest':
      return (
        glyph: base.glyph,
        code: base.code,
        angle: base.angle - 0.03,
        radius: base.radius + 2,
        top: base.top + 4,
        right: base.right - 2,
      );
    case 'corner':
      return (
        glyph: base.glyph,
        code: base.code,
        angle: base.angle + 0.05,
        radius: base.radius - 2,
        top: base.top - 8,
        right: base.right,
      );
    case 'vertical':
      return (
        glyph: base.glyph,
        code: base.code,
        angle: -0.02,
        radius: base.radius + 4,
        top: base.top + 8,
        right: base.right + 2,
      );
    case 'orbit':
      return (
        glyph: base.glyph,
        code: base.code,
        angle: base.angle - 0.08,
        radius: base.radius + 1,
        top: base.top + 10,
        right: base.right + 4,
      );
    case 'medallion':
      return (
        glyph: base.glyph,
        code: base.code,
        angle: 0,
        radius: base.radius + 6,
        top: base.top + 12,
        right: base.right + 8,
      );
    default:
      return base;
  }
}

TasteCardSignatureConfig tasteCardSignatureConfigFor(String category) {
  switch (category) {
    case 'flavor':
      return (
        glyph: '味',
        code: 'FLAVOR',
        angle: -0.08,
        radius: 16,
        top: 32,
        right: 10,
      );
    case 'ingredient':
      return (
        glyph: '材',
        code: 'ING',
        angle: -0.02,
        radius: 20,
        top: 26,
        right: 12,
      );
    case 'scene':
      return (
        glyph: '景',
        code: 'SCENE',
        angle: 0.06,
        radius: 22,
        top: 24,
        right: 12,
      );
    case 'cuisine':
      return (
        glyph: '系',
        code: 'CUISINE',
        angle: -0.04,
        radius: 18,
        top: 24,
        right: 10,
      );
    case 'staple':
      return (
        glyph: '食',
        code: 'STAPLE',
        angle: 0.04,
        radius: 16,
        top: 26,
        right: 10,
      );
    case 'fortune':
      return (
        glyph: '运',
        code: 'FORTUNE',
        angle: -0.1,
        radius: 20,
        top: 22,
        right: 12,
      );
    case 'dietary':
      return (
        glyph: '律',
        code: 'DIET',
        angle: 0.02,
        radius: 14,
        top: 26,
        right: 10,
      );
    case 'meta':
      return (
        glyph: '趣',
        code: 'META',
        angle: -0.12,
        radius: 18,
        top: 22,
        right: 12,
      );
    default:
      return (
        glyph: '签',
        code: 'TAG',
        angle: 0,
        radius: 16,
        top: 24,
        right: 10,
      );
  }
}

Color tasteCardParseHexColor(String raw) {
  final normalized = raw.replaceFirst('0x', '');
  final value = normalized.length == 6 ? 'FF$normalized' : normalized;
  return Color(int.parse(value, radix: 16));
}
