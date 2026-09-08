import 'dart:math' as math;

import 'package:eatwhat_app/v2/core/theme/app_theme_controller.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class FloatingEditorialBackground extends StatefulWidget {
  const FloatingEditorialBackground({super.key});

  @override
  State<FloatingEditorialBackground> createState() =>
      _FloatingEditorialBackgroundState();
}

class _FloatingEditorialBackgroundState
    extends State<FloatingEditorialBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final isTestBinding = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    if (isTestBinding) {
      _controller.value = 0.23;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final phase = _controller.value * math.pi * 2;
        // Palette dispatch: cream keeps the misty garden-paper look; the
        // dark stage swaps in a night field with candle-gold orbs.
        final isCream = AppThemeController.isCream;
        final baseColors = isCream
            ? const [
                Color(0xFFF9FCF7),
                Color(0xFFEAF5E7),
                Color(0xFFDCEFD9),
                Color(0xFFF8FBF5),
              ]
            : const [
                Color(0xFF101013),
                Color(0xFF17171B),
                Color(0xFF0E0D11),
                Color(0xFF131218),
              ];
        final orbOneColors = isCream
            ? const [Color(0x665FB96C), Color(0x337FCB78)]
            : [
                GoldPalette.gold.withValues(alpha: 0.10),
                GoldPalette.gold.withValues(alpha: 0.03),
              ];
        final orbTwoColors = isCream
            ? const [Color(0x55D9EFAE), Color(0x334F9D69)]
            : [
                GoldPalette.goldSoft.withValues(alpha: 0.08),
                GoldPalette.goldSoft.withValues(alpha: 0.02),
              ];
        final cardOneColor = isCream
            ? const Color(0x55FFFFFF)
            : Colors.white.withValues(alpha: 0.05);
        final cardTwoColor = isCream
            ? const Color(0x28498F5B)
            : GoldPalette.gold.withValues(alpha: 0.07);
        return Stack(
          key: const ValueKey('warm-palette-motion-background'),
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: baseColors,
                  stops: const [0, 0.34, 0.72, 1],
                ),
              ),
            ),
            Positioned(
              top: -80 + math.sin(phase) * 18,
              right: -30,
              child: _BlurOrb(
                size: 220,
                colors: orbOneColors,
              ),
            ),
            Positioned(
              left: -70,
              bottom: 120 + math.cos(phase * 0.9) * 22,
              child: _BlurOrb(
                size: 250,
                colors: orbTwoColors,
              ),
            ),
            Positioned(
              top: 120 + math.sin(phase * 1.2) * 12,
              left: 32,
              child: Transform.rotate(
                angle: -0.18,
                child: _FloatingCard(
                  width: 126,
                  height: 168,
                  color: cardOneColor,
                ),
              ),
            ),
            Positioned(
              right: 24,
              bottom: 160 + math.cos(phase * 1.1) * 18,
              child: Transform.rotate(
                angle: 0.22,
                child: _FloatingCard(
                  width: 110,
                  height: 144,
                  color: cardTwoColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _FloatingCard extends StatelessWidget {
  const _FloatingCard({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0x331E1010).withValues(alpha: 0.12),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
      ),
    );
  }
}
