import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/services/taste_profile_service.dart';
import '../../../core/services/user_preference_service.dart';
import '../../../shared/widgets/taste_radar_chart.dart';
import '../../../core/theme/glassmorphism_theme.dart';

/// 味觉画像可视化页面
/// 展示用户的口味偏好雷达图，支持编辑和重置
class TasteProfileScreen extends StatefulWidget {
  const TasteProfileScreen({super.key});

  @override
  State<TasteProfileScreen> createState() => _TasteProfileScreenState();
}

class _TasteProfileScreenState extends State<TasteProfileScreen>
    with TickerProviderStateMixin {
  late Map<String, double> _tasteProfile;
  bool _isEditing = false;
  bool _isLoading = true;

  // 统计数据
  final int _recommendedCount = 0;
  final int _likedCount = 0;
  final int _dislikedCount = 0;
  final double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTasteProfile();
  }

  Future<void> _loadTasteProfile() async {
    setState(() => _isLoading = true);

    try {
      // 获取用户偏好
      final preference = await UserPreferenceService.getUserPreference();

      // 构建完整46维味觉向量
      final fullTasteVector = Map<String, double>.from(preference.tastePreferences);

      // 降维到10维
      final primaryProfile = TasteProfileService().extractPrimaryDimensions(fullTasteVector);

      // 如果为空，初始化为默认值
      if (primaryProfile.values.every((v) => v == 0)) {
        for (final dim in TasteProfileService.primaryDimensions) {
          primaryProfile[dim] = 5.0; // 默认中间值
        }
      }

      setState(() {
        _tasteProfile = primaryProfile;
        _isLoading = false;
      });

      debugPrint('🍽️ 已加载味觉画像: $_tasteProfile');
    } catch (e) {
      debugPrint('加载味觉画像失败: $e');
      setState(() {
        _tasteProfile = {};
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    try {
      // 将编辑后的10维向量展开为46维
      final fullTasteVector = _expandToFullDimensions(_tasteProfile);

      // 保存到用户偏好
      final preference = await UserPreferenceService.getUserPreference();
      final updatedPreference = preference.copyWith(
        tastePreferences: fullTasteVector,
        lastUpdated: DateTime.now(),
      );

      await UserPreferenceService.saveUserPreference(updatedPreference);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('口味画像已保存'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }

      debugPrint('✅ 味觉画像已保存');
    } catch (e) {
      debugPrint('保存味觉画像失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 将10维向量展开为46维
  Map<String, double> _expandToFullDimensions(Map<String, double> primary) {
    final full = <String, double>{};

    for (final entry in TasteProfileService.dimensionMapping.entries) {
      final primaryValue = primary[entry.key] ?? 0;
      for (final dim in entry.value) {
        full[dim] = primaryValue;
      }
    }

    return full;
  }

  void _resetProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认重置'),
        content: const Text('重置后你的口味偏好将清空，确定要重置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performReset();
            },
            child: const Text('确认重置'),
          ),
        ],
      ),
    );
  }

  Future<void> _performReset() async {
    try {
      await UserPreferenceService.clearAllPreferences();

      // 重置为默认值
      final defaultProfile = <String, double>{};
      for (final dim in TasteProfileService.primaryDimensions) {
        defaultProfile[dim] = 0;
      }

      setState(() {
        _tasteProfile = defaultProfile;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('口味画像已重置'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('重置味觉画像失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景
          _buildBackground(),

          // 内容
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GlassmorphismTheme.primaryGradients.first,
            GlassmorphismTheme.primaryGradients.last,
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(),
          ),
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
              HapticFeedback.lightImpact();
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
              '口味画像',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (_isEditing) _saveProfile();
              setState(() => _isEditing = !_isEditing);
            },
            child: GlassmorphismTheme.glassContainer(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isEditing ? Icons.check : Icons.edit,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _isEditing ? '保存' : '编辑',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // 标题
          Text(
            '你的口味偏好',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '基于你的选择和互动学习得出',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withAlpha(179),
            ),
          ),
          SizedBox(height: 24.h),

          // 雷达图
          _buildRadarChart(),
          SizedBox(height: 24.h),

          // 编辑模式滑块
          if (_isEditing) _buildEditableSliders(),

          // 统计信息
          if (!_isEditing) _buildTasteStats(),
          SizedBox(height: 24.h),

          // 重置按钮
          _buildResetButton(),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildRadarChart() {
    return GlassmorphismTheme.floatingCard(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            SizedBox(
              height: 300.h,
              child: Center(
                child: TasteRadarChart(
                  data: _tasteProfile,
                  maxValue: 10.0,
                  fillColor: Theme.of(context).primaryColor,
                  borderColor: Theme.of(context).primaryColor,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // 图例
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12.w,
      runSpacing: 8.h,
      alignment: WrapAlignment.center,
      children: TasteProfileService.primaryDimensions.map((dim) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 4.w),
            Text(
              dim,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white.withAlpha(204),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEditableSliders() {
    return GlassmorphismTheme.floatingCard(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '调整口味偏好',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '拖动滑块调整各项口味强度 (-10 到 10)',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withAlpha(179),
              ),
            ),
            SizedBox(height: 16.h),
            ...TasteProfileService.primaryDimensions.map((dim) {
              return Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dim,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            _tasteProfile[dim]?.toStringAsFixed(1) ?? '0.0',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Theme.of(context).primaryColor,
                        inactiveTrackColor: Colors.white.withAlpha(51),
                        thumbColor: Colors.white,
                        overlayColor: Theme.of(context).primaryColor.withAlpha(51),
                        trackHeight: 4.h,
                      ),
                      child: Slider(
                        value: _tasteProfile[dim] ?? 0,
                        min: -10,
                        max: 10,
                        divisions: 20,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _tasteProfile[dim] = value;
                          });
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '不喜欢',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white.withAlpha(128),
                          ),
                        ),
                        Text(
                          '喜欢',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white.withAlpha(128),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTasteStats() {
    return GlassmorphismTheme.floatingCard(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '推荐统计',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.restaurant_menu,
                    label: '已推荐菜品',
                    value: '$_recommendedCount',
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.thumb_up,
                    label: '喜欢',
                    value: '$_likedCount',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.thumb_down,
                    label: '不喜欢',
                    value: '$_dislikedCount',
                    color: Colors.orange,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.star,
                    label: '平均评分',
                    value: _averageRating.toStringAsFixed(1),
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 24.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withAlpha(179),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return GlassmorphismTheme.floatingCard(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Text(
              '口味偏好基于你的选择自动学习',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withAlpha(179),
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _resetProfile,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  '重置口味画像',
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withAlpha(128)),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
