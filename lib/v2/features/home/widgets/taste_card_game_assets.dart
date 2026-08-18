import 'dart:math' as math;

import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_copy_helpers.dart';
import 'package:flutter/material.dart';

const _assetRoot = 'assets/images/card_game';

String tasteGameCardFrameAsset(TasteDeckCard card) {
  return switch (tasteCardRarityFor(card)) {
    '史诗' => '$_assetRoot/frame_epic.png',
    '稀有' => '$_assetRoot/frame_rare.png',
    '精良' => '$_assetRoot/frame_refined.png',
    _ => '$_assetRoot/frame_common.png',
  };
}

String tasteGameCardArtAsset(TasteDeckCard card) {
  final artKeyAsset = switch (card.artKey) {
    'pepper-flare' => '$_assetRoot/art_spicy.png',
    'electric-pepper' => '$_assetRoot/art_numbing_manga_review.png',
    'tidal-mist' => '$_assetRoot/art_fresh.png',
    'dew-note' => '$_assetRoot/art_light.png',
    'butcher-ledger' => '$_assetRoot/art_beef.png',
    'harbor-glass' => '$_assetRoot/art_seafood.png',
    'porcelain-block' => '$_assetRoot/art_tofu.png',
    'sichuan-seal' => '$_assetRoot/art_sichuan.png',
    'canton-porcelain' => '$_assetRoot/art_cantonese.png',
    'zen-tray' => '$_assetRoot/art_japanese.png',
    'boiling-ring' => '$_assetRoot/art_hotpot.png',
    'gold-altar' => '$_assetRoot/art_wealth.png',
    'quiet-water' => '$_assetRoot/art_calm.png',
    'sunrise-checkin' => '$_assetRoot/art_breakfast.png',
    'midnight-snack' => '$_assetRoot/art_late_snack.png',
    'table-toast' => '$_assetRoot/art_party.png',
    _ => null,
  };
  if (artKeyAsset != null) {
    return artKeyAsset;
  }

  final idAsset = switch (card.id) {
    'f_spicy' => '$_assetRoot/art_spicy.png',
    'f_numbing' => '$_assetRoot/art_numbing_manga_review.png',
    'f_fresh' => '$_assetRoot/art_fresh.png',
    'f_light' => '$_assetRoot/art_light.png',
    'i_potato' => '$_assetRoot/art_potato.png',
    'i_tofu' => '$_assetRoot/art_tofu.png',
    'i_beef' => '$_assetRoot/art_beef.png',
    'i_seafood' ||
    'i_shellfish' ||
    'i_shrimp' ||
    'i_fish' =>
      '$_assetRoot/art_seafood.png',
    'st_rice' => '$_assetRoot/art_rice.png',
    'st_noodle' => '$_assetRoot/art_noodle.png',
    'st_porridge' => '$_assetRoot/art_porridge.png',
    'st_dumpling' => '$_assetRoot/art_dumpling.png',
    'd_low_carb' => '$_assetRoot/art_low_carb.png',
    'd_vegetarian' => '$_assetRoot/art_vegetarian.png',
    'd_light' || 's_healthy' => '$_assetRoot/art_healthy.png',
    'm_cheap' => '$_assetRoot/art_cheap.png',
    'm_random' => '$_assetRoot/art_random.png',
    'm_surprise' => '$_assetRoot/art_surprise.png',
    's_date' => '$_assetRoot/art_date.png',
    's_snack' => '$_assetRoot/art_late_snack.png',
    's_party' => '$_assetRoot/art_party.png',
    's_solo' => '$_assetRoot/art_solo.png',
    's_afternoon_tea' => '$_assetRoot/art_afternoon_tea.png',
    's_street' => '$_assetRoot/art_street.png',
    'c_sichuan' || 'c_hunan' => '$_assetRoot/art_sichuan.png',
    'c_cantonese' || 'c_hongkong' => '$_assetRoot/art_cantonese.png',
    'c_japanese' => '$_assetRoot/art_japanese.png',
    'c_vietnamese' => '$_assetRoot/art_vietnamese.png',
    'c_thai' => '$_assetRoot/art_thai.png',
    'c_hotpot' => '$_assetRoot/art_hotpot.png',
    'c_bbq' => '$_assetRoot/art_bbq.png',
    'c_western' ||
    'c_french' =>
      '$_assetRoot/art_western.png',
    'ft_wealth' => '$_assetRoot/art_wealth.png',
    _ => null,
  };
  if (idAsset != null) {
    return idAsset;
  }

  return switch (card.category) {
    'flavor' => '$_assetRoot/art_flavor.png',
    'ingredient' => '$_assetRoot/art_ingredient.png',
    'scene' => '$_assetRoot/art_scene.png',
    'cuisine' => '$_assetRoot/art_cuisine.png',
    'staple' => '$_assetRoot/art_staple.png',
    'fortune' => '$_assetRoot/art_fortune.png',
    'dietary' => '$_assetRoot/art_dietary.png',
    'meta' => '$_assetRoot/art_meta.png',
    _ => '$_assetRoot/art_meta.png',
  };
}

