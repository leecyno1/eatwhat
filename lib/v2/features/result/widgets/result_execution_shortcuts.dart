import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
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
    return preferredPath == ExecutionPath.any || preferredPath == path;
  }

  Widget _buildAction({
    required String keyName,
    required String label,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    required bool preferred,
    required bool compact,
  }) {
    final accent = switch (keyName) {
      'cook' => const Color(0xFF6F8F63),
      'delivery' => const Color(0xFFF46B40),
      'dine-in' => const Color(0xFF3E6FB0),
      _ => AppColors.textPrimary,
    };

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.panel,
          child: Container(
            key: ValueKey('result-execution-$keyName'),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 14,
              vertical: compact ? 10 : 13,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadii.panel,
              color: Colors.white.withValues(alpha: 0.72),
              border: Border.all(
                color: preferred
                    ? accent.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.72),
              ),
            ),
            child: compact
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.12),
                        ),
                        child: Icon(icon, size: 16, color: accent),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppType.section.copyWith(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (preferred) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: AppRadii.capsule,
                          ),
                          child: Text(
                            '推荐',
                            style: AppType.microLabel.copyWith(
                              color: accent,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.12),
                        ),
                        child: Icon(icon, size: 18, color: accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppType.section.copyWith(
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (preferred) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.12),
                                      borderRadius: AppRadii.capsule,
                                    ),
                                    child: Text(
                                      '推荐',
                                      style: AppType.microLabel.copyWith(
                                        color: accent,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.microLabel.copyWith(
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return Container(
          key: const ValueKey('result-execution-shortcuts'),
          padding: EdgeInsets.all(compact ? 10 : 12),
          decoration: BoxDecoration(
            borderRadius: AppRadii.panel,
            color: Colors.white.withValues(alpha: 0.36),
            border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '先选怎么吃',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.section.copyWith(
                        fontSize: compact ? 15 : 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        preferredPath == ExecutionPath.any
                            ? '给你三条直达路'
                            : '按这口味优先走',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: AppType.microLabel.copyWith(
                          color: AppColors.textPrimary.withValues(alpha: 0.52),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildAction(
                    keyName: 'cook',
                    label: '自己做',
                    hint: '进菜谱，直接开做',
                    icon: Icons.kitchen_rounded,
                    onTap: onCook,
                    preferred: _isPreferred(ExecutionPath.cook),
                    compact: compact,
                  ),
                  SizedBox(width: compact ? 6 : 10),
                  _buildAction(
                    keyName: 'delivery',
                    label: '叫外卖',
                    hint: '进平台执行页',
                    icon: Icons.delivery_dining_rounded,
                    onTap: onDelivery,
                    preferred: _isPreferred(ExecutionPath.delivery),
                    compact: compact,
                  ),
                  SizedBox(width: compact ? 6 : 10),
                  _buildAction(
                    keyName: 'dine-in',
                    label: '去堂食',
                    hint: '先看附近店',
                    icon: Icons.storefront_rounded,
                    onTap: onDineIn,
                    preferred: _isPreferred(ExecutionPath.dineIn),
                    compact: compact,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
