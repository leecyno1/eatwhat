import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class TasteCardBoardShell extends StatelessWidget {
  const TasteCardBoardShell({
    super.key,
    required this.slotCount,
    required this.slotRectFor,
  });

  final int slotCount;
  final Rect Function(int index) slotRectFor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: SizedBox(
            key: ValueKey('taste-board-corner-markers'),
          ),
        ),
        ...List.generate(slotCount, (index) {
          final rect = slotRectFor(index);
          return Positioned(
            left: rect.left,
            top: rect.top,
            width: rect.width,
            height: rect.height,
            child: IgnorePointer(
              child: DecoratedBox(
                key: ValueKey('taste-board-slot-$index'),
                decoration: BoxDecoration(
                  color: AppPalette.surfaceMuted.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppPalette.divider),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
