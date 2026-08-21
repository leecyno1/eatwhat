import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// How-to-eat actions as three gold-on-black cards — one glance, one tap.
/// The preferred path (when the session constrained it) carries a lit gold
/// border and a tiny 首选 badge.
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
    return Row(
      key: const ValueKey('result-execution-shortcuts'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _GoldActionCard(
            key: const ValueKey('result-execution-delivery'),
            iconKey: const ValueKey('result-execution-delivery-icon'),
            icon: Icons.moped_rounded,
            title: '外卖到家',
            preferred: _isPreferred(ExecutionPath.delivery),
            onTap: onDelivery,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _GoldActionCard(
            key: const ValueKey('result-execution-cook'),
            iconKey: const ValueKey('result-execution-cook-icon'),
            icon: Icons.soup_kitchen_rounded,
            title: '在家开火',
            preferred: _isPreferred(ExecutionPath.cook),
            onTap: onCook,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _GoldActionCard(
            key: const ValueKey('result-execution-dine-in'),
            iconKey: const ValueKey('result-execution-dine-in-icon'),
            icon: Icons.storefront_rounded,
            title: '出门堂食',
            preferred: _isPreferred(ExecutionPath.dineIn),
            onTap: onDineIn,
          ),
        ),
      ],
    );
  }
}

class _GoldActionCard extends StatefulWidget {
  const _GoldActionCard({
    super.key,
    required this.iconKey,
    required this.icon,
    required this.title,
    required this.preferred,
    required this.onTap,
  });

  final Key iconKey;
  final IconData icon;
  final String title;
  final bool preferred;
  final VoidCallback onTap;

  @override
  State<_GoldActionCard> createState() => _GoldActionCardState();
}

class _GoldActionCardState extends State<_GoldActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final gold = widget.preferred ? GoldPalette.gold : GoldPalette.goldSoft;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: AppMotion.enter,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: _pressed
              ? GoldPalette.panel.withValues(alpha: 0.96)
              : GoldPalette.panel,
          borderRadius: AppRadii.small,
          border: Border.all(
            color: widget.preferred ? gold : GoldPalette.goldHairline,
            width: widget.preferred ? 1.4 : 1,
          ),
          gradient: widget.preferred
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    GoldPalette.gold.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              key: widget.iconKey,
              size: 24,
              color: gold,
            ),
            const SizedBox(height: 6),
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: GoldPalette.creamText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            if (widget.preferred) ...[
              const SizedBox(height: 3),
              Text(
                '首选',
                style: TextStyle(
                  color: GoldPalette.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
