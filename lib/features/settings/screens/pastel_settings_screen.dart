import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../shared/themes/design_tokens.dart';
import '../../../shared/widgets/ui/rounded_card.dart';
import '../../../core/routes/app_router.dart';

/// 新样式设置界面（圆角奶油风）
class PastelSettingsScreen extends StatefulWidget {
  const PastelSettingsScreen({super.key});

  @override
  State<PastelSettingsScreen> createState() => _PastelSettingsScreenState();
}

class _PastelSettingsScreenState extends State<PastelSettingsScreen> {
  bool _enableHapticFeedback = true;
  bool _enableAnimations = true;
  bool _enableSoundEffects = false;
  bool _enableNotifications = true;
  bool _enableDarkMode = false;
  bool _enableAutoSave = true;

  void _saveSettings() {
    if (_enableHapticFeedback) HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设置已保存')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            RoundedCard(
              child: Column(
                children: [
                  _switchTile(
                    icon: Icons.vibration,
                    title: '触觉反馈',
                    subtitle: '交互时提供触觉反馈',
                    value: _enableHapticFeedback,
                    onChanged: (v) => setState(() => _enableHapticFeedback = v),
                  ),
                  _divider(),
                  _switchTile(
                    icon: Icons.animation,
                    title: '动画效果',
                    subtitle: '启用界面动画',
                    value: _enableAnimations,
                    onChanged: (v) => setState(() => _enableAnimations = v),
                  ),
                  _divider(),
                  _switchTile(
                    icon: Icons.notifications,
                    title: '通知',
                    subtitle: '接收推荐通知',
                    value: _enableNotifications,
                    onChanged: (v) => setState(() => _enableNotifications = v),
                  ),
                  _divider(),
                  _switchTile(
                    icon: Icons.dark_mode,
                    title: '深色模式',
                    subtitle: '自动切换深色主题',
                    value: _enableDarkMode,
                    onChanged: (v) => setState(() => _enableDarkMode = v),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            RoundedCard(
              child: Column(
                children: [
                  _switchTile(
                    icon: Icons.save,
                    title: '自动保存',
                    subtitle: '自动保存用户偏好',
                    value: _enableAutoSave,
                    onChanged: (v) => setState(() => _enableAutoSave = v),
                  ),
                  _divider(),
                  _navTile(
                    icon: Icons.info_outline,
                    title: '关于',
                    subtitle: '版本与开源协议',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.check_rounded),
              label: const Text('保存设置'),
            ),
            SizedBox(height: 12.h),
            OutlinedButton.icon(
              onPressed: () => AppNavigation.goToGlassmorphismHome(context),
              icon: const Icon(Icons.home_rounded),
              label: const Text('返回主页'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0x11000000));

  Widget _switchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      secondary: Icon(icon, color: DesignTokens.ink),
      title:
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: DesignTokens.ink)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: DesignTokens.inkMuted))
          : null,
      value: value,
      onChanged: (v) {
        onChanged(v);
        if (_enableHapticFeedback) HapticFeedback.lightImpact();
      },
    );
  }

  Widget _navTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Icon(icon, color: DesignTokens.ink),
      title:
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: DesignTokens.ink)),
      subtitle: Text(subtitle, style: const TextStyle(color: DesignTokens.inkMuted)),
      trailing: const Icon(Icons.chevron_right_rounded, color: DesignTokens.inkMuted),
      onTap: onTap,
    );
  }
}