String tasteGameCardEffectAsset(TasteCardReaction? reaction) {
  return switch (reaction) {
    TasteCardReaction.liked => '$_assetRoot/effect_burst.png',
    TasteCardReaction.disliked => '$_assetRoot/effect_slash.png',
    TasteCardReaction.skipped => '$_assetRoot/effect_spark.png',
    null => '$_assetRoot/effect_spark.png',
  };
}

class TasteGameCardFrameLayer extends StatelessWidget {
  const TasteGameCardFrameLayer({
    super.key,
    required this.card,
    required this.compact,
  });

  final TasteDeckCard card;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: compact ? 0.58 : 0.72,
              child: Image.asset(
                tasteGameCardFrameAsset(card),
                fit: BoxFit.fill,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const _RarityFoilSweep(),
          ],
        ),
      ),
    );
  }
}

class _RarityFoilSweep extends StatelessWidget {
  const _RarityFoilSweep();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: -1.25, end: 1.25),
      duration: const Duration(milliseconds: 1800),
      curve: Curves.easeInOutCubic,
      builder: (context, value, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(value - 0.32, -1),
              end: Alignment(value + 0.32, 1),
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.22),
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0, 0.36, 0.5, 0.64, 1],
            ),
          ),
        );
      },
    );
  }
}

class TasteGameCardArtLayer extends StatelessWidget {
  const TasteGameCardArtLayer({
    super.key,
    required this.card,
    required this.compact,
  });

  final TasteDeckCard card;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: compact ? 6 : 12,
      right: compact ? 6 : 12,
      top: compact ? 8 : 14,
      bottom: compact ? 8 : 16,
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(compact ? 17 : 22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                tasteGameCardArtAsset(card),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              if (_usesNumbingReviewArt(card)) const _NumbingElectricOverlay(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.02),
                      Colors.black.withValues(alpha: compact ? 0.28 : 0.22),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(compact ? 17 : 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _usesNumbingReviewArt(TasteDeckCard card) {
  return card.id == 'f_numbing' || card.artKey == 'electric-pepper';
}

class _NumbingElectricOverlay extends StatefulWidget {
  const _NumbingElectricOverlay();

  @override
  State<_NumbingElectricOverlay> createState() =>
      _NumbingElectricOverlayState();
}

class _NumbingElectricOverlayState extends State<_NumbingElectricOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _NumbingElectricPainter(_controller.value),
          );
        },
      ),
    );
  }
}

class _NumbingElectricPainter extends CustomPainter {
  const _NumbingElectricPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = (math.sin(progress * math.pi * 2) + 1) / 2;
    final center = Offset(size.width * 0.52, size.height * 0.54);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.1 + pulse * 1.4
      ..color = Color.lerp(
        const Color(0x66FF8AF7),
        const Color(0xCCFFFFFF),
        pulse,
      )!;

    for (final points in _arcPoints(size, center, progress)) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i += 1) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    final sparkPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFC65A).withValues(alpha: 0.45 + pulse * 0.35);
    for (var i = 0; i < 9; i += 1) {
      final angle = progress * math.pi * 2 + i * 0.72;
      final radius = size.shortestSide * (0.22 + (i % 3) * 0.08);
      final point = center +
          Offset(
            math.cos(angle) * radius,
            math.sin(angle * 1.12) * radius,
          );
      canvas.drawCircle(point, 1.2 + pulse * 1.2, sparkPaint);
    }
  }

  List<List<Offset>> _arcPoints(Size size, Offset center, double progress) {
    final drift = (progress - 0.5) * size.shortestSide * 0.08;
    return [
      [
        Offset(size.width * 0.18, size.height * 0.38 + drift),
        Offset(size.width * 0.32, size.height * 0.46 - drift),
        center,
        Offset(size.width * 0.69, size.height * 0.45 + drift),
        Offset(size.width * 0.84, size.height * 0.32 - drift),
      ],
      [
        Offset(size.width * 0.22, size.height * 0.72 - drift),
        Offset(size.width * 0.38, size.height * 0.64 + drift),
        center,
        Offset(size.width * 0.63, size.height * 0.71 - drift),
        Offset(size.width * 0.79, size.height * 0.82 + drift),
      ],
      [
        Offset(size.width * 0.42 + drift, size.height * 0.18),
        Offset(size.width * 0.49 - drift, size.height * 0.34),
        center,
        Offset(size.width * 0.57 + drift, size.height * 0.72),
      ],
    ];
  }

  @override
  bool shouldRepaint(_NumbingElectricPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class TasteGameCardEffectLayer extends StatelessWidget {
  const TasteGameCardEffectLayer({
    super.key,
    required this.reaction,
    required this.progress,
  });

  final TasteCardReaction? reaction;
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (reaction == null && progress <= 0.01) {
      return const SizedBox.shrink();
    }
    final opacity = reaction == null ? (progress * 0.5).clamp(0.0, 0.5) : 0.82;
    final scale = 0.96 + progress.clamp(0.0, 1.0) * 0.32;

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Image.asset(
                tasteGameCardEffectAsset(reaction),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
