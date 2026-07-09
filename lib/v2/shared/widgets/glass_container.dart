import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../core/theme/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;
  final double borderRadius;

  const GlassContainer({
    super.key,
    required this.width,
    required this.height,
    required this.child,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: width,
      height: height,
      borderRadius: borderRadius,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.glassWhite.withOpacity(0.1),
            AppColors.glassWhite.withOpacity(0.05),
          ],
          stops: const [
            0.1,
            1,
          ]),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.glassWhite.withOpacity(0.5),
          AppColors.glassWhite.withOpacity(0.5),
        ],
      ),
      child: child,
    );
  }
}
