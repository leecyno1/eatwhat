import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eatwhat_app/core/services/deep_link_service.dart';
import 'controllers/cart_controller.dart';
import 'widgets/cart_item_card.dart';
import 'widgets/platform_selector.dart';

/// 购物车页面
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartController(),
      child: const _CartScreenContent(),
    );
  }
}

class _CartScreenContent extends StatelessWidget {
  const _CartScreenContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('购物车'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<CartController>(
            builder: (context, controller, _) {
              if (controller.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _showClearCartDialog(context, controller),
                child: Text(
                  '清空',
                  style: TextStyle(color: colorScheme.error),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // 商品列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: controller.items.length,
                  itemBuilder: (context, index) {
                    final item = controller.items[index];
                    return CartItemCard(
                      item: item,
                      onIncrement: () => controller.incrementQuantity(item.id),
                      onDecrement: () => controller.decrementQuantity(item.id),
                      onDelete: () => controller.removeFromCart(item.id),
                    );
                  },
                ),
              ),
              // 结算栏
              _buildCheckoutBar(context, controller),
            ],
          );
        },
      ),
    );
  }

  /// 构建空购物车状态
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '购物车是空的',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '快去挑选美食吧',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('去点餐'),
          ),
        ],
      ),
    );
  }

  /// 构建结算栏
  Widget _buildCheckoutBar(BuildContext context, CartController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 价格明细
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '共 ${controller.itemCount} 件商品',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '小计: ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '¥${controller.subtotal.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // 配送费
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '配送费',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      if (controller.deliveryFee == 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '已免',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      Text(
                        controller.deliveryFee == 0
                            ? '¥0.00'
                            : '¥${controller.deliveryFee.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: controller.deliveryFee == 0
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // 配送费提示
              if (controller.deliveryFee > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        controller.deliveryFeeHint,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // 总计与结算按钮
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '合计',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '¥',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              controller.total.toStringAsFixed(2),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () => _handleCheckout(context, controller),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      '去结算',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示清空购物车对话框
  void _showClearCartDialog(BuildContext context, CartController controller) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空购物车'),
        content: const Text('确定要清空购物车中的所有商品吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              controller.clearCart();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  /// 处理结算按钮点击
  void _handleCheckout(BuildContext context, CartController controller) {
    _showPlatformSelector(context, controller);
  }

  /// 显示平台选择器
  Future<void> _showPlatformSelector(
    BuildContext context,
    CartController controller,
  ) async {
    final deepLinkService = DeepLinkService();
    final navigator = Navigator.of(context);

    // 显示加载状态
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在检测平台...'),
              ],
            ),
          ),
        ),
      ),
    );

    // 检测平台可用性
    final platformAvailability = await deepLinkService.checkPlatformsAvailability();

    // 关闭加载对话框
    if (context.mounted) {
      navigator.pop();
    }

    // 显示平台选择对话框
    if (!context.mounted) return;
    final selectedPlatform = await showPlatformSelectorDialog(
      context: context,
      items: controller.items,
      platformAvailability: platformAvailability,
    );

    if (selectedPlatform == null || !context.mounted) {
      return;
    }

    // 执行跳转
    await _performPlatformJump(context, controller, selectedPlatform);
  }

  /// 执行平台跳转
  Future<void> _performPlatformJump(
    BuildContext context,
    CartController controller,
    DeliveryPlatform platform,
  ) async {
    final deepLinkService = DeepLinkService();
    final colorScheme = Theme.of(context).colorScheme;

    // 显示跳转进度
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('正在打开${platform.displayName}...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final usedApp = await deepLinkService.openPlatformWithCart(
        platform,
        controller.items,
      );

      // 关闭进度对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // 显示结果提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  usedApp ? Icons.check_circle : Icons.public,
                  color: colorScheme.onInverseSurface,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    usedApp
                        ? '已打开${platform.displayName}App'
                        : '已打开${platform.displayName}网页版',
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      debugPrint(
        '[CartScreen] 跳转${platform.displayName}成功, usedApp=$usedApp',
      );
    } catch (e) {
      // 关闭进度对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // 显示错误提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: colorScheme.onInverseSurface,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('打开${platform.displayName}失败: $e'),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: colorScheme.error,
          ),
        );
      }

      debugPrint('[CartScreen] 跳转${platform.displayName}失败: $e');
    }
  }
}
