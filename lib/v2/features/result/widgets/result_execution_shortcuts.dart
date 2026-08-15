import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class ResultExecutionShortcuts extends StatelessWidget {
  const ResultExecutionShortcuts({
    super.key,
    required this.preferredPath,
    required this.onCook,
    required this.onDelivery,
    required this.onDineIn,
  });

  final ExecutionPath preferredPath;
  final VoidCallback onCook;
  final VoidCallback onDelivery;
  final VoidCallback onDineIn;

  bool _isPreferred(ExecutionPath path) {
    return preferredPath != ExecutionPath.any && preferredPath == path;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('result-execution-shortcuts'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('怎么吃', style: AppType.section),
          const SizedBox(height: 4),
          Text(
            preferredPath == ExecutionPath.any
                ? '选好菜后，可以直接做、叫外卖或找附近餐馆。'
                : '已按你的要求标出优先方式。',
            style: AppType.label,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ExecutionAction(
            key: const ValueKey('result-execution-delivery'),
            iconKey: const ValueKey('result-execution-delivery-icon'),
            icon: Icons.delivery_dining_rounded,
            title: '叫外卖',
            subtitle: '搜索匹配菜品并进入美团菜单',
            preferred: _isPreferred(ExecutionPath.delivery),
            onTap: onDelivery,
          ),
          const SizedBox(height: AppSpacing.xs),
          _ExecutionAction(
            key: const ValueKey('result-execution-cook'),
            iconKey: const ValueKey('result-execution-cook-icon'),
            icon: Icons.kitchen_rounded,
            title: '自己做',
            subtitle: '查看材料和步骤',
            preferred: _isPreferred(ExecutionPath.cook),
            onTap: onCook,
          ),
          const SizedBox(height: AppSpacing.xs),
          _ExecutionAction(
            key: const ValueKey('result-execution-dine-in'),
            iconKey: const ValueKey('result-execution-dine-in-icon'),
            icon: Icons.storefront_rounded,
            title: '去堂食',
            subtitle: '查看附近餐馆',
            preferred: _isPreferred(ExecutionPath.dineIn),
            onTap: onDineIn,
          ),
        ],
      ),
    );
  }
}

class _ExecutionAction extends StatefulWidget {
  const _ExecutionAction({
    super.key,
    required this.iconKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.preferred,
    required this.onTap,
  });

  final Key iconKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool preferred;
  final VoidCallback onTap;

  @override
  State<_ExecutionAction> createState() => _ExecutionActionState();
}

class _ExecutionActionState extends State<_ExecutionAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.title,
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
          scale: _pressed ? 0.98 : 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: widget.preferred
                  ? AppPalette.positiveSurface
                  : AppPalette.surfaceMuted,
              borderRadius: AppRadii.small,
              border: Border.all(
                color: widget.preferred
                    ? AppPalette.chili.withValues(alpha: 0.32)
                    : AppPalette.divider,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppPalette.surface,
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                  child: Icon(
                    widget.icon,
                    key: widget.iconKey,
                    size: 19,
                    color: widget.preferred
                        ? AppPalette.chili
                        : AppPalette.inkSoft,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(widget.title, style: AppType.section),
                          ),
                          if (widget.preferred) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppPalette.surface,
                                borderRadius: AppRadii.capsule,
                              ),
                              child: Text(
                                '优先',
                                style: AppType.microLabel.copyWith(
                                  color: AppPalette.chili,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.label,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppPalette.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
