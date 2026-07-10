import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/food.dart';

/// 渠道选择弹窗
/// 用户选择推荐菜品后显示获取渠道选择
class ChannelSelectorDialog extends StatefulWidget {
  final Food selectedFood;
  final VoidCallback? onDismiss;

  const ChannelSelectorDialog({
    super.key,
    required this.selectedFood,
    this.onDismiss,
  });

  @override
  State<ChannelSelectorDialog> createState() => _ChannelSelectorDialogState();
}

class _ChannelSelectorDialogState extends State<ChannelSelectorDialog>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          // 背景点击区域
          GestureDetector(
            onTap: _dismissDialog,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),

          // 主内容
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_slideAnimation, _scaleAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildFoodInfo(),
                          const SizedBox(height: 32),
                          _buildChannelGrid(),
                          const SizedBox(height: 24),
                          _buildCloseButton(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建头部标题
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade400,
                Colors.deepOrange.shade500,
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.restaurant_menu,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '获取美食',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '选择您想要的获取方式',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  /// 构建食物信息
  Widget _buildFoodInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // 食物图片
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (widget.selectedFood.imageUrl?.isNotEmpty ?? false)
                ? Image.network(
                    widget.selectedFood.imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
          ),
          const SizedBox(width: 16),

          // 食物信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedFood.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.selectedFood.cuisineType ?? '美食',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.selectedFood.rating}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建占位图片
  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.restaurant,
        color: Colors.grey.shade500,
        size: 24,
      ),
    );
  }

  /// 构建渠道网格
  Widget _buildChannelGrid() {
    final channels = _getChannels();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '选择获取渠道',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
        ),
        const SizedBox(height: 16),
        // 使用固定高度的容器来避免溢出
        SizedBox(
          height: 200, // 固定高度
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9, // 调整比例
            ),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return _buildChannelCard(channel);
            },
          ),
        ),
      ],
    );
  }

  /// 构建渠道卡片
  Widget _buildChannelCard(ChannelOption channel) {
    return GestureDetector(
      onTap: () => _selectChannel(channel),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: channel.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                channel.icon,
                color: channel.color,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              channel.title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              channel.subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建关闭按钮
  Widget _buildCloseButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _dismissDialog,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Text(
          '关闭',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 获取渠道选项
  List<ChannelOption> _getChannels() {
    return [
      ChannelOption(
        id: 'delivery',
        title: '外卖订购',
        subtitle: '美团/饿了么',
        icon: Icons.delivery_dining,
        color: Colors.orange,
        type: ChannelType.delivery,
      ),
      ChannelOption(
        id: 'review',
        title: '餐厅点评',
        subtitle: '大众点评',
        icon: Icons.star_rate,
        color: Colors.amber,
        type: ChannelType.review,
      ),
      ChannelOption(
        id: 'recipe',
        title: '学做菜谱',
        subtitle: '下厨房',
        icon: Icons.menu_book,
        color: Colors.green,
        type: ChannelType.recipe,
      ),
      ChannelOption(
        id: 'video',
        title: '视频教程',
        subtitle: '美食视频',
        icon: Icons.play_circle,
        color: Colors.red,
        type: ChannelType.video,
      ),
      ChannelOption(
        id: 'shopping',
        title: '食材购买',
        subtitle: '生鲜电商',
        icon: Icons.shopping_cart,
        color: Colors.blue,
        type: ChannelType.shopping,
      ),
      ChannelOption(
        id: 'social',
        title: '分享讨论',
        subtitle: '小红书',
        icon: Icons.share,
        color: Colors.pink,
        type: ChannelType.social,
      ),
    ];
  }

  /// 选择渠道
  void _selectChannel(ChannelOption channel) async {
    HapticFeedback.mediumImpact();

    try {
      final success = await _launchChannel(channel);
      if (success) {
        _dismissDialog();
      } else {
        _showErrorSnackBar('暂时无法打开${channel.title}');
      }
    } catch (e) {
      _showErrorSnackBar('打开${channel.title}时出现错误');
    }
  }

  /// 启动渠道
  Future<bool> _launchChannel(ChannelOption channel) async {
    final foodName = widget.selectedFood.name;
    final encodedFoodName = Uri.encodeComponent(foodName);

    String url = '';

    switch (channel.type) {
      case ChannelType.delivery:
        // 尝试打开美团外卖
        url = 'imeituan://www.meituan.com/search?q=$encodedFoodName';
        if (!await launchUrl(Uri.parse(url))) {
          // 备用方案：网页版
          url = 'https://www.meituan.com/search?q=$encodedFoodName';
        }
        break;

      case ChannelType.review:
        // 大众点评
        url = 'dianping://search?keyword=$encodedFoodName';
        if (!await launchUrl(Uri.parse(url))) {
          url = 'https://www.dianping.com/search/keyword/1/0_$encodedFoodName';
        }
        break;

      case ChannelType.recipe:
        // 下厨房
        url = 'xiachufang://search?keyword=$encodedFoodName';
        if (!await launchUrl(Uri.parse(url))) {
          url = 'https://www.xiachufang.com/search/?keyword=$encodedFoodName';
        }
        break;

      case ChannelType.video:
        // 视频平台搜索
        url = 'https://www.bilibili.com/search?keyword=${encodedFoodName}制作';
        break;

      case ChannelType.shopping:
        // 生鲜电商
        url = 'https://www.jd.com/search?keyword=${encodedFoodName}食材';
        break;

      case ChannelType.social:
        // 小红书
        url = 'xhsdiscover://search/result?keyword=$encodedFoodName';
        if (!await launchUrl(Uri.parse(url))) {
          url = 'https://www.xiaohongshu.com/search_result?keyword=$encodedFoodName';
        }
        break;
    }

    if (url.isNotEmpty) {
      return await launchUrl(Uri.parse(url));
    }

    return false;
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 关闭对话框
  void _dismissDialog() async {
    await _slideController.reverse();
    await _scaleController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
      widget.onDismiss?.call();
    }
  }

  /// 显示渠道选择对话框 (静态方法)
  static Future<void> showChannelSelector(
    BuildContext context,
    Food selectedFood, {
    VoidCallback? onDismiss,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => ChannelSelectorDialog(
        selectedFood: selectedFood,
        onDismiss: onDismiss,
      ),
    );
  }
}

/// 渠道选项
class ChannelOption {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final ChannelType type;

  const ChannelOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.type,
  });
}

/// 渠道类型
enum ChannelType {
  delivery, // 外卖
  review, // 点评
  recipe, // 菜谱
  video, // 视频
  shopping, // 购物
  social, // 社交
}
