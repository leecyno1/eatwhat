import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme_controller.dart';
import '../../../core/theme/app_tokens.dart';

/// Size of the whole key including its lacquer base.
const double potButtonWidth = 208;
const double potButtonRise = 104;

/// A lacquered, half-round “吃什么” key sitting on the storefront sill.
///
/// One object, one arch: a dark lacquer base with a raised cap that sinks when
/// pressed. No labels; the brush word and the seal are the only copy.
class PotButton extends StatefulWidget {
  const PotButton({
    super.key,
    required this.selectionCount,
    required this.enabled,
    required this.onTap,
  });

  final int selectionCount;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<PotButton> createState() => _PotButtonState();
}

class _PotButtonState extends State<PotButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );
  bool _pressed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = .3;
    } else if (!_controller.isAnimating) {
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
    final skin = AppThemeController.skin;
    final isCream = skin.isLight;
    final enabled = widget.enabled;
    final accent = AppPalette.leaf;
    final buttonAsset = skin.assetPath('button');
    final sealAsset = skin.assetPath('seal');

    final capColors = isCream
        ? const [Color(0xFFFFFBF4), Color(0xFFF4E8D8), Color(0xFFEAD9C4)]
        : const [Color(0xFF31363D), Color(0xFF24292F), Color(0xFF1B1F24)];
    final baseColors = buttonAsset != null
        ? [skin.accent, skin.accentDeep]
        : isCream
            ? const [Color(0xFFA8492B), Color(0xFF7A301A)]
            : const [Color(0xFFB84A31), Color(0xFF7B2D1D)];
    final ink = skin.ink;

    return Semantics(
      button: true,
      label: '吃什麼，生成建議',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: SizedBox(
          width: potButtonWidth,
          height: potButtonRise,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Lacquer base: the fixed body of the key.
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final pulse = .5 +
                      .5 *
                          math.sin(
                            _controller.value * math.pi * 2,
                          );
                  return Container(
                    width: potButtonWidth,
                    height: potButtonRise,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: baseColors,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(potButtonRise),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isCream ? .26 : .55,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: accent.withValues(
                            alpha: (isCream ? .12 : .20) +
                                (enabled ? .06 : 0) +
                                .08 * pulse,
                          ),
                          blurRadius: 30,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Raised cap: this is what moves when the key is pressed.
              Positioned(
                bottom: 8,
                child: AnimatedSlide(
                  offset: Offset(0, _pressed ? .062 : 0),
                  duration: const Duration(milliseconds: 130),
                  curve: Curves.easeOut,
                  child: AnimatedScale(
                    scale: _pressed ? .99 : 1,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: Container(
                      width: potButtonWidth - 16,
                      height: potButtonRise - 8,
                      decoration: BoxDecoration(
                        image: buttonAsset == null
                            ? null
                            : DecorationImage(
                                image: AssetImage(buttonAsset),
                                fit: BoxFit.cover,
                              ),
                        gradient: buttonAsset != null
                            ? null
                            : LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: capColors,
                              ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(potButtonRise - 8),
                        ),
                        border: buttonAsset != null
                            ? null
                            : Border.all(
                                color: isCream
                                    ? const Color(0xFF8F3B24)
                                        .withValues(alpha: .22)
                                    : AppPalette.leaf.withValues(alpha: .26),
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: _pressed
                                  ? (isCream ? .12 : .30)
                                  : (isCream ? .22 : .45),
                            ),
                            blurRadius: _pressed ? 4 : 12,
                            offset: Offset(0, _pressed ? 2 : 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) => CustomPaint(
                              painter: _LacquerPainter(
                                time: _controller.value,
                                pressed: _pressed,
                                enabled: enabled,
                                hopping: widget.selectionCount >= 3,
                                ink: ink,
                                isCream: isCream,
                                textured: buttonAsset != null,
                                paintSeal: sealAsset == null,
                              ),
                            ),
                          ),
                          if (sealAsset != null)
                            Positioned(
                              right: 8,
                              bottom: 6,
                              child: Image.asset(
                                sealAsset,
                                width: 20,
                                height: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LacquerPainter extends CustomPainter {
  _LacquerPainter({
    required this.time,
    required this.pressed,
    required this.enabled,
    required this.hopping,
    required this.ink,
    required this.isCream,
    this.textured = false,
    this.paintSeal = true,
  });

  final double time;
  final bool pressed;
  final bool enabled;
  final bool hopping;
  final Color ink;
  final bool isCream;

  /// True when an image accessory already paints the enamel face; the
  /// painter then only draws the brush word (and skips its own gloss).
  final bool textured;

  /// False when a seal image accessory is layered on top instead.
  final bool paintSeal;

  static const _chars = ['吃', '什', '么'];
  static const _angles = [-2.36, -math.pi / 2, -0.78];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final pulse = .5 + .5 * math.sin(time * math.pi * 2);

    // Enamel gloss: a soft highlight at the upper left plus a rim sheen.
    // Skipped when an image accessory already carries the surface art.
    if (!textured) {
      canvas
        ..drawCircle(
          Offset(size.width * .36, size.height * .18),
          size.width * .52,
          Paint()
            ..shader = RadialGradient(
              colors: [
                Colors.white.withValues(
                  alpha: (isCream ? .32 : .06) + .04 * pulse,
                ),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0, 1],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * .36, size.height * .18),
                radius: size.width * .52,
              ),
            ),
        )
        ..drawArc(
          Rect.fromCircle(center: center, radius: size.width / 2 - 5),
          math.pi * 1.02,
          math.pi * .96,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = isCream
                ? Colors.white.withValues(alpha: .35)
                : AppPalette.leaf.withValues(alpha: .22),
        )
        // A gold hairline inset in the ivory face, like a plaque border.
        ..drawArc(
          Rect.fromCircle(center: center, radius: size.width / 2 - 9),
          math.pi,
          math.pi,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = (isCream ? const Color(0xFFC9A96E) : AppPalette.leaf)
                .withValues(alpha: isCream ? .55 : .35),
        );
    }

    // Brush word.
    for (var i = 0; i < _chars.length; i++) {
      final angle = _angles[i];
      final phase = time * math.pi * 2 * 2 + i * .9;
      final hop = hopping && enabled ? -3 + 3 * math.sin(phase) : 0.0;
      final position = Offset(
        center.dx + math.cos(angle) * size.width * .32,
        center.dy + math.sin(angle) * size.width * .32 + hop,
      );
      final painter = TextPainter(
        text: TextSpan(
          text: _chars[i],
          style: TextStyle(
            fontFamily: 'BrushLogo',
            fontSize: 42,
            height: 1,
            color: ink,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final glyphOffset = Offset(-painter.width / 2, -painter.height / 2);
      canvas
        ..save()
        ..translate(position.dx, position.dy)
        ..rotate(angle + math.pi / 2);
      // A small offset thickens the brush strokes on the lacquer.
      painter
        ..paint(canvas, glyphOffset + const Offset(.55, 1.0))
        ..paint(canvas, glyphOffset);
      canvas.restore();
    }

    if (paintSeal) {
      _paintSeal(canvas, size);
    }
  }

  void _paintSeal(Canvas canvas, Size size) {
    const sealSize = 18.0;
    final rect = Rect.fromCenter(
      center: Offset(size.width - 20, size.height - 18),
      width: sealSize,
      height: sealSize,
    );
    canvas
      ..save()
      ..translate(rect.center.dx, rect.center.dy)
      ..rotate(-.08);
    final outer = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: sealSize,
        height: sealSize,
      ),
      const Radius.circular(3),
    );
    canvas
      ..drawRRect(
        outer,
        Paint()..color = AppPalette.chiliDeep,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: sealSize - 3.4,
            height: sealSize - 3.4,
          ),
          const Radius.circular(1.6),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8
          ..color = const Color(0xFFFFF2E2).withValues(alpha: .55),
      );
    final sealText = TextPainter(
      text: const TextSpan(
        text: '食',
        style: TextStyle(
          fontFamily: 'Songti SC',
          fontFamilyFallback: ['STSong', 'serif'],
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFF2E2),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    sealText.paint(canvas, Offset(-sealText.width / 2, -sealText.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LacquerPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.pressed != pressed ||
        oldDelegate.enabled != enabled ||
        oldDelegate.hopping != hopping ||
        oldDelegate.ink != ink ||
        oldDelegate.isCream != isCream ||
        oldDelegate.textured != textured ||
        oldDelegate.paintSeal != paintSeal;
  }
}
