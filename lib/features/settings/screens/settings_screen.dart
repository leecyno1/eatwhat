import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/glassmorphism_theme.dart';
import '../../../shared/widgets/glassmorphism_button.dart';
import '../../../core/routes/app_router.dart';
import '../../preferences/screens/taste_profile_screen.dart';

/// Glassmorphism风格设置界面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  bool _enableHapticFeedback = true;
  bool _enableParticleEffects = true;
  bool _enableAnimations = true;
  bool _enableSoundEffects = false;
  bool _enableNotifications = true;
  bool _enableDarkMode = false;
  bool _enableAutoSave = true;

  // DEBUG 模式或管理员可查看运营数据
  final bool _isDebugMode = true; // 实际应从配置读取
  final bool _isAdmin = true; // 实际应从用户权限读取

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _backgroundController.repeat(reverse: true);
  }

  void _loadSettings() {
    // TODO: 从本地存储加载设置
    setState(() {
      _enableHapticFeedback = true;
      _enableParticleEffects = true;
      _enableAnimations = true;
      _enableSoundEffects = false;
      _enableNotifications = true;
      _enableDarkMode = false;
      _enableAutoSave = true;
    });
  }

  void _saveSettings() {
    // TODO: 保存设置到本地存储
    if (_enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('设置已保存'),
        backgroundColor: GlassmorphismTheme.primaryGradients.first,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 动画背景
          _buildAnimatedBackground(),

          // 主内容
          _buildMainContent(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return GlassmorphismTheme.animatedGradientBackground(
          gradientSets: [
            GlassmorphismTheme.primaryGradients,
            GlassmorphismTheme.secondaryGradients,
            GlassmorphismTheme.accentGradients,
            GlassmorphismTheme.warmGradients,
          ],
          duration: const Duration(seconds: 20),
          child: Container(),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildSettingsList(),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GlassmorphismTheme.floatingCard(
      margin: EdgeInsets.all(16.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_enableHapticFeedback) {
                HapticFeedback.lightImpact();
              }
              Navigator.of(context).pop();
            },
            child: GlassmorphismTheme.glassContainer(
              padding: EdgeInsets.all(12.w),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              '设置',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: _saveSettings,
            child: GlassmorphismTheme.glassContainer(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                '保存',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList() {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _buildSettingsSection(
          title: '界面设置',
          icon: Icons.palette,
          children: [
            _buildSettingItem(
              icon: Icons.vibration,
              title: '触觉反馈',
              subtitle: '交互时提供触觉反馈',
              value: _enableHapticFeedback,
              onChanged: (value) {
                setState(() {
                  _enableHapticFeedback = value;
                });
                if (value) {
                  HapticFeedback.lightImpact();
                }
              },
            ),
            _buildSettingItem(
              icon: Icons.auto_awesome,
              title: '粒子效果',
              subtitle: '显示背景粒子动画',
              value: _enableParticleEffects,
              onChanged: (value) {
                setState(() {
                  _enableParticleEffects = value;
                });
              },
            ),
            _buildSettingItem(
              icon: Icons.animation,
              title: '动画效果',
              subtitle: '启用界面动画',
              value: _enableAnimations,
              onChanged: (value) {
                setState(() {
                  _enableAnimations = value;
                });
              },
            ),
            _buildSettingItem(
              icon: Icons.dark_mode,
              title: '深色模式',
              subtitle: '自动切换深色主题',
              value: _enableDarkMode,
              onChanged: (value) {
                setState(() {
                  _enableDarkMode = value;
                });
              },
            ),
          ],
        ),
        SizedBox(height: 24.h),
        _buildSettingsSection(
          title: '功能设置',
          icon: Icons.settings,
          children: [
            _buildInfoItem(
              icon: Icons.radar,
              title: '口味画像',
              subtitle: '查看和编辑你的口味偏好',
              onTap: () {
                if (_enableHapticFeedback) {
                  HapticFeedback.lightImpact();
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TasteProfileScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.volume_up,
              title: '音效',
              subtitle: '播放操作音效',
              value: _enableSoundEffects,
              onChanged: (value) {
                setState(() {
                  _enableSoundEffects = value;
                });
              },
            ),
            _buildSettingItem(
              icon: Icons.notifications,
              title: '通知',
              subtitle: '接收推荐通知',
              value: _enableNotifications,
              onChanged: (value) {
                setState(() {
                  _enableNotifications = value;
                });
              },
            ),
            _buildSettingItem(
              icon: Icons.save,
              title: '自动保存',
              subtitle: '自动保存用户偏好',
              value: _enableAutoSave,
              onChanged: (value) {
                setState(() {
                  _enableAutoSave = value;
                });
              },
            ),
          ],
        ),
        SizedBox(height: 24.h),
        _buildSettingsSection(
          title: '关于',
          icon: Icons.info,
          children: [
            _buildInfoItem(
              icon: Icons.apps,
              title: '应用版本',
              subtitle: '1.0.0',
              onTap: () {
                // 显示版本信息
              },
            ),
            _buildInfoItem(
              icon: Icons.description,
              title: '用户协议',
              subtitle: '查看用户协议和隐私政策',
              onTap: () {
                // 打开用户协议
              },
            ),
            _buildInfoItem(
              icon: Icons.feedback,
              title: '意见反馈',
              subtitle: '向我们反馈问题或建议',
              onTap: () {
                // 打开反馈界面
              },
            ),
            // DEBUG 模式或管理员显示运营数据入口
            if (_isDebugMode || _isAdmin)
              _buildInfoItem(
                icon: Icons.analytics,
                title: '运营数据',
                subtitle: '查看核心指标看板',
                onTap: () {
                  if (_enableHapticFeedback) {
                    HapticFeedback.lightImpact();
                  }
                  AppNavigation.pushMetricsDashboard(context);
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return GlassmorphismTheme.floatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.8),
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40.w,
              height: 20.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                color: value
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
              ),
              child: AnimatedAlign(
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 16.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.8),
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.6),
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return GlassmorphismTheme.floatingCard(
      margin: EdgeInsets.all(16.w),
      child: Column(
        children: [
          GlassmorphismButton(
            text: '重置所有设置',
            icon: const Icon(Icons.refresh),
            style: GlassmorphismButtonStyle.warning,
            onPressed: () {
              if (_enableHapticFeedback) {
                HapticFeedback.mediumImpact();
              }
              _showResetConfirmation();
            },
          ),
          SizedBox(height: 12.h),
          GlassmorphismButton(
            text: '返回主页',
            icon: const Icon(Icons.home),
            style: GlassmorphismButtonStyle.primary,
            onPressed: () {
              if (_enableHapticFeedback) {
                HapticFeedback.lightImpact();
              }
              AppNavigation.goToGlassmorphismHome(context);
            },
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => GlassmorphismTheme.glassContainer(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning,
              color: Colors.orange,
              size: 48.sp,
            ),
            SizedBox(height: 16.h),
            Text(
              '重置设置',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '确定要重置所有设置吗？此操作无法撤销。',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GlassmorphismButton(
                  text: '取消',
                  style: GlassmorphismButtonStyle.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                GlassmorphismButton(
                  text: '重置',
                  style: GlassmorphismButtonStyle.danger,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetAllSettings();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _resetAllSettings() {
    setState(() {
      _enableHapticFeedback = true;
      _enableParticleEffects = true;
      _enableAnimations = true;
      _enableSoundEffects = false;
      _enableNotifications = true;
      _enableDarkMode = false;
      _enableAutoSave = true;
    });

    if (_enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('设置已重置'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}
