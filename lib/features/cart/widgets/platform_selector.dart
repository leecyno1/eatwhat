import 'package:flutter/material.dart';
import 'package:eatwhat_app/core/models/cart_item.dart';
import 'package:eatwhat_app/core/services/deep_link_service.dart';

/// 平台选择按钮
class _PlatformButton extends StatelessWidget {
  final DeliveryPlatform platform;
  final bool isSelected;
  final bool isInstalled;
  final VoidCallback onTap;

  const _PlatformButton({
    required this.platform,
    required this.isSelected,
    required this.isInstalled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 平台图标
            Stack(
              children: [
                _buildPlatformIcon(platform, colorScheme, isSelected),
                // 未安装标记
                if (!isInstalled)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // 平台名称
            Text(
              platform.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformIcon(
    DeliveryPlatform platform,
    ColorScheme colorScheme,
    bool isSelected,
  ) {
    final color = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    IconData iconData;
    switch (platform) {
      case DeliveryPlatform.meituan:
        iconData = Icons.delivery_dining;
        break;
      case DeliveryPlatform.eleme:
        iconData = Icons.restaurant;
        break;
      case DeliveryPlatform.dianping:
        iconData = Icons.rate_review;
        break;
    }

    return Icon(iconData, color: color, size: 28);
  }
}

/// 平台选择器组件
///
/// 用于在结算时选择外卖平台
class PlatformSelector extends StatelessWidget {
  final List<CartItem> items;
  final DeliveryPlatform? selectedPlatform;
  final Function(DeliveryPlatform) onPlatformSelected;
  final Map<DeliveryPlatform, bool>? platformAvailability;

  const PlatformSelector({
    super.key,
    required this.items,
    required this.onPlatformSelected,
    this.selectedPlatform,
    this.platformAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题栏
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '选择外卖平台',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 商品摘要
            _buildItemsSummary(context),
            const SizedBox(height: 16),

            // 平台按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: DeliveryPlatform.values.map((platform) {
                return _PlatformButton(
                  platform: platform,
                  isSelected: platform == selectedPlatform,
                  isInstalled: platformAvailability?[platform] ?? true,
                  onTap: () => onPlatformSelected(platform),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 提示信息
            _buildHintText(context),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSummary(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalPrice = items.fold<double>(0, (sum, item) => sum + item.totalPrice);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              items.length == 1
                  ? items.first.name
                  : '${items.first.name}等${items.length}件商品',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '¥${totalPrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintText(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          Icons.info_outline,
          size: 14,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '点击后将打开所选平台App或网页版',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

/// 显示平台选择对话框
Future<DeliveryPlatform?> showPlatformSelectorDialog({
  required BuildContext context,
  required List<CartItem> items,
  Map<DeliveryPlatform, bool>? platformAvailability,
}) async {
  DeliveryPlatform? selected;

  final result = await showModalBottomSheet<DeliveryPlatform>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return PlatformSelector(
          items: items,
          selectedPlatform: selected,
          platformAvailability: platformAvailability,
          onPlatformSelected: (platform) {
            setState(() {
              selected = platform;
            });
          },
        );
      },
    ),
  );

  return result;
}
