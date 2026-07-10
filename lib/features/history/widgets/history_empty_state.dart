import 'package:flutter/material.dart';

/// 历史记录空状态组件
class HistoryEmptyState extends StatelessWidget {
  final String filterBy;
  final VoidCallback? onClearFilter;

  const HistoryEmptyState({
    super.key,
    required this.filterBy,
    this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 空状态图标
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getEmptyIcon(),
                size: 60,
                color: Colors.grey[400],
              ),
            ),

            const SizedBox(height: 24),

            // 主要文本
            Text(
              _getEmptyTitle(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // 描述文本
            Text(
              _getEmptyDescription(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // 操作按钮
            ..._buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// 获取空状态图标
  IconData _getEmptyIcon() {
    switch (filterBy) {
      case 'today':
        return Icons.today;
      case 'week':
        return Icons.date_range;
      case 'month':
        return Icons.calendar_month;
      case 'all':
      default:
        return Icons.history;
    }
  }

  /// 获取空状态标题
  String _getEmptyTitle() {
    switch (filterBy) {
      case 'today':
        return '今日暂无浏览记录';
      case 'week':
        return '本周暂无浏览记录';
      case 'month':
        return '本月暂无浏览记录';
      case 'all':
      default:
        return '暂无浏览历史';
    }
  }

  /// 获取空状态描述
  String _getEmptyDescription() {
    switch (filterBy) {
      case 'today':
        return '今天还没有浏览过任何美食\n快去发现你喜欢的食物吧！';
      case 'week':
        return '本周还没有浏览过任何美食\n试试查看其他时间段的记录';
      case 'month':
        return '本月还没有浏览过任何美食\n试试查看其他时间段的记录';
      case 'all':
      default:
        return '还没有浏览过任何美食\n开始探索美食世界吧！';
    }
  }

  /// 构建操作按钮
  List<Widget> _buildActionButtons(BuildContext context) {
    final buttons = <Widget>[];

    // 如果是筛选状态且有清除筛选回调，显示清除筛选按钮
    if (filterBy != 'all' && onClearFilter != null) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: onClearFilter,
          icon: const Icon(Icons.clear),
          label: const Text('查看全部记录'),
        ),
      );
      buttons.add(const SizedBox(height: 12));
    }

    // 探索美食按钮
    buttons.add(
      ElevatedButton.icon(
        onPressed: () {
          // 切换到气泡页面
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        icon: const Icon(Icons.explore),
        label: const Text('去探索美食'),
      ),
    );

    return buttons;
  }
}
