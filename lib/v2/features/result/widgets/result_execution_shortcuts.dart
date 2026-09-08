import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// How-to-eat actions as three branded gold-on-black cards. Each channel
/// carries its brand badge (美团黄 / 点评橙 / kitchen gold), the action
/// name, and the channel it routes to.
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
          child: _ChannelCard(
            key: const ValueKey('result-execution-delivery'),
            iconKey: const ValueKey('result-execution-delivery-icon'),
            icon: Icons.moped_rounded,
            badgeColor: const Color(0xFFFFD100),
            badgeInk: const Color(0xFF3A2E00),
            title: '外卖到家',
            channel: '美团外卖',
            channelColor: const Color(0xFFE6B800),
            preferred: _isPreferred(ExecutionPath.delivery),
            onTap: onDelivery,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ChannelCard(
            key: const ValueKey('result-execution-cook'),
            iconKey: const ValueKey('result-execution-cook-icon'),
            icon: Icons.soup_kitchen_rounded,
            badgeColor: GoldPalette.gold,
            badgeInk: GoldPalette.nightDeep,
            title: '在家开火',
            channel: '菜谱直出',
            channelColor: GoldPalette.goldSoft,
            preferred: _isPreferred(ExecutionPath.cook),
            onTap: onCook,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ChannelCard(
            key: const ValueKey('result-execution-dine-in'),
            iconKey: const ValueKey('result-execution-dine-in-icon'),
            icon: Icons.storefront_rounded,
            badgeColor: const Color(0xFFFF6633),
            badgeInk: const Color(0xFFFFF3EC),
            title: '出门堂食',
            channel: '大众点评',
            channelColor: const Color(0xFFFF8A5C),
            preferred: _isPreferred(ExecutionPath.dineIn),
            onTap: onDineIn,
          ),
        ),
      ],
    );
  }
}

class _ChannelCard extends StatefulWidget {
  const _ChannelCard({
    super.key,
    required this.iconKey,
    required this.icon,
    required this.badgeColor,
    required this.badgeInk,
    required this.title,
    required this.channel,
    required this.channelColor,
    required this.preferred,
    required this.onTap,
  });

  final Key iconKey;
  final IconData icon;
  final Color badgeColor;
  final Color badgeInk;
  final String title;
  final String channel;
  final Color channelColor;
  final bool preferred;
  final VoidCallback onTap;

  @override
  State<_ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<_ChannelCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
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
            color:
                widget.preferred ? GoldPalette.gold : GoldPalette.goldHairline,
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
            // Brand badge: channel-colored tile with the channel icon.
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.badgeColor,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: widget.badgeColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                key: widget.iconKey,
                size: 20,
                color: widget.badgeInk,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GoldPalette.creamText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.channel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.channelColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            if (widget.preferred) ...[
              const SizedBox(height: 3),
              const Text(
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
