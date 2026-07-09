import 'dart:math' as math;

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
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF5EC),
                    Color(0xFFFFD7BE),
                    Color(0xFFF6C4B7),
                    Color(0xFFFFF7F0),
                  ],
                  stops: [0.0, 0.34, 0.72, 1.0],
                ),
              ),
            ),
            Positioned(
              top: -80 + math.sin(phase) * 18,
              right: -30,
              child: const _BlurOrb(
                size: 220,
                colors: [
                  Color(0x88FF7B54),
                  Color(0x44FFB88C),
                ],
              ),
            ),
            Positioned(
              left: -70,
              bottom: 120 + math.cos(phase * 0.9) * 22,
              child: const _BlurOrb(
                size: 250,
                colors: [
                  Color(0x55FFD6C6),
                  Color(0x33F65A32),
                ],
              ),
            ),
            Positioned(
              top: 120 + math.sin(phase * 1.2) * 12,
              left: 32,
              child: Transform.rotate(
                angle: -0.18,
                child: const _FloatingCard(
                  width: 126,
                  height: 168,
                  color: Color(0x55FFFFFF),
                ),
              ),
            ),
            Positioned(
              right: 24,
              bottom: 160 + math.cos(phase * 1.1) * 18,
              child: Transform.rotate(
                angle: 0.22,
                child: const _FloatingCard(
                  width: 110,
                  height: 144,
                  color: Color(0x35A62612),
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
  const _BlurOrb({
    required this.size,
    required this.colors,
  });

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
          gradient: RadialGradient(
            colors: colors,
          ),
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
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
          ),
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
