import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class ResultTagChip extends StatelessWidget {
  const ResultTagChip({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppPalette.surfaceMuted,
        borderRadius: AppRadii.capsule,
      ),
      child: Text(label, style: AppType.label),
    );
  }
}

class ResultActionBar extends StatelessWidget {
  const ResultActionBar({
    super.key,
    required this.onReroll,
    required this.onOpenSimilarRecipes,
    required this.onOpenRecipe,
  });

  final VoidCallback onReroll;
  final VoidCallback onOpenSimilarRecipes;
  final VoidCallback onOpenRecipe;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('result-secondary-actions'),
      children: [
        Expanded(
          child: _SecondaryAction(
            icon: Icons.refresh_rounded,
            label: '再看看',
            onTap: onReroll,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _SecondaryAction(
            key: const ValueKey('result-open-howtocook-library'),
            icon: Icons.view_carousel_rounded,
            label: '同类菜',
            onTap: onOpenSimilarRecipes,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _SecondaryAction(
            icon: Icons.menu_book_rounded,
            label: '看菜谱',
            onTap: onOpenRecipe,
          ),
        ),
      ],
    );
  }
}

class ResultPrimaryConfirmBar extends StatelessWidget {
  const ResultPrimaryConfirmBar({
    super.key,
    required this.onConfirm,
    this.confirmLabel = '就吃这个',
  });

  final VoidCallback onConfirm;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('result-primary-confirm-bar'),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: AppDecorations.floating(radius: AppRadii.md),
      child: FilledButton.icon(
        key: const ValueKey('execution-entry-button'),
        onPressed: onConfirm,
        icon: const Icon(Icons.arrow_forward_rounded, size: 19),
        label: Text(confirmLabel),
      ),
    );
  }
}

class _SecondaryAction extends StatefulWidget {
  const _SecondaryAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_SecondaryAction> createState() => _SecondaryActionState();
}

class _SecondaryActionState extends State<_SecondaryAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          duration: AppMotion.press,
          curve: AppMotion.enter,
          scale: _pressed ? 0.97 : 1,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: AppDecorations.card(radius: AppRadii.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 17, color: AppPalette.inkSoft),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.label.copyWith(color: AppPalette.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
