import 'package:flutter/material.dart';

/// 用户个人资料页面
class ProfileScreen extends StatelessWidget {
  final List<Widget> extraActions;

  const ProfileScreen({
    super.key,
    this.extraActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人资料'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 用户头像和基本信息
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.orange,
              child: Icon(Icons.star),
            ),
            const SizedBox(height: 16),
            const Text(
              '用户名',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'user@example.com',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // 个人设置项
            const ListTile(
              leading: Icon(Icons.favorite),
              title: Text('我的收藏'),
              trailing: Icon(Icons.chevron_right),
            ),
            const ListTile(
              leading: Icon(Icons.history),
              title: Text('使用历史'),
              trailing: Icon(Icons.chevron_right),
            ),
            const ListTile(
              leading: Icon(Icons.settings),
              title: Text('偏好设置'),
              trailing: Icon(Icons.chevron_right),
            ),
            const ListTile(
              leading: Icon(Icons.help),
              title: Text('帮助中心'),
              trailing: Icon(Icons.chevron_right),
            ),
            const ListTile(
              leading: Icon(Icons.info),
              title: Text('关于我们'),
              trailing: Icon(Icons.chevron_right),
            ),

            // 额外的操作按钮
            if (extraActions.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                '开发者调试',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ...extraActions,
            ],
          ],
        ),
      ),
    );
  }
}
